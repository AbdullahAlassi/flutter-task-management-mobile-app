import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/providers/theme_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/profile/edit_profile_screen.dart';
import 'package:frontend/widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  user.profilePicture != null
                      ? NetworkImage(user.profilePicture!)
                      : null,
              child:
                  user.profilePicture == null
                      ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36),
                      )
                      : null,
            ),
            const SizedBox(height: 16),
            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            const SizedBox(height: 32),
            _buildProfileItem(
              context,
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                // Navigate to change password screen
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.notifications,
              title: 'Notification Settings',
              onTap: () {
                // Navigate to notification settings screen
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // Navigate to help & support screen
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                // Navigate to about screen
              },
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Logout',
              isOutlined: true,
              textColor: Theme.of(context).colorScheme.error,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
