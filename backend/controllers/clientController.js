const db = require("../firebase");
const bcrypt = require("bcryptjs");

exports.registerClient = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    // Basic validation
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    // Email format
    if (!/\S+@\S+\.\S+/.test(email)) {
      return res.status(400).json({ message: "Invalid email format" });
    }

    // Phone validation
    if (!/^\d{10}$/.test(phone)) {
      return res.status(400).json({ message: "Phone must be 10 digits" });
    }

    // Check if email already exists
    const existingUser = await db
      .collection("clients")
      .where("email", "==", email)
      .get();

    if (!existingUser.empty) {
      return res.status(409).json({ message: "Email already registered" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    await db.collection("clients").add({
      name,
      email,
      phone,
      password: hashedPassword,
      role: "client",
      createdAt: new Date()
    });

    res.status(201).json({ message: "Client registered successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllClients = async (req, res) => {
  try {
    const snapshot = await db.collection("clients").get();

    const clients = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.status(200).json(clients);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

