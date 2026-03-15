const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  register,
  login,
  logout,
  getCurrentProfile,
  updateCurrentProfile,
} = require("../controllers/authController");

router.post("/register", register);
router.post("/login", login);
router.post("/logout", logout);
router.get("/me", authMiddleware, getCurrentProfile);
router.put("/me", authMiddleware, updateCurrentProfile);

module.exports = router;
