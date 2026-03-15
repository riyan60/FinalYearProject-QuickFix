const { db } = require("../firebase");

const goaCities = [
  "Panaji",
  "Margao",
  "Vasco da Gama",
  "Mapusa",
  "Ponda",
  "Bicholim",
  "Curchorem",
  "Sanquelim",
  "Valpoi",
  "Quepem",
  "Canacona",
  "Pernem",
];

async function seedGoaCities() {
  console.log("Seeding Goa cities...");

  let createdCount = 0;
  let skippedCount = 0;

  for (const cityName of goaCities) {
    const existingSnap = await db
      .collection("cities")
      .where("name", "==", cityName)
      .limit(1)
      .get();

    if (!existingSnap.empty) {
      skippedCount += 1;
      console.log(`Skipped existing city: ${cityName}`);
      continue;
    }

    await db.collection("cities").add({
      name: cityName,
      state: "Goa",
      country: "India",
      is_active: true,
      created_at: new Date(),
      updated_at: new Date(),
    });

    createdCount += 1;
    console.log(`Added city: ${cityName}`);
  }

  console.log(`Done. Created ${createdCount}, skipped ${skippedCount}.`);
}

seedGoaCities()
  .catch((error) => {
    console.error("Failed to seed Goa cities:", error);
    process.exitCode = 1;
  })
  .finally(() => {
    process.exit();
  });
