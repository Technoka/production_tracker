import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/message_bubble_widget.dart';
import '../../widgets/message_input_widget.dart';
import '../../l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final String organizationId;
  final String entityType;
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
    AppLocalizations l10n,
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

      setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (e) {
      _showError('${l10n.sendMessageError} $e');
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

  void _handleMessageLongPress(MessageModel message, AppLocalizations l10n) {
    if (_currentUser == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildMessageActions(message, l10n),
    );
  }

  Widget _buildMessageActions(MessageModel message, AppLocalizations l10n) {
    final canEdit = message.canEdit(_currentUser!.uid);
    final canDelete = message.canDelete(_currentUser!.uid, _currentUser!.role == 'admin');

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (!message.isSystemGenerated)
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(l10n.reply),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = message);
              },
            ),

          if (!message.isSystemGenerated)
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: Text(l10n.react),
              onTap: () {
                Navigator.pop(context);
                EmojiReactionPicker.show(context, (emoji) {
                  _addReaction(message, emoji, l10n);
                });
              },
            ),

          if (!message.isSystemGenerated)
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.copy),
              onTap: () {
                Navigator.pop(context);
                _showSuccess(l10n.textCopied);
              },
            ),

          if (!message.isSystemGenerated)
            ListTile(
              leading: Icon(message.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(message.isPinned ? l10n.unpin : l10n.pin),
              onTap: () {
                Navigator.pop(context);
                _togglePin(message, l10n);
              },
            ),

          if (canEdit)
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.editMessage),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(message, l10n);
              },
            ),

          if (canDelete)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.deleteMessage, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(message, l10n);
              },
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _addReaction(MessageModel message, String emoji, AppLocalizations l10n) async {
    if (_currentUser == null) return;

    try {
      final hasReacted = message.reactions.any(
        (r) => r.userId == _currentUser!.uid && r.emoji == emoji,
      );

      if (hasReacted) {
        await _messageService.removeReaction(
          organizationId: widget.organizationId,
          entityType: widget.entityType,
          entityId: widget.entityId,
          messageId: message.id,
          emoji: emoji,
          userId: _currentUser!.uid,
        );
      } else {
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
      _showError('${l10n.reactionError} $e');
    }
  }

  Future<void> _togglePin(MessageModel message, AppLocalizations l10n) async {
    try {
      await _messageService.togglePin(
        organizationId: widget.organizationId,
        entityType: widget.entityType,
        entityId: widget.entityId,
        messageId: message.id,
        isPinned: !message.isPinned,
      );
      _showSuccess(message.isPinned ? l10n.messageUnpinned : l10n.messagePinned);
    } catch (e) {
      _showError('${l10n.error}: $e');
    }
  }

  void _showEditDialog(MessageModel message, AppLocalizations l10n) {
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
            border: const OutlineInputBorder(),
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
                  messageId: message.id,
                  newContent: newContent,
                );
                Navigator.pop(context);
                _showSuccess(l10n.messageEdited);
              } catch (e) {
                _showError('${l10n.editError} $e');
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MessageModel message, AppLocalizations l10n) {
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
                  messageId: message.id,
                );
                Navigator.pop(context);
                _showSuccess(l10n.messageDeleted);
              } catch (e) {
                _showError('${l10n.deleteError} $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.entityName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          _buildPinnedMessages(l10n),
          Expanded(child: _buildMessagesList(l10n)),
          MessageInput(
            onSend: (content, mentions, isInternal) => _sendMessage(content, mentions, isInternal, l10n),
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

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.entityName),
          Text(
            'Chat', // Podrías usar l10n.chat si existe
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
             PopupMenuItem(
              value: 'info',
              child: Text(l10n.chatInfo),
            ),
             PopupMenuItem(
              value: 'mute',
              child: Text(l10n.muteNotifications),
            ),
          ],
          onSelected: (value) {},
        ),
      ],
    );
  }

  Widget _buildPinnedMessages(AppLocalizations l10n) {
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
                    '${l10n.pinnedMessages} (${pinnedMessages.length})',
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
        // Scroll to pinned message
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

  Widget _buildMessagesList(AppLocalizations l10n) {
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
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(l10n);
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
              onLongPress: () => _handleMessageLongPress(message, l10n),
              onReactionTap: (emoji) => _addReaction(message, emoji, l10n),
              onReply: message.threadCount > 0
                  ? () => setState(() => _replyingTo = message)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
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
            l10n.noMessagesYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beFirstToMessage,
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