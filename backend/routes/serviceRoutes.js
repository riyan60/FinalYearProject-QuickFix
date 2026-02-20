const express = require("express");
const router = express.Router();

const serviceController = require("../controllers/serviceController");
const authMiddleware = require("../middleware/authMiddleware");

// Get all services (public)
router.get("/", serviceController.getAllServices);

// Get service by ID (public)
router.get("/:id", serviceController.getServiceById);

// Create service (protected - could be admin only)
router.post("/", authMiddleware, serviceController.createService);

// Update service (protected)
router.put("/:id", authMiddleware, serviceController.updateService);

// Delete service (protected)
router.delete("/:id", authMiddleware, serviceController.deleteService);

module.exports = router;
