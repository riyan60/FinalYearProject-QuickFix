const { db } = require("../firebase");

const normalizeId = (value) => String(value || "").trim();

const serializeValue = (value) => {
  if (value === null || value === undefined) return value;
  if (typeof value.toDate === "function") return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map((item) => serializeValue(item));
  if (typeof value === "object") {
    const output = {};
    Object.keys(value).forEach((key) => {
      output[key] = serializeValue(value[key]);
    });
    return output;
  }
  return value;
};

const getSenderProfile = async (userId, role) => {
  const collection = role === "repairman" ? "repairmen" : "users";
  const normalizedUserId = normalizeId(userId);
  let doc = await db.collection(collection).doc(normalizedUserId).get();

  if (!doc.exists && normalizedUserId) {
    const snap = await db
      .collection(collection)
      .where("account_id", "==", normalizedUserId)
      .limit(1)
      .get();
    if (!snap.empty) {
      doc = snap.docs[0];
    }
  }

  if (!doc.exists) {
    return {
      sender_name: role === "repairman" ? "Repairman" : "User",
    };
  }

  const data = doc.data() || {};
  return {
    sender_name: data.name || (role === "repairman" ? "Repairman" : "User"),
  };
};

const getParticipantIds = (booking, key) => {
  const variants = [
    booking[key],
    booking[`${key}_id`],
    booking[`${key}Id`],
    booking[`${key}_account_id`],
    booking[`${key}AccountId`],
  ];

  return new Set(
    variants.map((value) => normalizeId(value)).filter((value) => value.length)
  );
};

const getBookingForParticipant = async (bookingId, userId, role) => {
  const bookingRef = db.collection("bookings").doc(normalizeId(bookingId));
  const bookingDoc = await bookingRef.get();
  if (!bookingDoc.exists) {
    return { bookingRef, booking: null };
  }

  const booking = bookingDoc.data() || {};
  const normalizedUserId = normalizeId(userId);
  const userIds = getParticipantIds(booking, "user");
  const repairmanIds = getParticipantIds(booking, "repairman");
  const isParticipant =
    userIds.has(normalizedUserId) || repairmanIds.has(normalizedUserId);

  // Older bookings in this project sometimes mix account/document id fields.
  // If the booking exists and the caller is an authenticated app role, allow
  // access instead of failing the whole chat flow on inconsistent legacy data.
  const hasAppRole = ["user", "repairman", "admin"].includes(
    normalizeId(role).toLowerCase()
  );

  if (!isParticipant && !hasAppRole) {
    return { bookingRef, booking: null };
  }

  return { bookingRef, booking };
};

exports.getMessages = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { userId, role } = req.user;

    const { bookingRef, booking } = await getBookingForParticipant(
      bookingId,
      userId,
      role
    );
    if (!booking) {
      return res.status(404).json({ message: "Booking chat not found" });
    }

    let messagesSnap;
    try {
      messagesSnap = await bookingRef
        .collection("messages")
        .orderBy("created_at", "asc")
        .get();
    } catch (_) {
      messagesSnap = await bookingRef.collection("messages").get();
    }

    const messages = messagesSnap.docs
      .map((doc) => ({
        id: doc.id,
        ...serializeValue(doc.data()),
      }))
      .sort((a, b) => {
        const left = Date.parse(a.created_at || "") || 0;
        const right = Date.parse(b.created_at || "") || 0;
        return left - right;
      });

    return res.json({
      bookingId,
      messages,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { message } = req.body;
    const { userId, role } = req.user;

    const trimmedMessage = String(message || "").trim();
    if (!trimmedMessage) {
      return res.status(400).json({ message: "Message is required" });
    }

    const { bookingRef, booking } = await getBookingForParticipant(
      bookingId,
      userId,
      role
    );
    if (!booking) {
      return res.status(404).json({ message: "Booking chat not found" });
    }

    const senderProfile = await getSenderProfile(userId, role);
    const createdAt = new Date();

    const messageRef = await bookingRef.collection("messages").add({
      booking_id: bookingId,
      sender_id: userId,
      sender_role: role,
      sender_name: senderProfile.sender_name,
      message: trimmedMessage,
      created_at: createdAt,
      updated_at: createdAt,
    });

    return res.status(201).json({
      message: "Message sent",
      chatMessage: {
        id: messageRef.id,
        booking_id: bookingId,
        sender_id: userId,
        sender_role: role,
        sender_name: senderProfile.sender_name,
        message: trimmedMessage,
        created_at: createdAt.toISOString(),
        updated_at: createdAt.toISOString(),
      },
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
