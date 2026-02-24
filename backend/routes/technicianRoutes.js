const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const technicianController = require("../controllers/technicianController");

router.get("/me", authMiddleware, technicianController.getMyProfile);
router.put("/update", authMiddleware, technicianController.updateProfile);
router.get("/:id", technicianController.getTechnicianById);

module.exports = router;
