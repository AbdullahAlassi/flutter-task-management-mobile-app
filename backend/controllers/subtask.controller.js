// Subtask controller
const subtaskService = require('../services/subtask.service');
const taskService = require('../services/task.service');
const boardService = require('../services/board.service');
const projectService = require('../services/project.service');
const ApiResponse = require('../utils/apiResponse');
const logger = require('../utils/logger');

class SubtaskController {
  /**
   * Create a new subtask
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async createSubtask(req, res) {
    try {
      console.log('[DEBUG] [Controller] createSubtask called');
      console.log('[DEBUG] [Controller] req.params:', req.params);
      console.log('[DEBUG] [Controller] req.body:', req.body);
      console.log('[DEBUG] [Controller] req.userId:', req.userId);
      const { taskId } = req.params;
      
      // Get task to check permissions
      const task = await taskService.getTaskById(taskId);
      console.log('[DEBUG] [Controller] taskService.getTaskById result:', task);
      
      // Get board to check permissions
      const board = await boardService.getBoardById(task.board);
      
      // Get project to check permissions
      const project = await projectService.getProjectById(board.project);
      
      // Check if user has access to the project
      const isAdmin = (req.userRole ? req.userRole.toLowerCase() : '') === "admin" || req.userRole === "Admin"
      const isManager = project.manager._id ? project.manager._id.toString() === req.userId.toString() : project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })

      if (!isAdmin && !isManager && !isProjectMember) {
        console.log('[DEBUG] [Controller] Unauthorized user');
        return ApiResponse.error(res, 'Unauthorized to create subtask for this task', 403);
      }
      
      console.log('[DEBUG] [Controller] Calling subtaskService.createSubtask');
      const subtask = await subtaskService.createSubtask(taskId, req.body, req.userId);
      console.log('[DEBUG] [Controller] subtaskService.createSubtask result:', subtask);
      
      // Emit socket event for real-time updates
      const io = req.app.get('io');
      if (io) {
        try {
          // Notify all project members
          project.members.forEach(member => {
            io.to(member.toString()).emit('subtask:created', { subtask, taskId });
          });
        } catch (socketError) {
          console.error('[DEBUG] Socket event error:', socketError);
          // Do not throw, just log
        }
      }
      
      return ApiResponse.success(res, 'Subtask created successfully', { subtask }, 201);
    } catch (error) {
      console.error('[DEBUG] [Controller] Error in createSubtask:', error);
      logger.error(`Error creating subtask: ${error.message}`);
      return ApiResponse.error(
        res, 
        error.message === 'Task not found' ? 'Task not found' : 'Error creating subtask', 
        error.message === 'Task not found' ? 404 : 500
      );
    }
  }
  
  /**
   * Get all subtasks for a task
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getSubtasksByTask(req, res) {
    try {
      const { taskId } = req.params;
      
      // Get task to check permissions
      const task = await taskService.getTaskById(taskId);
      
      // Get board to check permissions
      const board = await boardService.getBoardById(task.board);
      
      // Get project to check permissions
      const project = await projectService.getProjectById(board.project);
      
      // Check if user has access to the project
      const isAdmin = (req.userRole ? req.userRole.toLowerCase() : '') === "admin" || req.userRole === "Admin"
      const isManager = project.manager._id ? project.manager._id.toString() === req.userId.toString() : project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })

      if (!isAdmin && !isManager && !isProjectMember) {
        return ApiResponse.error(res, 'Unauthorized to access subtasks for this task', 403);
      }
      
      const subtasks = await subtaskService.getSubtasksByTask(taskId);
      
      return ApiResponse.success(res, 'Subtasks retrieved successfully', { subtasks });
    } catch (error) {
      logger.error(`Error getting subtasks by task: ${error.message}`);
      return ApiResponse.error(
        res, 
        error.message === 'Task not found' ? 'Task not found' : 'Error retrieving subtasks', 
        error.message === 'Task not found' ? 404 : 500
      );
    }
  }
  
  /**
   * Get subtask by ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getSubtaskById(req, res) {
    try {
      const { id } = req.params;
      const subtask = await subtaskService.getSubtaskById(id);
      
      // Get task to check permissions
      const task = await taskService.getTaskById(subtask.task);
      
      // Get board to check permissions
      const board = await boardService.getBoardById(task.board);
      
      // Get project to check permissions
      const project = await projectService.getProjectById(board.project);
      
      // Check if user has access to the project
      const isAdmin = (req.userRole ? req.userRole.toLowerCase() : '') === "admin" || req.userRole === "Admin"
      const isManager = project.manager._id ? project.manager._id.toString() === req.userId.toString() : project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })

      if (!isAdmin && !isManager && !isProjectMember) {
        return ApiResponse.error(res, 'Unauthorized to access this subtask', 403);
      }
      
      return ApiResponse.success(res, 'Subtask retrieved successfully', { subtask });
    } catch (error) {
      logger.error(`Error getting subtask by ID: ${error.message}`);
      return ApiResponse.error(
        res, 
        error.message === 'Subtask not found' ? 'Subtask not found' : 'Error retrieving subtask', 
        error.message === 'Subtask not found' ? 404 : 500
      );
    }
  }
  
  /**
   * Update subtask
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async updateSubtask(req, res) {
    try {
      const { id } = req.params;
      
      // Get subtask to check permissions
      const subtask = await subtaskService.getSubtaskById(id);
      
      // Get task to check permissions
      const task = await taskService.getTaskById(subtask.task);
      
      // Get board to check permissions
      const board = await boardService.getBoardById(task.board);
      
      // Get project to check permissions
      const project = await projectService.getProjectById(board.project);
      
      // Check if user has permission to update this subtask
      const userRole = standardizeRole(req.userRole || '')
      const isOwner = userRole === "owner"
      const isAdmin = userRole === "admin"
      const isManager = project.manager._id ? project.manager._id.toString() === req.userId.toString() : project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? standardizeRole(member.role) : 'viewer'
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })
      const isAssignee = task.assignees.some((assignee) => assignee.toString() === req.userId.toString())

      // Project owners, admins, and managers can update any subtask
      // Project members and assignees can update their own subtasks
      if (!isOwner && !isAdmin && !isManager && !isProjectMember && !isAssignee) {
        return ApiResponse.error(res, 'Unauthorized to update this subtask', 403);
      }
      
      const updatedSubtask = await subtaskService.updateSubtask(id, req.body, req.userId);
      
      // Emit socket event for real-time updates
      const io = req.app.get('io');
      if (io) {
        // Notify all project members
        project.members.forEach(member => {
          io.to(member.toString()).emit('subtask:updated', { subtaskId: id, taskId: task._id });
        });
      }
      
      return ApiResponse.success(res, 'Subtask updated successfully', { subtask: updatedSubtask });
    } catch (error) {
      logger.error(`Error updating subtask: ${error.message}`, {
        subtaskId: req.params.id,
        error: error.stack
      });
      return ApiResponse.error(res, error.message || 'Error updating subtask', 500);
    }
  }
  
  /**
   * Delete subtask
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async deleteSubtask(req, res) {
    try {
      const { id } = req.params;
      
      // Get subtask to check permissions
      const subtask = await subtaskService.getSubtaskById(id);
      
      // Get task to check permissions
      const task = await taskService.getTaskById(subtask.task);
      
      // Get board to check permissions
      const board = await boardService.getBoardById(task.board);
      
      // Get project to check permissions
      const project = await projectService.getProjectById(board.project);
      
      // Check if user has permission to delete this subtask
      const userRole = standardizeRole(req.userRole || '')
      const isOwner = userRole === "owner"
      const isAdmin = userRole === "admin"
      const isManager = project.manager._id ? project.manager._id.toString() === req.userId.toString() : project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? standardizeRole(member.role) : 'viewer'
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })
      const isAssignee = task.assignees.some((assignee) => assignee.toString() === req.userId.toString())

      // Project owners, admins, and managers can delete any subtask
      // Project members and assignees can delete their own subtasks
      if (!isOwner && !isAdmin && !isManager && !isProjectMember && !isAssignee) {
        return ApiResponse.error(res, 'Unauthorized to delete this subtask', 403);
      }
      
      await subtaskService.deleteSubtask(id, req.userId);
      
      // Emit socket event for real-time updates
      const io = req.app.get('io');
      if (io) {
        // Notify all project members
        project.members.forEach(member => {
          io.to(member.toString()).emit('subtask:deleted', { subtaskId: id, taskId: task._id });
        });
      }
      
      return ApiResponse.success(res, 'Subtask deleted successfully');
    } catch (error) {
      logger.error(`Error deleting subtask: ${error.message}`, {
        subtaskId: req.params.id,
        error: error.stack
      });
      return ApiResponse.error(res, error.message || 'Error deleting subtask', 500);
    }
  }
  
  /**
   * Reorder subtasks
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async reorderSubtasks(req, res) {
    try {
      const { taskId } = req.params;
      const { subtaskOrders } = req.body;
      
      if (!subtaskOrders || !Array.isArray(subtaskOrders)) {
        return ApiResponse.error(res, 'Invalid subtask orders data', 400);
      }
      
      // Get task to check permissions
      const task = await taskService.getTaskById(taskId);
      
      // Get board to check permissions
      const board = await boardService.getBoardById(task.board);
      
      // Get project to check permissions
      const project = await projectService.getProjectById(board.project);
      
      // Check if user has access to the project
      const isAdmin = (req.userRole ? req.userRole.toLowerCase() : '') === "admin" || req.userRole === "Admin"
      const isManager = project.manager._id ? project.manager._id.toString() === req.userId.toString() : project.manager.toString() === req.userId.toString()
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId.toString() : member.toString()
        const memberRole = member.role ? member.role.toLowerCase() : ''
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member')
      })

      if (!isAdmin && !isManager && !isProjectMember) {
        return ApiResponse.error(res, 'Unauthorized to reorder subtasks for this task', 403);
      }
      
      const updatedSubtasks = await subtaskService.reorderSubtasks(taskId, subtaskOrders, req.userId);
      
      // Emit socket event for real-time updates
      const io = req.app.get('io');
      if (io) {
        // Notify all project members
        project.members.forEach(member => {
          io.to(member.toString()).emit('subtasks:reordered', { subtasks: updatedSubtasks, taskId });
        });
      }
      
      return ApiResponse.success(res, 'Subtasks reordered successfully', { subtasks: updatedSubtasks });
    } catch (error) {
      logger.error(`Error reordering subtasks: ${error.message}`);
      return ApiResponse.error(
        res, 
        error.message === 'Task not found' ? 'Task not found' : 'Error reordering subtasks', 
        error.message === 'Task not found' ? 404 : 500
      );
    }
  }
}

module.exports = new SubtaskController();