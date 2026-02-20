const db = require("../firebase");
const bcrypt = require("bcryptjs");

exports.registerRepairman = async (req, res) => {
  try {
    const { name, email, phone, password, service_type } = req.body;

    // Basic validation
    if (!name || !email || !phone || !password || !service_type) {
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
    
    const existingUser = await db
      .collection("repairmen")
      .where("email", "==", email)
      .get();

    if (!existingUser.empty) {
      return res.status(409).json({ message: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.collection("repairmen").add({
      name,
      email,
      phone,
      password: hashedPassword,
      service_type,
      role: "repairman",
      createdAt: new Date()
    });

    res.status(201).json({ message: "Repairman registered successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllRepairmen = async (req, res) => {
  const snapshot = await db.collection("repairmen").get();
  const repairmen = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
  res.json(repairmen);
};
