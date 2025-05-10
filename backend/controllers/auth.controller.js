const User = require("../models/user.model") // Import the User model
const jwt = require("jsonwebtoken") // Import the jsonwebtoken library
const authService = require("../services/auth.service") // Import authService
const ApiResponse = require("../utils/apiResponse") // Import ApiResponse
const logger = require("../utils/logger") // Import logger

// Auth controller
class AuthController {
  /**
   * Register a new user
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async register(req, res) {
    try {
      const { user, token } = await authService.register(req.body)
      return ApiResponse.success(res, "User registered successfully", { user, token }, 201)
    } catch (error) {
      logger.error(`Registration error: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "User with this email already exists"
          ? "User with this email already exists"
          : "Error registering user",
        error.message === "User with this email already exists" ? 400 : 500,
      )
    }
  }

  /**
   * Login a user
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async login(req, res) {
    try {
      const { email, password } = req.body
      const { user, token } = await authService.login(email, password)

      return ApiResponse.success(res, "Login successful", { user, token })
    } catch (error) {
      logger.error(`Login error: ${error.message}`)
      return ApiResponse.error(
        res,
        error.message === "Invalid email or password" || error.message === "Account is deactivated"
          ? error.message
          : "Error logging in",
        error.message === "Invalid email or password" || error.message === "Account is deactivated" ? 401 : 500,
      )
    }
  }

  /**
   * Logout a user
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async logout(req, res) {
    try {
      // JWT is stateless, so we don't need to do anything server-side
      // The client should remove the token from storage

      return ApiResponse.success(res, "Logged out successfully")
    } catch (error) {
      logger.error(`Logout error: ${error.message}`)
      return ApiResponse.error(res, "Error logging out", 500)
    }
  }

  async changePassword(req, res) {
    try {
      const userId = req.user._id || req.userId;
      const { currentPassword, newPassword } = req.body;

      logger.debug(`[changePassword] userId: ${userId}`);
      logger.debug(`[changePassword] currentPassword: ${currentPassword ? '[provided]' : '[missing]'}, newPassword: ${newPassword ? '[provided]' : '[missing]'}`);

      if (!currentPassword || !newPassword) {
        logger.debug('[changePassword] Missing current or new password');
        return res.status(400).json({ message: 'Current and new password are required.' });
      }

      const user = await User.findById(userId).select('+password');
      logger.debug(`[changePassword] User found: ${!!user}`);
      if (!user) {
        logger.debug('[changePassword] User not found');
        return res.status(404).json({ message: 'User not found' });
      }

      const isMatch = await user.matchPassword(currentPassword);
      logger.debug(`[changePassword] Password match: ${isMatch}`);
      if (!isMatch) {
        logger.debug('[changePassword] Old password is incorrect');
        return res.status(400).json({ message: 'Old password is incorrect' });
      }

      user.password = newPassword;
      await user.save();
      logger.debug('[changePassword] Password updated and saved');

      res.status(200).json({ message: 'Password changed successfully' });
    } catch (error) {
      logger.error(`[changePassword] Error: ${error.message}`);
      res.status(500).json({ message: 'Error changing password', error: error.message });
    }
  }
}

module.exports = new AuthController()

