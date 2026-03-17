require("dotenv").config();
const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const { db } = require("./firebase");

const app = express();
const server = http.createServer(app);

app.use(cors());
app.use(express.json());

app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/repairmen", require("./routes/repairmanRoutes"));
app.use("/api/services", require("./routes/serviceRoutes"));
app.use("/api/bookings", require("./routes/bookingRoutes"));
app.use("/api/location", require("./routes/locationRoutes"));
app.use("/api/reviews", require("./routes/reviewRoutes"));
app.use("/api/payments", require("./routes/paymentRoutes"));
app.use("/api/admin", require("./routes/adminRoutes"));
app.use("/api/password", require("./routes/passwordResetRoutes"));
app.use("/api/chats", require("./routes/chatRoutes"));
app.use("/api/calls", require("./routes/callRoutes"));

const io = new Server(server, {
  cors: {
    origin: "*",
  },
});

const isActiveBooking = (status) =>
  ["pending", "accepted", "ongoing"].includes(status);

io.use((socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error("No token"));

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error("Invalid token"));
  }
});

io.on("connection", (socket) => {
  // CHAT JOIN
  socket.on("join_chat", async ({ bookingId }) => {
    try {
      const bookingDoc = await db.collection("bookings").doc(bookingId).get();
      if (!bookingDoc.exists) {
        return socket.emit("chat_error", { message: "Booking not found" });
      }

      const booking = bookingDoc.data();
      const userId = socket.user.userId;

      if (booking.user_id !== userId && booking.repairman_id !== userId) {
        return socket.emit("chat_error", { message: "Access denied" });
      }

      if (!isActiveBooking(booking.status)) {
        return socket.emit("chat_error", { message: "Chat is closed" });
      }

      const chatRef = db.collection("chats").doc(bookingId);
      const chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        await chatRef.set({
          booking_id: bookingId,
          user_id: booking.user_id,
          repairman_id: booking.repairman_id,
          is_active: true,
          created_at: new Date(),
          last_message: "",
          last_message_at: null,
          last_sender_id: null,
          closed_at: null,
        });
      }

      socket.join(`chat_${bookingId}`);
      socket.emit("joined_chat", { bookingId });
    } catch (err) {
      socket.emit("chat_error", { message: err.message });
    }
  });

  // CHAT SEND
  socket.on("send_message", async ({ bookingId, text }) => {
    try {
      if (!text || !String(text).trim()) {
        return socket.emit("chat_error", { message: "Message cannot be empty" });
      }

      const bookingDoc = await db.collection("bookings").doc(bookingId).get();
      if (!bookingDoc.exists) {
        return socket.emit("chat_error", { message: "Booking not found" });
      }

      const booking = bookingDoc.data();
      const userId = socket.user.userId;
      const role = socket.user.role;

      if (booking.user_id !== userId && booking.repairman_id !== userId) {
        return socket.emit("chat_error", { message: "Access denied" });
      }

      if (!isActiveBooking(booking.status)) {
        return socket.emit("chat_error", { message: "Chat is closed" });
      }

      const chatRef = db.collection("chats").doc(bookingId);
      const chatDoc = await chatRef.get();

      if (!chatDoc.exists || chatDoc.data().is_active === false) {
        return socket.emit("chat_error", { message: "Chat not active" });
      }

      const now = new Date();

      const msgRef = await chatRef.collection("messages").add({
        sender_id: userId,
        sender_role: role,
        text: String(text).trim(),
        created_at: now,
      });

      await chatRef.set(
        {
          last_message: String(text).trim(),
          last_message_at: now,
          last_sender_id: userId,
        },
        { merge: true }
      );

      io.to(`chat_${bookingId}`).emit("new_message", {
        id: msgRef.id,
        sender_id: userId,
        sender_role: role,
        text: String(text).trim(),
        created_at: now,
      });
    } catch (err) {
      socket.emit("chat_error", { message: err.message });
    }
  });

  // CALL JOIN
  socket.on("join_call_room", async ({ bookingId }) => {
    try {
      const bookingDoc = await db.collection("bookings").doc(bookingId).get();
      if (!bookingDoc.exists) {
        return socket.emit("call_error", { message: "Booking not found" });
      }

      const booking = bookingDoc.data();
      const userId = socket.user.userId;

      if (booking.user_id !== userId && booking.repairman_id !== userId) {
        return socket.emit("call_error", { message: "Access denied" });
      }

      if (!isActiveBooking(booking.status)) {
        return socket.emit("call_error", { message: "Call is not allowed" });
      }

      socket.join(`call_${bookingId}`);
      socket.emit("joined_call_room", { bookingId });
    } catch (err) {
      socket.emit("call_error", { message: err.message });
    }
  });

  // START CALL
  socket.on("start_call", async ({ bookingId }) => {
    try {
      const bookingDoc = await db.collection("bookings").doc(bookingId).get();
      if (!bookingDoc.exists) {
        return socket.emit("call_error", { message: "Booking not found" });
      }

      const booking = bookingDoc.data();
      const userId = socket.user.userId;

      if (booking.user_id !== userId && booking.repairman_id !== userId) {
        return socket.emit("call_error", { message: "Access denied" });
      }

      if (!isActiveBooking(booking.status)) {
        return socket.emit("call_error", { message: "Call is not allowed" });
      }

      await db.collection("calls").doc(bookingId).set(
        {
          booking_id: bookingId,
          user_id: booking.user_id,
          repairman_id: booking.repairman_id,
          status: "ringing",
          caller_id: userId,
          created_at: new Date(),
          started_at: null,
          ended_at: null,
        },
        { merge: true }
      );

      socket.to(`call_${bookingId}`).emit("incoming_call", {
        bookingId,
        caller_id: userId,
      });
    } catch (err) {
      socket.emit("call_error", { message: err.message });
    }
  });

  // ACCEPT CALL
  socket.on("accept_call", async ({ bookingId }) => {
    try {
      const callRef = db.collection("calls").doc(bookingId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        return socket.emit("call_error", { message: "Call not found" });
      }

      await callRef.update({
        status: "ongoing",
        started_at: new Date(),
      });

      io.to(`call_${bookingId}`).emit("call_accepted", { bookingId });
    } catch (err) {
      socket.emit("call_error", { message: err.message });
    }
  });

  // REJECT CALL
  socket.on("reject_call", async ({ bookingId }) => {
    try {
      const callRef = db.collection("calls").doc(bookingId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        return socket.emit("call_error", { message: "Call not found" });
      }

      await callRef.update({
        status: "rejected",
        ended_at: new Date(),
      });

      io.to(`call_${bookingId}`).emit("call_rejected", { bookingId });
    } catch (err) {
      socket.emit("call_error", { message: err.message });
    }
  });

  // END CALL
  socket.on("end_call", async ({ bookingId }) => {
    try {
      const callRef = db.collection("calls").doc(bookingId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        return socket.emit("call_error", { message: "Call not found" });
      }

      await callRef.update({
        status: "ended",
        ended_at: new Date(),
      });

      io.to(`call_${bookingId}`).emit("call_ended", { bookingId });
    } catch (err) {
      socket.emit("call_error", { message: err.message });
    }
  });

  // WEBRTC OFFER
  socket.on("webrtc_offer", ({ bookingId, offer }) => {
    socket.to(`call_${bookingId}`).emit("receive_offer", { bookingId, offer });
  });

  // WEBRTC ANSWER
  socket.on("webrtc_answer", ({ bookingId, answer }) => {
    socket.to(`call_${bookingId}`).emit("receive_answer", { bookingId, answer });
  });

  // ICE CANDIDATE
  socket.on("webrtc_ice_candidate", ({ bookingId, candidate }) => {
    socket.to(`call_${bookingId}`).emit("receive_ice_candidate", {
      bookingId,
      candidate,
    });
  });
});

server.listen(process.env.PORT, () =>
  console.log(`Server running on port ${process.env.PORT}`)
);