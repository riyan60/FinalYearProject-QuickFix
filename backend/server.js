require("dotenv").config();   

const express = require("express");
const cors = require("cors");

const clientRoutes = require("./routes/clientRoutes");
const repairmanRoutes = require("./routes/repairmanRoutes");
const bookingRoutes = require("./routes/bookingRoutes");
const authRoutes = require("./routes/authRoutes");
const serviceRoutes = require("./routes/serviceRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/client", clientRoutes);
app.use("/api/repairman", repairmanRoutes);
app.use("/api/booking", bookingRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/services", serviceRoutes);

app.listen(5000, () => {
  console.log("Server running on port 5000");
});



