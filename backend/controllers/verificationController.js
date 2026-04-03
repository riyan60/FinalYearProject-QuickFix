const { db } = require("../firebase");

const normalizeString = (value) => String(value || "").trim();

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

const getVerificationSnapshot = async (repairmanId) => {
  const repairmanRef = db.collection("repairmen").doc(repairmanId);
  const repairmanDoc = await repairmanRef.get();
  if (!repairmanDoc.exists) {
    return { repairmanRef, profile: null };
  }

  return {
    repairmanRef,
    profile: repairmanDoc.data() || {},
  };
};

const buildVerificationPayload = (body = {}, existingProfile = {}) => {
  const fullName = normalizeString(body.full_name || body.fullName || existingProfile.name);
  const idType = normalizeString(body.id_type || body.idType);
  const idNumber = normalizeString(body.id_number || body.idNumber);
  const idLast4 = idNumber.length >= 4 ? idNumber.slice(-4) : idNumber;
  const address = normalizeString(body.address || existingProfile.address);
  const city = normalizeString(body.city || existingProfile.city);
  const phone = normalizeString(body.phone || existingProfile.phone);
  const documentUrlsRaw =
    body.document_urls || body.documentUrls || body.documents || [];
  const documentUrls = Array.isArray(documentUrlsRaw)
    ? documentUrlsRaw.map((item) => normalizeString(item)).filter(Boolean)
    : String(documentUrlsRaw || "")
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean);

  return {
    verification_status: "pending",
    verification_submitted_at: new Date(),
    verification_reviewed_at: null,
    verification_reviewed_by: "",
    verification_rejection_reason: "",
    verification_profile: {
      full_name: fullName,
      date_of_birth: normalizeString(body.date_of_birth || body.dateOfBirth),
      phone,
      address,
      city,
      specialization: normalizeString(
        body.specialization || existingProfile.specialization
      ),
      experience_years: Number(body.experience_years ?? existingProfile.experience ?? 0),
      notes: normalizeString(body.notes),
    },
    verification_documents: {
      id_type: idType,
      id_last4: idLast4,
      id_proof_url: normalizeString(body.id_proof_url || body.idProofUrl),
      address_proof_url: normalizeString(
        body.address_proof_url || body.addressProofUrl
      ),
      skill_certificate_url: normalizeString(
        body.skill_certificate_url || body.skillCertificateUrl
      ),
      selfie_url: normalizeString(body.selfie_url || body.selfieUrl),
      document_urls: documentUrls,
      digilocker_reference: normalizeString(
        body.digilocker_reference || body.digilockerReference
      ),
    },
    updated_at: new Date(),
  };
};

exports.getMyVerification = async (req, res) => {
  try {
    const { userId, role } = req.user;
    if (role !== "repairman") {
      return res.status(403).json({ message: "Only repairmen can access verification" });
    }

    const { profile } = await getVerificationSnapshot(userId);
    if (!profile) {
      return res.status(404).json({ message: "Repairman profile not found" });
    }

    return res.json({
      verification: {
        status: profile.verification_status || "unverified",
        is_verified: profile.is_verified === true,
        submitted_at: serializeValue(profile.verification_submitted_at),
        reviewed_at: serializeValue(profile.verification_reviewed_at),
        reviewed_by: profile.verification_reviewed_by || "",
        rejection_reason: profile.verification_rejection_reason || "",
        profile: serializeValue(profile.verification_profile || {}),
        documents: serializeValue(profile.verification_documents || {}),
      },
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.submitMyVerification = async (req, res) => {
  try {
    const { userId, role } = req.user;
    if (role !== "repairman") {
      return res.status(403).json({ message: "Only repairmen can submit verification" });
    }

    const { repairmanRef, profile } = await getVerificationSnapshot(userId);
    if (!profile) {
      return res.status(404).json({ message: "Repairman profile not found" });
    }

    const payload = buildVerificationPayload(req.body || {}, profile);
    if (!payload.verification_profile.full_name) {
      return res.status(400).json({ message: "Full name is required" });
    }
    if (!payload.verification_documents.id_type) {
      return res.status(400).json({ message: "ID type is required" });
    }
    if (!payload.verification_documents.id_last4) {
      return res.status(400).json({ message: "ID number is required" });
    }

    await repairmanRef.set(payload, { merge: true });
    return res.json({
      message: "Verification submitted",
      verification: {
        status: payload.verification_status,
        is_verified: false,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.getPendingVerifications = async (req, res) => {
  try {
    const snap = await db
      .collection("repairmen")
      .where("verification_status", "in", ["pending", "rejected", "under_review"])
      .get();

    const items = snap.docs
      .map((doc) => {
        const data = doc.data() || {};
        return {
          id: doc.id,
          name: data.name || data.verification_profile?.full_name || "Repairman",
          phone: data.phone || data.verification_profile?.phone || "",
          city: data.city || data.verification_profile?.city || "",
          specialization:
            data.specialization ||
            data.verification_profile?.specialization ||
            "",
          status: data.verification_status || "unverified",
          is_verified: data.is_verified === true,
          submitted_at: serializeValue(data.verification_submitted_at),
          reviewed_at: serializeValue(data.verification_reviewed_at),
          rejection_reason: data.verification_rejection_reason || "",
          verification_profile: serializeValue(data.verification_profile || {}),
          verification_documents: serializeValue(data.verification_documents || {}),
        };
      })
      .sort((a, b) => {
        const left = Date.parse(a.submitted_at || "") || 0;
        const right = Date.parse(b.submitted_at || "") || 0;
        return right - left;
      });

    return res.json({ items });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.reviewVerification = async (req, res) => {
  try {
    const { repairmanId } = req.params;
    const { decision, rejection_reason } = req.body || {};
    const normalizedDecision = normalizeString(decision).toLowerCase();

    if (!["approve", "reject", "under_review"].includes(normalizedDecision)) {
      return res.status(400).json({ message: "decision must be approve, reject, or under_review" });
    }

    const repairmanRef = db.collection("repairmen").doc(normalizeString(repairmanId));
    const repairmanDoc = await repairmanRef.get();
    if (!repairmanDoc.exists) {
      return res.status(404).json({ message: "Repairman not found" });
    }

    const update = {
      verification_status:
        normalizedDecision === "approve"
          ? "verified"
          : normalizedDecision === "reject"
          ? "rejected"
          : "under_review",
      is_verified: normalizedDecision === "approve",
      verification_reviewed_at: new Date(),
      verification_reviewed_by: normalizeString(req.user?.userId || "admin"),
      verification_rejection_reason:
        normalizedDecision === "reject"
          ? normalizeString(rejection_reason)
          : "",
      updated_at: new Date(),
    };

    await repairmanRef.set(update, { merge: true });
    return res.json({
      message:
        normalizedDecision === "approve"
          ? "Repairman verified"
          : normalizedDecision === "reject"
          ? "Verification rejected"
          : "Verification marked under review",
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
