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
      $or: [{ manager: req.user._id }, { members: req.user._id }],
    })
      .populate("manager", "name email profilePicture")
      .populate("members", "name email profilePicture")
      .sort({ createdAt: -1 })

    // Calculate progress and update status for each project
    const projectsWithProgress = await Promise.all(
      projects.map(async (project) => {
        const projectObj = project.toObject()
        const progress = await project.calculateProgress()
        projectObj.progress = progress
        return projectObj
      }),
    )

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

    const project = await Project.findById(projectId)
      .populate("manager", "name email profilePicture")
      .populate("members", "name email profilePicture")

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
    const { title, description, members, deadline } = req.body

    // Create the project with the current user as manager
    const project = await Project.create({
      title,
      description,
      manager: req.user._id,
      members: members || [],
      deadline,
      status: "Planning", // Default status for new projects
    })

    // Add the manager to members if not already included
    if (!project.members.includes(req.user._id)) {
      project.members.push(req.user._id)
      await project.save()
    }

    // Populate manager and members for the response
    const populatedProject = await Project.findById(project._id)
      .populate("manager", "name email profilePicture")
      .populate("members", "name email profilePicture")

    // Calculate initial progress
    const projectObj = populatedProject.toObject()
    const progress = await populatedProject.calculateProgress()
    projectObj.progress = progress

    // Create notifications for members
    if (members && members.length > 0) {
      for (const memberId of members) {
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
    const updates = req.body

    // Remove status from updates as it's now managed automatically
    delete updates.status

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
        message: "Only the project manager can update the project",
      })
    }

    // Check if members are being updated
    const membersChanged = updates.members && JSON.stringify(updates.members) !== JSON.stringify(project.members)
    const oldMembers = [...project.members].map((id) => id.toString())

    // Update the project
    const updatedProject = await Project.findByIdAndUpdate(
      projectId,
      { $set: updates },
      { new: true, runValidators: true },
    )
      .populate("manager", "name email profilePicture")
      .populate("members", "name email profilePicture")

    // Calculate progress and update status
    const projectObj = updatedProject.toObject()
    const progress = await updatedProject.calculateProgress()
    projectObj.progress = progress

    // If members were updated, notify new members
    if (membersChanged && updates.members) {
      const newMembers = updates.members.filter((id) => !oldMembers.includes(id.toString()))

      for (const memberId of newMembers) {
        await createNotification({
          recipient: memberId,
          sender: req.user._id,
          message: `You have been added to project "${project.title}"`,
          relatedItem: {
            itemId: project._id,
            itemType: "Project",
          },
        })
      }
    }

    res.status(200).json({
      success: true,
      data: {
        project: projectObj,
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
    const { userId } = req.body

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
    if (project.members.includes(userId)) {
      return res.status(400).json({
        success: false,
        message: "User is already a member of this project",
      })
    }

    // Add user to members
    project.members.push(userId)
    await project.save()

    // Populate manager and members for the response
    const updatedProject = await Project.findById(projectId)
      .populate("manager", "name email profilePicture")
      .populate("members", "name email profilePicture")

    // Create notification for the added member
    await createNotification({
      recipient: userId,
      sender: req.user._id,
      message: `You have been added to project "${project.title}"`,
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
      .populate("members", "name email profilePicture")

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

