const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const env = require("./config/env");

function getServiceAccountFromEnv() {
  const serviceAccountJson = env.firebaseServiceAccountJson();
  if (serviceAccountJson) {
    return JSON.parse(serviceAccountJson);
  }

  const projectId = env.firebaseProjectId();
  const privateKey = env.firebasePrivateKey();
  const clientEmail = env.firebaseClientEmail();

  if (!projectId || !privateKey || !clientEmail) {
    return null;
  }

  return {
    projectId,
    privateKey,
    clientEmail,
  };
}

function getServiceAccountFromFile() {
  const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");
  if (!fs.existsSync(serviceAccountPath)) {
    return null;
  }

  return require("./serviceAccountKey.json");
}

const serviceAccount = getServiceAccountFromEnv() || getServiceAccountFromFile();

if (!serviceAccount) {
  throw new Error(
    "Firebase credentials missing. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY and FIREBASE_CLIENT_EMAIL."
  );
}

const firebaseConfig = {
  credential: admin.credential.cert(serviceAccount),
};

if (env.firebaseDatabaseUrl()) {
  firebaseConfig.databaseURL = env.firebaseDatabaseUrl();
}

admin.initializeApp(firebaseConfig);

const db = admin.firestore();
module.exports = { admin, db };
