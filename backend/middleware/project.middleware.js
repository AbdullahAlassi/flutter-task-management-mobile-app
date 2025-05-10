const Project = require("../models/project.model")
const logger = require("../utils/logger")
const { standardizeRole } = require("../utils/permissions")

/**
 * Middleware to check if project exists and attach it to request
 */
const projectMiddleware = async (req, res, next) => {
  try {
    const projectId = req.body.projectId || req.params.projectId

    if (!projectId) {
      return res.status(400).json({
        success: false,
        message: "Project ID is required"
      })
    }

    const project = await Project.findById(projectId)
      .populate("manager", "name email profilePicture")
      .populate({
        path: "members.userId",
        select: "name email profilePicture"
      })

    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found"
      })
    }

    // Get current user's role in the project
    const currentUserMember = project.members.find(
      (member) => {
        const memberId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
        return memberId === req.userId.toString()
      }
    )
    
    // Check if user is the project manager (owner)
    const isManager = project.manager._id ? 
      project.manager._id.toString() === req.userId.toString() : 
      project.manager.toString() === req.userId.toString()
    
    // Set role to 'owner' if user is the manager, otherwise use member role or default to 'viewer'
    const currentUserRole = isManager ? 'owner' : 
      (currentUserMember ? standardizeRole(currentUserMember.role) : 'viewer')

    // Log project data for debugging
    logger.debug("Project middleware - Project data:", {
      projectId,
      manager: project.manager,
      members: project.members,
      currentUserRole,
      currentUserId: req.userId,
      isManager,
      memberIds: project.members.map(m => ({
        id: m.userId._id ? m.userId._id.toString() : m.userId.toString(),
        role: m.role
      }))
    });

    // Attach project and user role to request
    req.project = project
    req.userRole = currentUserRole
    next()
  } catch (error) {
    logger.error("Project middleware error:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
    })
  }
}

module.exports = projectMiddleware 