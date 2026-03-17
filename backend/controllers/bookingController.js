const { db } = require("../firebase");

const genOtp = () => String(Math.floor(1000 + Math.random() * 9000));

exports.createBooking = async (req, res) => {
  try {
    const { serviceId, repairmanId, bookingDate, scheduledTime } = req.body;
    const { userId, role } = req.user;

    if (role !== "user") {
      return res.status(403).json({ message: "Only users can book" });
    }

    if (!serviceId || !repairmanId || !bookingDate || !scheduledTime) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const serviceDoc = await db.collection("services").doc(serviceId).get();
    if (!serviceDoc.exists) {
      return res.status(404).json({ message: "Service not found" });
    }

    const repairmanDoc = await db.collection("repairmen").doc(repairmanId).get();
    if (!repairmanDoc.exists) {
      return res.status(404).json({ message: "Repairman not found" });
    }

    const basePrice = Number(serviceDoc.data().base_price || 0);

    const rsDoc = await db
      .collection("repairmen")
      .doc(repairmanId)
      .collection("services")
      .doc(serviceId)
      .get();

    const customPrice = rsDoc.exists ? Number(rsDoc.data().custom_price || 0) : 0;
    const total_amount = customPrice > 0 ? customPrice : basePrice;

    const bookingRef = await db.collection("bookings").add({
      user_id: userId,
      repairman_id: repairmanId,
      service_id: serviceId,
      booking_date: new Date(bookingDate),
      scheduled_time: scheduledTime,
      status: "pending",
      total_amount,
      otp_verification: genOtp(),
      created_at: new Date(),
      updated_at: new Date(),
    });

    console.log("Creating chat for booking:", bookingRef.id);
    
    await db.collection("chats").doc(bookingRef.id).set({
      booking_id: bookingRef.id,
      user_id: userId,
      repairman_id: repairmanId,
      is_active: true,
      created_at: new Date(),
      last_message: "",
      last_message_at: null,
      last_sender_id: null,
      closed_at: null,
    });

    return res.status(201).json({
      message: "Booking created",
      bookingId: bookingRef.id,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.getMyBookings = async (req, res) => {
  try {
    const { userId, role } = req.user;

    let q;

    if (role === "user") {
      q = db.collection("bookings").where("user_id", "==", userId);
    } else if (role === "repairman") {
      q = db.collection("bookings").where("repairman_id", "==", userId);
    } else {
      return res.status(403).json({ message: "Access denied" });
    }

    const snap = await q.get();
    const bookings = snap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    return res.json({ bookings });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.updateBookingStatus = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { status } = req.body;
    const { userId, role } = req.user;

    if (!status) {
      return res.status(400).json({ message: "Status required" });
    }

    const bRef = db.collection("bookings").doc(bookingId);
    const bDoc = await bRef.get();

    if (!bDoc.exists) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bDoc.data();

    if (role === "repairman" && booking.repairman_id !== userId) {
      return res.status(403).json({ message: "Not your booking" });
    }

    if (role === "user" && booking.user_id !== userId) {
      return res.status(403).json({ message: "Not your booking" });
    }

    await bRef.update({
      status,
      updated_at: new Date(),
    });

    if (["completed", "cancelled"].includes(status)) {
      await db.collection("chats").doc(bookingId).set(
        {
          is_active: false,
          closed_at: new Date(),
        },
        { merge: true }
      );

      await db.collection("calls").doc(bookingId).set(
        {
          status: "ended",
          ended_at: new Date(),
        },
        { merge: true }
      );
    }

    return res.json({ message: "Booking status updated" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.verifyOtpAndComplete = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { otp } = req.body;
    const { userId, role } = req.user;

    if (!otp) {
      return res.status(400).json({ message: "otp required" });
    }

    const bRef = db.collection("bookings").doc(bookingId);
    const bDoc = await bRef.get();

    if (!bDoc.exists) {
      return res.status(404).json({ message: "Booking not found" });
    }

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

    await db.collection("chats").doc(bookingId).set(
      {
        is_active: false,
        closed_at: new Date(),
      },
      { merge: true }
    );

    await db.collection("calls").doc(bookingId).set(
      {
        status: "ended",
        ended_at: new Date(),
      },
      { merge: true }
    );

    return res.json({ message: "OTP verified. Booking completed." });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};