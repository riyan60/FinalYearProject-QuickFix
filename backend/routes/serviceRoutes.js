const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const serviceController = require("../controllers/serviceController");

router.post("/", authMiddleware, serviceController.createService);
router.get("/category/:category", serviceController.getServicesByCategory);
router.get("/technician/:technicianId", serviceController.getServicesByTechnician);
router.put("/:serviceId", authMiddleware, serviceController.updateService);
router.delete("/:serviceId", authMiddleware, serviceController.deleteService);

module.exports = router;
