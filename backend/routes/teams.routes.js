// Team routes
const express = require("express")
const teamController = require("../controllers/team.controller")
const { validate } = require("../middleware/validation.middleware")
const { teamValidation } = require("../utils/validators")
const { verifyToken, verifyProjectManager } = require("../middleware/auth.middleware")
const projectMiddleware = require("../middleware/project.middleware")
const logger = require("../utils/logger")

const router = express.Router()

// Add team member
router.post(
  "/project/:projectId/members",
  verifyToken,
  projectMiddleware,
  async (req, res, next) => {
    logger.debug("=== Team Routes: Add Member Request ===")
    logger.debug("Request body:", req.body)
    logger.debug("Request user:", {
      id: req.userId,
      role: req.userRole
    })
    next()
  },
  teamController.addTeamMember
)

// Remove team member
router.delete(
  "/project/:projectId/members/:userId",
  verifyToken,
  projectMiddleware,
  teamController.removeTeamMember
)

// Update team member role
router.put(
  "/project/:projectId/members/:userId/role",
  verifyToken,
  projectMiddleware,
  teamController.updateTeamMemberRole
)

// Get team members
router.get(
  "/project/:projectId/members",
  verifyToken,
  projectMiddleware,
  teamController.getTeamMembers
)

module.exports = router

