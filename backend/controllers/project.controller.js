const Project = require("../models/project.model")
const Board = require("../models/board.model")
const Task = require("../models/task.model")
const User = require("../models/user.model")
const Notification = require("../models/notification.model")
const mongoose = require("mongoose")
const { createNotification } = require("../utils/notificationHelper")

// Get all projects for the authenticated user
exports.getAllProjects = async (req, res) => {
  try {
    // Find projects where the user is a manager or a member
    const projects = await Project.find({
      $or: [{ manager: req.user._id }, { "members.userId": req.user._id }],
    })
      .populate("manager", "name email profilePicture")
      .populate("members.userId", "name email profilePicture")
      .sort({ createdAt: -1 })

    // Debug print to check populated projects
    console.log("getAllProjects - Raw projects before population:", JSON.stringify(projects, null, 2))

    // Calculate progress and update status for each project
    const projectsWithProgress = await Promise.all(
      projects.map(async (project) => {
        const projectObj = project.toObject()
        const progress = await project.calculateProgress()
        projectObj.progress = progress
        return projectObj
      }),
    )

    // Debug print to check final response
    console.log("getAllProjects - Final response:", JSON.stringify(projectsWithProgress, null, 2))

    res.status(200).json({
      success: true,
      data: {
        projects: projectsWithProgress,
        count: projects.length,
      },
    })
  } catch (error) {
    console.error("Error getting all projects:", error)
    res.status(500).json({
      success: false,
      message: "Failed to get projects",
      error: error.message,
    })
  }
}

// Get project by ID
exports.getProjectById = async (req, res) => {
  try {
    const { projectId } = req.params

    // Debug print the project ID
    console.log("getProjectById - Project ID:", projectId)

    const project = await Project.findById(projectId)
      .populate("manager", "name email profilePicture")
      .populate("members.userId", "name email profilePicture")

    // Debug print to check populated project
    console.log("getProjectById - Populated project just before response:", JSON.stringify(project, null, 2))

    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found",
      })
    }

    // Calculate progress and update status
    const projectObj = project.toObject()
    const progress = await project.calculateProgress()
    projectObj.progress = progress

    // Debug print to check final response
    console.log("getProjectById - Final response:", JSON.stringify(projectObj, null, 2))

    res.status(200).json({
      success: true,
      data: {
        project: projectObj,
      },
    })
  } catch (error) {
    console.error("Error getting project by ID:", error)
    res.status(500).json({
      success: false,
      message: "Failed to get project",
      error: error.message,
    })
  }
}

// Create a new project
exports.createProject = async (req, res) => {
  try {
    const { title, description, members, deadline, color } = req.body

    // Create the project with the current user as manager
    const project = await Project.create({
      title,
      description,
      manager: req.user._id,
      members: members || [],
      deadline,
      status: "Planning", // Default status for new projects
      color: color || "#2196F3", // Use color from request or default
    })

    // Populate manager and members for the response
    const populatedProject = await Project.findById(project._id)
      .populate("manager", "name email profilePicture")
      .populate("members.userId", "name email profilePicture")

    // Calculate initial progress
    const projectObj = populatedProject.toObject()
    const progress = await populatedProject.calculateProgress()
    projectObj.progress = progress

    // Create notifications for members
    if (members && members.length > 0) {
      for (const member of members) {
        const memberId = member.userId || member; // support both object and string
        // Don't notify the creator/manager
        if (memberId.toString() !== req.user._id.toString()) {
          await createNotification({
            recipient: memberId,
            sender: req.user._id,
            message: `You have been added to project "${title}"`,
            relatedItem: {
              itemId: project._id,
              itemType: "Project",
            },
          })
        }
      }
    }

    res.status(201).json({
      success: true,
      data: {
        project: projectObj,
      },
    })
  } catch (error) {
    console.error("Error creating project:", error)
    res.status(500).json({
      success: false,
      message: "Failed to create project",
      error: error.message,
    })
  }
}

// Update a project
exports.updateProject = async (req, res) => {
  try {
    const { projectId } = req.params
    const { title, description, deadline, status, color, members } = req.body

    // Debug logging
    console.log('Update Project - User Role:', req.userRole)
    console.log('Update Project - User ID:', req.user._id)
    console.log('Update Project - Members:', members)

    // Find the project
    const project = await Project.findById(projectId)
    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found",
      })
    }

    // Debug logging
    console.log('Project Manager ID:', project.manager)
    console.log('Project Manager ID type:', typeof project.manager)
    console.log('User ID type:', typeof req.user._id)

    // Check if user is the manager
    const isManager = project.manager.toString() === req.user._id.toString()
    
    // Check if user is an admin (either globally or in the project)
    const isGlobalAdmin = req.userRole && (
      req.userRole.toLowerCase() === "admin" || 
      req.userRole === "Admin"
    )
    
    // Check if user is an admin in this project
    const projectMember = project.members.find(
      member => member.userId.toString() === req.user._id.toString()
    )
    const isProjectAdmin = projectMember && projectMember.role === "admin"

    // Debug logging
    console.log('Is Manager:', isManager)
    console.log('Is Global Admin:', isGlobalAdmin)
    console.log('Is Project Admin:', isProjectAdmin)
    console.log('User Role:', req.userRole)
    console.log('Project Member Role:', projectMember ? projectMember.role : 'Not a member')

    // Allow manager, global admin, or project admin to update project details
    if (!isManager && !isGlobalAdmin && !isProjectAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only project manager or admin can update project details",
      })
    }

    // Update project fields
    if (title) project.title = title
    if (description) project.description = description
    if (deadline) project.deadline = deadline
    if (status) project.status = status
    if (color) project.color = color
    if (members) {
      // Ensure the manager is always included in members
      const managerExists = members.some(m => m.userId === project.manager.toString())
      if (!managerExists) {
        members.push({
          userId: project.manager,
          role: 'owner'
        })
      }
      project.members = members
    }

    await project.save()

    // Populate manager and members for the response
    const updatedProject = await Project.findById(projectId)
      .populate("manager", "name email profilePicture")
      .populate("members.userId", "name email profilePicture")

    res.status(200).json({
      success: true,
      data: {
        project: updatedProject,
      },
    })
  } catch (error) {
    console.error("Error updating project:", error)
    res.status(500).json({
      success: false,
      message: "Failed to update project",
      error: error.message,
    })
  }
}

// Delete a project
exports.deleteProject = async (req, res) => {
  try {
    const { projectId } = req.params

    // Find the project
    const project = await Project.findById(projectId)
    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found",
      })
    }

    // Check if user is the manager
    if (project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Only the project manager can delete the project",
      })
    }

    // Find all boards in the project
    const boards = await Board.find({ project: projectId })
    const boardIds = boards.map((board) => board._id)

    // Delete all tasks in the boards
    await Task.deleteMany({ board: { $in: boardIds } })

    // Delete all boards
    await Board.deleteMany({ project: projectId })

    // Delete the project
    await Project.findByIdAndDelete(projectId)

    // Delete any notifications related to this project
    await Notification.deleteMany({
      "relatedItem.itemId": projectId,
      "relatedItem.itemType": "Project",
    })

    res.status(200).json({
      success: true,
      data: {},
    })
  } catch (error) {
    console.error("Error deleting project:", error)
    res.status(500).json({
      success: false,
      message: "Failed to delete project",
      error: error.message,
    })
  }
}

// Add a member to a project
exports.addMember = async (req, res) => {
  try {
    const { projectId } = req.params
    const { userId, role } = req.body

    // Validate user exists
    const user = await User.findById(userId)
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    // Find the project
    const project = await Project.findById(projectId)
    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found",
      })
    }

    // Check if user is already a member
    if (project.members.some(member => member.userId._id.toString() === userId)) {
      return res.status(400).json({
        success: false,
        message: "User is already a member of this project",
      })
    }

    // Add user to members with role
    project.members.push({
      userId: {
        _id: userId
      },
      role: role || "member"
    })
    await project.save()

    // Populate manager and members for the response
    const updatedProject = await Project.findById(projectId)
      .populate("manager", "name email profilePicture")
      .populate("members.userId", "name email profilePicture")

    // Create notification for the added member
    await createNotification({
      recipient: userId,
      sender: req.user._id,
      message: `You have been added to project "${project.title}" as a ${role || "member"}`,
      relatedItem: {
        itemId: project._id,
        itemType: "Project",
      },
    })

    res.status(200).json({
      success: true,
      data: {
        project: updatedProject,
      },
    })
  } catch (error) {
    console.error("Error adding member to project:", error)
    res.status(500).json({
      success: false,
      message: "Failed to add member to project",
      error: error.message,
    })
  }
}

// Remove a member from a project
exports.removeMember = async (req, res) => {
  try {
    const { projectId, userId } = req.params

    // Find the project
    const project = await Project.findById(projectId)
    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found",
      })
    }

    // Check if user is the manager
    if (project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Only the project manager can remove members",
      })
    }

    // Check if user is a member
    if (!project.members.includes(userId)) {
      return res.status(400).json({
        success: false,
        message: "User is not a member of this project",
      })
    }

    // Remove user from members
    project.members = project.members.filter((member) => member.toString() !== userId.toString())
    await project.save()

    // Populate manager and members for the response
    const updatedProject = await Project.findById(projectId)
      .populate("manager", "name email profilePicture")
      .populate("members.userId", "name email profilePicture")

    // Create notification for the removed member
    await createNotification({
      recipient: userId,
      sender: req.user._id,
      message: `You have been removed from project "${project.title}"`,
      relatedItem: {
        itemId: project._id,
        itemType: "Project",
      },
    })

    res.status(200).json({
      success: true,
      data: {
        project: updatedProject,
      },
    })
  } catch (error) {
    console.error("Error removing member from project:", error)
    res.status(500).json({
      success: false,
      message: "Failed to remove member from project",
      error: error.message,
    })
  }
}

// Get project statistics
exports.getProjectStats = async (req, res) => {
  try {
    const { projectId } = req.params

    // Find the project
    const project = await Project.findById(projectId)
    if (!project) {
      return res.status(404).json({
        success: false,
        message: "Project not found",
      })
    }

    // Find all boards in the project
    const boards = await Board.find({ project: projectId })
    const boardIds = boards.map((board) => board._id)

    // Get task counts by status
    const taskStats = await Task.aggregate([
      { $match: { board: { $in: boardIds.map((id) => mongoose.Types.ObjectId(id.toString())) } } },
      {
        $group: {
          _id: "$status",
          count: { $sum: 1 },
        },
      },
    ])

    // Get task counts by priority
    const priorityStats = await Task.aggregate([
      { $match: { board: { $in: boardIds.map((id) => mongoose.Types.ObjectId(id.toString())) } } },
      {
        $group: {
          _id: "$priority",
          count: { $sum: 1 },
        },
      },
    ])

    // Format the results
    const stats = {
      total: 0,
      byStatus: {},
      byPriority: {},
    }

    taskStats.forEach((stat) => {
      stats.byStatus[stat._id] = stat.count
      stats.total += stat.count
    })

    priorityStats.forEach((stat) => {
      stats.byPriority[stat._id] = stat.count
    })

    // Calculate completion percentage
    const completedTasks = stats.byStatus["Done"] || 0
    stats.completionPercentage = stats.total > 0 ? (completedTasks / stats.total) * 100 : 0

    res.status(200).json({
      success: true,
      data: {
        stats,
      },
    })
  } catch (error) {
    console.error("Error getting project stats:", error)
    res.status(500).json({
      success: false,
      message: "Failed to get project statistics",
      error: error.message,
    })
  }
}

module.exports = exports

