require("dotenv").config();
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateBookings() {
  console.log("Starting migration of bookings...");

  try {
    const bookingsSnapshot = await db.collection("bookings").get();

    if (bookingsSnapshot.empty) {
      console.log("No bookings found to migrate.");
      return;
    }

    console.log(`Found ${bookingsSnapshot.size} bookings to migrate.`);

    let migratedCount = 0;
    let skippedCount = 0;

    for (const doc of bookingsSnapshot.docs) {
      const data = doc.data();
      const updates = {};

      // Check if migration is needed
      if (data.clientId && !data.userId) {
        updates.userId = data.clientId;
        console.log(`Migrating clientId -> userId for document ${doc.id}`);
      }

      if (data.serviceType && !data.serviceId) {
        updates.serviceId = data.serviceType;
        console.log(`Migrating serviceType -> serviceId for document ${doc.id}`);
      }

      if (data.createdAt && !data.date) {
        updates.date = data.createdAt;
        console.log(`Migrating createdAt -> date for document ${doc.id}`);
      }

      if (Object.keys(updates).length > 0) {
        // Keep original fields for backward compatibility
        await doc.ref.update(updates);
        migratedCount++;
        console.log(`Successfully migrated document ${doc.id}`);
      } else {
        skippedCount++;
        console.log(`Skipped document ${doc.id} - already migrated or no changes needed`);
      }
    }

    console.log("\n=== Migration Summary ===");
    console.log(`Total bookings: ${bookingsSnapshot.size}`);
    console.log(`Migrated: ${migratedCount}`);
    console.log(`Skipped: ${skippedCount}`);
    console.log("Migration completed successfully!");

  } catch (error) {
    console.error("Migration failed:", error);
  }

  process.exit(0);
}

// Run the migration
migrateBookings();
