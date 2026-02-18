const db = require("../firebase");

// Get all services
exports.getAllServices = async (req, res) => {
  try {
    const snapshot = await db.collection("services").get();
    const services = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    res.json(services);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get service by ID
exports.getServiceById = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection("services").doc(id).get();
    
    if (!doc.exists) {
      return res.status(404).json({ message: "Service not found" });
    }
    
    res.json({ id: doc.id, ...doc.data() });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Create a new service
exports.createService = async (req, res) => {
  try {
    const { name, description, price, category } = req.body;

    if (!name || !description || !price || !category) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const serviceData = {
      name,
      description,
      price: parseFloat(price),
      category,
      createdAt: new Date()
    };

    const serviceRef = await db.collection("services").add(serviceData);

    res.status(201).json({
      message: "Service created successfully",
      id: serviceRef.id,
      ...serviceData
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Update a service
exports.updateService = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price, category } = req.body;

    const updateData = {};
    if (name) updateData.name = name;
    if (description) updateData.description = description;
    if (price) updateData.price = parseFloat(price);
    if (category) updateData.category = category;
    updateData.updatedAt = new Date();

    await db.collection("services").doc(id).update(updateData);

    res.json({ message: "Service updated successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Delete a service
exports.deleteService = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection("services").doc(id).delete();
    res.json({ message: "Service deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
