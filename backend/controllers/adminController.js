const { db } = require("../firebase");

const COLLECTION_MAP = {
  dashboard: "bookings",
  users: "users",
  repairmen: "repairmen",
  services: "services",
  bookings: "bookings",
  payments: "payments",
  reviews: "reviews",
  reports: "bookings",
  settings: "accounts",
  accounts: "accounts",
  locations: "locations",
  cities: "cities",
};

const ALLOWED_COLLECTIONS = new Set([
  "accounts",
  "users",
  "repairmen",
  "services",
  "bookings",
  "payments",
  "reviews",
  "locations",
  "cities",
]);

const resolveCollection = (entity = "") => {
  const key = String(entity).trim().toLowerCase();
  const collection = COLLECTION_MAP[key] || key;
  if (!ALLOWED_COLLECTIONS.has(collection)) return null;
  return collection;
};

const coerceBoolean = (value, fallback) => {
  if (value === undefined) return fallback;
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (normalized === "true") return true;
    if (normalized === "false") return false;
  }
  return Boolean(value);
};

const coerceNumber = (value, fallback = 0) => {
  if (value === undefined || value === null || value === "") return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const normalizeServicePayload = (payload = {}, isCreate = false) => {
  const normalized = { ...payload };

  const serviceName = payload.service_name ?? payload.name;
  if (serviceName !== undefined) normalized.service_name = String(serviceName).trim();

  const description = payload.description;
  if (description !== undefined) normalized.description = String(description).trim();

  const category = payload.category;
  if (category !== undefined) normalized.category = String(category).trim();

  const basePrice = payload.base_price ?? payload.price;
  if (basePrice !== undefined) normalized.base_price = coerceNumber(basePrice, 0);

  normalized.is_active = coerceBoolean(payload.is_active, isCreate ? true : payload.is_active);

  delete normalized.name;
  delete normalized.price;

  return normalized;
};

const normalizeEntityPayload = (collection, payload = {}, isCreate = false) => {
  if (collection === "services") return normalizeServicePayload(payload, isCreate);
  if (collection === "cities") {
    return {
      ...payload,
      name: String(payload.name || payload.city || "").trim(),
      is_active: coerceBoolean(payload.is_active, isCreate ? true : payload.is_active),
    };
  }
  return { ...payload };
};

const toMillis = (value) => {
  if (!value) return 0;
  if (typeof value.toDate === "function") return value.toDate().getTime();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? 0 : date.getTime();
};

const toAmount = (value) => {
  const num = Number(value || 0);
  return Number.isFinite(num) ? num : 0;
};

const serialize = (value) => {
  if (value === null || value === undefined) return value;
  if (typeof value.toDate === "function") return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map((item) => serialize(item));
  if (typeof value === "object") {
    const out = {};
    Object.keys(value).forEach((key) => {
      out[key] = serialize(value[key]);
    });
    return out;
  }
  return value;
};

const enrichBooking = async (row) => {
  if (!row || !row.id) return row;

  const enriched = { ...row };
  const [userDoc, repairmanDoc, serviceDoc] = await Promise.all([
    row.user_id ? db.collection("users").doc(String(row.user_id)).get() : null,
    row.repairman_id ? db.collection("repairmen").doc(String(row.repairman_id)).get() : null,
    row.service_id ? db.collection("services").doc(String(row.service_id)).get() : null,
  ]);

  if (userDoc && userDoc.exists) {
    const user = userDoc.data() || {};
    enriched.user_name = user.name || enriched.user_name || "";
  }

  if (repairmanDoc && repairmanDoc.exists) {
    const repairman = repairmanDoc.data() || {};
    enriched.repairman_name =
      enriched.repairman_name || repairman.name || enriched.repairman_name || "";
    enriched.specialty =
      enriched.specialty || repairman.specialization || enriched.specialty || "";
  }

  if (serviceDoc && serviceDoc.exists) {
    const service = serviceDoc.data() || {};
    enriched.service_name = service.service_name || enriched.service_name || "";
  }

  return enriched;
};

const getPrimaryText = (collection, row) => {
  if (collection === "users" || collection === "repairmen") return row.name || row.account_id || row.id;
  if (collection === "services") return row.service_name || row.id;
  if (collection === "bookings") {
    const label =
      row.booking_type === "direct_repairman"
        ? row.specialty || "Direct repairman booking"
        : row.service_name || row.service_id || "Service booking";
    return `Booking ${row.id} • ${label}`;
  }
  if (collection === "payments") return row.transaction_id || row.booking_id || row.id;
  if (collection === "reviews") return `Booking ${row.booking_id || "-"}`;
  if (collection === "accounts") return row.username || row.email || row.id;
  if (collection === "locations") return row.repairman_id || row.id;
  if (collection === "cities") return row.name || row.city || row.id;
  return row.id;
};

const getSecondaryText = (collection, row) => {
  if (collection === "users" || collection === "repairmen") return row.phone || row.address || "No details";
  if (collection === "services") return row.description || "No description";
  if (collection === "bookings") {
    const isDirectBooking = row.booking_type === "direct_repairman";
    const bookingLabel = isDirectBooking
      ? row.specialty || row.booking_mode || "Direct repairman booking"
      : row.service_name || row.service_id || "-";
    const repairmanLabel = row.repairman_name || row.repairman_id || "-";
    return `${isDirectBooking ? "Booking" : "Service"}: ${bookingLabel} | Repairman: ${repairmanLabel}`;
  }
  if (collection === "payments") return row.payment_method || "Unknown";
  if (collection === "reviews") return row.comment || "No comment";
  if (collection === "accounts") return row.email || row.role || "No details";
  if (collection === "locations") return `${row.latitude || "-"}, ${row.longitude || "-"}`;
  if (collection === "cities") return row.state || row.country || "City";
  return "No details";
};

const getStatusText = (collection, row) => {
  if (collection === "repairmen") return row.availability_status || "unknown";
  if (collection === "services") return row.is_active === false ? "inactive" : "active";
  if (collection === "bookings") return row.status || "unknown";
  if (collection === "payments") return row.payment_status || "unknown";
  if (collection === "reviews") return `${toAmount(row.rating)}/5`;
  if (collection === "accounts") return row.is_active === false ? "disabled" : "active";
  if (collection === "cities") return row.is_active === false ? "inactive" : "active";
  return "active";
};

const buildActivityRows = (collection, docs) =>
  docs
    .slice()
    .sort((a, b) => toMillis(b.created_at || b.updated_at || b.payment_date) - toMillis(a.created_at || a.updated_at || a.payment_date))
    .slice(0, 20)
    .map((row) => ({
      id: row.id,
      primary: getPrimaryText(collection, row),
      secondary: getSecondaryText(collection, row),
      status: getStatusText(collection, row),
      amount:
        collection === "payments"
          ? toAmount(row.amount_paid)
          : collection === "bookings"
          ? toAmount(row.total_amount)
          : undefined,
      }));

exports.getDashboardSummary = async (req, res) => {
  try {
    const [accountsSnap, usersSnap, repairmenSnap, servicesSnap, bookingsSnap, paymentsSnap, reviewsSnap, citiesSnap] =
      await Promise.all([
        db.collection("accounts").get(),
        db.collection("users").get(),
        db.collection("repairmen").get(),
        db.collection("services").get(),
        db.collection("bookings").get(),
        db.collection("payments").get(),
        db.collection("reviews").get(),
        db.collection("cities").get(),
      ]);

    const accounts = accountsSnap.docs.map((doc) => doc.data());
    const repairmen = repairmenSnap.docs.map((doc) => doc.data());
    const services = servicesSnap.docs.map((doc) => doc.data());
    const bookings = bookingsSnap.docs.map((doc) => doc.data());
    const payments = paymentsSnap.docs.map((doc) => doc.data());
    const reviews = reviewsSnap.docs.map((doc) => doc.data());

    const totalRevenue = bookings.length * 20;
    const activeUsers = accounts.filter((a) => a.role === "user" && a.is_active !== false).length;
    const activeRepairmen = repairmen.filter((r) => r.availability_status === "available").length;
    const pendingBookings = bookings.filter((b) => b.status === "pending").length;
    const completedBookings = bookings.filter((b) => b.status === "completed").length;
    const activeServices = services.filter((s) => s.is_active !== false).length;
    const ratingSum = reviews.reduce((sum, review) => sum + toAmount(review.rating), 0);
    const avgRating = reviews.length ? ratingSum / reviews.length : 0;

    return res.json({
      stats: {
        totalRevenue,
        activeUsers,
        activeRepairmen,
        pendingBookings,
        completedBookings,
        avgRating,
        activeServices,
      },
      totals: {
        accounts: accountsSnap.size,
        users: usersSnap.size,
        repairmen: repairmenSnap.size,
        services: servicesSnap.size,
        bookings: bookingsSnap.size,
        payments: paymentsSnap.size,
        reviews: reviewsSnap.size,
        cities: citiesSnap ? citiesSnap.size : 0,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getRecentActivity = async (req, res) => {
  try {
    const { tab = "dashboard" } = req.query;
    const collection = resolveCollection(tab) || "bookings";
    const snap = await db.collection(collection).get();
    let docs = snap.docs.map((doc) => ({ id: doc.id, ...serialize(doc.data()) }));
    if (collection === "bookings") {
      docs = await Promise.all(docs.map((row) => enrichBooking(row)));
    }
    const items = buildActivityRows(collection, docs);
    return res.json({ tab, items });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getEntities = async (req, res) => {
  try {
    const { entity } = req.params;
    const { q = "" } = req.query;

    const collection = resolveCollection(entity);
    if (!collection) return res.status(400).json({ message: "Unsupported entity" });

    const snap = await db.collection(collection).get();
    let items = snap.docs.map((doc) => ({ id: doc.id, ...serialize(doc.data()) }));
    if (collection === "bookings") {
      items = await Promise.all(items.map((row) => enrichBooking(row)));
    }

    const needle = String(q).trim().toLowerCase();
    if (needle) {
      items = items.filter((item) => JSON.stringify(item).toLowerCase().includes(needle));
    }

    items = items
      .slice()
      .sort(
        (a, b) =>
          toMillis(b.created_at || b.updated_at || b.payment_date) -
          toMillis(a.created_at || a.updated_at || a.payment_date)
      );

    return res.json({ collection, count: items.length, items });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.createEntity = async (req, res) => {
  try {
    const { entity } = req.params;
    const collection = resolveCollection(entity);
    if (!collection) return res.status(400).json({ message: "Unsupported entity" });

    const normalized = normalizeEntityPayload(collection, req.body || {}, true);
    const payload = { ...normalized, created_at: new Date(), updated_at: new Date() };
    const ref = await db.collection(collection).add(payload);
    return res.status(201).json({ message: "Created", id: ref.id });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.updateEntity = async (req, res) => {
  try {
    const { entity, id } = req.params;
    const collection = resolveCollection(entity);
    if (!collection) return res.status(400).json({ message: "Unsupported entity" });
    if (!id) return res.status(400).json({ message: "id is required" });

    const normalized = normalizeEntityPayload(collection, req.body || {});
    const patch = { ...normalized, updated_at: new Date() };
    delete patch.id;
    await db.collection(collection).doc(id).set(patch, { merge: true });
    return res.json({ message: "Updated" });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.deleteEntity = async (req, res) => {
  try {
    const { entity, id } = req.params;
    const collection = resolveCollection(entity);
    if (!collection) return res.status(400).json({ message: "Unsupported entity" });
    if (!id) return res.status(400).json({ message: "id is required" });

    await db.collection(collection).doc(id).delete();
    return res.json({ message: "Deleted" });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getCollections = async (req, res) => {
  return res.json({
    collections: [
      "dashboard",
      "users",
      "repairmen",
      "services",
      "bookings",
      "payments",
      "reviews",
      "accounts",
      "locations",
      "cities",
      "reports",
      "settings",
    ],
  });
};
