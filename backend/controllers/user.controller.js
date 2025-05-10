const User = require("../models/user.model")
const bcrypt = require("bcryptjs")
const { standardizeRole } = require("../utils/permissions")
const ApiResponse = require("../utils/apiResponse")
const logger = require("../utils/logger")

// Get all users (admin and project managers)
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find()
      .select("-password -__v -createdAt -updatedAt")
      .sort({ name: 1 });

    return ApiResponse.success(res, "Users retrieved successfully", { users });
  } catch (error) {
    logger.error(`Error in getAllUsers: ${error.message}`);
    return ApiResponse.error(res, "Error retrieving users", 500);
  }
};

// Get current user profile
exports.getCurrentUser = async (req, res) => {
  try {
    if (!req.user) {
      return ApiResponse.error(res, "User not authenticated", 401);
    }

    const userId = req.user.id || req.user._id;
    const user = await User.findById(userId).select("-password");

    if (!user) {
      return ApiResponse.error(res, "User not found", 404);
    }

    return ApiResponse.success(res, "User profile retrieved successfully", { user });
  } catch (error) {
    logger.error(`Error in getCurrentUser: ${error.message}`);
    return ApiResponse.error(res, "Error retrieving user profile", 500);
  }
};

// Get user by ID
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");

    if (!user) {
      return ApiResponse.error(res, "User not found", 404);
    }

    return ApiResponse.success(res, "User retrieved successfully", { user });
  } catch (error) {
    logger.error(`Error in getUserById: ${error.message}`);
    return ApiResponse.error(res, "Error retrieving user", 500);
  }
};

// Update user
exports.updateUser = async (req, res) => {
  try {
    const { name, email, profilePicture, contactInfo } = req.body;
    const user = await User.findById(req.params.id);

    if (!user) {
      return ApiResponse.error(res, "User not found", 404);
    }

    // Check permission - only allow users to update their own profile
    if (req.userId.toString() !== req.params.id) {
      return ApiResponse.error(res, "Not authorized to update this user", 403);
    }

    // Update fields
    if (name) user.name = name;
    if (email) user.email = email;
    if (profilePicture !== undefined) user.profilePicture = profilePicture;
    if (contactInfo) {
      user.contactInfo = {
        ...user.contactInfo,
        ...contactInfo,
      };
    }

    await user.save();
    const updatedUser = await User.findById(req.params.id).select("-password");

    return ApiResponse.success(res, "User updated successfully", { user: updatedUser });
  } catch (error) {
    logger.error(`Error in updateUser: ${error.message}`);
    return ApiResponse.error(res, "Error updating user", 500);
  }
};

// Delete user
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return ApiResponse.error(res, "User not found", 404);
    }

    // Only allow users to delete their own account
    if (req.userId.toString() !== req.params.id) {
      return ApiResponse.error(res, "Not authorized to delete this user", 403);
    }

    await user.deleteOne();

    return ApiResponse.success(res, "User deleted successfully");
  } catch (error) {
    logger.error(`Error in deleteUser: ${error.message}`);
    return ApiResponse.error(res, "Error deleting user", 500);
  }
};

// Change user role
exports.changeUserRole = async (req, res) => {
  try {
    const { role } = req.body;
    const user = await User.findById(req.params.id);

    if (!user) {
      return ApiResponse.error(res, "User not found", 404);
    }

    // Only allow users to update their own role
    if (req.userId.toString() !== req.params.id) {
      return ApiResponse.error(res, "Not authorized to change this user's role", 403);
    }

    // Validate role
    const validRoles = ["member", "admin", "owner", "viewer"];
    const standardizedRole = standardizeRole(role);
    
    if (!validRoles.includes(standardizedRole)) {
      return ApiResponse.error(res, "Invalid role", 400);
    }

    user.role = standardizedRole;
    await user.save();

    return ApiResponse.success(res, "User role updated successfully", {
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    logger.error(`Error in changeUserRole: ${error.message}`);
    return ApiResponse.error(res, "Error changing user role", 500);
  }
};

// Change password
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body

    // Validate input
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Current password and new password are required",
      })
    }

    // Get user with password
    const user = await User.findById(req.user.id).select("+password")

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    // Check if current password matches
    const isMatch = await user.matchPassword(currentPassword)

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Current password is incorrect",
      })
    }

    // Set and hash new password
    user.password = newPassword
    await user.save()

    res.status(200).json({
      success: true,
      message: "Password updated successfully",
    })
  } catch (error) {
    console.error("Error in changePassword:", error)
    res.status(500).json({
      success: false,
      message: "Error changing password",
    })
  }
}

// Add this method to support the Flutter app's endpoint
exports.updateCurrentUser = async (req, res) => {
  try {
    // Get data to update
    const { name, profilePicture, contactInfo } = req.body

    // Check if user exists
    const user = await User.findById(req.user.id)

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    // Update fields
    if (name) user.name = name
    if (profilePicture !== undefined) user.profilePicture = profilePicture

    // Update contactInfo if provided
    if (contactInfo) {
      user.contactInfo = {
        ...user.contactInfo,
        ...contactInfo,
      }
    }

    await user.save()

    // Return updated user
    const updatedUser = await User.findById(req.user.id).select("-password")

    res.status(200).json({
      success: true,
      data: {
        user: updatedUser,
      },
    })
  } catch (error) {
    console.error("Error in updateCurrentUser:", error)
    res.status(500).json({
      success: false,
      message: "Error updating user profile",
    })
  }
}

/**
 * Search users by email
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.searchUsersByEmail = async (req, res) => {
  try {
    const { email } = req.query

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required for search",
      })
    }

    // Find users whose email contains the search string (case insensitive)
    const users = await User.find({
      email: { $regex: email, $options: "i" },
    })
      .select("-password")
      .limit(10)

    // Don't include the current user in the results
    const filteredUsers = users.filter((user) => user._id.toString() !== req.user.id)

    res.status(200).json({
      success: true,
      data: { users: filteredUsers },
    })
  } catch (error) {
    console.error(`Error searching users by email: ${error.message}`)
    res.status(500).json({
      success: false,
      message: "Error searching users",
    })
  }
}
