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
]);

const resolveCollection = (entity = "") => {
  const key = String(entity).trim().toLowerCase();
  const collection = COLLECTION_MAP[key] || key;
  if (!ALLOWED_COLLECTIONS.has(collection)) return null;
  return collection;
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

const getPrimaryText = (collection, row) => {
  if (collection === "users" || collection === "repairmen") return row.name || row.account_id || row.id;
  if (collection === "services") return row.service_name || row.id;
  if (collection === "bookings") return `Booking ${row.id}`;
  if (collection === "payments") return row.transaction_id || row.booking_id || row.id;
  if (collection === "reviews") return `Booking ${row.booking_id || "-"}`;
  if (collection === "accounts") return row.username || row.email || row.id;
  if (collection === "locations") return row.repairman_id || row.id;
  return row.id;
};

const getSecondaryText = (collection, row) => {
  if (collection === "users" || collection === "repairmen") return row.phone || row.address || "No details";
  if (collection === "services") return row.description || "No description";
  if (collection === "bookings")
    return `Service: ${row.service_id || "-"} | Repairman: ${row.repairman_id || "-"}`;
  if (collection === "payments") return row.payment_method || "Unknown";
  if (collection === "reviews") return row.comment || "No comment";
  if (collection === "accounts") return row.email || row.role || "No details";
  if (collection === "locations") return `${row.latitude || "-"}, ${row.longitude || "-"}`;
  return "No details";
};

const getStatusText = (collection, row) => {
  if (collection === "repairmen") return row.availability_status || "unknown";
  if (collection === "services") return row.is_active === false ? "inactive" : "active";
  if (collection === "bookings") return row.status || "unknown";
  if (collection === "payments") return row.payment_status || "unknown";
  if (collection === "reviews") return `${toAmount(row.rating)}/5`;
  if (collection === "accounts") return row.is_active === false ? "disabled" : "active";
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
    const [accountsSnap, usersSnap, repairmenSnap, servicesSnap, bookingsSnap, paymentsSnap, reviewsSnap] =
      await Promise.all([
        db.collection("accounts").get(),
        db.collection("users").get(),
        db.collection("repairmen").get(),
        db.collection("services").get(),
        db.collection("bookings").get(),
        db.collection("payments").get(),
        db.collection("reviews").get(),
      ]);

    const accounts = accountsSnap.docs.map((doc) => doc.data());
    const repairmen = repairmenSnap.docs.map((doc) => doc.data());
    const services = servicesSnap.docs.map((doc) => doc.data());
    const bookings = bookingsSnap.docs.map((doc) => doc.data());
    const payments = paymentsSnap.docs.map((doc) => doc.data());
    const reviews = reviewsSnap.docs.map((doc) => doc.data());

    const totalRevenue = payments.reduce((sum, payment) => sum + toAmount(payment.amount_paid), 0);
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
    const docs = snap.docs.map((doc) => ({ id: doc.id, ...serialize(doc.data()) }));
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

    const payload = { ...(req.body || {}), created_at: new Date(), updated_at: new Date() };
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

    const patch = { ...(req.body || {}), updated_at: new Date() };
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
      "reports",
      "settings",
    ],
  });
};
