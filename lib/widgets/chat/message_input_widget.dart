import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:gestion_produccion/l10n/app_localizations.dart';
import 'dart:io' show Platform;
import '../../models/message_model.dart';

/// Widget de input para enviar mensajes
/// Reutilizable con soporte para menciones, adjuntos y respuestas
class MessageInput extends StatefulWidget {
  final Function(String content, List<String> mentions, bool isInternal) onSend;
  final VoidCallback? onAttachFile;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;
  final bool showInternalToggle;
  final bool isLoading;

  const MessageInput({
    Key? key,
    required this.onSend,
    this.onAttachFile,
    this.replyingTo,
    this.onCancelReply,
    this.showInternalToggle = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isInternal = false;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _controller.text.trim().isNotEmpty;
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;

    // Detectar menciones @usuario
    final mentions = _detectMentions(text);

    widget.onSend(text, mentions, _isInternal);
    _controller.clear();

    // AGREGAR: Mantener el teclado en móvil
    // _focusNode.unfocus();

    setState(() {
      _isComposing = false;
    });
  }

  List<String> _detectMentions(String text) {
    // Detectar patrones @usuario
    final mentionPattern = RegExp(r'@(\w+)');
    final matches = mentionPattern.allMatches(text);

    // En producción, deberías resolver estos nombres a userIds
    // Por ahora, retornamos los nombres detectados
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Verificar si estamos en desktop (web o desktop app)
  bool get _isDesktop {
    if (kIsWeb) return true;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// Manejar el evento de tecla presionada
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Solo procesar cuando se suelta la tecla
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Enter sin Shift: enviar mensaje (solo en desktop)
    if (_isDesktop && 
        event.logicalKey == LogicalKeyboardKey.enter && 
        !HardwareKeyboard.instance.isShiftPressed) {
      _handleSend();
      return KeyEventResult.handled;
    }

    // Shift+Enter: nueva línea (comportamiento por defecto)
    // No necesitamos hacer nada especial, el TextField lo maneja automáticamente

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview de respuesta
            if (widget.replyingTo != null) _buildReplyPreview(),

            // Input principal
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Botón de adjuntar (opcional)
                  if (widget.onAttachFile != null)
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: widget.isLoading ? null : widget.onAttachFile,
                      color: Theme.of(context).primaryColor,
                    ),

                  // Campo de texto
                  Expanded(
                    child: Focus(
                      onKeyEvent: _handleKeyEvent,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: widget.replyingTo != null
                                ? l10n.answer
                                : l10n.writeAMessage,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          // En móvil, mantener el comportamiento por defecto de onSubmitted
                          onSubmitted: !_isDesktop ? (_) => _handleSend() : null,
                          enabled: !widget.isLoading,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botón de enviar
                  Material(
                    color: _isComposing && !widget.isLoading
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isComposing && !widget.isLoading ? _handleSend : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: widget.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: _isComposing ? Colors.white : Colors.grey[600],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Toggle de mensaje interno (solo si showInternalToggle es true)
            if (widget.showInternalToggle)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: _isInternal ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.internalMessageDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Switch(
                      value: _isInternal,
                      onChanged: widget.isLoading
                          ? null
                          : (value) => setState(() => _isInternal = value),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Preview del mensaje al que se está respondiendo
  Widget _buildReplyPreview() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.messageAnsweringTo} ${widget.replyingTo!.authorName ?? 'User?'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyingTo!.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.isLoading ? null : widget.onCancelReply,
            color: Colors.grey[600],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet para seleccionar emoji de reacción
class EmojiReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const EmojiReactionPicker({
    Key? key,
    required this.onEmojiSelected,
  }) : super(key: key);

  static const List<String> _commonEmojis = [
    '👍', '❤️', '😂', '😮', '😢', '🙏',
    '🎉', '🔥', '👏', '✅', '❌', '👀',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Text(
            l10n.messageReactWith,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          // Grid de emojis
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _commonEmojis.length,
            itemBuilder: (context, index) {
              final emoji = _commonEmojis[index];
              return InkWell(
                onTap: () {
                  onEmojiSelected(emoji);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Mostrar el picker como bottom sheet
  static void show(BuildContext context, Function(String) onEmojiSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EmojiReactionPicker(onEmojiSelected: onEmojiSelected),
    );
  }
}