const { db } = require("../firebase");

// Create Service
exports.createService = async (req, res) => {
  try {
    if (req.user.role !== "technician") {
      return res.status(403).json({ message: "Only technicians allowed" });
    }

    const { category, title, description, price, duration } = req.body;

    const serviceRef = db.collection("services").doc();

    await serviceRef.set({
      technicianId: req.user.id,
      category,
      title,
      description,
      price,
      duration,
      isActive: true,
      createdAt: new Date(),
    });

    res.status(201).json({
      message: "Service created successfully",
      serviceId: serviceRef.id,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get Services By Category
exports.getServicesByCategory = async (req, res) => {
  try {
    const { category } = req.params;

    const snapshot = await db
      .collection("services")
      .where("category", "==", category)
      .where("isActive", "==", true)
      .get();

    const services = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.json(services);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get Services By Technician
exports.getServicesByTechnician = async (req, res) => {
  try {
    const { technicianId } = req.params;

    const snapshot = await db
      .collection("services")
      .where("technicianId", "==", technicianId)
      .where("isActive", "==", true)
      .get();

    const services = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.json(services);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Update Service
exports.updateService = async (req, res) => {
  try {
    const { serviceId } = req.params;

    const serviceDoc = await db.collection("services").doc(serviceId).get();

    if (!serviceDoc.exists) {
      return res.status(404).json({ message: "Service not found" });
    }

    if (serviceDoc.data().technicianId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    await db.collection("services").doc(serviceId).update(req.body);

    res.json({ message: "Service updated successfully" });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Soft Delete Service
exports.deleteService = async (req, res) => {
  try {
    const { serviceId } = req.params;

    const serviceDoc = await db.collection("services").doc(serviceId).get();

    if (!serviceDoc.exists) {
      return res.status(404).json({ message: "Service not found" });
    }

    if (serviceDoc.data().technicianId !== req.user.id) {
      return res.status(403).json({ message: "Unauthorized" });
    }

    await db.collection("services").doc(serviceId).update({
      isActive: false,
    });

    res.json({ message: "Service deactivated successfully" });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
