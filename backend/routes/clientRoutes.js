const express = require("express");
const router = express.Router();
const {
  registerClient,
  getAllClients
} = require("../controllers/clientController");

router.post("/register", registerClient);
router.get("/", getAllClients);

module.exports = router;
