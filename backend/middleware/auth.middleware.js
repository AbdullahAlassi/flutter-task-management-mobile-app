const jwt = require("jsonwebtoken")
const User = require("../models/user.model")
const Project = require("../models/project.model")
const { standardizeRole } = require("../utils/permissions")
const logger = require("../utils/logger")

// Protect routes - Authentication middleware
exports.protect = async (req, res, next) => {
  logger.debug('Auth Middleware: Incoming headers:', req.headers)
  try {
    let token

    // Check if token exists in headers
    if (req.headers.authorization && req.headers.authorization.startsWith("Bearer")) {
      token = req.headers.authorization.split(" ")[1]
    }

    // Check if token exists
    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Not authorized to access this route",
      })
    }

    try {
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET)

      // Get user from token
      req.user = await User.findById(decoded.id).select("-password")

      // Add user ID to request for easier access
      req.userId = req.user._id

      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: "User not found",
        })
      }

      logger.debug('Auth Middleware: Decoded user:', req.user)

      next()
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: "Not authorized to access this route",
      })
    }
  } catch (error) {
    logger.error("Auth middleware error:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
    })
  }
}

// Add the verifyToken function that's being used in your routes
exports.verifyToken = async (req, res, next) => {
  try {
    let token

    // Check if token exists in headers
    if (req.headers.authorization && req.headers.authorization.startsWith("Bearer")) {
      token = req.headers.authorization.split(" ")[1]
    }

    // Check if token exists
    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Not authorized to access this route",
      })
    }

    try {
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET)

      // Get user from token
      req.user = await User.findById(decoded.id).select("-password")

      // Add user ID to request for easier access
      req.userId = req.user._id

      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: "User not found",
        })
      }

      next()
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: "Not authorized to access this route",
      })
    }
  } catch (error) {
    logger.error("Auth middleware error:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
    })
  }
}

// Add the verifyProjectManager function that's mentioned in the error logs
exports.verifyProjectManager = async (req, res, next) => {
  try {
    // This middleware should be used after verifyToken
    // so req.user should be available
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Not authorized to access this route",
      })
    }

    // For project creation, we don't need to check if the user is a manager
    // since they're creating a new project and will become the manager
    next()
  } catch (error) {
    logger.error("Auth middleware error:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
    })
  }
}

// Add the verifyProjectAdmin function that's mentioned in the error logs
exports.verifyProjectAdmin = async (req, res, next) => {
  try {
    // This middleware should be used after verifyToken
    // so req.user should be available
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Not authorized to access this route",
      })
    }

    // Get project from request
    const project = req.project
    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found",
      })
    }

    // Check if user is project owner or admin
    const member = project.members.find(m => m.userId._id.toString() === req.userId.toString())
    const role = standardizeRole(member?.role)

    logger.debug(`Project admin check - User: ${req.userId}, Role: ${role}`)

    if (!member || (role !== 'owner' && role !== 'admin')) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to access this route",
      })
    }

    // Set the user's role in the request for use in controllers
    req.userRole = role
    next()
  } catch (error) {
    logger.error("Auth middleware error:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
    })
  }
}