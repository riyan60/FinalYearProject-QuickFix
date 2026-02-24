const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { allowRoles } = require("../middleware/authMiddleware");
const reviewController = require("../controllers/reviewController");

router.post(
  "/",
  authMiddleware,
  allowRoles("user"),
  reviewController.addReview
);

module.exports = router;