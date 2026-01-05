import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../widgets/message_bubble_widget.dart';

/// Delegate para búsqueda de mensajes
/// Implementa búsqueda en memoria (gratis, sin servicios externos)
class MessageSearchDelegate extends SearchDelegate<MessageModel?> {
  final String organizationId;
  final String entityType;
  final String entityId;
  final UserModel currentUser;
  final MessageService _messageService = MessageService();

  List<MessageModel> _allMessages = [];
  bool _isLoading = true;

  MessageSearchDelegate({
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.currentUser,
  });

  @override
  String get searchFieldLabel => 'Buscar mensajes...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<MessageModel>>(
      stream: _messageService.getMessages(
        organizationId: organizationId,
        entityType: entityType,
        entityId: entityId,
        includeInternal: true,
        limit: 500, // Cargar más para búsqueda
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loading),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${l10n.error}: ${snapshot.error}'),
          );
        }

        _allMessages = snapshot.data ?? [];

        if (query.isEmpty) {
          return _buildRecentSearches(context);
        }

        // Buscar en el contenido y nombre del autor
        final results = _searchMessages(query.toLowerCase());

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noResultsFound,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tryOtherSearchTerms,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final message = results[index];
            return _buildSearchResultItem(context, message);
          },
        );
      },
    );
  }

  /// Buscar mensajes que coincidan con la query
  List<MessageModel> _searchMessages(String searchQuery) {
    return _allMessages.where((message) {
      // Buscar en el contenido del mensaje
      final matchesContent = message.content
          .toLowerCase()
          .contains(searchQuery);

      // Buscar en el nombre del autor
      final matchesAuthor = message.authorName
              ?.toLowerCase()
              .contains(searchQuery) ??
          false;

      // Buscar en menciones (opcional)
      final matchesMentions = message.mentions.any(
        (mention) => mention.toLowerCase().contains(searchQuery),
      );

      return matchesContent || matchesAuthor || matchesMentions;
    }).toList();
  }

  Widget _buildSearchResultItem(BuildContext context, MessageModel message) {
    final highlightedContent = _highlightQuery(message.content, query);

    return InkWell(
      onTap: () {
        close(context, message);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Autor y fecha
            Row(
              children: [
                if (!message.isSystemGenerated) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: message.authorAvatar != null
                        ? NetworkImage(message.authorAvatar!)
                        : null,
                    child: message.authorAvatar == null
                        ? Text(
                            message.authorName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    message.isSystemGenerated
                        ? 'Sistema'
                        : message.authorName ?? 'Usuario',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  _formatDate(message.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contenido con highlight
            RichText(
              text: highlightedContent,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Badges
            if (message.isInternal || message.isPinned) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  if (message.isInternal)
                    _buildBadge('Interno', Colors.orange[100]!, Colors.orange[900]!),
                  if (message.isPinned)
                    _buildBadge('Fijado', Colors.blue[100]!, Colors.blue[900]!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Resaltar la query en el texto
  TextSpan _highlightQuery(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int indexOfQuery;

    while ((indexOfQuery = lowerText.indexOf(lowerQuery, start)) != -1) {
      // Texto antes del match
      if (indexOfQuery > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfQuery),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ));
      }

      // Texto del match (destacado)
      spans.add(TextSpan(
        text: text.substring(indexOfQuery, indexOfQuery + query.length),
        style: TextStyle(
          fontSize: 14,
          color: Colors.black87,
          backgroundColor: Colors.yellow[200],
          fontWeight: FontWeight.bold,
        ),
      ));

      start = indexOfQuery + query.length;
    }

    // Texto después del último match
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildRecentSearches(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Buscar en mensajes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Escribe para buscar en el contenido de los mensajes, nombres de usuario o menciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      const weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return weekDays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}