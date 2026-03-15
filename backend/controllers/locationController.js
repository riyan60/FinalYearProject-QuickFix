const { db } = require("../firebase");

exports.getCities = async (req, res) => {
  try {
    const snap = await db.collection("cities").get();

    const cities = snap.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .filter((city) => city.is_active !== false)
      .sort((a, b) => String(a.name || "").localeCompare(String(b.name || "")));

    return res.json(cities);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

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

exports.getRepairmanLocationByBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;

    // Get booking
    const bookingDoc = await db.collection("bookings").doc(bookingId).get();
    if (!bookingDoc.exists) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const booking = bookingDoc.data();
    const repairmanId = booking.repairman_id;
    if (!repairmanId) {
      return res.status(404).json({ message: "No repairman assigned to this booking" });
    }

    // Get latest location
    const locationDoc = await db.collection("locations").doc(repairmanId).get();
    if (!locationDoc.exists) {
      return res.status(404).json({ message: "Repairman location not available" });
    }

    const location = locationDoc.data();
    return res.json({
      repairman_id: repairmanId,
      latitude: location.latitude,
      longitude: location.longitude,
      updated_at: location.updated_at ? location.updated_at.toDate().toISOString() : null,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

