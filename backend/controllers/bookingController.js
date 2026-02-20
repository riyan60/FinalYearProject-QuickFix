const db = require("../firebase");

exports.createBooking = async (req, res) => {
  try {
    const {
      userId,
      serviceId,
      repairmanId,
      date,
      status
    } = req.body;

    if (!userId || !serviceId || !repairmanId || !date) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const bookingData = {
      userId,
      serviceId,
      repairmanId,
      date: new Date(date),
      status: status || "pending",
      createdAt: new Date()
    };

    await db.collection("bookings").add(bookingData);

    res.status(201).json({ message: "Booking created successfully" });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getMyBookings = async (req, res) => {
  try {
    const { userId, role } = req.user;

    let query;
    if (role === "client") {
      query = db.collection("bookings").where("userId", "==", userId);
    } else if (role === "repairman") {
      query = db.collection("bookings").where("repairmanId", "==", userId);
    }

    const snapshot = await query.get();
    const bookings = [];

    snapshot.forEach(doc => {
      bookings.push({ id: doc.id, ...doc.data() });
    });

    res.json({ bookings });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateBookingStatus = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ message: "Status required" });
    }

    await db.collection("bookings").doc(bookingId).update({
      status,
      updatedAt: new Date()
    });

    res.json({ message: "Booking status updated successfully" });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
