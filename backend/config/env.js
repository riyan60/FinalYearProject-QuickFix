const path = require("path");
const dotenv = require("dotenv");

dotenv.config();
dotenv.config({ path: path.join(__dirname, "..", ".env") });

function getEnv(name, fallback = "") {
  const value = process.env[name];
  if (value === undefined || value === null) {
    return fallback;
  }
  return String(value);
}

function requireEnv(name) {
  const value = getEnv(name).trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function getNumberEnv(name, fallback) {
  const raw = getEnv(name, "");
  if (!raw.trim()) {
    return fallback;
  }

  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

module.exports = {
  port: getNumberEnv("PORT", 5000),
  nodeEnv: getEnv("NODE_ENV", "development").trim() || "development",
  jwtSecret: () => requireEnv("JWT_SECRET"),
  firebaseProjectId: () => getEnv("FIREBASE_PROJECT_ID").trim(),
  firebasePrivateKey: () => getEnv("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n"),
  firebaseClientEmail: () => getEnv("FIREBASE_CLIENT_EMAIL").trim(),
  firebaseDatabaseUrl: () => getEnv("FIREBASE_DATABASE_URL").trim(),
  firebaseServiceAccountJson: () => getEnv("FIREBASE_SERVICE_ACCOUNT_JSON").trim(),
  emailUser: () => getEnv("EMAIL_USER").trim(),
  emailPass: () => getEnv("EMAIL_PASS").trim(),
  otpExpMin: getNumberEnv("OTP_EXP_MIN", 10),
  otpResendCooldownSec: getNumberEnv("OTP_RESEND_COOLDOWN_SEC", 45),
  razorpayKeyId: () => getEnv("RAZORPAY_KEY_ID").trim(),
  razorpayKeySecret: () => getEnv("RAZORPAY_KEY_SECRET").trim(),
};
