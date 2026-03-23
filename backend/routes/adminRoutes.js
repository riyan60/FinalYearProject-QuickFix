const express = require("express");
const router = express.Router();

const adminController = require("../controllers/adminController");
const verificationController = require("../controllers/verificationController");
const authMiddleware = require("../middleware/authMiddleware");
const { allowRoles } = require("../middleware/authMiddleware");

// TODO: keep open for local development if auth isn't wired in admin-panel yet.
const maybeAdminGuard = (req, res, next) => {
  if (!req.headers.authorization) return next();
  return authMiddleware(req, res, () => allowRoles("admin")(req, res, next));
};

router.use(maybeAdminGuard);
router.get("/collections", adminController.getCollections);
router.get("/summary", adminController.getDashboardSummary);
router.get("/activity", adminController.getRecentActivity);
router.get("/verifications", verificationController.getPendingVerifications);
router.post("/verifications/:repairmanId/review", verificationController.reviewVerification);
router.get("/entities/:entity", adminController.getEntities);
router.post("/entities/:entity", adminController.createEntity);
router.patch("/entities/:entity/:id", adminController.updateEntity);
router.delete("/entities/:entity/:id", adminController.deleteEntity);

module.exports = router;
