const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const paymentController = require("../controllers/payment_controller");

router.post("/create-order", authMiddleware, paymentController.createOrder);
router.post("/verify-payment", authMiddleware, paymentController.verifyPayment);
router.post("/", authMiddleware, paymentController.createPayment);

module.exports = router;
