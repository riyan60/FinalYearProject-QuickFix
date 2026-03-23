const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const chatController = require("../controllers/chatController");

router.get("/:bookingId/messages", authMiddleware, chatController.getMessages);
router.post("/:bookingId/messages", authMiddleware, chatController.sendMessage);

module.exports = router;
