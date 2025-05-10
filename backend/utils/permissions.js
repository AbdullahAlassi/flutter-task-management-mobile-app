const rolePermissions = {
  owner: ['create', 'edit', 'delete', 'assign_roles', 'invite_members', 'view', 'move_own_tasks', 'assign_members', 'manage_boards', 'manage_tasks', 'manage_subtasks', 'manage_members', 'manage_project'],
  admin: ['create', 'edit', 'invite_members', 'view', 'move_own_tasks', 'assign_members', 'manage_boards', 'manage_tasks', 'manage_subtasks'],
  member: ['create', 'edit_own', 'view', 'move_own_tasks'],
  viewer: ['view']
};

// Role mapping to standardize role names
const roleMapping = {
  'Admin': 'admin',
  'Team Member': 'member',
  'Member': 'member',
  'Viewer': 'viewer',
  'Owner': 'owner'
};

// Helper function to standardize role names
const standardizeRole = (role) => {
  if (!role) return 'viewer';
  const normalizedRole = roleMapping[role] || role.toLowerCase();
  return normalizedRole;
};

module.exports = {
  rolePermissions,
  roleMapping,
  standardizeRole
}; 