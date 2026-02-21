import 'package:flutter/material.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/notification_model.dart';
import 'approval_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final permissionService = Provider.of<PermissionService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    final user = authService.currentUserData;
    final organizationId = user?.organizationId;

    if (user == null || organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notifications)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canApproveClientRequests = permissionService.canApproveClientRequests;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: l10n.markAllAsRead,
            onPressed: () async {
              await notificationService.markAllAsRead(organizationId, user.uid);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getUserNotificationsStream(
          organizationId,
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noNotifications,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification.isReadBy(user.uid);

              // Determinar si el usuario es el solicitante de esta notificación
              final bool isRequesterNotif =
                  notification.type == NotificationType.approvalRequest &&
                      notification.isRequesterFor(user.uid);

              // Usar icono y color diferenciado para el solicitante
              final IconData displayIcon = isRequesterNotif
                  ? Icons.hourglass_empty
                  : notification.type.icon;
              final Color displayColor =
                  isRequesterNotif ? Colors.amber : notification.type.color;

              return Card(
                elevation: isRead ? 0 : 2,
                margin: const EdgeInsets.only(bottom: 12),
                color: isRead ? null : Colors.blue.shade50,
                child: InkWell(
                  onTap: () async {
                    // Marcar como leída
                    if (!isRead) {
                      await notificationService.markAsRead(
                        organizationId,
                        notification.id,
                        user.uid,
                      );
                    }

                    // Navegar según tipo
                    if (notification.type == NotificationType.approvalRequest) {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApprovalDetailScreen(
                              notificationId: notification.id,
                              pendingObjectId: notification
                                  .metadata['pendingObjectId'] as String,
                              readOnly: !canApproveClientRequests,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: notification.type.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            displayIcon,
                            color: displayColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
