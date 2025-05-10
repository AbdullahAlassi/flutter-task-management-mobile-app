// Team service
const Project = require("../models/project.model")
const User = require("../models/user.model")
const ActivityLog = require("../models/activityLog.model")
const Notification = require("../models/notification.model")
const logger = require("../utils/logger")
const notificationService = require("./notification.service")
const { standardizeRole } = require("../utils/permissions")

class TeamService {
  /**
   * Add a team member to a project
   * @param {string} projectId - Project ID
   * @param {string} userId - User ID to add
   * @param {string} role - Role to assign
   * @returns {Promise<Object>} - Updated project
   */
  async addTeamMember(projectId, userId, role) {
    try {
      logger.info(`Adding member ${userId} to project ${projectId} with role ${role}`)

      // Check if user exists
      const user = await User.findById(userId)
      if (!user) {
        throw new Error("User not found")
      }

      // Get project
      const project = await Project.findById(projectId)
      if (!project) {
        throw new Error("Project not found")
      }

      // Check if user is already a member
      const isAlreadyMember = project.members.some(
        (member) => {
          const memberId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberId === userId
        }
      )
      if (isAlreadyMember) {
        throw new Error("User is already a member of this project")
      }

      // Add member with standardized role
      const standardizedRole = standardizeRole(role)
      project.members.push({
        userId: user._id,
        role: standardizedRole
      })

      await project.save()

      // Create activity log
      await ActivityLog.create({
        user: userId,
        action: "Member added",
        details: `User added to project with role: ${standardizedRole}`,
        relatedItem: {
          itemId: projectId,
          itemType: "Project"
        }
      })

      // Populate member details
      await project.populate({
        path: "members.userId",
        select: "name email profilePicture"
      })

      return project
    } catch (error) {
      logger.error(`Error adding team member: ${error.message}`, {
        projectId,
        userId,
        role,
        error: error.stack
      })
      throw error
    }
  }

  /**
   * Remove a team member from a project
   * @param {string} projectId - Project ID
   * @param {string} memberId - Member ID to remove
   * @returns {Promise<Object>} - Updated project
   */
  async removeTeamMember(projectId, memberId) {
    try {
      logger.info(`Removing member ${memberId} from project ${projectId}`)

      // Get project
      const project = await Project.findById(projectId)
      if (!project) {
        throw new Error("Project not found")
      }

      // Find member
      const memberIndex = project.members.findIndex(
        (member) => {
          const memberUserId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberUserId === memberId
        }
      )
      if (memberIndex === -1) {
        throw new Error("User is not a member of this project")
      }

      // Remove member
      project.members.splice(memberIndex, 1)
      await project.save()

      // Create activity log
      await ActivityLog.create({
        user: memberId,
        action: "Member removed",
        details: "User removed from project",
        relatedItem: {
          itemId: projectId,
          itemType: "Project"
        }
      })

      return project
    } catch (error) {
      logger.error(`Error removing team member: ${error.message}`, {
        projectId,
        memberId,
        error: error.stack
      })
      throw error
    }
  }

  /**
   * Update a team member's role
   * @param {string} projectId - Project ID
   * @param {string} memberId - Member ID to update
   * @param {string} role - New role
   * @returns {Promise<Object>} - Updated project
   */
  async updateTeamMemberRole(projectId, memberId, role) {
    try {
      logger.info(`Updating role for member ${memberId} in project ${projectId} to ${role}`)

      // Get project
      const project = await Project.findById(projectId)
      if (!project) {
        throw new Error("Project not found")
      }

      // Find member
      const member = project.members.find(
        (member) => {
          const memberUserId = member.userId._id ? member.userId._id.toString() : member.userId.toString()
          return memberUserId === memberId
        }
      )
      if (!member) {
        throw new Error("User is not a member of this project")
      }

      // Update role
      const standardizedRole = standardizeRole(role)
      member.role = standardizedRole
      await project.save()

      // Create activity log
      await ActivityLog.create({
        user: memberId,
        action: "Role updated",
        details: `User role updated to: ${standardizedRole}`,
        relatedItem: {
          itemId: projectId,
          itemType: "Project"
        }
      })

      // Populate member details
      await project.populate({
        path: "members.userId",
        select: "name email profilePicture"
      })

      return project
    } catch (error) {
      logger.error(`Error updating team member role: ${error.message}`, {
        projectId,
        memberId,
        role,
        error: error.stack
      })
      throw error
    }
  }

  /**
   * Get all team members for a project
   * @param {string} projectId - Project ID
   * @returns {Promise<Array>} - Array of team members
   */
  async getTeamMembers(projectId) {
    try {
      logger.info(`Getting team members for project ${projectId}`)

      const project = await Project.findById(projectId)
        .populate({
          path: "members.userId",
          select: "name email profilePicture"
        })

      if (!project) {
        throw new Error("Project not found")
      }

      return project.members
    } catch (error) {
      logger.error(`Error getting team members: ${error.message}`, {
        projectId,
        error: error.stack
      })
      throw error
    }
  }
}

module.exports = new TeamService()

