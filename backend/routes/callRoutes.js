const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const callController = require("../controllers/callController");

router.get("/:bookingId", authMiddleware, callController.getCallStatus);
router.post("/start", authMiddleware, callController.startCall);
router.post("/:bookingId/accept", authMiddleware, callController.acceptCall);
router.post("/:bookingId/reject", authMiddleware, callController.rejectCall);
router.post("/:bookingId/end", authMiddleware, callController.endCall);

module.exports = router;