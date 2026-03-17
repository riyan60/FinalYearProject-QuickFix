const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const chatController = require("../controllers/chatController");

router.get("/:bookingId", authMiddleware, chatController.getChatInfo);
router.get("/:bookingId/messages", authMiddleware, chatController.getChatMessages);

module.exports = router;