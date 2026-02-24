const { db } = require("../firebase");

// ===============================
// Get Logged-in Technician Profile (PRIVATE)
// ===============================
exports.getMyProfile = async (req, res) => {
  try {
    if (req.user.role !== "technician") {
      return res.status(403).json({ message: "Access denied" });
    }

    const userId = req.user.id;

    const userDoc = await db.collection("users").doc(userId).get();
    const techDoc = await db.collection("technicians").doc(userId).get();

    if (!techDoc.exists) {
      return res.status(404).json({ message: "Technician profile not found" });
    }

    const userData = userDoc.data();
    const techData = techDoc.data();

    res.json({
      id: userId,
      fullName: userData.fullName,
      email: userData.email,
      phone: userData.phone, // private (own profile only)
      role: userData.role,
      address: userData.address,
      skills: techData.skills,
      experience: techData.experience,
      description: techData.description,
      rating: techData.rating,
      isAvailable: techData.isAvailable,
      location: techData.location,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ===============================
// Update Technician Profile
// ===============================
exports.updateProfile = async (req, res) => {
  try {
    if (req.user.role !== "technician") {
      return res.status(403).json({ message: "Access denied" });
    }

    const userId = req.user.id;

    const {
      skills,
      experience,
      description,
      isAvailable,
      location,
    } = req.body;

    await db.collection("technicians").doc(userId).update({
      skills,
      experience,
      description,
      isAvailable,
      location,
    });

    res.json({ message: "Profile updated successfully" });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ===============================
// Get Technician By ID (PUBLIC)
// ===============================
exports.getTechnicianById = async (req, res) => {
  try {
    const { id } = req.params;

    const userDoc = await db.collection("users").doc(id).get();
    const techDoc = await db.collection("technicians").doc(id).get();

    if (!techDoc.exists) {
      return res.status(404).json({ message: "Technician not found" });
    }

    const userData = userDoc.data();
    const techData = techDoc.data();

    res.json({
      id,
      fullName: userData.fullName,
      role: userData.role,
      address: userData.address,
      skills: techData.skills,
      experience: techData.experience,
      description: techData.description,
      rating: techData.rating,
      isAvailable: techData.isAvailable,
      location: techData.location,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
