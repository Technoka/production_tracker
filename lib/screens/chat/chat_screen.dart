import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/message_bubble_widget.dart';
import '../../widgets/message_input_widget.dart';
import '../../widgets/message_search_delegate.dart';

/// Pantalla de chat reutilizable para lotes, proyectos y productos
class ChatScreen extends StatefulWidget {
  final String organizationId;
  final String entityType; // "batch", "project", "product"
  final String entityId;
  final String entityName;
  final bool showInternalMessages;

  const ChatScreen({
    Key? key,
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    this.showInternalMessages = true,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  UserModel? _currentUser;
  MessageModel? _replyingTo;
  bool _isLoading = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _scrollController.addListener(_onScroll);
    
    // Marcar mensajes como leídos al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Mostrar botón de scroll to bottom si no está en el final
    final showButton = _scrollController.offset > 500;
    if (showButton != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showButton);
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getUserData();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_currentUser == null) return;

    await _messageService.markAllAsRead(
      organizationId: widget.organizationId,
      entityType: widget.entityType,
      entityId: widget.entityId,
      userId: _currentUser!.uid,
    );
  }

  Future<void> _sendMessage(
    String content,
    List<String> mentions,
    bool isInternal,
  ) async {
    if (_currentUser == null || content.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _messageService.sendMessage(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        content: content,
        currentUser: _currentUser!,
        mentions: mentions,
        isInternal: isInternal,
        parentMessageId: _replyingTo?.id,
      );

      // Limpiar respuesta
      setState(() => _replyingTo = null);

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      _showError('Error al enviar mensaje: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleMessageLongPress(MessageModel message) {
    if (_currentUser == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildMessageActions(message),
    );
  }

  Widget _buildMessageActions(MessageModel message) {
    final canEdit = message.canEdit(_currentUser!.uid);
    final canDelete = message.canDelete(_currentUser!.uid, _currentUser!.role == 'admin');

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Responder
          if (!message.isSystemGenerated)
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = message);
              },
            ),

          // Reaccionar
          if (!message.isSystemGenerated)
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('Reaccionar'),
              onTap: () {
                Navigator.pop(context);
                EmojiReactionPicker.show(context, (emoji) {
                  _addReaction(message, emoji);
                });
              },
            ),

          // Copiar
          if (!message.isSystemGenerated)
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar copiar al portapapeles
                _showSuccess('Texto copiado');
              },
            ),

          // Fijar/Desfijar
          if (!message.isSystemGenerated)
            ListTile(
              leading: Icon(message.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(message.isPinned ? 'Desfijar' : 'Fijar'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(message);
              },
            ),

          // Editar
          if (canEdit)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(message);
              },
            ),

          // Eliminar
          if (canDelete)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(message);
              },
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _addReaction(MessageModel message, String emoji) async {
    if (_currentUser == null) return;

    try {
      // Verificar si el usuario ya reaccionó con este emoji
      final hasReacted = message.reactions.any(
        (r) => r.userId == _currentUser!.uid && r.emoji == emoji,
      );

      if (hasReacted) {
        // Quitar reacción
        await _messageService.removeReaction(
          organizationId: widget.organizationId,
          entityType: widget.entityType,
          entityId: widget.entityId,
          messageId: message.id,
          emoji: emoji,
          userId: _currentUser!.uid,
        );
      } else {
        // Añadir reacción
        await _messageService.addReaction(
          organizationId: widget.organizationId,
          entityType: widget.entityType,
          entityId: widget.entityId,
          messageId: message.id,
          emoji: emoji,
          user: _currentUser!,
        );
      }
    } catch (e) {
      _showError('Error al reaccionar: $e');
    }
  }

  Future<void> _togglePin(MessageModel message) async {
    try {
      await _messageService.togglePin(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        messageId: message.id,
        isPinned: !message.isPinned,
      );
      _showSuccess(message.isPinned ? 'Mensaje desfijado' : 'Mensaje fijado');
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showEditDialog(MessageModel message) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nuevo contenido...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty || newContent == message.content) {
                Navigator.pop(context);
                return;
              }

              try {
                await _messageService.editMessage(
                  organizationId: widget.organizationId,
                  entityType: widget.entityType,
                  entityId: widget.entityId,
                  messageId: message.id,
                  newContent: newContent,
                );
                Navigator.pop(context);
                _showSuccess('Mensaje editado');
              } catch (e) {
                _showError('Error al editar: $e');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Estás seguro de que quieres eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _messageService.deleteMessage(
                  organizationId: widget.organizationId,
                  entityType: widget.entityType,
                  entityId: widget.entityId,
                  messageId: message.id,
                );
                Navigator.pop(context);
                _showSuccess('Mensaje eliminado');
              } catch (e) {
                _showError('Error al eliminar: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.entityName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Mensajes fijados
          _buildPinnedMessages(),

          // Lista de mensajes
          Expanded(child: _buildMessagesList()),

          // Input de mensaje
          MessageInput(
            onSend: _sendMessage,
            replyingTo: _replyingTo,
            onCancelReply: () => setState(() => _replyingTo = null),
            showInternalToggle: widget.showInternalMessages,
            isLoading: _isLoading,
          ),
        ],
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.entityName),
          Text(
            _getEntityTypeLabel(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
      actions: [
        // Buscar
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () async {
            final result = await showSearch(
              context: context,
              delegate: MessageSearchDelegate(
                organizationId: widget.organizationId,
                entityType: widget.entityType,
                entityId: widget.entityId,
                currentUser: _currentUser!,
              ),
            );

            // Si se seleccionó un mensaje, scroll hacia él
            if (result != null) {
              // TODO: Implementar scroll to message
              _showSuccess('Mensaje encontrado');
            }
          },
          tooltip: l10n.search,
        ),
        // Más opciones
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'info',
              child: Text(l10n.chatInfo),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Text('Silenciar'), // TODO: Add to l10n
            ),
            PopupMenuItem(
              value: 'pinned',
              child: Text(l10n.pinnedMessages),
            ),
          ],
          onSelected: (value) {
            if (value == 'pinned') {
              _showPinnedMessages();
            }
          },
        ),
      ],
    );
  }

  /// Obtener label del tipo de entidad
  String _getEntityTypeLabel() {
    switch (widget.entityType) {
      case 'batch':
        return 'Chat del lote';
      case 'project':
        return 'Chat del proyecto';
      case 'product':
        return 'Chat del producto';
      default:
        return 'Chat';
    }
  }

  /// Mostrar diálogo con mensajes fijados
  void _showPinnedMessages() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return StreamBuilder<List<MessageModel>>(
            stream: _messageService.getPinnedMessages(
              organizationId: widget.organizationId,
              entityType: widget.entityType,
              entityId: widget.entityId,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.push_pin, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay mensajes fijados',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final pinnedMessages = snapshot.data!;

              return Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pinnedMessages,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${pinnedMessages.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Lista de mensajes fijados
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: pinnedMessages.length,
                      itemBuilder: (context, index) {
                        final message = pinnedMessages[index];
                        return MessageBubble(
                          message: message,
                          currentUser: _currentUser!,
                          onLongPress: () {
                            Navigator.pop(context);
                            _handleMessageLongPress(message);
                          },
                          onReactionTap: (emoji) => _addReaction(message, emoji),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPinnedMessages() {
    return StreamBuilder<List<MessageModel>>(
      stream: _messageService.getPinnedMessages(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final pinnedMessages = snapshot.data!;

        return Container(
          color: Colors.blue[50],
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.push_pin, size: 16, color: Colors.blue[900]),
                  const SizedBox(width: 8),
                  Text(
                    'Mensajes fijados (${pinnedMessages.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...pinnedMessages.take(2).map((message) => _buildPinnedMessagePreview(message)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinnedMessagePreview(MessageModel message) {
    return InkWell(
      onTap: () {
        // TODO: Scroll to pinned message
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          message.content,
          style: TextStyle(fontSize: 13, color: Colors.blue[800]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _messageService.getMessages(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        includeInternal: widget.showInternalMessages,
        limit: 100,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final messages = snapshot.data!;

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];

            return MessageBubble(
              message: message,
              currentUser: _currentUser!,
              onLongPress: () => _handleMessageLongPress(message),
              onReactionTap: (emoji) => _addReaction(message, emoji),
              onReply: message.threadCount > 0
                  ? () => setState(() => _replyingTo = message)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay mensajes aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sé el primero en enviar un mensaje',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}