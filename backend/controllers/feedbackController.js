const { db } = require("../firebase");

exports.submitFeedback = async (req, res) => {
  try {
    const { userId, role } = req.user || {};
    if (!userId) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const feedbackType = String(req.body.feedback_type || "").trim();
    const subject = String(req.body.subject || "").trim();
    const message = String(req.body.message || "").trim();
    const contactName = String(req.body.contact_name || "").trim();
    const contactPhone = String(req.body.contact_phone || "").trim();
    const ratingRaw = req.body.rating;

    if (!feedbackType) {
      return res.status(400).json({ message: "feedback_type is required" });
    }
    if (!subject) {
      return res.status(400).json({ message: "subject is required" });
    }
    if (!message) {
      return res.status(400).json({ message: "message is required" });
    }

    const allowedTypes = new Set(["user", "repairman"]);
    if (!allowedTypes.has(feedbackType)) {
      return res.status(400).json({ message: "feedback_type must be user or repairman" });
    }

    let rating = null;
    if (ratingRaw !== undefined && ratingRaw !== null && String(ratingRaw).trim() !== "") {
      const parsed = Number(ratingRaw);
      if (!Number.isFinite(parsed) || parsed < 1 || parsed > 5) {
        return res.status(400).json({ message: "rating must be between 1 and 5" });
      }
      rating = Math.round(parsed);
    }

    const payload = {
      user_id: String(userId),
      account_role: String(role || "").trim().toLowerCase(),
      feedback_type: feedbackType,
      subject,
      message,
      contact_name: contactName,
      contact_phone: contactPhone,
      created_at: new Date(),
      updated_at: new Date(),
      status: "new",
    };

    if (rating !== null) payload.rating = rating;

    const docRef = await db.collection("feedback").add(payload);
    return res.status(201).json({
      message: "Feedback submitted successfully",
      feedbackId: docRef.id,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
