const { db } = require("../firebase");
const crypto = require("crypto");
const Razorpay = require("razorpay");

function getRazorpayConfig() {
  const keyId = process.env.RAZORPAY_KEY_ID?.trim();
  const keySecret = process.env.RAZORPAY_KEY_SECRET?.trim();

  if (!keyId || !keySecret) {
    return null;
  }

  return {
    key_id: keyId,
    key_secret: keySecret,
  };
}

function getRazorpayClient() {
  const config = getRazorpayConfig();
  if (!config) {
    return null;
  }

  return new Razorpay(config);
}

exports.createPayment = async (req, res) => {
  try {
    const {
      bookingId,
      amount_paid,
      payment_method,
      payment_status,
      transaction_id,
    } = req.body;

    if (
      !bookingId ||
      amount_paid === undefined ||
      !payment_method ||
      !payment_status
    ) {
      return res.status(400).json({ message: "Missing fields" });
    }

    const ref = await db.collection("payments").add({
      booking_id: bookingId,
      amount_paid: Number(amount_paid),
      payment_method,
      payment_status,
      transaction_id: transaction_id || "",
      refund_amount: 0,
      payment_date: new Date(),
    });

    return res.status(201).json({
      message: "Payment stored",
      paymentId: ref.id,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

exports.createOrder = async (req, res) => {
  try {
    const razorpay = getRazorpayClient();
    if (!razorpay) {
      return res.status(500).json({
        message:
          "Razorpay keys are missing. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.",
      });
    }

    const amount = Number(req.body.amount);
    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({
        message: "Invalid amount. Provide amount in paise as a positive number.",
      });
    }

    const order = await razorpay.orders.create({
      amount: Math.round(amount),
      currency: "INR",
      receipt: `quickfix_${Date.now()}`,
      payment_capture: 1,
    });

    return res.status(201).json({
      success: true,
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to create Razorpay order.",
      error: error.message,
    });
  }
};

exports.verifyPayment = async (req, res) => {
  try {
    const razorpayConfig = getRazorpayConfig();
    if (!razorpayConfig) {
      return res.status(500).json({
        success: false,
        message:
          "Razorpay keys are missing. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.",
      });
    }

    const { order_id, payment_id, signature } = req.body;
    if (!order_id || !payment_id || !signature) {
      return res.status(400).json({
        success: false,
        message: "order_id, payment_id and signature are required.",
      });
    }

    const expectedSignature = crypto
      .createHmac("sha256", razorpayConfig.key_secret)
      .update(`${order_id}|${payment_id}`)
      .digest("hex");

    const isValid = expectedSignature === signature;
    if (!isValid) {
      return res.status(400).json({
        success: false,
        message: "Payment signature verification failed.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Payment verified successfully.",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Payment verification failed due to server error.",
      error: error.message,
    });
  }
};
