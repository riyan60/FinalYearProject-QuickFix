const { db } = require("../firebase");

const genOtp = () => String(Math.floor(1000 + Math.random() * 9000));

const normalizeCurrencyAmount = (value) => {
  const numeric = Number(value || 0);
  if (!Number.isFinite(numeric)) return 0;
  return Number(Math.round(numeric).toFixed(2));
};

const toDateOrNull = (value) => {
  if (!value) return null;
  if (typeof value?.toDate === "function") {
    const resolved = value.toDate();
    return Number.isNaN(resolved.getTime()) ? null : resolved;
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
};

const getScheduledStartAt = (booking) => {
  const baseDate = toDateOrNull(booking.booking_date);
  if (!baseDate) return null;

  const scheduledTime = String(booking.scheduled_time || "").trim().toUpperCase();
  if (!scheduledTime) {
    return new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate());
  }

  const match = scheduledTime.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/);
  if (!match) {
    return new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate());
  }

  const hour12 = Number.parseInt(match[1], 10);
  const minute = Number.parseInt(match[2], 10);
  const period = match[3];

  if (
    !Number.isFinite(hour12) ||
    !Number.isFinite(minute) ||
    hour12 < 1 ||
    hour12 > 12 ||
    minute < 0 ||
    minute > 59
  ) {
    return new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate());
  }

  let hour24 = hour12 % 12;
  if (period === "PM") hour24 += 12;

  return new Date(
    baseDate.getFullYear(),
    baseDate.getMonth(),
    baseDate.getDate(),
    hour24,
    minute,
    0,
    0
  );
};

const getCancellationDeadline = (booking) => {
  const createdAt = toDateOrNull(booking.created_at);
  const scheduledStartAt = getScheduledStartAt(booking);
  if (!createdAt || !scheduledStartAt) return null;

  const totalLeadMs = scheduledStartAt.getTime() - createdAt.getTime();
  if (totalLeadMs <= 0) return null;

  const allowedMs = Math.round(totalLeadMs * 0.2);
  return new Date(createdAt.getTime() + allowedMs);
};

const applyCompletionState = (booking, update) => {
  const bookingMode = String(booking.booking_mode || "").trim();
  const hasDirectMetadata =
    booking.hourly_rate !== undefined && booking.hourly_rate !== null ||
    booking.booked_hours !== undefined && booking.booked_hours !== null ||
    bookingMode.length > 0 ||
    String(booking.specialty || "").trim().length > 0 ||
    String(booking.repairman_name || "").trim().length > 0;
  const isDirectRepairmanBooking =
    booking.booking_type === "direct_repairman" || hasDirectMetadata;

  const completedAt = new Date();
  update.status = "completed";
  update.completed_at = completedAt;

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
    const durationMinutes = reachedAt
      ? Math.max(1, Math.round((completedAt.getTime() - reachedAt.getTime()) / 60000))
      : 0;
    const hourlyRate = Number(booking.hourly_rate || 0);
    const payableAmount = normalizeCurrencyAmount((durationMinutes / 60) * hourlyRate);

    update.actual_duration_minutes = durationMinutes;
    update.calculated_amount = payableAmount;
    update.total_amount = payableAmount > 0 ? payableAmount : Number(booking.total_amount || 0);
  }
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
    if (
      (enriched.user_latitude === undefined ||
        enriched.user_latitude === null ||
        enriched.user_latitude === "") &&
      user.latitude !== undefined &&
      user.latitude !== null
    ) {
      enriched.user_latitude = Number(user.latitude);
    }
    if (
      (enriched.user_longitude === undefined ||
        enriched.user_longitude === null ||
        enriched.user_longitude === "") &&
      user.longitude !== undefined &&
      user.longitude !== null
    ) {
      enriched.user_longitude = Number(user.longitude);
    }
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
    const { status, arrival_confirmed, completion_confirmed } = req.body;
    const { userId, role } = req.user;
    const hasArrivalConfirmation = Object.prototype.hasOwnProperty.call(
      req.body || {},
      "arrival_confirmed"
    );
    const hasCompletionConfirmation = Object.prototype.hasOwnProperty.call(
      req.body || {},
      "completion_confirmed"
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

    if (hasCompletionConfirmation) {
      const allowedStatuses = [
        "in_progress",
        "reached_destination",
        "arrival_confirmed",
        "completion_pending_user",
        "completion_pending_repairman",
      ];
      if (!allowedStatuses.includes(String(booking.status || "").trim())) {
        return res.status(400).json({ message: "Completion cannot be confirmed from current status" });
      }
      if (completion_confirmed !== true) {
        return res.status(400).json({ message: "completion_confirmed must be true" });
      }

      const update = { updated_at: new Date() };
      const userConfirmed =
        role === "user" ? true : booking.user_completion_confirmed === true;
      const repairmanConfirmed =
        role === "repairman"
          ? true
          : booking.repairman_completion_confirmed === true;

      if (role === "user") {
        update.user_completion_confirmed = true;
        update.user_completion_confirmed_at = new Date();
      } else if (role === "repairman") {
        update.repairman_completion_confirmed = true;
        update.repairman_completion_confirmed_at = new Date();
      } else {
        return res.status(403).json({ message: "Access denied" });
      }

      if (userConfirmed && repairmanConfirmed) {
        applyCompletionState(booking, update);
      } else {
        update.status = role === "user"
          ? "completion_pending_repairman"
          : "completion_pending_user";
      }

      await db.collection("bookings").doc(bookingId).update(update);
      return res.json({
        message:
          update.status === "completed"
            ? "Booking completed"
            : "Completion confirmed. Waiting for the other party.",
        status: update.status,
      });
    }

    if (!status) return res.status(400).json({ message: "Status required" });

    if (status === "cancelled") {
      if (role !== "user") {
        return res.status(403).json({ message: "Only users can cancel bookings" });
      }

      const currentStatus = String(booking.status || "").trim().toLowerCase();
      const blockedStatuses = new Set([
        "cancelled",
        "completed",
        "rejected",
        "completion_pending_user",
        "completion_pending_repairman",
      ]);
      if (blockedStatuses.has(currentStatus)) {
        return res
          .status(400)
          .json({ message: "Booking cannot be cancelled from current status" });
      }

      const cancelDeadline = getCancellationDeadline(booking);
      if (!cancelDeadline) {
        return res.status(400).json({
          message: "Cannot evaluate cancellation window for this booking",
        });
      }

      if (Date.now() > cancelDeadline.getTime()) {
        return res.status(400).json({
          message:
            "Cancellation is allowed only in first 20% of time between booking creation and scheduled time",
        });
      }

      update.status = "cancelled";
      update.cancelled_at = new Date();
      update.cancelled_by = userId;

      await db.collection("bookings").doc(bookingId).update(update);
      return res.json({ message: "Booking cancelled", status: "cancelled" });
    }

    if (status === "rejected") {
      if (role !== "repairman") {
        return res.status(403).json({ message: "Only repairmen can reject bookings" });
      }
      if (booking.status !== "pending") {
        return res.status(400).json({ message: "Only pending bookings can be rejected" });
      }

      update.status = "rejected";
      update.rejected_at = new Date();
      update.rejected_by = userId;

      await db.collection("bookings").doc(bookingId).update(update);
      return res.json({ message: "Booking rejected", status: "rejected" });
    }

    update.status = status;
    if (status === "booking_confirmed") update.confirmed_at = new Date();
    if (status === "reached_destination") update.reached_destination_at = new Date();
    if (status === "arrival_confirmed") {
      update.arrival_confirmed_by_user = true;
      update.arrival_confirmation = "yes";
      update.arrival_confirmed_at = new Date();
    }
    if (status === "completed") {
      const allowedStatuses = [
        "in_progress",
        "reached_destination",
        "arrival_confirmed",
        "completion_pending_user",
        "completion_pending_repairman",
      ];
      if (!allowedStatuses.includes(String(booking.status || "").trim())) {
        return res.status(400).json({ message: "Cannot complete booking from current status" });
      }
      if (role !== "repairman" && role !== "user") {
        return res.status(403).json({ message: "Access denied" });
      }
      if (role === "repairman") {
        update.repairman_completion_confirmed = true;
        update.repairman_completion_confirmed_at = new Date();
      }
      if (role === "user") {
        update.user_completion_confirmed = true;
        update.user_completion_confirmed_at = new Date();
      }

      const userConfirmed =
        role === "user" ? true : booking.user_completion_confirmed === true;
      const repairmanConfirmed =
        role === "repairman"
          ? true
          : booking.repairman_completion_confirmed === true;

      if (userConfirmed && repairmanConfirmed) {
        applyCompletionState(booking, update);
      } else {
        update.status = role === "user"
          ? "completion_pending_repairman"
          : "completion_pending_user";
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

    const update = {
      updated_at: new Date(),
      repairman_completion_confirmed: true,
      repairman_completion_confirmed_at: new Date(),
    };

    if (booking.user_completion_confirmed === true) {
      applyCompletionState(booking, update);
    } else {
      update.status = "completion_pending_user";
    }

    await bRef.update(update);

    return res.json({
      message:
        update.status === "completed"
          ? "OTP verified. Booking completed."
          : "OTP verified. Waiting for user completion confirmation.",
      status: update.status,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
