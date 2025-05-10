// Main application file
const express = require("express")
const cors = require("cors")
const helmet = require("helmet")
const cookieParser = require("cookie-parser")
const { errorHandler, notFound } = require("./middleware/error.middleware")
const logger = require("./utils/logger")

// Import routes
const authRoutes = require("./routes/auth.routes")
const userRoutes = require("./routes/users.routes")
const projectRoutes = require("./routes/projects.routes")
const boardRoutes = require("./routes/board.routes")
const taskRoutes = require("./routes/task.routes")
const subtaskRoutes = require("./routes/subtasks.routes")
const activityLogRoutes = require("./routes/activityLog.routes")
const notificationRoutes = require("./routes/notifications.routes")
const teamRoutes = require("./routes/teams.routes")
const searchRoutes = require('./routes/search.routes')
const calendarRoutes = require('./routes/calendar.routes')

// Initialize express app
const app = express()

// Middleware
app.use(helmet())
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || "*",
    credentials: true,
  }),
)
app.use(express.json())
app.use(express.urlencoded({ extended: true }))
app.use(cookieParser())

// API routes
app.use("/api/auth", authRoutes)
app.use("/api/users", userRoutes)
app.use("/api/projects", projectRoutes)
app.use("/api/boards", boardRoutes)
app.use("/api/tasks", taskRoutes)
app.use("/api/subtasks", subtaskRoutes)
app.use("/api/activity-logs", activityLogRoutes)
app.use("/api/notifications", notificationRoutes)
app.use("/api/teams", teamRoutes)
app.use("/api/search", searchRoutes)
app.use("/api/calendar", calendarRoutes)

// Health check route
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", message: "Server is running" })
})

// Error handling middleware
app.use(notFound)
app.use(errorHandler)

module.exports = app

