const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { allowRoles } = require("../middleware/authMiddleware");
const { db } = require("../firebase");

// 1️⃣ Public: List all repairmen (hide phone)
router.get("/", async (req, res) => {
  try {
    const snap = await db.collection("repairmen").get();

    const data = snap.docs.map((doc) => {
      const r = doc.data();
      delete r.phone;
      return { id: doc.id, ...r };
    });

    return res.json(data);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// 2️⃣ Public: Nearby repairmen (Haversine formula)
router.get("/nearby", async (req, res) => {
  try {
    const { lat, lng, km } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ message: "lat and lng are required" });
    }

    const userLat = Number(lat);
    const userLng = Number(lng);
    const radius = Number(km || 10);

    const snap = await db.collection("repairmen").get();

    const toRad = (value) => (value * Math.PI) / 180;

    const results = snap.docs
      .map((doc) => {
        const r = doc.data();

        if (!r.latitude || !r.longitude) return null;

        const dLat = toRad(r.latitude - userLat);
        const dLng = toRad(r.longitude - userLng);

        const a =
          Math.sin(dLat / 2) * Math.sin(dLat / 2) +
          Math.cos(toRad(userLat)) *
            Math.cos(toRad(r.latitude)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);

        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const distance = 6371 * c;

        if (distance <= radius) {
          delete r.phone;
          return {
            id: doc.id,
            distance_km: distance.toFixed(2),
            ...r,
          };
        }

        return null;
      })
      .filter(Boolean);

    return res.json({ repairmen: results });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// 3️⃣ Repairman: Link service (junction table)
router.post(
  "/me/services",
  authMiddleware,
  allowRoles("repairman"),
  async (req, res) => {
    try {
      const { serviceId, custom_price } = req.body;

      if (!serviceId) {
        return res.status(400).json({ message: "serviceId required" });
      }

      await db
        .collection("repairmen")
        .doc(req.user.userId)
        .collection("services")
        .doc(serviceId)
        .set(
          {
            service_id: serviceId,
            custom_price: Number(custom_price || 0),
            created_at: new Date(),
          },
          { merge: true }
        );

      return res.json({ message: "Service linked to repairman" });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  }
);

// 4️⃣ Repairman: Get my linked services
router.get(
  "/me/services",
  authMiddleware,
  allowRoles("repairman"),
  async (req, res) => {
    try {
      const snap = await db
        .collection("repairmen")
        .doc(req.user.userId)
        .collection("services")
        .get();

      const services = snap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      return res.json({ services });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  }
);

// 5️⃣ Repairman: Update availability
router.put(
  "/me/availability",
  authMiddleware,
  allowRoles("repairman"),
  async (req, res) => {
    try {
      const { availability_status } = req.body;

      if (!availability_status) {
        return res.status(400).json({ message: "availability_status required" });
      }

      await db.collection("repairmen").doc(req.user.userId).update({
        availability_status,
        updated_at: new Date(),
      });

      return res.json({ message: "Availability updated" });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  }
);

// 6️⃣ Repairman: Update profile (safe fields)
router.put(
  "/me/profile",
  authMiddleware,
  allowRoles("repairman"),
  async (req, res) => {
    try {
      const {
        name,
        address,
        latitude,
        longitude,
        experience,
        bio,
        skills,
        hourlyRate,
        hourly_rate,
        specialization,
      } = req.body;

      const update = { updated_at: new Date() };

      const normalizedSkills =
        skills === undefined
          ? undefined
          : Array.isArray(skills)
          ? skills.map((skill) => String(skill).trim()).filter(Boolean)
          : String(skills)
              .split(",")
              .map((skill) => skill.trim())
              .filter(Boolean);
      const normalizedHourlyRate = Number(hourlyRate ?? hourly_rate);

      if (name !== undefined) update.name = name;
      if (address !== undefined) update.address = address;
      if (latitude !== undefined) update.latitude = Number(latitude);
      if (longitude !== undefined) update.longitude = Number(longitude);
      if (experience !== undefined) update.experience = Number(experience);
      if (bio !== undefined) update.bio = bio;
      if (normalizedSkills !== undefined) update.skills = normalizedSkills;
      if (specialization !== undefined) update.specialization = specialization;
      else if (normalizedSkills !== undefined) {
        update.specialization = normalizedSkills[0] || "";
      }
      if (hourlyRate !== undefined || hourly_rate !== undefined) {
        update.hourly_rate = Number.isFinite(normalizedHourlyRate)
          ? normalizedHourlyRate
          : 0;
      }

      await db.collection("repairmen").doc(req.user.userId).update(update);

      return res.json({ message: "Profile updated" });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  }
);

// 7️⃣ Repairman: Get my jobs (optional status filter)
router.get("/me/jobs", authMiddleware, allowRoles("repairman"), async (req, res) => {
  try {
    const repairmanId = req.user.userId;
    const { status } = req.query;

    let q = db.collection("bookings").where("repairman_id", "==", repairmanId);
    if (status === "active") {
      q = q.where("status", "in", ["accepted", "in_progress"]);
    } else if (status) {
      q = q.where("status", "==", status);
    }

    const snap = await q.get();
    const jobs = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    return res.json({ jobs });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// 8️⃣ Accept job (pending -> accepted)
router.post("/me/jobs/:bookingId/accept", authMiddleware, allowRoles("repairman"), async (req, res) => {
  try {
    const repairmanId = req.user.userId;
    const { bookingId } = req.params;

    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) return res.status(404).json({ message: "Booking not found" });
    const booking = bookingSnap.data();
    if (booking.repairman_id !== repairmanId) return res.status(403).json({ message: "Not your booking" });
    if (booking.status !== "pending") return res.status(400).json({ message: "Cannot accept non-pending booking" });

    await bookingRef.update({
      status: "accepted",
      accepted_at: new Date(),
      updated_at: new Date()
    });
    return res.json({ message: "Job accepted" });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// 9️⃣ Start job (accepted -> in_progress)
router.post("/me/jobs/:bookingId/start", authMiddleware, allowRoles("repairman"), async (req, res) => {
  try {
    const repairmanId = req.user.userId;
    const { bookingId } = req.params;

    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) return res.status(404).json({ message: "Booking not found" });
    const booking = bookingSnap.data();
    if (booking.repairman_id !== repairmanId) return res.status(403).json({ message: "Not your booking" });
    if (booking.status !== "accepted") return res.status(400).json({ message: "Cannot start non-accepted booking" });

    await bookingRef.update({
      status: "in_progress",
      started_at: new Date(),
      updated_at: new Date()
    });
    return res.json({ message: "Job started" });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// 🔟 Complete job (in_progress -> completed)
router.post("/me/jobs/:bookingId/complete", authMiddleware, allowRoles("repairman"), async (req, res) => {
  try {
    const repairmanId = req.user.userId;
    const { bookingId } = req.params;

    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) return res.status(404).json({ message: "Booking not found" });
    const booking = bookingSnap.data();
    if (booking.repairman_id !== repairmanId) return res.status(403).json({ message: "Not your booking" });
    if (booking.status !== "in_progress") return res.status(400).json({ message: "Cannot complete non-in-progress booking" });

    await bookingRef.update({
      status: "completed",
      completed_at: new Date(),
      updated_at: new Date()
    });
    return res.json({ message: "Job completed" });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// 7️⃣ Repairman: Earnings (completed bookings) - moved after jobs
router.get(
  "/me/earnings",
  authMiddleware,
  allowRoles("repairman"),
  async (req, res) => {
    try {
      const repairmanId = req.user.userId;

      const snap = await db
        .collection("bookings")
        .where("repairman_id", "==", repairmanId)
        .where("status", "==", "completed")
        .get();

      let total = 0;

      const bookings = snap.docs.map((doc) => {
        const data = doc.data();
        total += Number(data.total_amount || 0);
        return { id: doc.id, ...data };
      });

      return res.json({
        total_earnings: total,
        completed_jobs: bookings.length,
        bookings,
      });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  }
);

module.exports = router;
