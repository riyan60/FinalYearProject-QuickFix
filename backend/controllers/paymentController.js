const { db } = require("../firebase");

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