const express = require("express");
const router = express.Router();

const bookingController = require("../controllers/bookingController");
const authMiddleware = require("../middleware/authMiddleware");

router.post("/create", authMiddleware, bookingController.createBooking);
router.get("/my", authMiddleware, bookingController.getMyBookings);
router.put("/:bookingId/status", authMiddleware, bookingController.updateBookingStatus);
router.post("/:bookingId/verify-otp", authMiddleware, bookingController.verifyOtpAndComplete);

module.exports = router;