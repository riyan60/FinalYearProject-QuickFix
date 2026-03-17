const { db } = require("../firebase");

exports.getChatMessages = async (req, res) => {
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

    const chatDoc = await db.collection("chats").doc(bookingId).get();
    if (!chatDoc.exists) {
      return res.json({ messages: [] });
    }

    const snap = await db
      .collection("chats")
      .doc(bookingId)
      .collection("messages")
      .orderBy("created_at", "asc")
      .get();

    const messages = snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.json({ messages });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.getChatInfo = async (req, res) => {
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

    const chatDoc = await db.collection("chats").doc(bookingId).get();

    if (!chatDoc.exists) {
      return res.json({
        id: bookingId,
        booking_id: bookingId,
        user_id: booking.user_id,
        repairman_id: booking.repairman_id,
        is_active: ["pending", "accepted", "ongoing"].includes(booking.status),
      });
    }

    return res.json({ id: chatDoc.id, ...chatDoc.data() });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};