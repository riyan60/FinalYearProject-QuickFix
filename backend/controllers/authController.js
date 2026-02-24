const { db } = require("../firebase");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// REGISTER
exports.register = async (req, res) => {
  try {
    const {
      username,
      email,
      password,
      role, // "user" | "repairman"
      name,
      phone,
      address,
      latitude,
      longitude,
      experience,
      bio
    } = req.body;

    if (!username || !email || !password || !role || !name || !phone) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    if (!["user", "repairman", "admin"].includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }

    const emailSnap = await db.collection("accounts").where("email", "==", email).get();
    if (!emailSnap.empty) return res.status(409).json({ message: "Email already exists" });

    const userSnap = await db.collection("accounts").where("username", "==", username).get();
    if (!userSnap.empty) return res.status(409).json({ message: "Username already exists" });

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
      last_login: null
    });

    if (role === "user") {
      await db.collection("users").doc(accountId).set({
        account_id: accountId,
        name,
        phone,
        address: address || "",
        latitude: latitude ?? null,
        longitude: longitude ?? null,
        created_at: new Date()
      });
    }

    if (role === "repairman") {
      await db.collection("repairmen").doc(accountId).set({
        account_id: accountId,
        name,
        phone,
        address: address || "",
        latitude: latitude ?? null,
        longitude: longitude ?? null,
        experience: Number(experience || 0),
        availability_status: "available",
        rating: 0,
        bio: bio || "",
        profile_pic: "",
        is_verified: false,
        created_at: new Date()
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
    const { username, password } = req.body;
    if (!username || !password) return res.status(400).json({ message: "Missing fields" });

    const snap = await db.collection("accounts").where("username", "==", username).get();
    if (snap.empty) return res.status(400).json({ message: "Invalid credentials" });

    const doc = snap.docs[0];
    const acc = doc.data();

    if (acc.is_active === false) return res.status(403).json({ message: "Account disabled" });

    const ok = await bcrypt.compare(password, acc.password_hash);
    if (!ok) return res.status(400).json({ message: "Invalid credentials" });

    await db.collection("accounts").doc(doc.id).update({ last_login: new Date() });

    const token = jwt.sign(
      { userId: doc.id, role: acc.role },
      password,
      email,
      fullName,
      address,
      role,
      skills,
      experience,
      hourlyRate,
      description,
    } = req.body;

    // ===== Validate required fields =====
    if (!username || !password || !email || !fullName || !address || !role) {
      return res.status(400).json({ message: "All required fields must be filled" });
    }

    // ===== Check if username already exists =====
    const usernameSnapshot = await db
      .collection("users")
      .where("username", "==", username)
      .get();

    if (!usernameSnapshot.empty) {
      return res.status(400).json({ message: "Username already exists" });
    }

    // ===== Hash password =====
    const hashedPassword = await bcrypt.hash(password, 10);

    // ===== Create user document =====
    const userRef = db.collection("users").doc();

    await userRef.set({
      username,
      email,
      fullName,
      address,
      password: hashedPassword,
      role, // "client" or "technician"
      createdAt: new Date(),
    });

    // ===== If technician, create technician profile =====
    if (role === "technician") {
      await db.collection("technicians").doc(userRef.id).set({
        skills: skills || "",
        experience: experience || "",
        hourlyRate: hourlyRate || 0,
        description: description || "",
      });
    }

    res.status(201).json({
      message: "User registered successfully",
      userId: userRef.id,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};

// ================= LOGIN =================
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // ===== Find user by username =====
    const snapshot = await db
      .collection("users")
      .where("username", "==", username)
      .get();

    if (snapshot.empty) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const userDoc = snapshot.docs[0];
    const user = userDoc.data();

    // ===== Compare password =====
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // ===== Generate JWT =====
    const token = jwt.sign(
      { id: userDoc.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return res.json({ message: "Login successful", token, role: acc.role, accountId: doc.id });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

// LOGOUT
exports.logout = async (req, res) => {
  try {
    // JWT is stateless, so we just inform the client to clear the token
    // In a more advanced implementation, you could add the token to a blacklist
    return res.json({ message: "Logout successful" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
