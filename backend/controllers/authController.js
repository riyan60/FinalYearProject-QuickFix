const { db } = require("../firebase");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// ================= REGISTER =================
exports.register = async (req, res) => {
  try {
    const {
      username,
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

    res.status(200).json({
      message: "Login successful",
      token,
      role: user.role,
      userId: userDoc.id,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};
