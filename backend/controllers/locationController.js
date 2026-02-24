const { db } = require("../firebase");

// Update latest location + store history
exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const repairmanId = req.user.userId;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ message: "latitude & longitude required" });
    }

    const lat = Number(latitude);
    const lng = Number(longitude);
    const now = new Date();

    // Latest location
    await db.collection("locations").doc(repairmanId).set({
      repairman_id: repairmanId,
      latitude: lat,
      longitude: lng,
      updated_at: now,
    });

    // History
    await db
      .collection("locations_history")
      .doc(repairmanId)
      .collection("points")
      .add({
        latitude: lat,
        longitude: lng,
        updated_at: now,
      });

    return res.json({ message: "Location updated" });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};