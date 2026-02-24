const { db } = require("../firebase");

exports.getAllServices = async (req, res) => {
  try {
    const snap = await db
      .collection("services")
      .where("is_active", "==", true)
      .get();

    const services = snap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    return res.json(services);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.getServiceById = async (req, res) => {
  try {
    const doc = await db.collection("services").doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ message: "Service not found" });

    return res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.createService = async (req, res) => {
  try {
    const { service_name, description, base_price } = req.body;

    if (!service_name || !description || base_price === undefined) {
      return res.status(400).json({ message: "Missing fields" });
    }

    const ref = await db.collection("services").add({
      service_name,
      description,
      base_price: Number(base_price),
      is_active: true,
      created_at: new Date(),
    });

    return res.status(201).json({ message: "Service created", id: ref.id });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.updateService = async (req, res) => {
  try {
    const { service_name, description, base_price, is_active } = req.body;

    const update = { updated_at: new Date() };
    if (service_name !== undefined) update.service_name = service_name;
    if (description !== undefined) update.description = description;
    if (base_price !== undefined) update.base_price = Number(base_price);
    if (is_active !== undefined) update.is_active = Boolean(is_active);

    await db.collection("services").doc(req.params.id).update(update);

    return res.json({ message: "Service updated" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

exports.deleteService = async (req, res) => {
  try {
    await db.collection("services").doc(req.params.id).update({
      is_active: false,
      updated_at: new Date(),
    });

    return res.json({ message: "Service disabled" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};