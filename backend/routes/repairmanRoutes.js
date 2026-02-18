const express = require("express");
const router = express.Router();
const {
  registerRepairman,
  getAllRepairmen
} = require("../controllers/repairmanController");

router.post("/register", registerRepairman);
router.get("/", getAllRepairmen);

module.exports = router;
