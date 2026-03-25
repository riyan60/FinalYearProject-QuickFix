const { db } = require("../firebase");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const env = require("../config/env");

// REGISTER
exports.register = async (req, res) => {
  try {
    const {
      username,
      email,
      password,
      role, // "user" | "repairman" | "admin"
      name,
      phone,
      address,
      city,
      latitude,
      longitude,
      experience,
      bio,
      skills,
      hourlyRate,
      hourly_rate,
    } = req.body;

    if (!username || !email || !password || !role || !name || !phone) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    if (!["user", "repairman", "admin"].includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }

    const emailSnap = await db.collection("accounts").where("email", "==", email).get();
    if (!emailSnap.empty) {
      return res.status(409).json({ message: "Email already exists" });
    }

    const userSnap = await db.collection("accounts").where("username", "==", username).get();
    if (!userSnap.empty) {
      return res.status(409).json({ message: "Username already exists" });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const accountRef = db.collection("accounts").doc();
    const accountId = accountRef.id;

    await accountRef.set({
      username,
      email,
      password_hash,
      role,
      is_active: true,
      created_at: new Date(),
      last_login: null,
    });

    if (role === "user") {
      await db.collection("users").doc(accountId).set({
        account_id: accountId,
        name,
        phone,
        address: address || "",
        city: city || "",
        latitude: latitude ?? null,
        longitude: longitude ?? null,
        created_at: new Date(),
      });
    }

    if (role === "repairman") {
      const normalizedSkills = Array.isArray(skills)
        ? skills.map((skill) => String(skill).trim()).filter(Boolean)
        : String(skills || "")
            .split(",")
            .map((skill) => skill.trim())
            .filter(Boolean);
      const normalizedHourlyRate = Number(hourlyRate ?? hourly_rate ?? 0);

      await db.collection("repairmen").doc(accountId).set({
        account_id: accountId,
        name,
        phone,
        address: address || "",
        city: city || "",
        latitude: latitude ?? null,
        longitude: longitude ?? null,
        experience: Number(experience || 0),
        skills: normalizedSkills,
        specialization: normalizedSkills[0] || "",
        hourly_rate: Number.isFinite(normalizedHourlyRate)
          ? normalizedHourlyRate
          : 0,
        availability_status: "available",
        emergency_service_enabled: false,
        rating: 0,
        bio: bio || "",
        profile_pic: "",
        is_verified: false,
        verification_status: "unverified",
        verification_submitted_at: null,
        verification_reviewed_at: null,
        verification_reviewed_by: "",
        verification_rejection_reason: "",
        verification_profile: {},
        verification_documents: {},
        created_at: new Date(),
      });
    }

    return res.status(201).json({ message: "Registered", accountId, role });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// LOGIN
exports.login = async (req, res) => {
  try {
    const { username, email, password } = req.body;
    const identity = (username || email || "").trim();

    if (!identity || !password) {
      return res.status(400).json({ message: "Missing fields" });
    }

    let snap = await db.collection("accounts").where("username", "==", identity).get();
    if (snap.empty) {
      snap = await db.collection("accounts").where("email", "==", identity).get();
    }

    if (snap.empty) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const doc = snap.docs[0];
    const acc = doc.data();
    let profile = null;

    if (acc.is_active === false) {
      return res.status(403).json({ message: "Account disabled" });
    }

    const ok = await bcrypt.compare(password, acc.password_hash);
    if (!ok) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    await db.collection("accounts").doc(doc.id).update({ last_login: new Date() });

    if (acc.role === "user") {
      const profileDoc = await db.collection("users").doc(doc.id).get();
      if (profileDoc.exists) {
        profile = { account_id: doc.id, ...profileDoc.data() };
      }
    } else if (acc.role === "repairman") {
      const profileDoc = await db.collection("repairmen").doc(doc.id).get();
      if (profileDoc.exists) {
        profile = { account_id: doc.id, ...profileDoc.data() };
      }
    }

    const token = jwt.sign(
      { userId: doc.id, role: acc.role },
      env.jwtSecret(),
      { expiresIn: "7d" }
    );

    return res.json({
      message: "Login successful",
      token,
      role: acc.role,
      accountId: doc.id,
      profile,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.getCurrentProfile = async (req, res) => {
  try {
    const { userId, role } = req.user;

    const accountDoc = await db.collection("accounts").doc(userId).get();
    if (!accountDoc.exists) {
      return res.status(404).json({ message: "Account not found" });
    }

    let profile = null;
    if (role === "user") {
      const profileDoc = await db.collection("users").doc(userId).get();
      if (profileDoc.exists) {
        profile = { account_id: userId, ...profileDoc.data() };
      }
    } else if (role === "repairman") {
      const profileDoc = await db.collection("repairmen").doc(userId).get();
      if (profileDoc.exists) {
        profile = { account_id: userId, ...profileDoc.data() };
      }
    }

    return res.json({
      accountId: userId,
      role,
      profile,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.updateCurrentProfile = async (req, res) => {
  try {
    const { userId, role } = req.user;
    const { city, latitude, longitude } = req.body;

    const update = { updated_at: new Date() };
    if (city !== undefined) update.city = String(city || "").trim();
    if (latitude !== undefined) update.latitude = Number(latitude);
    if (longitude !== undefined) update.longitude = Number(longitude);

    const collection = role === "repairman" ? "repairmen" : "users";
    await db.collection(collection).doc(userId).set(update, { merge: true });

    const profileDoc = await db.collection(collection).doc(userId).get();

    return res.json({
      message: "Profile updated",
      profile: profileDoc.exists
        ? { account_id: userId, ...profileDoc.data() }
        : null,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// LOGOUT
exports.logout = async (req, res) => {
  try {
    return res.json({ message: "Logout successful" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
