// Board controller
const boardService = require("../services/board.service")
const projectService = require("../services/project.service")
const ApiResponse = require("../utils/apiResponse")
const logger = require("../utils/logger")

class BoardController {
  /**
   * Create a new board
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async createBoard(req, res) {
    try {
      // Check if user has access to the project
      const project = await projectService.getProjectById(req.body.project)

      // Log for debugging
      console.log("Creating board for project:", req.body.project)
      console.log("User ID:", req.userId)
      console.log("User role:", req.userRole)
      console.log("Project manager:", project.manager)
      console.log("Project members:", project.members)

      // Check if project.manager is an object or just an ID
      const managerId = project.manager._id ? project.manager._id.toString() : project.manager.toString()

      // Check if the user is authorized
      const isAdmin = project.members.some((member) => 
        member.userId._id.toString() === req.userId.toString() && 
        member.role?.toLowerCase() === "admin"
      );
      const isManager = managerId === req.userId.toString();
      const isMember = project.members.some((member) => {
        const memberId = member.userId._id.toString();
        console.log("Comparing member ID:", memberId, "with user ID:", req.userId.toString());
        return memberId === req.userId.toString();
      });

      console.log("Authorization Check Results:")
      console.log("- Is Admin:", isAdmin)
      console.log("- Is Manager:", isManager)
      console.log("- Is Member:", isMember)

      if (!isAdmin && !isManager && !isMember) {
        return ApiResponse.error(res, "Unauthorized to create board in this project", 403)
      }

      const board = await boardService.createBoard(req.body, req.userId)
      return ApiResponse.success(res, "Board created successfully", { board }, 201)
    } catch (error) {
      logger.error(`Error creating board: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Project not found" ? "Project not found" : "Error creating board",
        error.message === "Project not found" ? 404 : 500,
      )
    }
  }

  /**
   * Get all boards for a project
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getBoardsByProject(req, res) {
    try {
      const { projectId } = req.params

      // Debug logging for request details
      console.log("=== getBoardsByProject Debug Info ===")
      console.log("Project ID:", projectId)
      console.log("User ID:", req.userId)
      console.log("User Role:", req.userRole)
      console.log("Raw User Role:", req.userRole)

      // Check if user has access to the project
      const project = await projectService.getProjectById(projectId)
      console.log("Project Manager:", project.manager)
      console.log("Project Members:", JSON.stringify(project.members, null, 2))

      // Check if project.manager is an object or just an ID
      const managerId = project.manager._id ? project.manager._id.toString() : project.manager.toString()
      console.log("Manager ID:", managerId)

      // Check if the user is authorized
      const isAdmin = project.members.some((member) => 
        member.userId._id.toString() === req.userId.toString() && 
        member.role?.toLowerCase() === "admin"
      );
      const isManager = managerId === req.userId.toString();
      const isMember = project.members.some((member) => {
        const memberId = member.userId._id.toString();
        console.log("Comparing member ID:", memberId, "with user ID:", req.userId.toString());
        return memberId === req.userId.toString();
      });

      console.log("Authorization Check Results:")
      console.log("- Is Admin:", isAdmin)
      console.log("- Is Manager:", isManager)
      console.log("- Is Member:", isMember)

      if (!isAdmin && !isManager && !isMember) {
        console.log("Authorization Failed - User not authorized")
        return ApiResponse.error(res, "Unauthorized to view boards in this project", 403)
      }

      console.log("Authorization Successful - Proceeding to fetch boards")
      const boards = await boardService.getBoardsByProject(projectId)
      return ApiResponse.success(res, "Boards retrieved successfully", { boards })
    } catch (error) {
      console.error("Error in getBoardsByProject:", error)
      logger.error(`Error getting boards by project: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Project not found" ? "Project not found" : "Error retrieving boards",
        error.message === "Project not found" ? 404 : 500,
      )
    }
  }

  /**
   * Get board by ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getBoardById(req, res) {
    try {
      const { id } = req.params

      const board = await boardService.getBoardById(id)

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)

      // Check if project.manager is an object or just an ID
      const managerId = project.manager._id ? project.manager._id.toString() : project.manager.toString()

      // Check if the user is authorized
      const isAdmin = project.members.some((member) => 
        member.userId._id.toString() === req.userId.toString() && 
        member.role?.toLowerCase() === "admin"
      );
      const isManager = managerId === req.userId.toString();
      const isMember = project.members.some((member) => {
        const memberId = member.userId._id.toString();
        return memberId === req.userId.toString();
      });

      if (!isAdmin && !isManager && !isMember) {
        return ApiResponse.error(res, "Unauthorized to view this board", 403)
      }

      return ApiResponse.success(res, "Board retrieved successfully", { board })
    } catch (error) {
      logger.error(`Error getting board by ID: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Board not found" ? "Board not found" : "Error retrieving board",
        error.message === "Board not found" ? 404 : 500,
      )
    }
  }

  /**
   * Update board
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async updateBoard(req, res) {
    try {
      const { id } = req.params

      // Get board to check permissions
      const board = await boardService.getBoardById(id)

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)

      // Check if project.manager is an object or just an ID
      const managerId = project.manager._id ? project.manager._id.toString() : project.manager.toString()

      // Check if the user is authorized
      const isAdmin = project.members.some((member) => 
        member.userId._id.toString() === req.userId.toString() && 
        member.role?.toLowerCase() === "admin"
      );
      const isManager = managerId === req.userId.toString();
      const isMember = project.members.some((member) => {
        const memberId = member.userId._id.toString();
        return memberId === req.userId.toString();
      });

      if (!isAdmin && !isManager && !isMember) {
        return ApiResponse.error(res, "Unauthorized to update this board", 403)
      }

      console.log("Updating board with data:", req.body)

      const updatedBoard = await boardService.updateBoard(id, req.body, req.userId)

      return ApiResponse.success(res, "Board updated successfully", { board: updatedBoard })
    } catch (error) {
      logger.error(`Error updating board: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Board not found" ? "Board not found" : "Error updating board",
        error.message === "Board not found" ? 404 : 500,
      )
    }
  }

  /**
   * Delete board
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async deleteBoard(req, res) {
    try {
      const { id } = req.params

      // Get board to check permissions
      const board = await boardService.getBoardById(id)

      // Get project to check permissions
      const project = await projectService.getProjectById(board.project)

      // Check if project.manager is an object or just an ID
      const managerId = project.manager._id ? project.manager._id.toString() : project.manager.toString()

      // Check if the user is authorized
      const isAdmin = project.members.some((member) => 
        member.userId._id.toString() === req.userId.toString() && 
        member.role?.toLowerCase() === "admin"
      );
      const isManager = managerId === req.userId.toString();

      if (!isAdmin && !isManager) {
        return ApiResponse.error(res, "Unauthorized to delete this board", 403)
      }

      await boardService.deleteBoard(id, req.userId)

      return ApiResponse.success(res, "Board deleted successfully")
    } catch (error) {
      logger.error(`Error deleting board: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Board not found" ? "Board not found" : "Error deleting board",
        error.message === "Board not found" ? 404 : 500,
      )
    }
  }

  /**
   * Reorder boards
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async reorderBoards(req, res) {
    try {
      const { projectId } = req.params
      const { boards } = req.body

      if (!Array.isArray(boards)) {
        return ApiResponse.error(res, "Boards must be an array", 400)
      }

      // Get project to check permissions
      const project = await projectService.getProjectById(projectId)

      // Check if the user is authorized
      const isAdmin = project.members.some((member) => 
        member.userId._id.toString() === req.userId.toString() && 
        member.role?.toLowerCase() === "admin"
      );
      const isManager = project.manager._id ? 
        project.manager._id.toString() === req.userId.toString() : 
        project.manager.toString() === req.userId.toString();
      const isProjectMember = project.members.some((member) => {
        const memberId = member.userId ? member.userId._id.toString() : member.toString();
        const memberRole = member.role ? member.role.toLowerCase() : '';
        return memberId === req.userId.toString() && (memberRole === 'admin' || memberRole === 'owner' || memberRole === 'member');
      });

      // Debug logs for permission checks
      logger.debug('Board reorder permission check details:', {
        userId: req.userId,
        userRole: req.userRole,
        projectManager: project.manager,
        isAdmin,
        isManager,
        isProjectMember,
        projectId
      });

      if (!isAdmin && !isManager && !isProjectMember) {
        return ApiResponse.error(res, "Unauthorized to reorder boards in this project", 403)
      }

      await boardService.reorderBoards(projectId, boards, req.userId)
      return ApiResponse.success(res, "Boards reordered successfully")
    } catch (error) {
      logger.error(`Error reordering boards: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Project not found" ? "Project not found" : "Error reordering boards",
        error.message === "Project not found" ? 404 : 500,
      )
    }
  }
}

module.exports = new BoardController()
