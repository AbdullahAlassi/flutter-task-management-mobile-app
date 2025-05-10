// Task controller
const taskService = require("../services/task.service")
const boardService = require("../services/board.service")
const projectService = require("../services/project.service")
const ApiResponse = require("../utils/apiResponse")
const logger = require("../utils/logger")
const { standardizeRole } = require("../utils/permissions")

class TaskController {
  /**
   * Get all tasks for the authenticated user
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getAllTasks(req, res) {
    try {
      const tasks = await taskService.getAllTasks(req.userId)
      return ApiResponse.success(res, "Tasks retrieved successfully", { tasks })
    } catch (error) {
      logger.error(`Error getting all tasks: ${error.message}`)
      return ApiResponse.error(res, "Error retrieving tasks", 500)
    }
  }

  /**
   * Get tasks by board
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getTasksByBoard(req, res) {
    try {
      const { boardId } = req.params
      logger.info(`Getting tasks for board: ${boardId}`)

      // Get board to check permissions
      const board = await boardService.getBoardById(boardId)
      if (!board) {
        logger.warn(`Board not found: ${boardId}`)
        return ApiResponse.error(res, "Board not found", 404)
      }

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)
      if (!project) {
        logger.warn(`Project not found for board: ${boardId}`)
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Check if the user is authorized
      const userRole = standardizeRole(req.userRole || '')
      const isOwner = userRole === "owner"
      const isAdmin = userRole === "admin"
      const isManager = project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? standardizeRole(member.role) : 'viewer'
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member' || memberRole === 'viewer')
      })

      logger.info(`User authorization check - isOwner: ${isOwner}, isAdmin: ${isAdmin}, isManager: ${isManager}, isProjectMember: ${isProjectMember}, userRole: ${userRole}`)

      if (!isOwner && !isAdmin && !isManager && !isProjectMember) {
        logger.warn(`Unauthorized access attempt to board: ${boardId} by user: ${req.userId}`)
        return ApiResponse.error(res, "Unauthorized to view tasks in this board", 403)
      }

      const tasks = await taskService.getTasksByBoard(boardId)
      logger.info(`Successfully retrieved ${tasks.length} tasks for board: ${boardId}`)
      return ApiResponse.success(res, "Tasks retrieved successfully", { tasks })
    } catch (error) {
      logger.error(`Error getting tasks by board: ${error.message}`, {
        boardId: req.params.boardId,
        error: error.stack
      })
      return ApiResponse.error(res, error.message || "Error getting tasks", 500)
    }
  }

  /**
   * Get task by ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getTaskById(req, res) {
    try {
      const { taskId } = req.params
      const task = await taskService.getTaskById(taskId)

      if (!task) {
        return ApiResponse.error(res, "Task not found", 404)
      }

      // Get board to check permissions
      const board = await boardService.getBoardById(task.board)
      if (!board) {
        return ApiResponse.error(res, "Board not found", 404)
      }

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)
      if (!project) {
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Check if the user is authorized
      const isAdmin = req.userRole?.toLowerCase() === "admin" || req.userRole === "Admin"
      const isManager = project.manager?.toString() === req.userId?.toString()
      const isProjectMember = project.members?.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId?.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      }) || false
      const isAssignee = task.assignees?.some((assignee) => assignee?.toString() === req.userId?.toString()) || false

      if (!isAdmin && !isManager && !isProjectMember && !isAssignee) {
        return ApiResponse.error(res, "Unauthorized to view this task", 403)
      }

      return ApiResponse.success(res, "Task retrieved successfully", { task })
    } catch (error) {
      logger.error(`Error getting task by ID: ${error.message}`, {
        taskId: req.params.taskId,
        userId: req.userId,
        userRole: req.userRole,
        error: error.stack
      })
      return ApiResponse.error(
        res,
        error.message === "Task not found" ? "Task not found" : "Error retrieving task",
        error.message === "Task not found" ? 404 : 500,
      )
    }
  }

  /**
   * Create a new task
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async createTask(req, res) {
    try {
      const { board, color, leader } = req.body

      // Get board to check permissions
      const boardDoc = await boardService.getBoardById(board)
      if (!boardDoc) {
        return ApiResponse.error(res, "Board not found", 404)
      }

      // Get project to check permissions
      const project = await projectService.getProjectById(boardDoc.project)

      // Check if the user is authorized
      const isAdmin = req.userRole.toLowerCase() === "admin" || req.userRole === "Admin"
      const isManager = project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })

      if (!isAdmin && !isManager && !isProjectMember) {
        return ApiResponse.error(res, "Unauthorized to create task in this board", 403)
      }

      const leaderId = leader || req.user._id;
      const task = await taskService.createTask({ ...req.body, color, leader: leaderId }, req.userId)
      return ApiResponse.success(res, "Task created successfully", { task }, 201)
    } catch (error) {
      logger.error(`Error creating task: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Board not found" ? "Board not found" : "Error creating task",
        error.message === "Board not found" ? 404 : 500,
      )
    }
  }

  /**
   * Update a task
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async updateTask(req, res) {
    try {
      const { taskId } = req.params

      // Get task to check permissions
      const task = await taskService.getTaskById(taskId)
      if (!task) {
        return ApiResponse.error(res, "Task not found", 404)
      }

      // Get board to check permissions
      const board = await boardService.getBoardById(task.board)
      if (!board) {
        return ApiResponse.error(res, "Board not found", 404)
      }

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)
      if (!project) {
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Check if the user is authorized
      const userRole = req.userRole ? req.userRole.toLowerCase() : ''
      const isAdmin = userRole === "admin"
      const isManager = project.manager?.toString() === req.userId?.toString()
      const isProjectMember = project.members?.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId?.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      }) || false
      const isAssignee = task.assignees?.some((assignee) => assignee?.toString() === req.userId?.toString()) || false
      const isTaskLeader = task.leader?.toString() === req.userId?.toString()

      logger.debug('Permission check details:', {
        userId: req.userId,
        userRole: userRole,
        isAdmin,
        isManager,
        isProjectMember,
        isAssignee,
        isTaskLeader,
        taskId,
        boardId: task.board
      })

      if (!isAdmin && !isManager && !isProjectMember && !isAssignee && !isTaskLeader) {
        logger.warn(`Unauthorized attempt to update task: ${taskId} by user: ${req.userId}`)
        return ApiResponse.error(res, "Unauthorized to update this task", 403)
      }

      // Inside the updateTask method, before updating the task
      logger.debug("Updating task with data:", req.body)
      logger.debug("Current assignees:", task.assignees)
      logger.debug("New assignees:", req.body.assignees)

      const updatedTask = await taskService.updateTask(taskId, req.body, req.userId)

      // After updating the task
      logger.debug("Updated task:", updatedTask)

      return ApiResponse.success(res, "Task updated successfully", { task: updatedTask })
    } catch (error) {
      logger.error(`Error updating task: ${error.message}`, {
        taskId: req.params.taskId,
        userId: req.userId,
        userRole: req.userRole,
        error: error.stack
      })
      return ApiResponse.error(
        res,
        error.message === "Task not found" ? "Task not found" : "Error updating task",
        error.message === "Task not found" ? 404 : 500,
      )
    }
  }

  /**
   * Delete a task
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async deleteTask(req, res) {
    try {
      const { taskId } = req.params

      // Get task to check permissions
      const task = await taskService.getTaskById(taskId)
      if (!task) {
        return ApiResponse.error(res, "Task not found", 404)
      }

      // Get board to check permissions
      const board = await boardService.getBoardById(task.board)

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)

      // Check if the user is authorized
      const isAdmin = req.userRole.toLowerCase() === "admin" || req.userRole === "Admin"
      const isManager = project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })

      if (!isAdmin && !isManager && !isProjectMember) {
        return ApiResponse.error(res, "Unauthorized to delete this task", 403)
      }

      await taskService.deleteTask(taskId, req.userId)
      return ApiResponse.success(res, "Task deleted successfully")
    } catch (error) {
      logger.error(`Error deleting task: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Task not found" ? "Task not found" : "Error deleting task",
        error.message === "Task not found" ? 404 : 500,
      )
    }
  }

  /**
   * Move a task to another board
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async moveTask(req, res) {
    try {
      const { taskId } = req.params
      const { targetBoard } = req.body

      if (!targetBoard) {
        return ApiResponse.error(res, "Target board is required", 400)
      }

      // Get task to check permissions
      const task = await taskService.getTaskById(taskId)
      if (!task) {
        return ApiResponse.error(res, "Task not found", 404)
      }

      // Get source board to check permissions
      const sourceBoard = await boardService.getBoardById(task.board)

      // Get target board to check permissions
      const targetBoardDoc = await boardService.getBoardById(targetBoard)
      if (!targetBoardDoc) {
        return ApiResponse.error(res, "Target board not found", 404)
      }

      // Get projects to check permissions
      const sourceProject = await projectService.getProjectById(sourceBoard.project)
      const targetProject = await projectService.getProjectById(targetBoardDoc.project)

      // Check if both boards belong to the same project
      if (sourceBoard.project.toString() !== targetBoardDoc.project.toString()) {
        return ApiResponse.error(res, "Cannot move task to a board in a different project", 400)
      }

      // Add projectId to request body for projectMiddleware
      req.body.projectId = sourceBoard.project.toString()

      // Debug logs for permission checks
      logger.debug('Permission check details:', {
        userId: req.userId,
        userRole: req.userRole,
        rawUserRole: req.userRole,
        taskLeader: task.leader,
        projectManager: sourceProject.manager,
        isManager: sourceProject.manager._id ? 
          sourceProject.manager._id.toString() === req.userId.toString() : 
          sourceProject.manager.toString() === req.userId.toString(),
        projectId: sourceBoard.project.toString()
      })

      // Check if the user is authorized
      const userRole = standardizeRole(req.userRole || '')
      const isOwner = userRole === "owner"
      const isAdmin = userRole === "admin"
      const isManager = sourceProject.manager._id ? 
        sourceProject.manager._id.toString() === req.userId.toString() : 
        sourceProject.manager.toString() === req.userId.toString()
      const isTaskLeader = task.leader._id ? 
        task.leader._id.toString() === req.userId.toString() : 
        task.leader.toString() === req.userId.toString()

      logger.debug('Authorization check results:', {
        isOwner,
        isAdmin,
        isManager,
        isTaskLeader,
        userRole,
        userId: req.userId,
        projectManager: sourceProject.manager,
        projectId: sourceBoard.project.toString(),
        rawUserRole: req.userRole,
        standardizedRole: userRole
      })

      // Project owners, admins, and managers can move any task
      // Task leaders can move their own tasks
      if (!isOwner && !isAdmin && !isManager && !isTaskLeader) {
        logger.warn(`Unauthorized attempt to move task: ${taskId} by user: ${req.userId}`, {
          userRole,
          isOwner,
          isAdmin,
          isManager,
          isTaskLeader,
          projectId: sourceBoard.project.toString(),
          rawUserRole: req.userRole,
          standardizedRole: userRole
        })
        return ApiResponse.error(res, "Unauthorized to move this task", 403)
      }

      const updatedTask = await taskService.moveTask(taskId, targetBoard, req.userId)
      return ApiResponse.success(res, "Task moved successfully", { task: updatedTask })
    } catch (error) {
      logger.error(`Error moving task: ${error.message}`, {
        taskId: req.params.taskId,
        targetBoard: req.body.targetBoard,
        error: error.stack
      })
      return ApiResponse.error(res, error.message || "Error moving task", 500)
    }
  }

  /**
   * Reorder tasks within a board
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async reorderTasks(req, res) {
    try {
      const { boardId } = req.params
      const { tasks } = req.body

      if (!Array.isArray(tasks)) {
        return ApiResponse.error(res, "Tasks must be an array", 400)
      }

      // Get board to check permissions
      const board = await boardService.getBoardById(boardId)
      if (!board) {
        return ApiResponse.error(res, "Board not found", 404)
      }

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)

      // Check if the user is authorized
      const isAdmin = req.userRole.toLowerCase() === "admin" || req.userRole === "Admin"
      const isManager = project.manager.toString() === req.userId.toString()
      const isMember = project.members.some((member) => member.toString() === req.userId.toString())

      if (!isAdmin && !isManager && !isMember) {
        return ApiResponse.error(res, "Unauthorized to reorder tasks in this board", 403)
      }

      await taskService.reorderTasks(boardId, tasks, req.userId)
      return ApiResponse.success(res, "Tasks reordered successfully")
    } catch (error) {
      logger.error(`Error reordering tasks: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Board not found" ? "Board not found" : "Error reordering tasks",
        error.message === "Board not found" ? 404 : 500,
      )
    }
  }

  /**
   * Get task statistics for a project
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getTaskStatsByProject(req, res) {
    try {
      const { projectId } = req.params

      // Get project to check permissions
      const project = await projectService.getProjectById(projectId)
      if (!project) {
        return ApiResponse.error(res, "Project not found", 404)
      }

      // Check if the user is authorized
      const isAdmin = req.userRole.toLowerCase() === "admin" || req.userRole === "Admin"
      const isManager = project.manager.toString() === req.userId.toString()
      const isMember = project.members.some((member) => member.toString() === req.userId.toString())

      if (!isAdmin && !isManager && !isMember) {
        return ApiResponse.error(res, "Unauthorized to view task statistics for this project", 403)
      }

      const stats = await taskService.getTaskStatsByProject(projectId)
      return ApiResponse.success(res, "Task statistics retrieved successfully", { stats })
    } catch (error) {
      logger.error(`Error getting task statistics: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Project not found" ? "Project not found" : "Error retrieving task statistics",
        error.message === "Project not found" ? 404 : 500,
      )
    }
  }
}

module.exports = new TaskController()
