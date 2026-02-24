const { db } = require("../firebase");

exports.addReview = async (req, res) => {
  try {
    const { bookingId, rating, comment } = req.body;
    const { userId } = req.user;

    if (!bookingId || !rating) {
      return res.status(400).json({ message: "bookingId & rating required" });
    }

    const bDoc = await db.collection("bookings").doc(bookingId).get();
    if (!bDoc.exists) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bDoc.data();

    if (booking.user_id !== userId) {
      return res.status(403).json({ message: "Not your booking" });
    }

    if (booking.status !== "completed") {
      return res.status(400).json({ message: "Booking not completed" });
    }

    const ref = await db.collection("reviews").add({
      booking_id: bookingId,
      rating: Number(rating),
      comment: comment || "",
      created_at: new Date(),
    });

    return res.status(201).json({
      message: "Review added",
      reviewId: ref.id,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};