const express = require("express")
const router = express.Router()
const taskController = require("../controllers/task.controller")
const authMiddleware = require("../middleware/auth.middleware")
const projectMiddleware = require("../middleware/project.middleware")

// Get all tasks for the authenticated user
router.get("/", authMiddleware.protect, taskController.getAllTasks)

// Get tasks by board
router.get("/board/:boardId", authMiddleware.protect, taskController.getTasksByBoard)

// Get task statistics for a project
router.get("/stats/project/:projectId", authMiddleware.protect, taskController.getTaskStatsByProject)

// Get task by ID
router.get("/:taskId", authMiddleware.protect, taskController.getTaskById)

// Create a new task
router.post("/", authMiddleware.protect, projectMiddleware, taskController.createTask)

// Update a task
router.put("/:taskId", authMiddleware.protect, taskController.updateTask)

// Delete a task
router.delete("/:taskId", authMiddleware.protect, taskController.deleteTask)

// Move a task to another board
router.patch("/:taskId/move", authMiddleware.protect, projectMiddleware, taskController.moveTask)

// Reorder tasks within a board
router.patch("/board/:boardId/reorder", authMiddleware.protect, taskController.reorderTasks)

module.exports = router

