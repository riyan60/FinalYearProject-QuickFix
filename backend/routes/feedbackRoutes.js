const express = require("express");
const router = express.Router();

const feedbackController = require("../controllers/feedbackController");
const authMiddleware = require("../middleware/authMiddleware");

router.post("/", authMiddleware, feedbackController.submitFeedback);

module.exports = router;
