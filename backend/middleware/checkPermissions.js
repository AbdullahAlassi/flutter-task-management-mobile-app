const rolePermissions = require('../utils/permissions');

const checkPermissions = (requiredPermission) => {
  return (req, res, next) => {
    const { project } = req;
    const { userId } = req.user;

    const member = project.members.find(m => m.userId.toString() === userId);
    if (!member) {
      return res.status(403).json({ message: 'User is not a member of this project.' });
    }

    const permissions = rolePermissions[member.role];
    if (!permissions || !permissions.includes(requiredPermission)) {
      return res.status(403).json({ message: 'User does not have the required permission.' });
    }

    next();
  };
};

module.exports = checkPermissions; 