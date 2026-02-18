const db = require("../firebase");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ message: "Email, password & role required" });
    }

    const collection = role === "client" ? "clients" : "repairmen";

    const snapshot = await db
      .collection(collection)
      .where("email", "==", email)
      .get();

    if (snapshot.empty) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const userDoc = snapshot.docs[0];
    const user = userDoc.data();

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // 🔑 JWT token
    const token = jwt.sign(
      { userId: userDoc.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    res.json({
      message: "Login successful",
      token,
      role: user.role,
      user: {
        id: userDoc.id,
        name: user.name,
        email: user.email,
        phone: user.phone
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.signup = async (req, res) => {
  try {
    const { name, email, password, phone, role } = req.body;

    if (!name || !email || !password || !phone || !role) {
      return res.status(400).json({ message: "All fields required" });
    }

    const collection = role === "client" ? "clients" : "repairmen";

    // Check if user already exists
    const snapshot = await db
      .collection(collection)
      .where("email", "==", email)
      .get();

    if (!snapshot.empty) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = {
      name,
      email,
      password: hashedPassword,
      phone,
      role,
      createdAt: new Date(),
    };

    const userRef = await db.collection(collection).add(newUser);

    // Generate JWT token
    const token = jwt.sign(
      { userId: userRef.id, role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    res.json({
      message: "Signup successful",
      token,
      role,
      user: {
        id: userRef.id,
        name: newUser.name,
        email: newUser.email,
        phone: newUser.phone
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Token blacklist for invalidated tokens
const tokenBlacklist = new Set();

// Add token to blacklist (for logout)
const addToBlacklist = (token) => {
  tokenBlacklist.add(token);
  // Clean up old tokens periodically
  if (tokenBlacklist.size > 1000) {
    const tokensArray = Array.from(tokenBlacklist);
    tokenBlacklist.clear();
    tokensArray.slice(-500).forEach(t => tokenBlacklist.add(t));
  }
};

// Check if token is blacklisted
const isBlacklisted = (token) => {
  return tokenBlacklist.has(token);
};

exports.logout = async (req, res) => {
  try {
    // Get the token from the authorization header
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith("Bearer ")) {
      const token = authHeader.split(" ")[1];
      
      if (token) {
        // Add token to blacklist to invalidate it
        addToBlacklist(token);
      }
    }

    res.json({ 
      message: "Logout successful",
      shouldClearToken: true
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Export blacklist check function for middleware
exports.isTokenBlacklisted = isBlacklisted;
