const { db } = require("../firebase");

const genOtp = () => String(Math.floor(1000 + Math.random() * 9000));

const normalizeCurrencyAmount = (value) => {
  const numeric = Number(value || 0);
  if (!Number.isFinite(numeric)) return 0;
  return Number(Math.round(numeric).toFixed(2));
};

const enrichBooking = async (booking) => {
  const enriched = { ...booking };

  const [userDoc, repairmanDoc, serviceDoc] = await Promise.all([
    booking.user_id ? db.collection("users").doc(String(booking.user_id)).get() : null,
    booking.repairman_id
      ? db.collection("repairmen").doc(String(booking.repairman_id)).get()
      : null,
    booking.service_id ? db.collection("services").doc(String(booking.service_id)).get() : null,
  ]);

  if (userDoc && userDoc.exists) {
    const user = userDoc.data() || {};
    enriched.user_name = user.name || enriched.user_name || "";
  }

  if (repairmanDoc && repairmanDoc.exists) {
    const repairman = repairmanDoc.data() || {};
    enriched.repairman_name =
      enriched.repairman_name || repairman.name || enriched.repairman_name || "";
    enriched.specialty =
      enriched.specialty || repairman.specialization || enriched.specialty || "";
  }

  if (serviceDoc && serviceDoc.exists) {
    const service = serviceDoc.data() || {};
    enriched.service_name = service.service_name || enriched.service_name || "";
  }

  return enriched;
};

exports.createBooking = async (req, res) => {
  try {
    const {
      serviceId,
      repairmanId,
      bookingDate,
      scheduledTime,
      booking_type,
      booking_mode,
      hourly_rate,
      booked_hours,
      repairman_name,
      specialty,
      payment_method,
      paid_from_wallet,
      total_amount,
      issue_description,
      emergency_priority,
      emergency_request,
      user_latitude,
      user_longitude,
      userLatitude,
      userLongitude,
    } = req.body;
    const { userId, role } = req.user;

    if (role !== "user") return res.status(403).json({ message: "Only users can book" });
    if (!repairmanId || !bookingDate || !scheduledTime) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const normalizedServiceId = String(serviceId || "").trim();
    const normalizedBookingMode = String(booking_mode || "").trim();
    const normalizedRepairmanName = String(repairman_name || "").trim();
    const normalizedSpecialty = String(specialty || "").trim();
    const hasHourlyMetadata =
      hourly_rate !== undefined ||
      booked_hours !== undefined ||
      normalizedBookingMode.length > 0 ||
      normalizedRepairmanName.length > 0 ||
      normalizedSpecialty.length > 0;
    const looksLikeDirectServiceLabel =
      normalizedServiceId.toLowerCase().startsWith("hourly booking") ||
      normalizedServiceId.toLowerCase().startsWith("pay as you go");
    const isDirectRepairmanBooking =
      booking_type === "direct_repairman" ||
      hasHourlyMetadata ||
      looksLikeDirectServiceLabel;

    if (!isDirectRepairmanBooking && !normalizedServiceId) {
      return res.status(400).json({ message: "serviceId required for service booking" });
    }

    let resolvedTotalAmount = 0;
    if (isDirectRepairmanBooking) {
      resolvedTotalAmount = Number(total_amount || 0);
    } else {
      const serviceDoc = await db.collection("services").doc(normalizedServiceId).get();
      if (!serviceDoc.exists) return res.status(404).json({ message: "Service not found" });

      const basePrice = Number(serviceDoc.data().base_price || 0);

      const rsDoc = await db
        .collection("repairmen")
        .doc(repairmanId)
        .collection("services")
        .doc(normalizedServiceId)
        .get();

      const customPrice = rsDoc.exists ? Number(rsDoc.data().custom_price || 0) : 0;
      resolvedTotalAmount = customPrice > 0 ? customPrice : basePrice;
    }
    const latitude = user_latitude ?? userLatitude;
    const longitude = user_longitude ?? userLongitude;

    const bookingRef = await db.collection("bookings").add({
      user_id: userId,
      repairman_id: repairmanId,
      service_id: isDirectRepairmanBooking ? "" : normalizedServiceId,
      booking_date: new Date(bookingDate),
      scheduled_time: scheduledTime,
      status: "pending",
      total_amount: resolvedTotalAmount,
      booking_type: isDirectRepairmanBooking ? "direct_repairman" : "service_booking",
      booking_mode: normalizedBookingMode,
      hourly_rate: hourly_rate !== undefined ? Number(hourly_rate) : null,
      booked_hours: booked_hours !== undefined ? Number(booked_hours) : null,
      repairman_name: normalizedRepairmanName,
      specialty: normalizedSpecialty,
      payment_method: payment_method || "",
      paid_from_wallet: paid_from_wallet === true,
      issue_description: String(issue_description || "").trim(),
      emergency_priority: String(emergency_priority || "").trim(),
      emergency_request: emergency_request === true,
      otp_verification: genOtp(),
      user_latitude: latitude !== undefined ? Number(latitude) : null,
      user_longitude: longitude !== undefined ? Number(longitude) : null,
      created_at: new Date(),
      updated_at: new Date(),
    });

    return res.status(201).json({ message: "Booking created", bookingId: bookingRef.id });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.getMyBookings = async (req, res) => {
  try {
    const { userId, role } = req.user;

    let q;
    if (role === "user") q = db.collection("bookings").where("user_id", "==", userId);
    else if (role === "repairman") q = db.collection("bookings").where("repairman_id", "==", userId);
    else return res.status(403).json({ message: "Access denied" });

    const snap = await q.get();
    const bookings = await Promise.all(
      snap.docs.map((d) => enrichBooking({ id: d.id, ...d.data() }))
    );

    return res.json({ bookings });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.updateBookingStatus = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { status, arrival_confirmed } = req.body;
    const { userId, role } = req.user;
    const hasArrivalConfirmation = Object.prototype.hasOwnProperty.call(
      req.body || {},
      "arrival_confirmed"
    );

    const bDoc = await db.collection("bookings").doc(bookingId).get();
    if (!bDoc.exists) return res.status(404).json({ message: "Booking not found" });

    const booking = bDoc.data();

    if (role === "repairman" && booking.repairman_id !== userId) {
      return res.status(403).json({ message: "Not your booking" });
    }
    if (role === "user" && booking.user_id !== userId) {
      return res.status(403).json({ message: "Not your booking" });
    }

    const update = { updated_at: new Date() };

    if (hasArrivalConfirmation) {
      if (role !== "user") {
        return res.status(403).json({ message: "Only users can confirm arrival" });
      }
      if (booking.status !== "reached_destination") {
        return res.status(400).json({ message: "Arrival can only be confirmed after repairman reaches destination" });
      }

      if (arrival_confirmed === true) {
        update.arrival_confirmed_by_user = true;
        update.arrival_confirmation = "yes";
        update.arrival_confirmed_at = new Date();
      } else {
        update.status = "booking_confirmed";
        update.arrival_confirmed_by_user = false;
        update.arrival_confirmation = "no";
        update.arrival_denied_at = new Date();
        update.reached_destination_at = null;
      }

      await db.collection("bookings").doc(bookingId).update(update);
      return res.json({
        message: arrival_confirmed === true
          ? "Arrival confirmed"
          : "Arrival denied. Booking moved back to confirmed",
      });
    }

    if (!status) return res.status(400).json({ message: "Status required" });

    update.status = status;
    if (status === "booking_confirmed") update.confirmed_at = new Date();
    if (status === "reached_destination") update.reached_destination_at = new Date();
    if (status === "arrival_confirmed") {
      update.arrival_confirmed_by_user = true;
      update.arrival_confirmation = "yes";
      update.arrival_confirmed_at = new Date();
    }
    if (status === "completed") {
      const bookingMode = String(booking.booking_mode || "").trim();
      const hasDirectMetadata =
        booking.hourly_rate !== undefined && booking.hourly_rate !== null ||
        booking.booked_hours !== undefined && booking.booked_hours !== null ||
        bookingMode.length > 0 ||
        String(booking.specialty || "").trim().length > 0 ||
        String(booking.repairman_name || "").trim().length > 0;
      const isDirectRepairmanBooking =
        booking.booking_type === "direct_repairman" ||
        hasDirectMetadata;

      update.completed_at = new Date();

      if (isDirectRepairmanBooking) {
        const reachedAt = booking.reached_destination_at?.toDate
          ? booking.reached_destination_at.toDate()
          : booking.reached_destination_at
          ? new Date(booking.reached_destination_at)
          : booking.arrival_confirmed_at?.toDate
          ? booking.arrival_confirmed_at.toDate()
          : booking.arrival_confirmed_at
          ? new Date(booking.arrival_confirmed_at)
          : booking.confirmed_at?.toDate
          ? booking.confirmed_at.toDate()
          : booking.confirmed_at
          ? new Date(booking.confirmed_at)
          : null;
        const completedAt = new Date();
        const durationMinutes = reachedAt
          ? Math.max(1, Math.round((completedAt.getTime() - reachedAt.getTime()) / 60000))
          : 0;
        const hourlyRate = Number(booking.hourly_rate || 0);
        const payableAmount = normalizeCurrencyAmount(
          (durationMinutes / 60) * hourlyRate
        );

        update.completed_at = completedAt;
        update.actual_duration_minutes = durationMinutes;
        update.calculated_amount = payableAmount;
        update.total_amount = payableAmount > 0 ? payableAmount : Number(booking.total_amount || 0);
      }
    }

    await db.collection("bookings").doc(bookingId).update(update);

    return res.json({ message: "Booking status updated" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// OTP verify + mark completed (repairman only)
exports.verifyOtpAndComplete = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { otp } = req.body;
    const { userId, role } = req.user;

    if (!otp) return res.status(400).json({ message: "otp required" });

    const bRef = db.collection("bookings").doc(bookingId);
    const bDoc = await bRef.get();

    if (!bDoc.exists) return res.status(404).json({ message: "Booking not found" });

    const booking = bDoc.data();

    if (role !== "repairman") {
      return res.status(403).json({ message: "Only repairman can verify OTP" });
    }
    if (booking.repairman_id !== userId) {
      return res.status(403).json({ message: "Not your booking" });
    }

    if (String(booking.otp_verification) !== String(otp)) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    await bRef.update({
      status: "completed",
      updated_at: new Date(),
    });

    return res.json({ message: "OTP verified. Booking completed." });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
