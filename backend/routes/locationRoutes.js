const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { allowRoles } = require("../middleware/authMiddleware");
const locationController = require("../controllers/locationController");

router.post(
  "/update",
  authMiddleware,
  allowRoles("repairman"),
  locationController.updateLocation
);

module.exports = router;