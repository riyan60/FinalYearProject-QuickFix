const { db } = require("../firebase");
const bcrypt = require("bcryptjs");
const nodemailer = require("nodemailer");
const env = require("../config/env");

const OTP_LEN = 4;
const OTP_EXP_MIN = env.otpExpMin;
const RESEND_COOLDOWN_SEC = env.otpResendCooldownSec;
const MAX_ATTEMPTS = 5;
const MAX_RESENDS = 5;

function getTransporter() {
  const emailUser = env.emailUser();
  const emailPass = env.emailPass();

  if (!emailUser || !emailPass) {
    return null;
  }

  return nodemailer.createTransport({
    service: "gmail",
    auth: { user: emailUser, pass: emailPass },
  });
}

const genOtp = () => String(Math.floor(1000 + Math.random() * 9000));
const addMinutes = (min) => new Date(Date.now() + min * 60 * 1000);

const maskEmail = (email) => {
  if (!email || !email.includes("@")) return "";
  const [name, domain] = email.split("@");
  const start = name.slice(0, 2);
  const end = name.slice(-1);
  return `${start}***${end}@${domain}`;
};

const canResendNow = (lastSentAt) => {
  const last = lastSentAt?.toDate ? lastSentAt.toDate() : lastSentAt ? new Date(lastSentAt) : null;
  if (!last) return true;
  return (Date.now() - last.getTime()) / 1000 >= RESEND_COOLDOWN_SEC;
};

const getAccountByUsername = async (username) => {
  const snap = await db.collection("accounts").where("username", "==", username).get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return { id: doc.id, ...doc.data() };
};

const sendEmailOtp = async (toEmail, otp) => {
  const transporter = getTransporter();
  if (!transporter) {
    throw new Error("Password reset email is not configured. Set EMAIL_USER and EMAIL_PASS.");
  }

  await transporter.sendMail({
    from: env.emailUser(),
    to: toEmail,
    subject: "QuickFix Password Reset OTP",
    text: `Your OTP is ${otp}. It expires in ${OTP_EXP_MIN} minutes.`,
  });
};

// 1) Request OTP (email-only)
// Body: { username }
exports.requestOtp = async (req, res) => {
  try {
    const { username } = req.body;
    if (!username) return res.status(400).json({ message: "username required" });

    const acc = await getAccountByUsername(username);

    // Security: do not reveal whether username exists
    if (!acc || !acc.email) {
      return res.json({ message: "If the account exists, OTP has been sent." });
    }

    const resetRef = db.collection("password_resets").doc(acc.id);
    const resetDoc = await resetRef.get();

    if (resetDoc.exists) {
      const data = resetDoc.data();

      if (!canResendNow(data.last_sent_at)) {
        return res.status(429).json({
          message: "Please wait before resending OTP",
          masked_email: maskEmail(acc.email),
          cooldown_sec: RESEND_COOLDOWN_SEC,
        });
      }

      if (Number(data.resend_count || 0) >= MAX_RESENDS) {
        return res.status(429).json({
          message: "Resend limit reached. Try later.",
          masked_email: maskEmail(acc.email),
        });
      }
    }

    const otp = genOtp();
    const otp_hash = await bcrypt.hash(otp, 10);

    await resetRef.set(
      {
        account_id: acc.id,
        otp_hash,
        expires_at: addMinutes(OTP_EXP_MIN),
        attempts: 0,
        last_sent_at: new Date(),
        resend_count: resetDoc.exists ? Number(resetDoc.data().resend_count || 0) + 1 : 1,
        verified: false,
        verified_at: null,
      },
      { merge: true }
    );

    await sendEmailOtp(acc.email, otp);

    return res.json({
      message: "OTP sent",
      masked_email: maskEmail(acc.email),
      cooldown_sec: RESEND_COOLDOWN_SEC,
      expires_min: OTP_EXP_MIN,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

// 2) Resend OTP (email-only)
// Body: { username }
exports.resendOtp = async (req, res) => {
  return exports.requestOtp(req, res);
};

// 3) Verify OTP
// Body: { username, otp }
exports.verifyOtp = async (req, res) => {
  try {
    const { username, otp } = req.body;
    if (!username || !otp || String(otp).length !== OTP_LEN) {
      return res.status(400).json({ message: "username and 4-digit otp required" });
    }

    const acc = await getAccountByUsername(username);
    if (!acc) return res.status(400).json({ message: "Invalid OTP" });

    const resetRef = db.collection("password_resets").doc(acc.id);
    const resetDoc = await resetRef.get();
    if (!resetDoc.exists) return res.status(400).json({ message: "Invalid OTP" });

    const data = resetDoc.data();
    const expiresAt = data.expires_at?.toDate ? data.expires_at.toDate() : new Date(data.expires_at);

    if (Date.now() > expiresAt.getTime()) {
      await resetRef.delete();
      return res.status(400).json({ message: "OTP expired" });
    }

    const attempts = Number(data.attempts || 0);
    if (attempts >= MAX_ATTEMPTS) {
      await resetRef.delete();
      return res.status(429).json({ message: "Too many attempts. Request new OTP." });
    }

    const ok = await bcrypt.compare(String(otp), data.otp_hash);
    if (!ok) {
      await resetRef.update({ attempts: attempts + 1 });
      return res.status(400).json({ message: "Invalid OTP" });
    }

    await resetRef.update({ verified: true, verified_at: new Date() });
    return res.json({ message: "OTP verified" });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

// 4) Reset Password
// Body: { username, newPassword }
exports.resetPassword = async (req, res) => {
  try {
    const { username, newPassword } = req.body;
    if (!username || !newPassword) {
      return res.status(400).json({ message: "username and newPassword required" });
    }

    const acc = await getAccountByUsername(username);
    if (!acc) return res.status(400).json({ message: "Invalid request" });

    const resetRef = db.collection("password_resets").doc(acc.id);
    const resetDoc = await resetRef.get();
    if (!resetDoc.exists) return res.status(400).json({ message: "Invalid request" });

    const reset = resetDoc.data();
    if (!reset.verified) return res.status(403).json({ message: "OTP not verified" });

    const expiresAt = reset.expires_at?.toDate ? reset.expires_at.toDate() : new Date(reset.expires_at);
    if (Date.now() > expiresAt.getTime()) {
      await resetRef.delete();
      return res.status(400).json({ message: "OTP expired" });
    }

    const password_hash = await bcrypt.hash(newPassword, 10);
    await db.collection("accounts").doc(acc.id).update({ password_hash });

    await resetRef.delete();
    return res.json({ message: "Password reset successful" });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};
