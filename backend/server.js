const express = require("express");
const cors = require("cors");
const env = require("./config/env");

const app = express();
const PORT = env.port;

app.use(cors());
app.use(express.json());

app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/repairmen", require("./routes/repairmanRoutes"));
app.use("/api/services", require("./routes/serviceRoutes"));
app.use("/api/bookings", require("./routes/bookingRoutes"));
app.use("/api/location", require("./routes/locationRoutes"));
app.use("/api/reviews", require("./routes/reviewRoutes"));
app.use("/api/feedback", require("./routes/feedbackRoutes"));
app.use("/api/payments", require("./routes/paymentRoutes"));
app.use("/api/chat", require("./routes/chatRoutes"));
app.use("/api/admin", require("./routes/adminRoutes"));

try {
  app.use("/api/password", require("./routes/passwordResetRoutes"));
} catch (error) {
  console.warn("Password reset routes disabled:", error.message);
}

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
