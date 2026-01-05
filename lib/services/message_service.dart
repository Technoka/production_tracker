import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

/// Servicio para gestionar mensajes de chat
/// Modular y reutilizable para lotes, proyectos y productos
class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener referencia a la colección de mensajes según el tipo de entidad
  CollectionReference _getMessagesCollection(
    String organizationId,
    String entityType,
    String entityId,
  ) {
    switch (entityType) {
      case 'batch':
        return _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('production_batches')
            .doc(entityId)
            .collection('messages');
      case 'project':
        return _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(entityId)
            .collection('messages');
      case 'product':
        // Para productos dentro de proyectos
        // entityId debe ser "projectId/products/productId"
        final parts = entityId.split('/');
        if (parts.length == 3) {
          return _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('projects')
              .doc(parts[0])
              .collection('products')
              .doc(parts[2])
              .collection('messages');
        }
        throw ArgumentError('Invalid product entityId format');
      default:
        throw ArgumentError('Invalid entity type: $entityType');
    }
  }

  /// Stream de mensajes en tiempo real
  Stream<List<MessageModel>> getMessages({
    required String organizationId,
    required String entityType,
    required String entityId,
    bool includeInternal = true,
    int limit = 100,
  }) {
    Query query = _getMessagesCollection(organizationId, entityType, entityId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // Filtrar mensajes internos si es necesario (para clientes)
    if (!includeInternal) {
      query = query.where('isInternal', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  /// Obtener mensajes paginados
  Future<List<MessageModel>> getMessagesPaginated({
    required String organizationId,
    required String entityType,
    required String entityId,
    bool includeInternal = true,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _getMessagesCollection(organizationId, entityType, entityId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (!includeInternal) {
      query = query.where('isInternal', isEqualTo: false);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
  }

  /// Enviar mensaje de usuario
  Future<String> sendMessage({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String content,
    required UserModel currentUser,
    List<String> mentions = const [],
    List<MessageAttachment> attachments = const [],
    bool isInternal = false,
    String? parentMessageId,
  }) async {
    final messagesRef = _getMessagesCollection(organizationId, entityType, entityId);

    final message = MessageModel(
      id: messagesRef.doc().id,
      entityType: entityType,
      entityId: entityId,
      type: MessageType.userMessage,
      content: content.trim(),
      authorId: currentUser.uid,
      authorName: currentUser.name,
      authorRole: currentUser.role,
      authorAvatar: currentUser.photoURL,
      mentions: mentions,
      attachments: attachments,
      isInternal: isInternal,
      parentMessageId: parentMessageId,
      createdAt: DateTime.now(),
    );

    await messagesRef.doc(message.id).set(message.toMap());

    // Si es respuesta, incrementar threadCount del mensaje padre
    if (parentMessageId != null) {
      await _incrementThreadCount(
        organizationId,
        entityType,
        entityId,
        parentMessageId,
      );
    }

    return message.id;
  }

  /// Crear evento del sistema
  Future<String> createSystemEvent({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String eventType,
    Map<String, dynamic>? eventData,
    bool isInternal = true,
  }) async {
    final messagesRef = _getMessagesCollection(organizationId, entityType, entityId);

    final content = SystemEventType.getEventContent(eventType, eventData);
print('message id: ${messagesRef.doc().id} ------------------------------------------');
    final message = MessageModel(
      id: messagesRef.doc().id,
      entityType: entityType,
      entityId: entityId,
      type: MessageType.systemEvent,
      content: content,
      isSystemGenerated: true,
      eventType: eventType,
      eventData: eventData,
      isInternal: isInternal,
      createdAt: DateTime.now(),
    );

    await messagesRef.doc(message.id).set(message.toMap());

    return message.id;
  }

  /// Editar mensaje
  Future<void> editMessage({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String messageId,
    required String newContent,
  }) async {
    final messageRef = _getMessagesCollection(organizationId, entityType, entityId)
        .doc(messageId);

    await messageRef.update({
      'content': newContent.trim(),
      'editedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Eliminar mensaje
  Future<void> deleteMessage({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String messageId,
  }) async {
    final messageRef = _getMessagesCollection(organizationId, entityType, entityId)
        .doc(messageId);

    await messageRef.delete();
  }

  /// Marcar mensaje como leído
  Future<void> markAsRead({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String messageId,
    required String userId,
  }) async {
    final messageRef = _getMessagesCollection(organizationId, entityType, entityId)
        .doc(messageId);

    await messageRef.update({
      'readBy': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Marcar todos los mensajes como leídos
  Future<void> markAllAsRead({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String userId,
  }) async {
    final messagesRef = _getMessagesCollection(organizationId, entityType, entityId);

    // Obtener mensajes no leídos
    final snapshot = await messagesRef
        .where('readBy', whereNotIn: [userId])
        .limit(500) // Límite de Firestore
        .get();

    // Batch write para eficiencia
    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  /// Añadir reacción a un mensaje
  Future<void> addReaction({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String messageId,
    required String emoji,
    required UserModel user,
  }) async {
    final messageRef = _getMessagesCollection(organizationId, entityType, entityId)
        .doc(messageId);

    final reaction = MessageReaction(
      emoji: emoji,
      userId: user.uid,
      userName: user.name,
      createdAt: DateTime.now(),
    );

    await messageRef.update({
      'reactions': FieldValue.arrayUnion([reaction.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Quitar reacción de un mensaje
  Future<void> removeReaction({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final messageRef = _getMessagesCollection(organizationId, entityType, entityId)
        .doc(messageId);

    // Obtener el mensaje actual
    final doc = await messageRef.get();
    if (!doc.exists) return;

    final message = MessageModel.fromFirestore(doc);

    // Filtrar la reacción del usuario
    final updatedReactions = message.reactions
        .where((r) => !(r.emoji == emoji && r.userId == userId))
        .toList();

    await messageRef.update({
      'reactions': updatedReactions.map((r) => r.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Fijar/desfijar mensaje
  Future<void> togglePin({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String messageId,
    required bool isPinned,
  }) async {
    final messageRef = _getMessagesCollection(organizationId, entityType, entityId)
        .doc(messageId);

    await messageRef.update({
      'isPinned': isPinned,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Obtener mensajes fijados
  Stream<List<MessageModel>> getPinnedMessages({
    required String organizationId,
    required String entityType,
    required String entityId,
  }) {
    return _getMessagesCollection(organizationId, entityType, entityId)
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  /// Obtener respuestas de un mensaje (thread)
  Stream<List<MessageModel>> getThreadReplies({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String parentMessageId,
  }) {
    return _getMessagesCollection(organizationId, entityType, entityId)
        .where('parentMessageId', isEqualTo: parentMessageId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  /// Buscar mensajes
  Future<List<MessageModel>> searchMessages({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String searchTerm,
    bool includeInternal = true,
  }) async {
    // Firestore no tiene búsqueda full-text nativa
    // Esta es una implementación básica que puede ser mejorada con Algolia
    final messagesRef = _getMessagesCollection(organizationId, entityType, entityId);

    Query query = messagesRef
        .orderBy('createdAt', descending: true)
        .limit(500);

    if (!includeInternal) {
      query = query.where('isInternal', isEqualTo: false);
    }

    final snapshot = await query.get();

    // Filtrar en memoria (no óptimo para grandes datasets)
    final allMessages = snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList();

    return allMessages.where((message) {
      return message.content.toLowerCase().contains(searchTerm.toLowerCase()) ||
          message.authorName?.toLowerCase().contains(searchTerm.toLowerCase()) == true;
    }).toList();
  }

  /// Obtener contador de mensajes no leídos
  Stream<int> getUnreadCount({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String userId,
  }) {
    return _getMessagesCollection(organizationId, entityType, entityId)
        .where('readBy', whereNotIn: [userId])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Incrementar threadCount del mensaje padre
  Future<void> _incrementThreadCount(
    String organizationId,
    String entityType,
    String entityId,
    String parentMessageId,
  ) async {
    final messageRef = _getMessagesCollection(organizationId, entityType, entityId)
        .doc(parentMessageId);

    await messageRef.update({
      'threadCount': FieldValue.increment(1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Verificar si el usuario tiene mensajes no leídos
  Future<bool> hasUnreadMessages({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String userId,
  }) async {
    final snapshot = await _getMessagesCollection(organizationId, entityType, entityId)
        .where('readBy', whereNotIn: [userId])
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}