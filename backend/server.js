require("dotenv").config();
const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/clients", require("./routes/clientRoutes"));
app.use("/api/repairmen", require("./routes/repairmanRoutes"));
app.use("/api/bookings", require("./routes/bookingRoutes"));

app.listen(process.env.PORT, () =>
  console.log(`Server running on port ${process.env.PORT}`)
);
