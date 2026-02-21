import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

/// Servicio para gestionar mensajes de chat
/// Modular y reutilizable para lotes, proyectos y productos
class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener referencia a la colección de mensajes según el tipo de entidad
  CollectionReference _getMessagesCollection(
      String organizationId, String entityType, String entityId,
      {String? parentId}) {
    final orgRef = _firestore.collection('organizations').doc(organizationId);

    switch (entityType) {
      case 'project':
        return orgRef
            .collection('projects')
            .doc(entityId)
            .collection('messages');

      case 'batch':
        return orgRef
            .collection('production_batches')
            .doc(entityId)
            .collection('messages');

      case 'batch_product':
        if (parentId == null) {
          throw ArgumentError(
              'parentId (batchId) is required for batch products');
        }
        return orgRef
            .collection('production_batches')
            .doc(parentId)
            .collection('batch_products')
            .doc(entityId)
            .collection('messages');

      case 'project_product':
        if (parentId == null) {
          throw ArgumentError(
              'parentId (projectId) is required for project products');
        }
        return orgRef
            .collection('projects')
            .doc(parentId)
            .collection('products')
            .doc(entityId)
            .collection('messages');

      default:
        return orgRef
            .collection(entityType)
            .doc(entityId)
            .collection('messages');
    }
  }

  /// Stream de mensajes en tiempo real
  Stream<List<MessageModel>> getMessages({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    bool includeInternal = true,
    int limit = 100,
  }) {
    Query query = _getMessagesCollection(organizationId, entityType, entityId,
            parentId: parentId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (!includeInternal) {
      query = query.where('isInternal', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Obtener mensajes paginados
  Future<List<MessageModel>> getMessagesPaginated({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    bool includeInternal = true,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _getMessagesCollection(organizationId, entityType, entityId,
            parentId: parentId)
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
    String? parentId,
    required String content,
    required UserModel currentUser,
    List<String> mentions = const [],
    List<MessageAttachment> attachments = const [],
    bool isInternal = false,
    String? parentMessageId,
  }) async {
    final messagesRef = _getMessagesCollection(
        organizationId, entityType, entityId,
        parentId: parentId);

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
        readBy: [currentUser.uid]);

    await messagesRef.doc(message.id).set(message.toMap());

    if (parentMessageId != null) {
      await _incrementThreadCount(
        organizationId,
        entityType,
        entityId,
        parentId,
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
    String? parentId,
    required String eventType,
    Map<String, dynamic>? eventData,
    bool isInternal = true,
  }) async {
    final messagesRef = _getMessagesCollection(
        organizationId, entityType, entityId,
        parentId: parentId);
    final content = SystemEventType.getEventContent(eventType, eventData);

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
    String? parentId,
    required String messageId,
    required String newContent,
  }) async {
    final messageRef = _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
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
    String? parentId,
    required String messageId,
  }) async {
    final messageRef = _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
        .doc(messageId);

    await messageRef.delete();
  }

  /// Marcar mensaje como leído
  Future<void> markAsRead({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String messageId,
    required String userId,
  }) async {
    final messageRef = _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
        .doc(messageId);

    // ✅ SOLO actualiza readBy, sin updatedAt
    await messageRef.update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Marcar todos los mensajes como leídos
  Future<void> markAllAsRead({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String userId,
  }) async {
    final messagesRef = _getMessagesCollection(
        organizationId, entityType, entityId,
        parentId: parentId);

    final snapshot = await messagesRef
        .where('readBy', whereNotIn: [userId])
        .limit(500)
        .get();

    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      // ✅ SOLO actualiza readBy, sin updatedAt
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();
  }

  /// Añadir reacción a un mensaje
  Future<void> addReaction({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String messageId,
    required String emoji,
    required UserModel user,
  }) async {
    final messageRef = _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
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
    String? parentId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final messageRef = _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
        .doc(messageId);

    final doc = await messageRef.get();
    if (!doc.exists) return;

    final message = MessageModel.fromFirestore(doc);
    final updatedReactions = message.reactions
        .where((r) => !(r.emoji == emoji && r.userId == userId))
        .toList();

    await messageRef.update({
      'reactions': updatedReactions.map((r) => r.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Gestionar reacción única por usuario: añade, cambia o elimina según el estado actual
  Future<void> toggleReaction({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String messageId,
    required String emoji,
    required UserModel user,
  }) async {
    final messageRef = _getMessagesCollection(
      organizationId,
      entityType,
      entityId,
      parentId: parentId,
    ).doc(messageId);

    final doc = await messageRef.get();
    if (!doc.exists) return;

    final message = MessageModel.fromFirestore(doc);

    // Reacción previa del usuario (si existe)
    final existingReaction =
        message.reactions.where((r) => r.userId == user.uid).firstOrNull;

    List<MessageReaction> updatedReactions;

    if (existingReaction != null && existingReaction.emoji == emoji) {
      // Mismo emoji → quitar reacción
      updatedReactions =
          message.reactions.where((r) => r.userId != user.uid).toList();
    } else {
      // Emoji distinto o sin reacción → reemplazar o añadir
      updatedReactions = [
        ...message.reactions.where((r) => r.userId != user.uid),
        MessageReaction(
          emoji: emoji,
          userId: user.uid,
          userName: user.name,
          createdAt: DateTime.now(),
        ),
      ];
    }

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
    String? parentId,
    required String messageId,
    required bool isPinned,
  }) async {
    final messageRef = _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
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
    String? parentId,
  }) {
    return _getMessagesCollection(organizationId, entityType, entityId,
            parentId: parentId)
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Obtener respuestas de un mensaje (thread)
  Stream<List<MessageModel>> getThreadReplies({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String parentMessageId,
  }) {
    return _getMessagesCollection(organizationId, entityType, entityId,
            parentId: parentId)
        .where('parentMessageId', isEqualTo: parentMessageId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Buscar mensajes
  Future<List<MessageModel>> searchMessages({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String searchTerm,
    bool includeInternal = true,
  }) async {
    final messagesRef = _getMessagesCollection(
        organizationId, entityType, entityId,
        parentId: parentId);

    Query query = messagesRef.orderBy('createdAt', descending: true).limit(500);

    if (!includeInternal) {
      query = query.where('isInternal', isEqualTo: false);
    }

    final snapshot = await query.get();
    final allMessages =
        snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();

    return allMessages.where((message) {
      return message.content.toLowerCase().contains(searchTerm.toLowerCase()) ||
          message.authorName
                  ?.toLowerCase()
                  .contains(searchTerm.toLowerCase()) ==
              true;
    }).toList();
  }

  /// Obtener contador de mensajes no leídos
  Stream<int> getUnreadCount({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String userId,
  }) {
    return _getMessagesCollection(organizationId, entityType, entityId,
            parentId: parentId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final readBy = List<String>.from(data['readBy'] ?? []);

        if (!readBy.contains(userId)) {
          count++;
        }
      }
      return count;
    });
  }

  /// Helper específico para productos de lote
  Stream<int> getProductUnreadCount({
    required String organizationId,
    required String batchId,
    required String productId,
    required String userId,
  }) {
    return getUnreadCount(
      organizationId: organizationId,
      entityType: 'batch_product',
      entityId: productId,
      parentId: batchId,
      userId: userId,
    );
  }

  /// Incrementar threadCount del mensaje padre
  Future<void> _incrementThreadCount(
    String organizationId,
    String entityType,
    String entityId,
    String? parentId,
    String parentMessageId,
  ) async {
    final messageRef = _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
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
    String? parentId,
    required String userId,
  }) async {
    final snapshot = await _getMessagesCollection(
            organizationId, entityType, entityId,
            parentId: parentId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);

      if (!readBy.contains(userId)) {
        return true;
      }
    }

    return false;
  }

  Future<void> markMessagesAsRead({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String userId,
  }) async {
    final collection = _getMessagesCollection(
        organizationId, entityType, entityId,
        parentId: parentId);

    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final readBy = List<String>.from(data['readBy'] ?? []);

        if (!readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
      } else {}
    } catch (e) {
      if (e is FirebaseException) {
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
      }
    }
  }

  /// Carga mensajes hasta incluir un messageId específico.
  /// Devuelve la lista ampliada si el mensaje no estaba en el límite actual.
  Future<List<MessageModel>> getMessagesUntil({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String targetMessageId,
    bool includeInternal = true,
    int batchSize = 100,
    int maxMessages = 1000,
  }) async {
    final collection = _getMessagesCollection(
      organizationId,
      entityType,
      entityId,
      parentId: parentId,
    );

    int loaded = 0;
    DocumentSnapshot? lastDoc;

    while (loaded < maxMessages) {
      Query query =
          collection.orderBy('createdAt', descending: true).limit(batchSize);

      if (!includeInternal) {
        query = query.where('isInternal', isEqualTo: false);
      }

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final found = snapshot.docs.any((d) => d.id == targetMessageId);
      loaded += snapshot.docs.length;
      lastDoc = snapshot.docs.last;

      if (found || snapshot.docs.length < batchSize) break;
    }

    // Devolver el total cargado como stream de una sola emisión no es posible,
    // así que devolvemos el nuevo limit necesario
    return []; // señal: usar getMessages con el nuevo limit
  }

  /// Obtener el offset aproximado de un mensaje (cuántos mensajes hay después de él)
  Future<int> getMessageOffset({
    required String organizationId,
    required String entityType,
    required String entityId,
    String? parentId,
    required String targetMessageId,
    bool includeInternal = true,
  }) async {
    final collection = _getMessagesCollection(
      organizationId,
      entityType,
      entityId,
      parentId: parentId,
    );

    // Obtener el documento del mensaje objetivo
    final targetDoc = await collection.doc(targetMessageId).get();
    if (!targetDoc.exists) return 0;

    final targetDate = (targetDoc.data() as Map<String, dynamic>)['createdAt'];

    // Contar cuántos mensajes son más recientes (vienen antes en la lista reverse:true)
    Query countQuery = collection
        .orderBy('createdAt', descending: true)
        .where('createdAt', isGreaterThan: targetDate);

    if (!includeInternal) {
      countQuery = countQuery.where('isInternal', isEqualTo: false);
    }

    final countSnapshot = await countQuery.count().get();
    return countSnapshot.count ?? 0;
  }
}
