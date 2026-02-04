import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

/// Widget de burbuja de mensaje reutilizable
/// Soporta mensajes de usuario y eventos del sistema
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel currentUser;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onReply;
  final bool showAvatar;
  final bool showTimestamp;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.currentUser,
    this.onTap,
    this.onLongPress,
    this.onReactionTap,
    this.onReply,
    this.showAvatar = true,
    this.showTimestamp = true,
  }) : super(key: key);

  bool get isOwnMessage => message.authorId == currentUser.uid;

  @override
  Widget build(BuildContext context) {
    // Eventos del sistema tienen diseño diferente
    if (message.isSystemGenerated) {
      return _buildSystemEvent(context);
    }

    return _buildUserMessage(context);
  }

  /// Mensaje de usuario normal
  Widget _buildUserMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar (izquierda para otros, oculto para propios)
          if (!isOwnMessage && showAvatar) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],

          // Contenido del mensaje
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isOwnMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Nombre del autor (solo si no es propio)
                  if (!isOwnMessage)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 2),
                      child: Text(
                        message.authorName ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),

                  // Burbuja del mensaje
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isOwnMessage
                          ? Colors.blue
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Respuesta a otro mensaje
                        if (message.parentMessageId != null)
                          _buildReplyPreview(context),

                        // Contenido del texto
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isOwnMessage ? Colors.white : Colors.black87,
                          ),
                        ),

                        // Adjuntos
                        if (message.attachments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...message.attachments.map(_buildAttachment),
                        ],

                        // Timestamp y estado
                        if (showTimestamp) ...[
                          const SizedBox(height: 4),
                          _buildTimestamp(context),
                        ],
                      ],
                    ),
                  ),

                  // Reacciones
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildReactions(context),
                  ],

                  // Badge de mensaje interno
                  if (message.isInternal) ...[
                    const SizedBox(height: 4),
                    _buildInternalBadge(context),
                  ],

                  // Badge de mensaje fijado
                  if (message.isPinned) ...[
                    const SizedBox(height: 4),
                    _buildPinnedBadge(context),
                  ],

                  // Badge de respuestas en el thread
                  if (message.threadCount > 0) ...[
                    const SizedBox(height: 4),
                    _buildThreadBadge(context),
                  ],
                ],
              ),
            ),
          ),

          // Avatar (derecha para propios)
          if (isOwnMessage && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  /// Evento del sistema
  Widget _buildSystemEvent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  // Icono del evento
                  Text(
                    SystemEventType.getEventIcon(message.eventType ?? ''),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),

                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (showTimestamp) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar del usuario
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage: message.authorAvatar != null
          ? NetworkImage(message.authorAvatar!)
          : null,
      child: message.authorAvatar == null
          ? Text(
              message.authorName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  /// Preview de respuesta
  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isOwnMessage ? Colors.white.withOpacity(0.2) : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOwnMessage ? Colors.white.withOpacity(0.3) : Colors.grey[400]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: isOwnMessage ? Colors.white70 : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Respondiendo a un mensaje',
              style: TextStyle(
                fontSize: 12,
                color: isOwnMessage ? Colors.white70 : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Adjunto
  Widget _buildAttachment(MessageAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOwnMessage ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            attachment.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isOwnMessage ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.formattedSize,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOwnMessage ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Timestamp y estado de lectura
  Widget _buildTimestamp(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimestamp(message.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: isOwnMessage ? Colors.white70 : Colors.grey[600],
          ),
        ),
        if (message.editedAt != null) ...[
          const SizedBox(width: 4),
          Text(
            '(editado)',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isOwnMessage ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
        if (isOwnMessage && message.readBy.length > 1) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.done_all,
            size: 14,
            color: Colors.white70,
          ),
        ],
      ],
    );
  }

  /// Reacciones agrupadas
  Widget _buildReactions(BuildContext context) {
    // Agrupar reacciones por emoji
    final groupedReactions = <String, List<MessageReaction>>{};
    for (var reaction in message.reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Wrap(
      spacing: 4,
      children: groupedReactions.entries.map((entry) {
        final emoji = entry.key;
        final reactions = entry.value;
        final hasUserReacted = reactions.any((r) => r.userId == currentUser.uid);

        return GestureDetector(
          onTap: () => onReactionTap?.call(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasUserReacted
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasUserReacted
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                  '${reactions.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasUserReacted
                        ? Theme.of(context).primaryColor
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Badge de mensaje interno
  Widget _buildInternalBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 12, color: Colors.orange[900]),
          const SizedBox(width: 4),
          Text(
            'Interno',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de mensaje fijado
  Widget _buildPinnedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.push_pin, size: 12, color: Colors.blue[900]),
          const SizedBox(width: 4),
          Text(
            'Fijado',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de thread con respuestas
  Widget _buildThreadBadge(BuildContext context) {
    return GestureDetector(
      onTap: onReply,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum, size: 12, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              '${message.threadCount} ${message.threadCount == 1 ? 'respuesta' : 'respuestas'}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formatear timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Hoy: mostrar solo hora
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Ayer
      return 'Ayer ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      // Esta semana: mostrar día
      return DateFormat('EEEE HH:mm', 'es').format(timestamp);
    } else {
      // Más antiguo: fecha completa
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
  }
}