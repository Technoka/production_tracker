import 'package:flutter/material.dart';
import 'package:gestion_produccion/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/user_cache_service.dart';
import '../../utils/ui_constants.dart';

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
  final bool showAuthorName;
  final bool? isHighlighted;

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
    this.showAuthorName = true,
    this.isHighlighted,
  }) : super(key: key);

  bool get isOwnMessage => message.authorId == currentUser.uid;

  @override
  Widget build(BuildContext context) {
    final highlighted = isHighlighted ?? false;

    // Eventos del sistema tienen diseño diferente
    if (message.isSystemGenerated) {
      final systemWidget = _buildSystemEvent(context);

      if (!highlighted) return systemWidget;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.amber.withOpacity(0.25),
        child: systemWidget,
      );
    }

    if (!highlighted) return _buildUserMessage(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: Colors.amber.withOpacity(0.25),
      child: _buildUserMessage(context),
    );
  }

  /// Mensaje de usuario normal
  Widget _buildUserMessage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: showAvatar ? 8 : 2,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alinear al fondo visualmente
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar (solo si no es propio)
          if (!isOwnMessage) ...[
            if (showAvatar)
              _buildAvatar()
            else
              // Mantiene el hueco del avatar para que el texto se alinee verticalmente bien
              const SizedBox(width: 40),
            const SizedBox(width: 8),
          ],

          // Usamos Flexible para que el mensaje se pueda encoger, pero no obligamos a expandirse
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Column(
                // Alineación INTERNA de la columna (texto y burbuja)
                crossAxisAlignment: isOwnMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Nombre del autor
                  if (!isOwnMessage && showAuthorName)
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

                  // BURBUJA DEL MENSAJE
                  Container(
                    // ⚠️ AQUÍ ESTÁ EL CONTROL DE ANCHO
                    // Usamos constraints para definir el máximo, pero el contenedor
                    // se ajustará al contenido si es más pequeño.
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isOwnMessage ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isOwnMessage
                            ? const Radius.circular(16)
                            : const Radius.circular(2),
                        bottomRight: isOwnMessage
                            ? const Radius.circular(2)
                            : const Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize
                          .min, // La columna ocupa lo mínimo necesario
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Respuesta a otro mensaje
                        if (message.parentMessageId != null)
                          _buildReplyPreview(context),

                        // Contenido del texto
                        SelectableText(
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

                        // Timestamp y ticks (Alineados al final del texto)
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Espacio flexible vacío para empujar la hora a la derecha
                            // si el texto es muy corto pero queremos la hora a la derecha de la burbuja
                            const SizedBox(width: 4),
                            _buildTimestamp(context),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reacciones, Badges, etc (fuera de la burbuja)
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
        ],
      ),
    );
  }

  /// Evento del sistema (centrado con ancho máximo 200px)
  Widget _buildSystemEvent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: UIConstants.MESSAGE_MAX_WIDTH),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono del evento
              Text(
                SystemEventType.getEventIcon(message.eventType ?? ''),
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Contenido
              SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[900],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              // Timestamp
              if (showTimestamp) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Avatar del usuario con foto actualizada de la base de datos
  Widget _buildAvatar() {
    // Si el mensaje tiene authorId, obtener la foto actual del usuario
    if (message.authorId != null) {
      return FutureBuilder<UserBasicData?>(
        future: UserCacheService().getUserBasicData(message.authorId!),
        builder: (context, snapshot) {
          final photoURL = snapshot.data?.photoURL ?? message.authorAvatar;
          final name = snapshot.data?.name ?? message.authorName ?? 'User?';

          return CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null
                ? Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  )
                : null,
          );
        },
      );
    }

    // Fallback si no hay authorId
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage: message.authorAvatar != null
          ? NetworkImage(message.authorAvatar!)
          : null,
      child: message.authorAvatar == null
          ? Text(
              message.authorName?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  /// Preview de respuesta
  Widget _buildReplyPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isOwnMessage ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.messageAnsweringTo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOwnMessage ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.originalMessage,
            style: TextStyle(
              fontSize: 13,
              color: isOwnMessage ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
    final l10n = AppLocalizations.of(context)!;

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
            '(${l10n.edited})',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isOwnMessage ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
        if (isOwnMessage && message.readBy.length > 1) ...[
          const SizedBox(width: 4),
          const Icon(
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
        final hasUserReacted =
            reactions.any((r) => r.userId == currentUser.uid);

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
    final l10n = AppLocalizations.of(context)!;

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
            l10n.internal,
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
    final l10n = AppLocalizations.of(context)!;

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
            l10n.pinned,
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
    final l10n = AppLocalizations.of(context)!;

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
              '${message.threadCount} ${message.threadCount == 1 ? l10n.answer : l10n.answerPlural}',
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
