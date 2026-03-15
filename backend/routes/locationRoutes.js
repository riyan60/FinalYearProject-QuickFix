const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { allowRoles } = require("../middleware/authMiddleware");
const locationController = require("../controllers/locationController");

router.get("/cities", locationController.getCities);

router.post(
  "/update",
  authMiddleware,
  allowRoles("repairman"),
  locationController.updateLocation
);

router.get(
  "/:bookingId",
  locationController.getRepairmanLocationByBooking
);

module.exports = router;
