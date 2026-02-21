import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:gestion_produccion/services/organization_member_service.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:gestion_produccion/utils/error_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/chat/message_bubble_widget.dart';
import '../../widgets/chat/message_input_widget.dart';
import '../../widgets/chat/message_search_delegate.dart';
import 'package:provider/provider.dart';
import '../../widgets/error_display_widget.dart';
import 'dart:async';

/// Pantalla de chat reutilizable para lotes, proyectos y productos
class ChatScreen extends StatefulWidget {
  final String organizationId;
  final String entityType; // "batch", "project", "product"
  final String entityId;
  final String entityName;
  final String? parentId;
  final bool showInternalMessages;
  final bool canSendMessages;

  const ChatScreen({
    Key? key,
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    this.parentId,
    this.showInternalMessages = true,
    this.canSendMessages = true,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inputKey = GlobalKey(); // AGREGAR
  double _inputHeight = 150; // AGREGAR: altura por defecto

  Stream<List<MessageModel>>? _messagesStream;
  int _messagesLimit = 100;

  UserModel? _currentUser;
  MessageModel? _replyingTo;
  bool _isLoading = false;
  bool _showScrollToBottom = false;
  bool _isUserClient = false;
  bool _isCheckingRole = true;

  // Scroll to message
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final Map<String, GlobalKey> _messageKeys = {};

  // Tiempo máximo para considerar mensajes consecutivos (5 minutos)
  static const Duration _consecutiveMessageThreshold = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _scrollController.addListener(_onScroll);
    _setupStream();

    // Marcar mensajes como leídos al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _setupStream() {
    // Calculamos si mostramos internos basándonos en el estado ACTUAL
    final showInternal = !_isUserClient && widget.showInternalMessages;

    _messagesStream = _messageService.getMessages(
      organizationId: widget.organizationId,
      entityType: widget.entityType,
      entityId: widget.entityId,
      parentId: widget.parentId,
      includeInternal: showInternal,
      limit: _messagesLimit,
    );
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

      // Verificar si el usuario es cliente
      if (user != null) {
        _checkUserRole();
      }
    }
  }

  /// Verificar si el usuario actual es cliente
  Future<void> _checkUserRole() async {
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);

    if (_currentUser == null) return;

    final isClient = memberService.currentMember!.isClient;

    if (mounted) {
      setState(() {
        _isUserClient = isClient;
        _isCheckingRole = false;
        _setupStream();
      });
    }
  }

  void _markAsRead() {
    final user =
        Provider.of<AuthService>(context, listen: false).currentUserData;

    if (user != null) {
      Provider.of<MessageService>(context, listen: false).markMessagesAsRead(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        parentId: widget.parentId,
        userId: user.uid,
      );
    }
  }

  Future<void> _sendMessage(
    String content,
    List<String> mentions,
    bool isInternal,
  ) async {
    if (_currentUser == null || content.trim().isEmpty) return;

    // Los clientes no pueden enviar mensajes internos
    final finalIsInternal = _isUserClient ? false : isInternal;

    // No usar setState aquí para evitar rebuild durante el envío
    // Solo marcar como loading internamente
    _isLoading = true;

    try {
      await _messageService.sendMessage(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        parentId: widget.parentId,
        content: content,
        currentUser: _currentUser!,
        mentions: mentions,
        isInternal: finalIsInternal,
        parentMessageId: _replyingTo?.id,
      );

      // Limpiar respuesta solo si está montado
      if (mounted) {
        setState(() => _replyingTo = null);
      }

      // Scroll to bottom suavemente
      _scrollToBottom();
    } catch (e) {
      if (mounted) AppErrorSnackBar.show(context, ErrorHandler.from(e));
    } finally {
      _isLoading = false;
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
    final l10n = AppLocalizations.of(context)!;
    final canEdit = message.canEdit(_currentUser!.uid);
    final canDelete = message.canDelete(_currentUser!.uid, false);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Responder
          ListTile(
            leading: const Icon(Icons.reply),
            title: Text(l10n.answer),
            onTap: () {
              Navigator.pop(context);
              setState(() => _replyingTo = message);
            },
          ),

          // Reaccionar
          if (!message.isSystemGenerated) ...[
            Builder(builder: (context) {
              final existingReaction = message.reactions
                  .where((r) => r.userId == _currentUser!.uid)
                  .firstOrNull;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_reaction),
                    title: Text(existingReaction != null
                        ? '${l10n.react} (${l10n.change}: ${existingReaction.emoji})'
                        : l10n.react),
                    onTap: () {
                      Navigator.pop(context);
                      EmojiReactionPicker.show(context, (emoji) {
                        _addReaction(message, emoji);
                      });
                    },
                  ),
                  if (existingReaction != null)
                    ListTile(
                      leading: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      title: Text(l10n.removeReaction,
                          style: const TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        _addReaction(
                            message, existingReaction.emoji); // toggle → quita
                      },
                    ),
                ],
              );
            }),
          ],
          // Copiar
          if (!message.isSystemGenerated)
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.copy),
              onTap: () async {
                // 1. Marca como async
                Navigator.pop(context);

                // 2. Implementación de copiar
                await Clipboard.setData(ClipboardData(text: message.content));

                // 3. Feedback (asumiendo que tienes esta función)
                _showSuccess(l10n.textCopied);
              },
            ),

          // Editar (solo si puede)
          if (canEdit)
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(message);
              },
            ),

          // Fijar/Desfijar
          ListTile(
            leading: Icon(
                message.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(message.isPinned ? l10n.unpin : l10n.pin),
            onTap: () {
              Navigator.pop(context);
              _togglePin(message);
            },
          ),

          // Eliminar (solo si puede)
          if (canDelete)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(message);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _addReaction(MessageModel message, String emoji) async {
    try {
      await _messageService.toggleReaction(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        parentId: widget.parentId,
        messageId: message.id,
        emoji: emoji,
        user: _currentUser!,
      );
    } catch (e) {
      if (mounted) AppErrorSnackBar.show(context, ErrorHandler.from(e));
    }
  }

  Future<void> _togglePin(MessageModel message) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await _messageService.togglePin(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        parentId: widget.parentId,
        messageId: message.id,
        isPinned: !message.isPinned,
      );
      _showSuccess(
          message.isPinned ? l10n.messageUnpinned : l10n.messagePinned);
    } catch (e) {
      if (mounted) AppErrorSnackBar.show(context, ErrorHandler.from(e));
    }
  }

  void _showEditDialog(MessageModel message) {
    final l10n = AppLocalizations.of(context)!;

    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editMessage),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.newContentHint,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
                  parentId: widget.parentId,
                  messageId: message.id,
                  newContent: newContent,
                );
                if (context.mounted) Navigator.pop(context);
                _showSuccess(l10n.messageEdited);
              } catch (e) {
                if (context.mounted)
                  AppErrorSnackBar.show(context, ErrorHandler.from(e));
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MessageModel message) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMessage),
        content: Text(l10n.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _messageService.deleteMessage(
                  organizationId: widget.organizationId,
                  entityType: widget.entityType,
                  entityId: widget.entityId,
                  parentId: widget.parentId,
                  messageId: message.id,
                );
                if (context.mounted) Navigator.pop(context);
                _showSuccess(l10n.messageDeleted);
              } catch (e) {
                if (context.mounted)
                  AppErrorSnackBar.show(context, ErrorHandler.from(e));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _isCheckingRole) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.entityName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determinar si mostrar mensajes internos
    // Los clientes NO ven mensajes internos
    final effectiveShowInternal = !_isUserClient && widget.showInternalMessages;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Container(
          // Limitar ancho máximo en web a 1000px
          constraints: kIsWeb
              ? const BoxConstraints(maxWidth: 1000)
              : const BoxConstraints(),
          child: Stack(
            // CAMBIAR: Column a Stack
            children: [
              Column(
                children: [
                  // Mensajes fijados
                  _buildPinnedMessages(),

                  // Lista de mensajes
                  Expanded(child: _buildMessagesList(effectiveShowInternal)),

                  _buildMessageInputWithKey(),
                ],
              ),

              // AGREGAR: Botón flotante encima del MessageInput
              if (_showScrollToBottom)
                Positioned(
                  bottom: _inputHeight + 20, // Encima del input
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _scrollToBottom,
                    backgroundColor: Colors.green,
                    child:
                        const Icon(Icons.arrow_downward, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
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
            _getEntityTypeLabel(l10n),
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
                parentId: widget.parentId,
                currentUser: _currentUser!,
              ),
            );

            // Si se seleccionó un mensaje, scroll hacia él
            if (result != null) {
              _scrollToMessage(result.id);
            }
          },
          tooltip: l10n.search,
        ),
        // Más opciones
        PopupMenuButton(
          itemBuilder: (context) => [
            // TODO: descomentar cuando este implementado o haya algo que mostrar
            // PopupMenuItem(
            //   value: 'info',
            //   child: Text(l10n.chatInfo),
            // ),
            // PopupMenuItem(
            //   value: 'mute',
            //   child: Text(l10n.mute)
            // ),
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
  String _getEntityTypeLabel(AppLocalizations l10n) {
    switch (widget.entityType) {
      case 'batch':
        return l10n.batchChat;
      case 'project':
        return l10n.projectChat;
      case 'product':
        return l10n.productChat;
      default:
        return l10n.chat;
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
      builder: (context) {
        return StreamBuilder<List<MessageModel>>(
          stream: _messageService.getPinnedMessages(
            organizationId: widget.organizationId,
            entityType: widget.entityType,
            entityId: widget.entityId,
            parentId: widget.parentId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pinnedMessages = snapshot.data!;

            if (pinnedMessages.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noPinnedMessages,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.push_pin, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            l10n.pinnedMessages,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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
                            // onReactionTap: (emoji) =>
                            //     _addReaction(message, emoji),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPinnedMessages() {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<MessageModel>>(
      stream: _messageService.getPinnedMessages(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        parentId: widget.parentId,
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
                    '${l10n.pinnedMessages}: (${pinnedMessages.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...pinnedMessages
                  .take(2)
                  .map((message) => _buildPinnedMessagePreview(message)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinnedMessagePreview(MessageModel message) {
    return InkWell(
      onTap: () {
        // TODO: scrollear al mensaje fijado al hacer click
        Navigator.pop(context); // cerrar el bottom sheet primero
        _scrollToMessage(message.id);
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

  Widget _buildMessagesList(bool showInternalMessages) {
    return StreamBuilder<List<MessageModel>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ MEJORA: Solo mostramos carga si NO hay datos previos.
        // Esto evita que parpadee si la conexión se refresca pero ya teníamos mensajes.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
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

            // Determinar si debe mostrar avatar y nombre
            final shouldShowAvatar = _shouldShowAvatar(messages, index);
            final shouldShowAuthorName = shouldShowAvatar;

            final key = _messageKeys.putIfAbsent(
              message.id,
              () => GlobalKey(),
            );

            return MessageBubble(
              key: key,
              message: message,
              currentUser: _currentUser!,
              showAvatar: shouldShowAvatar,
              showAuthorName: shouldShowAuthorName,
              isHighlighted: _highlightedMessageId == message.id,
              onLongPress: () => _handleMessageLongPress(message),
              // onReactionTap: (emoji) => _addReaction(message, emoji),
              onReply: message.threadCount > 0 ? () {/* TODO: thread */} : null,
            );
          },
        );
      },
    );
  }

  /// Determinar si debe mostrar avatar basado en mensajes consecutivos
  /// Un mensaje debe mostrar avatar si:
  /// 1. Es el primer mensaje de la lista
  /// 2. El mensaje anterior es de otro usuario
  /// 3. Han pasado más de 5 minutos desde el mensaje anterior del mismo usuario
  bool _shouldShowAvatar(List<MessageModel> messages, int index) {
    // Siempre mostrar avatar para mensajes del sistema
    if (messages[index].isSystemGenerated) return true;

    // Siempre mostrar avatar para el último mensaje (primero en la lista reversa)
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    // Mostrar si el autor es diferente
    if (currentMessage.authorId != previousMessage.authorId) return true;

    // Mostrar si el mensaje anterior es del sistema
    if (previousMessage.isSystemGenerated) return true;

    // Mostrar si han pasado más de 5 minutos
    final timeDifference =
        previousMessage.createdAt.difference(currentMessage.createdAt);
    if (timeDifference.abs() > _consecutiveMessageThreshold) return true;

    // No mostrar avatar (mensajes consecutivos del mismo usuario)
    return false;
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noMessagesYet,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beFirstToMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputWithKey() {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final canSendMessages = permissionService.canSendMessages;

    // Medir la altura del input después de construir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _inputKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && mounted) {
        final newHeight = renderBox.size.height;
        if (newHeight != _inputHeight) {
          setState(() {
            _inputHeight = newHeight;
          });
        }
      }
    });

    return Container(
      key: _inputKey,
      child: MessageInput(
        onSend: _sendMessage,
        replyingTo: _replyingTo,
        onCancelReply: () => setState(() => _replyingTo = null),
        showInternalToggle: !_isUserClient && widget.showInternalMessages,
        isLoading: _isLoading,
        canSend: canSendMessages,
      ),
    );
  }

  Future<void> _scrollToMessage(String messageId) async {
    setState(() => _highlightedMessageId = messageId);

    // Cancelar cualquier highlight pendiente previo
    _highlightTimer?.cancel();

    final success = await _attemptScrollToMessage(messageId);

    if (!success) {
      // Intentar ampliar límite y reintentar
      try {
        final offset = await _messageService.getMessageOffset(
          organizationId: widget.organizationId,
          entityType: widget.entityType,
          entityId: widget.entityId,
          parentId: widget.parentId,
          targetMessageId: messageId,
          includeInternal: !_isUserClient && widget.showInternalMessages,
        );

        final neededLimit = offset + 20;
        if (neededLimit > _messagesLimit) {
          setState(() {
            _messagesLimit = neededLimit;
            _setupStream();
          });
          // Esperar a que ListView renderice los nuevos items
          await Future.delayed(const Duration(milliseconds: 800));
        }

        // Segundo intento con retries
        await _retryScrollToMessage(messageId);
      } catch (e) {
        debugPrint('Error scrolling to message: $e');
      }
    }

    // Siempre limpiar el highlight después de 2s, pase lo que pase
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  /// Intenta hacer scroll. Devuelve true si tuvo éxito.
  Future<bool> _attemptScrollToMessage(String messageId) async {
    final key = _messageKeys[messageId];
    if (key == null) return false;

    // Esperar un frame para que el context esté disponible
    final completer = Completer<bool>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final context = key.currentContext;
        if (context == null) {
          completer.complete(false);
          return;
        }
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
        completer.complete(true);
      } catch (e) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Reintenta el scroll hasta 5 veces con delay entre intentos.
  Future<void> _retryScrollToMessage(String messageId,
      {int maxRetries = 10}) async {
    for (int i = 0; i < maxRetries; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      final success = await _attemptScrollToMessage(messageId);
      if (success) return;
    }
    debugPrint(
        '⚠️ Could not scroll to message $messageId after $maxRetries retries');
  }
}
