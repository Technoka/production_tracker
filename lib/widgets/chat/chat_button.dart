import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../../screens/chat/chat_screen.dart';

/// Widget de botón de chat con badge reutilizable
/// Funciona para batch, project, product
class ChatButton extends StatelessWidget {
  final String organizationId;
  final String entityType; // 'batch', 'project', 'product'
  final String entityId;
  final String entityName;
  final String? parentId;
  final UserModel user;
  final bool showInAppBar; // Si es true, es un IconButton, si no, FloatingActionButton

  const ChatButton({
    Key? key,
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    this.parentId,
    required this.user,
    this.showInAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageService = MessageService();

    return StreamBuilder<int>(
      stream: messageService.getUnreadCount(
        organizationId: organizationId,
        entityType: entityType,
        entityId: entityId,
        parentId: parentId,
        userId: user.uid,
      ),
      builder: (context, unreadSnapshot) {
        final unreadCount = unreadSnapshot.data ?? 0;

        if (showInAppBar) {
          return _buildAppBarButton(context, unreadCount);
        } else {
          return _buildFloatingButton(context, unreadCount);
        }
      },
    );
  }

  Widget _buildAppBarButton(BuildContext context, int unreadCount) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => _openChat(context),
          tooltip: 'Chat',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingButton(BuildContext context, int unreadCount) {
    return Stack(
      children: [
        FloatingActionButton(
          heroTag: 'chat_fab_${entityId}',
          onPressed: () => _openChat(context),
          backgroundColor: Colors.blue[700],
          child: const Icon(Icons.chat),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          organizationId: organizationId,
          entityType: entityType,
          entityId: entityId,
          entityName: entityName,
          parentId: parentId,
          showInternalMessages: true,
        ),
      ),
    );
  }
}