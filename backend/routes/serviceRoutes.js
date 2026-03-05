const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const { allowRoles } = require("../middleware/authMiddleware");
const serviceController = require("../controllers/serviceController");

// Public
router.get("/", serviceController.getAllServices);
router.get("/:id", serviceController.getServiceById);

// Admin only
router.post("/", authMiddleware, allowRoles("admin"), serviceController.createService);
router.put("/:id", authMiddleware, allowRoles("admin"), serviceController.updateService);
router.delete("/:id", authMiddleware, allowRoles("admin"), serviceController.deleteService);

module.exports = router;
