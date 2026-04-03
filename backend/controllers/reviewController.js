const { db } = require("../firebase");

exports.addReview = async (req, res) => {
  try {
    const { bookingId, rating, comment } = req.body;
    const { userId } = req.user;
    const normalizedBookingId = String(bookingId || "").trim();
    const normalizedRating = Number(rating);

    if (!normalizedBookingId || Number.isNaN(normalizedRating)) {
      return res.status(400).json({ message: "bookingId & rating required" });
    }
    if (normalizedRating < 1 || normalizedRating > 5) {
      return res.status(400).json({ message: "rating must be between 1 and 5" });
    }

    const bDoc = await db.collection("bookings").doc(normalizedBookingId).get();
    if (!bDoc.exists) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bDoc.data();
    const repairmanId = String(booking.repairman_id || booking.repairmanId || "").trim();

    if (booking.user_id !== userId) {
      return res.status(403).json({ message: "Not your booking" });
    }

    if (booking.status !== "completed") {
      return res.status(400).json({ message: "Booking not completed" });
    }

    if (booking.review_submitted === true) {
      return res.status(409).json({ message: "Review already submitted for this booking" });
    }
    if (!repairmanId) {
      return res.status(400).json({ message: "Repairman not assigned for this booking" });
    }

    const ref = await db.collection("reviews").add({
      booking_id: normalizedBookingId,
      user_id: userId,
      repairman_id: repairmanId,
      rating: normalizedRating,
      comment: String(comment || "").trim(),
      created_at: new Date(),
    });

    await db.collection("bookings").doc(normalizedBookingId).update({
      review_submitted: true,
      review_submitted_at: new Date(),
      updated_at: new Date(),
    });

    const reviewsSnap = await db.collection("reviews").where("repairman_id", "==", repairmanId).get();
    const ratingCount = reviewsSnap.size;
    const ratingSum = reviewsSnap.docs.reduce((sum, doc) => {
      const value = Number(doc.data()?.rating || 0);
      return sum + (Number.isNaN(value) ? 0 : value);
    }, 0);
    const averageRating = ratingCount > 0 ? Number((ratingSum / ratingCount).toFixed(2)) : 0;

    await db.collection("repairmen").doc(repairmanId).set(
      {
        rating: averageRating,
        rating_count: ratingCount,
        updated_at: new Date(),
      },
      { merge: true }
    );

    return res.status(201).json({
      message: "Review added",
      reviewId: ref.id,
      rating: averageRating,
      ratingCount,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

exports.getMyReviews = async (req, res) => {
  try {
    const { userId, role } = req.user;

    if (role !== "repairman") {
      return res.status(403).json({ message: "Only repairmen can view this review list" });
    }

    const snap = await db.collection("reviews").where("repairman_id", "==", userId).get();

    const reviews = await Promise.all(
      snap.docs.map(async (doc) => {
        const review = { id: doc.id, ...doc.data() };

        const [bookingDoc, userDoc] = await Promise.all([
          review.booking_id ? db.collection("bookings").doc(String(review.booking_id)).get() : null,
          review.user_id ? db.collection("users").doc(String(review.user_id)).get() : null,
        ]);

        const booking = bookingDoc && bookingDoc.exists ? bookingDoc.data() || {} : {};
        const user = userDoc && userDoc.exists ? userDoc.data() || {} : {};

        return {
          ...review,
          user_name: user.name || "",
          booking_date: booking.booking_date || null,
          service_id: booking.service_id || "",
          service_name: booking.service_name || "",
          specialty: booking.specialty || "",
        };
      })
    );

    reviews.sort((a, b) => {
      const aTime = new Date(a.created_at?.toDate ? a.created_at.toDate() : a.created_at || 0).getTime();
      const bTime = new Date(b.created_at?.toDate ? b.created_at.toDate() : b.created_at || 0).getTime();
      return bTime - aTime;
    });

    return res.json({ reviews });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};
