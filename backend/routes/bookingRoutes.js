const express = require("express");
const router = express.Router();

const bookingController = require("../controllers/bookingController");
const authMiddleware = require("../middleware/authMiddleware");

// Create booking
router.post(
  "/create",
  authMiddleware,
  bookingController.createBooking
);

// Get own bookings
router.get(
  "/my-bookings",
  authMiddleware,
  bookingController.getMyBookings
);

// Update booking status
router.put(
  "/update-status/:bookingId",
  authMiddleware,
  bookingController.updateBookingStatus
);

module.exports = router;
