// Subtask service
const Subtask = require("../models/subtask.model")
const Task = require("../models/task.model")
const ActivityLog = require("../models/activityLog.model")
const logger = require("../utils/logger")
const notificationService = require("./notification.service")

class SubtaskService {
  /**
   * Create a new subtask
   * @param {string} taskId - Task ID
   * @param {Object} subtaskData - Subtask data
   * @param {string} userId - Creator user ID
   * @returns {Object} - Newly created subtask
   */
  async createSubtask(taskId, subtaskData, userId) {
    try {
      console.log('[DEBUG] createSubtask called with:', { taskId, subtaskData, userId });
      // Check if task exists
      const task = await Task.findById(taskId)
      if (!task) {
        console.error('[DEBUG] Task not found for taskId:', taskId);
        throw new Error("Task not found")
      }

      // Check if subtask deadline is before task deadline
      if (subtaskData.deadline && task.deadline) {
        const subtaskDeadline = new Date(subtaskData.deadline);
        const taskDeadline = new Date(task.deadline);
        if (subtaskDeadline < taskDeadline) {
          console.log('[DEBUG] Subtask deadline validation passed:', {
            subtaskDeadline,
            taskDeadline
          });
        } else {
          console.error('[DEBUG] Subtask deadline validation failed:', {
            subtaskDeadline,
            taskDeadline
          });
          throw new Error('Subtask deadline must be before the parent task deadline');
        }
      }

      // Get the highest order value for existing subtasks in this task
      const highestOrderSubtask = await Subtask.findOne({ task: taskId }).sort({ order: -1 })
      console.log('[DEBUG] highestOrderSubtask:', highestOrderSubtask);

      const order = highestOrderSubtask ? highestOrderSubtask.order + 1 : 0

      // Create the subtask with assignees
      const subtask = new Subtask({
        ...subtaskData,
        task: taskId,
        order,
        deadline: subtaskData.deadline ? new Date(subtaskData.deadline) : null,
        assignees: subtaskData.assignees || [] // Initialize assignees array
      })
      console.log('[DEBUG] New subtask to save:', subtask);

      await subtask.save()
      console.log('[DEBUG] Subtask saved:', subtask);

      // Add the subtask to the task's subtasks array
      task.subtasks.push(subtask._id)
      await task.save()
      console.log('[DEBUG] Subtask ID added to task:', task.subtasks);

      // Create activity log
      await ActivityLog.create({
        user: userId,
        action: "Created subtask",
        details: `Subtask "${subtask.title}" was created for task "${task.title}"`,
        relatedItem: {
          itemId: subtask._id,
          itemType: "Subtask",
        },
      })
      console.log('[DEBUG] Activity log created for subtask');

      // Create notifications for assignees if any
      if (subtask.assignees && subtask.assignees.length > 0) {
        try {
          await notificationService.createSubtaskAssignmentNotification(
            subtask._id,
            subtask.title,
            task._id,
            task.title,
            userId,
            subtask.assignees
          )
          console.log('[DEBUG] Notifications created for subtask assignees');
        } catch (notifError) {
          console.error('[DEBUG] Notification error:', notifError);
          // Do not throw, just log
        }
      }

      // Populate the subtask before returning
      const populatedSubtask = await Subtask.findById(subtask._id)
        .populate('assignees', 'name email profilePicture')
        .lean();

      return populatedSubtask;
    } catch (error) {
      console.error('[DEBUG] Error in createSubtask:', error);
      logger.error(`Error creating subtask: ${error.message}`)
      throw error
    }
  }

  /**
   * Get all subtasks for a task
   * @param {string} taskId - Task ID
   * @returns {Array} - List of subtasks
   */
  async getSubtasksByTask(taskId) {
    try {
      // Check if task exists
      const task = await Task.findById(taskId)
      if (!task) {
        throw new Error("Task not found")
      }

      // Get all subtasks for the task
      const subtasks = await Subtask.find({ task: taskId }).sort({ order: 1 })

      return subtasks
    } catch (error) {
      logger.error(`Error getting subtasks by task: ${error.message}`)
      throw error
    }
  }

  /**
   * Get subtask by ID
   * @param {string} subtaskId - Subtask ID
   * @returns {Object} - Subtask data
   */
  async getSubtaskById(subtaskId) {
    try {
      const subtask = await Subtask.findById(subtaskId)

      if (!subtask) {
        throw new Error("Subtask not found")
      }

      return subtask
    } catch (error) {
      logger.error(`Error getting subtask by ID: ${error.message}`)
      throw error
    }
  }

  /**
   * Update subtask
   * @param {string} subtaskId - Subtask ID
   * @param {Object} updateData - Data to update
   * @param {string} userId - User ID making the update
   * @returns {Object} - Updated subtask
   */
  async updateSubtask(subtaskId, updateData, userId) {
    try {
      const subtask = await Subtask.findById(subtaskId)

      if (!subtask) {
        throw new Error("Subtask not found")
      }

      // Get task for activity log
      const task = await Task.findById(subtask.task)

      // Update the subtask
      const updatedSubtask = await Subtask.findByIdAndUpdate(subtaskId, updateData, { new: true, runValidators: true })

      // If subtask is marked as completed, create notifications
      if (updateData.isCompleted === true) {
        // Get the task to find assignees
        const task = await Task.findById(subtask.task).populate("assignees")

        if (task && task.assignees && task.assignees.length > 0) {
          const assigneeIds = task.assignees.map((assignee) => assignee._id)

          await notificationService.createSubtaskCompletionNotification(
            subtask._id,
            subtask.title,
            task._id,
            task.title,
            userId,
            assigneeIds,
          )
        }
      }

      // Create activity log
      await ActivityLog.create({
        user: userId,
        action: "Updated subtask",
        details: `Subtask "${subtask.title}" was updated for task "${task.title}"`,
        relatedItem: {
          itemId: subtask._id,
          itemType: "Subtask",
        },
      })

      return updatedSubtask
    } catch (error) {
      logger.error(`Error updating subtask: ${error.message}`)
      throw error
    }
  }

  /**
   * Delete subtask
   * @param {string} subtaskId - Subtask ID
   * @param {string} userId - User ID making the deletion
   * @returns {boolean} - Success status
   */
  async deleteSubtask(subtaskId, userId) {
    try {
      const subtask = await Subtask.findById(subtaskId)

      if (!subtask) {
        throw new Error("Subtask not found")
      }

      // Get task for activity log
      const task = await Task.findById(subtask.task)

      // Remove the subtask from the task's subtasks array
      task.subtasks = task.subtasks.filter(id => id.toString() !== subtaskId.toString())
      await task.save()

      // Delete the subtask
      await Subtask.findByIdAndDelete(subtaskId)

      // Create activity log
      await ActivityLog.create({
        user: userId,
        action: "Deleted subtask",
        details: `Subtask "${subtask.title}" was deleted from task "${task.title}"`,
        relatedItem: {
          itemId: subtask._id,
          itemType: "Subtask",
        },
      })

      return true
    } catch (error) {
      logger.error(`Error deleting subtask: ${error.message}`)
      throw error
    }
  }

  /**
   * Reorder subtasks
   * @param {string} taskId - Task ID
   * @param {Array} subtaskOrders - Array of {id, order} objects
   * @param {string} userId - User ID making the update
   * @returns {Array} - Updated subtasks
   */
  async reorderSubtasks(taskId, subtaskOrders, userId) {
    try {
      // Check if task exists
      const task = await Task.findById(taskId)
      if (!task) {
        throw new Error("Task not found")
      }

      // Update each subtask's order
      const updatePromises = subtaskOrders.map(({ id, order }) =>
        Subtask.findByIdAndUpdate(id, { order }, { new: true }),
      )

      const updatedSubtasks = await Promise.all(updatePromises)

      // Create activity log
      await ActivityLog.create({
        user: userId,
        action: "Reordered subtasks",
        details: `Subtasks in task "${task.title}" were reordered`,
        relatedItem: {
          itemId: task._id,
          itemType: "Task",
        },
      })

      return updatedSubtasks
    } catch (error) {
      logger.error(`Error reordering subtasks: ${error.message}`)
      throw error
    }
  }
}

module.exports = new SubtaskService()

