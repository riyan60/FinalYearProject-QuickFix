const express = require("express");
const router = express.Router();

const passwordResetController = require("../controllers/passwordResetController");

router.post("/request-otp", passwordResetController.requestOtp);
router.post("/resend-otp", passwordResetController.resendOtp);
router.post("/verify-otp", passwordResetController.verifyOtp);
router.post("/reset-password", passwordResetController.resetPassword);

module.exports = router;