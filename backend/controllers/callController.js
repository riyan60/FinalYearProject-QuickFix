const { db } = require("../firebase");

const isActiveBooking = (status) =>
  ["pending", "accepted", "ongoing"].includes(status);

exports.getCallStatus = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { userId } = req.user;

    const bookingDoc = await db.collection("bookings").doc(bookingId).get();
    if (!bookingDoc.exists) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bookingDoc.data();

    if (booking.user_id !== userId && booking.repairman_id !== userId) {
      return res.status(403).json({ message: "Access denied" });
    }

    const callDoc = await db.collection("calls").doc(bookingId).get();

    if (!callDoc.exists) {
      return res.json({
        booking_id: bookingId,
        status: "idle",
      });
    }

    return res.json({ id: callDoc.id, ...callDoc.data() });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.startCall = async (req, res) => {
  try {
    const { bookingId } = req.body;
    const { userId } = req.user;

    if (!bookingId) {
      return res.status(400).json({ message: "bookingId required" });
    }

    const bookingDoc = await db.collection("bookings").doc(bookingId).get();
    if (!bookingDoc.exists) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bookingDoc.data();

    if (booking.user_id !== userId && booking.repairman_id !== userId) {
      return res.status(403).json({ message: "Access denied" });
    }

    if (!isActiveBooking(booking.status)) {
      return res.status(400).json({ message: "Calling is not allowed for this booking" });
    }

    await db.collection("calls").doc(bookingId).set(
      {
        booking_id: bookingId,
        user_id: booking.user_id,
        repairman_id: booking.repairman_id,
        status: "ringing",
        caller_id: userId,
        created_at: new Date(),
        started_at: null,
        ended_at: null,
      },
      { merge: true }
    );

    return res.json({ message: "Call started", callId: bookingId });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.acceptCall = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { userId } = req.user;

    const callRef = db.collection("calls").doc(bookingId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      return res.status(404).json({ message: "Call not found" });
    }

    const call = callDoc.data();

    if (call.user_id !== userId && call.repairman_id !== userId) {
      return res.status(403).json({ message: "Access denied" });
    }

    await callRef.update({
      status: "ongoing",
      started_at: new Date(),
    });

    return res.json({ message: "Call accepted" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.rejectCall = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { userId } = req.user;

    const callRef = db.collection("calls").doc(bookingId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      return res.status(404).json({ message: "Call not found" });
    }

    const call = callDoc.data();

    if (call.user_id !== userId && call.repairman_id !== userId) {
      return res.status(403).json({ message: "Access denied" });
    }

    await callRef.update({
      status: "rejected",
      ended_at: new Date(),
    });

    return res.json({ message: "Call rejected" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.endCall = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { userId } = req.user;

    const callRef = db.collection("calls").doc(bookingId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      return res.status(404).json({ message: "Call not found" });
    }

    const call = callDoc.data();

    if (call.user_id !== userId && call.repairman_id !== userId) {
      return res.status(403).json({ message: "Access denied" });
    }

    await callRef.update({
      status: "ended",
      ended_at: new Date(),
    });

    return res.json({ message: "Call ended" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};