const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { allowRoles } = require("../middleware/authMiddleware");
const { db } = require("../firebase");
const verificationController = require("../controllers/verificationController");

const enrichBooking = async (booking) => {
  const enriched = { ...booking };

  const [userDoc, serviceDoc] = await Promise.all([
    booking.user_id ? db.collection("users").doc(String(booking.user_id)).get() : null,
    booking.service_id ? db.collection("services").doc(String(booking.service_id)).get() : null,
  ]);

  if (userDoc && userDoc.exists) {
    const user = userDoc.data() || {};
    enriched.user_name = user.name || enriched.user_name || "";
  }

  if (serviceDoc && serviceDoc.exists) {
    const service = serviceDoc.data() || {};
    enriched.service_name = service.service_name || enriched.service_name || "";
  }

  return enriched;
};

const normalizeCurrencyAmount = (value) => {
  const numeric = Number(value || 0);
  if (!Number.isFinite(numeric)) return 0;
  return Number(Math.round(numeric).toFixed(2));
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
    booking.booking_type === "direct_repairman" ||
    hasDirectMetadata ||
    (String(booking.service_id || "").trim().length === 0 &&
      ["booking_confirmed", "reached_destination", "arrival_confirmed"].includes(
        String(booking.status || "").trim()
      ));

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
      const {
        serviceId,
        custom_price,
        service_name,
        name,
        category,
        description,
      } = req.body;

      const normalizedServiceId = String(serviceId || "").trim();
      const normalizedServiceName = String(service_name || name || "").trim();
      const normalizedCategory = String(category || "").trim();
      const normalizedDescription = String(description || "").trim();
      const normalizedPrice = Number(custom_price || 0);

      if (!normalizedServiceId && !normalizedServiceName) {
        return res.status(400).json({ message: "serviceId or service_name required" });
      }

      const docId =
        normalizedServiceId ||
        `custom_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

      const payload = {
        custom_price: Number.isFinite(normalizedPrice) ? normalizedPrice : 0,
        updated_at: new Date(),
      };

      if (normalizedServiceId) {
        payload.service_id = normalizedServiceId;
      } else {
        payload.service_id = "";
        payload.service_name = normalizedServiceName;
        payload.category = normalizedCategory;
        payload.description = normalizedDescription;
        payload.is_custom_service = true;
      }

      await db
        .collection("repairmen")
        .doc(req.user.userId)
        .collection("services")
        .doc(docId)
        .set(
          {
            ...payload,
            created_at: new Date(),
          },
          { merge: true }
        );

      return res.json({
        message: normalizedServiceId
            ? "Service linked to repairman"
            : "Custom service added",
        service: {
          id: docId,
          ...payload,
        },
      });
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
        emergency_service_enabled,
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
      if (emergency_service_enabled !== undefined) {
        update.emergency_service_enabled = Boolean(emergency_service_enabled);
      }
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

router.get(
  "/me/verification",
  authMiddleware,
  allowRoles("repairman"),
  verificationController.getMyVerification
);

router.post(
  "/me/verification",
  authMiddleware,
  allowRoles("repairman"),
  verificationController.submitMyVerification
);

// 7️⃣ Repairman: Get my jobs (optional status filter)
router.get("/me/jobs", authMiddleware, allowRoles("repairman"), async (req, res) => {
  try {
    const repairmanId = req.user.userId;
    const { status } = req.query;

    let q = db.collection("bookings").where("repairman_id", "==", repairmanId);
    if (status === "active") {
      q = q.where("status", "in", [
        "accepted",
        "in_progress",
        "booking_confirmed",
        "reached_destination",
        "arrival_confirmed",
        "completion_pending_user",
        "completion_pending_repairman",
      ]);
    } else if (status) {
      q = q.where("status", "==", status);
    }

    const snap = await q.get();
    const jobs = await Promise.all(
      snap.docs.map((doc) => enrichBooking({ id: doc.id, ...doc.data() }))
    );
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

    const nextStatus =
      booking.booking_type === "direct_repairman" ? "booking_confirmed" : "accepted";

    await bookingRef.update({
      status: nextStatus,
      accepted_at: new Date(),
      confirmed_at: nextStatus === "booking_confirmed" ? new Date() : booking.confirmed_at || null,
      updated_at: new Date()
    });
    return res.json({ message: "Job accepted", status: nextStatus });
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
    const isDirectRepairmanBooking = booking.booking_type === "direct_repairman";
    const allowedCurrentStatus = isDirectRepairmanBooking
      ? "booking_confirmed"
      : "accepted";
    if (booking.status !== allowedCurrentStatus) {
      return res.status(400).json({ message: "Cannot start booking from current status" });
    }

    const update = {
      status: isDirectRepairmanBooking ? "reached_destination" : "in_progress",
      updated_at: new Date()
    };
    if (isDirectRepairmanBooking) {
      update.reached_destination_at = new Date();
      update.arrival_confirmed_by_user = null;
      update.arrival_confirmation = "";
      update.arrival_confirmed_at = null;
      update.arrival_denied_at = null;
    } else {
      update.started_at = new Date();
    }

    await bookingRef.update(update);
    return res.json({ message: "Job started", status: update.status });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// 🔟 Complete job (repairman confirmation; user must also confirm)
router.post("/me/jobs/:bookingId/complete", authMiddleware, allowRoles("repairman"), async (req, res) => {
  try {
    const repairmanId = req.user.userId;
    const { bookingId } = req.params;

    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) return res.status(404).json({ message: "Booking not found" });
    const booking = bookingSnap.data();
    if (booking.repairman_id !== repairmanId) return res.status(403).json({ message: "Not your booking" });
    const bookingMode = String(booking.booking_mode || "").trim();
    const hasDirectMetadata =
      booking.hourly_rate !== undefined && booking.hourly_rate !== null ||
      booking.booked_hours !== undefined && booking.booked_hours !== null ||
      bookingMode.length > 0 ||
      String(booking.specialty || "").trim().length > 0 ||
      String(booking.repairman_name || "").trim().length > 0;
    const isDirectRepairmanBooking =
      booking.booking_type === "direct_repairman" ||
      hasDirectMetadata ||
      (String(booking.service_id || "").trim().length === 0 &&
        ["booking_confirmed", "reached_destination", "arrival_confirmed"].includes(
          String(booking.status || "").trim()
        ));
    if (isDirectRepairmanBooking) {
    } else if (!["in_progress", "completion_pending_repairman"].includes(String(booking.status || "").trim())) {
      return res.status(400).json({ message: "Cannot complete booking from current status" });
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

    await bookingRef.update(update);
    return res.json({
      message:
        update.status === "completed"
          ? "Job completed"
          : "Repairman confirmed completion. Waiting for user confirmation.",
      status: update.status,
    });
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

      const bookings = await Promise.all(snap.docs.map(async (doc) => {
        const data = doc.data();
        total += Number(data.total_amount || 0);
        return enrichBooking({ id: doc.id, ...data });
      }));

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
