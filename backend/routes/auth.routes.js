const express = require("express")
const router = express.Router()
const authController = require("../controllers/auth.controller")
const { verifyToken } = require("../middleware/auth.middleware")

// Register a new user
router.post("/register", authController.register)

// Login user
router.post("/login", authController.login)

// Logout user
router.post("/logout", authController.logout)

// Change password
router.post("/change-password", verifyToken, authController.changePassword)

module.exports = router

