import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/models/notification.dart';
import 'package:frontend/core/theme/app_colors.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: notification.isRead
            ? null
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundImage: (notification.senderProfilePicture != null &&
                    notification.senderProfilePicture!.isNotEmpty &&
                    notification.senderProfilePicture!.startsWith('http'))
                ? NetworkImage(notification.senderProfilePicture!)
                : null,
            child: (notification.senderProfilePicture == null ||
                    notification.senderProfilePicture!.isEmpty ||
                    !notification.senderProfilePicture!.startsWith('http'))
                ? Icon(
                    _getIconForNotificationType(notification),
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
          title: Text(
            notification.message,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            _formatTimeAgo(notification.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }

  IconData _getIconForNotificationType(NotificationModel notification) {
    if (notification.relatedItem == null) {
      return Icons.notifications;
    }

    switch (notification.relatedItem!.itemType) {
      case 'Project':
        return Icons.folder;
      case 'Board':
        return Icons.dashboard;
      case 'Task':
        return Icons.task_alt;
      case 'Subtask':
        return Icons.check_circle;
      case 'User':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
