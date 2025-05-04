const mongoose = require("mongoose")
const Schema = mongoose.Schema

const ProjectSchema = new Schema(
  {
    title: {
      type: String,
      required: [true, "Project title is required"],
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    manager: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Project manager is required"],
    },
    members: [
      {
        type: Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    deadline: {
      type: Date,
    },
    status: {
      type: String,
      enum: ["Planning", "In Progress", "Completed"],
      default: "Planning",
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  },
)

// Add a method to calculate project progress and update status
ProjectSchema.methods.calculateProgress = async function () {
  const Board = mongoose.model("Board")
  const Task = mongoose.model("Task")

  // Find all boards in this project
  const boards = await Board.find({ project: this._id })
  const boardIds = boards.map((board) => board._id)

  // Get total tasks count
  const totalTasks = await Task.countDocuments({ board: { $in: boardIds } })

  // Get completed tasks count
  const completedTasks = await Task.countDocuments({
    board: { $in: boardIds },
    status: "Done",
  })

  // Calculate progress percentage
  const progressPercentage = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0

  // Update project status based on progress
  let newStatus = "Planning"
  if (progressPercentage > 0 && progressPercentage < 100) {
    newStatus = "In Progress"
  } else if (progressPercentage === 100) {
    newStatus = "Completed"
  }

  // Update the project status if it has changed
  if (this.status !== newStatus) {
    this.status = newStatus
    await this.save()
  }

  return {
    totalTasks,
    completedTasks,
    progressPercentage,
  }
}

// Update the project controller to include progress information
ProjectSchema.set("toJSON", {
  transform: (doc, ret, options) => {
    ret.id = ret._id
    delete ret.__v
    return ret
  },
})

module.exports = mongoose.model("Project", ProjectSchema)

