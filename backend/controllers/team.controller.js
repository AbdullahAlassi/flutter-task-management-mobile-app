// Team controller
const teamService = require("../services/team.service")
const projectService = require("../services/project.service")
const ApiResponse = require("../utils/apiResponse")
const logger = require("../utils/logger")
const { standardizeRole } = require("../utils/permissions")

class TeamController {
  /**
   * Add a new team member
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async addTeamMember(req, res) {
    try {
      const { projectId } = req.params
      const { userId, role } = req.body

      logger.info(`Adding team member request - Project: ${projectId}, User: ${userId}, Role: ${role}`)

      // Get project to check permissions
      const project = await projectService.getProjectById(projectId)
      if (!project) {
        logger.warn(`Project not found: ${projectId}`)
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Get current user's role in the project
      const currentUserMember = project.members.find(
        (member) => {
          const memberId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberId === req.userId.toString()
        }
      )
      const currentUserRole = standardizeRole(currentUserMember?.role)

      logger.info(`Current user role check - User: ${req.userId}, Role: ${currentUserRole}`)

      // Check if user has permission to add members
      if (currentUserRole !== "owner" && currentUserRole !== "admin") {
        logger.warn(`Unauthorized attempt to add member by user ${req.userId} with role ${currentUserRole}`)
        return ApiResponse.error(res, "Only project owners and admins can add members", 403)
      }

      // Standardize the new member's role
      const standardizedRole = standardizeRole(role)
      logger.info(`Adding member with standardized role: ${standardizedRole}`)

      const member = await teamService.addTeamMember(projectId, userId, standardizedRole)
      return ApiResponse.success(res, "Team member added successfully", { member })
    } catch (error) {
      logger.error(`Error adding team member: ${error.message}`, {
        projectId: req.params.projectId,
        userId: req.body.userId,
        role: req.body.role,
        error: error.stack
      })
      return ApiResponse.error(res, error.message || "Error adding team member", 500)
    }
  }

  /**
   * Remove a team member
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async removeTeamMember(req, res) {
    try {
      const { projectId, memberId } = req.params

      logger.info(`Removing team member request - Project: ${projectId}, Member: ${memberId}`)

      // Get project to check permissions
      const project = await projectService.getProjectById(projectId)
      if (!project) {
        logger.warn(`Project not found: ${projectId}`)
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Get current user's role in the project
      const currentUserMember = project.members.find(
        (member) => {
          const memberId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberId === req.userId.toString()
        }
      )
      const currentUserRole = standardizeRole(currentUserMember?.role)

      // Get target member's role
      const targetMember = project.members.find(
        (member) => {
          const memberUserId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberUserId === memberId
        }
      )
      const targetMemberRole = standardizeRole(targetMember?.role)

      logger.info(`Role check - Current user: ${currentUserRole}, Target member: ${targetMemberRole}`)

      // Check if user has permission to remove members
      if (currentUserRole !== "owner" && currentUserRole !== "admin") {
        logger.warn(`Unauthorized attempt to remove member by user ${req.userId} with role ${currentUserRole}`)
        return ApiResponse.error(res, "Only project owners and admins can remove members", 403)
      }

      // Prevent removing the project owner
      if (targetMemberRole === "owner") {
        logger.warn(`Attempt to remove project owner by user ${req.userId}`)
        return ApiResponse.error(res, "Cannot remove the project owner", 403)
      }

      await teamService.removeTeamMember(projectId, memberId)
      return ApiResponse.success(res, "Team member removed successfully")
    } catch (error) {
      logger.error(`Error removing team member: ${error.message}`, {
        projectId: req.params.projectId,
        memberId: req.params.memberId,
        error: error.stack
      })
      return ApiResponse.error(res, error.message || "Error removing team member", 500)
    }
  }

  /**
   * Update a team member's role
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async updateTeamMemberRole(req, res) {
    try {
      const { projectId, memberId } = req.params
      const { role } = req.body

      logger.info(`Updating team member role request - Project: ${projectId}, Member: ${memberId}, New role: ${role}`)

      // Get project to check permissions
      const project = await projectService.getProjectById(projectId)
      if (!project) {
        logger.warn(`Project not found: ${projectId}`)
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Get current user's role in the project
      const currentUserMember = project.members.find(
        (member) => {
          const memberId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberId === req.userId.toString()
        }
      )
      const currentUserRole = standardizeRole(currentUserMember?.role)

      // Get target member's role
      const targetMember = project.members.find(
        (member) => {
          const memberUserId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberUserId === memberId
        }
      )
      const targetMemberRole = standardizeRole(targetMember?.role)

      logger.info(`Role check - Current user: ${currentUserRole}, Target member: ${targetMemberRole}, New role: ${role}`)

      // Only project owners can update roles
      if (currentUserRole !== "owner") {
        logger.warn(`Unauthorized attempt to update role by user ${req.userId} with role ${currentUserRole}`)
        return ApiResponse.error(res, "Only project owners can update member roles", 403)
      }

      // Prevent changing the project owner's role
      if (targetMemberRole === "owner") {
        logger.warn(`Attempt to change project owner's role by user ${req.userId}`)
        return ApiResponse.error(res, "Cannot change the project owner's role", 403)
      }

      // Standardize the new role
      const standardizedRole = standardizeRole(role)
      logger.info(`Updating member with standardized role: ${standardizedRole}`)

      const member = await teamService.updateTeamMemberRole(projectId, memberId, standardizedRole)
      return ApiResponse.success(res, "Team member role updated successfully", { member })
    } catch (error) {
      logger.error(`Error updating team member role: ${error.message}`, {
        projectId: req.params.projectId,
        memberId: req.params.memberId,
        role: req.body.role,
        error: error.stack
      })
      return ApiResponse.error(res, error.message || "Error updating team member role", 500)
    }
  }

  /**
   * Get all team members
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getTeamMembers(req, res) {
    try {
      const { projectId } = req.params

      logger.info(`Getting team members request - Project: ${projectId}`)

      // Get project to check permissions
      const project = await projectService.getProjectById(projectId)
      if (!project) {
        logger.warn(`Project not found: ${projectId}`)
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Get current user's role in the project
      const currentUserMember = project.members.find(
        (member) => {
          const memberId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberId === req.userId.toString()
        }
      )
      const currentUserRole = standardizeRole(currentUserMember?.role)

      logger.info(`Current user role check - User: ${req.userId}, Role: ${currentUserRole}`)

      // Check if user has permission to view members
      if (!currentUserRole) {
        logger.warn(`Unauthorized attempt to view members by user ${req.userId}`)
        return ApiResponse.error(res, "You must be a project member to view team members", 403)
      }

      const members = await teamService.getTeamMembers(projectId)
      return ApiResponse.success(res, "Team members retrieved successfully", { members })
    } catch (error) {
      logger.error(`Error getting team members: ${error.message}`, {
        projectId: req.params.projectId,
        error: error.stack
      })
      return ApiResponse.error(res, error.message || "Error retrieving team members", 500)
    }
  }
}

module.exports = new TeamController()

