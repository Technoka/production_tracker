import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para mensajes del chat
/// Soporta mensajes de usuario, eventos del sistema, menciones, adjuntos y threads
class MessageModel {
  final String id;
  final String entityType; // "batch", "project", "product"
  final String entityId; // ID del lote/proyecto/producto
  final MessageType type;
  final String content;

  // Autor (solo para mensajes de usuario)
  final String? authorId;
  final String? authorName;
  final String? authorRole;
  final String? authorAvatar;

  // Sistema (solo para eventos automáticos)
  final bool isSystemGenerated;
  final String? eventType; // "batch_created", "phase_completed", "delay_detected", etc.
  final Map<String, dynamic>? eventData; // Datos adicionales del evento

  // Interacción
  final List<String> mentions; // IDs de usuarios mencionados
  final List<MessageAttachment> attachments;
  final List<MessageReaction> reactions;

  // Metadata
  final bool isInternal; // true = solo equipo, false = visible para cliente
  final bool isPinned;

  // Thread (respuestas)
  final String? parentMessageId;
  final int threadCount;

  // Estado
  final List<String> readBy; // IDs de usuarios que leyeron el mensaje
  final List<String> deliveredTo;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.type,
    required this.content,
    this.authorId,
    this.authorName,
    this.authorRole,
    this.authorAvatar,
    this.isSystemGenerated = false,
    this.eventType,
    this.eventData,
    this.mentions = const [],
    this.attachments = const [],
    this.reactions = const [],
    this.isInternal = false,
    this.isPinned = false,
    this.parentMessageId,
    this.threadCount = 0,
    this.readBy = const [],
    this.deliveredTo = const [],
    required this.createdAt,
    this.updatedAt,
    this.editedAt,
  });

  /// Crear desde Firestore
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.userMessage,
      ),
      content: data['content'] ?? '',
      authorId: data['authorId'],
      authorName: data['authorName'],
      authorRole: data['authorRole'],
      authorAvatar: data['authorAvatar'],
      isSystemGenerated: data['isSystemGenerated'] ?? false,
      eventType: data['eventType'],
      eventData: data['eventData'] != null 
          ? Map<String, dynamic>.from(data['eventData'])
          : null,
      mentions: List<String>.from(data['mentions'] ?? []),
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((a) => MessageAttachment.fromMap(a))
              .toList() ??
          [],
      reactions: (data['reactions'] as List<dynamic>?)
              ?.map((r) => MessageReaction.fromMap(r))
              .toList() ??
          [],
      isInternal: data['isInternal'] ?? false,
      isPinned: data['isPinned'] ?? false,
      parentMessageId: data['parentMessageId'],
      threadCount: data['threadCount'] ?? 0,
      readBy: List<String>.from(data['readBy'] ?? []),
      deliveredTo: List<String>.from(data['deliveredTo'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      'type': type.name,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorAvatar': authorAvatar,
      'isSystemGenerated': isSystemGenerated,
      'eventType': eventType,
      'eventData': eventData,
      'mentions': mentions,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'reactions': reactions.map((r) => r.toMap()).toList(),
      'isInternal': isInternal,
      'isPinned': isPinned,
      'parentMessageId': parentMessageId,
      'threadCount': threadCount,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  /// Copiar con cambios
  MessageModel copyWith({
    String? content,
    List<String>? mentions,
    List<MessageAttachment>? attachments,
    List<MessageReaction>? reactions,
    bool? isInternal,
    bool? isPinned,
    int? threadCount,
    List<String>? readBy,
    List<String>? deliveredTo,
    DateTime? updatedAt,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id,
      entityType: entityType,
      entityId: entityId,
      type: type,
      content: content ?? this.content,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: authorAvatar,
      isSystemGenerated: isSystemGenerated,
      eventType: eventType,
      eventData: eventData,
      mentions: mentions ?? this.mentions,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      isInternal: isInternal ?? this.isInternal,
      isPinned: isPinned ?? this.isPinned,
      parentMessageId: parentMessageId,
      threadCount: threadCount ?? this.threadCount,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  /// Verificar si el usuario ya leyó el mensaje
  bool isReadBy(String userId) => readBy.contains(userId);

  /// Verificar si el usuario puede editar este mensaje
  bool canEdit(String userId) => authorId == userId && !isSystemGenerated;

  /// Verificar si el usuario puede eliminar este mensaje
  bool canDelete(String userId, bool isAdmin) =>
      (authorId == userId || isAdmin) && !isSystemGenerated;
}

/// Tipos de mensaje
enum MessageType {
  userMessage, // Mensaje normal de usuario
  systemEvent, // Evento automático del sistema
  statusChange, // Cambio de estado
}

/// Adjunto de mensaje
class MessageAttachment {
  final String name;
  final String url;
  final String type; // "image", "pdf", "document"
  final int size; // Bytes

  MessageAttachment({
    required this.name,
    required this.url,
    required this.type,
    required this.size,
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? '',
      size: map['size'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'size': size,
    };
  }

  /// Obtener icono según el tipo de archivo
  String get icon {
    switch (type) {
      case 'image':
        return '🖼️';
      case 'pdf':
        return '📄';
      case 'document':
        return '📋';
      default:
        return '📎';
    }
  }

  /// Formatear tamaño del archivo
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Reacción a un mensaje
class MessageReaction {
  final String emoji;
  final String userId;
  final String userName;
  final DateTime createdAt;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      emoji: map['emoji'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emoji': emoji,
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Tipos de eventos del sistema
class SystemEventType {
  static const String batchCreated = 'batch_created';
  static const String batchStatusChanged = 'batch_status_changed';
  static const String phaseCompleted = 'phase_completed';
  static const String productMoved = 'product_moved';
  static const String delayDetected = 'delay_detected';
  static const String memberAssigned = 'member_assigned';
  static const String memberRemoved = 'member_removed';
  static const String invoiceIssued = 'invoice_issued';
  static const String paymentReceived = 'payment_received';
  static const String noteAdded = 'note_added';
  static const String fileUploaded = 'file_uploaded';

  /// Generar contenido legible para cada tipo de evento
  static String getEventContent(String eventType, Map<String, dynamic>? data) {
    switch (eventType) {
      case batchCreated:
        return 'Lote creado';
      case batchStatusChanged:
        return 'Estado cambiado a ${data?['newStatus'] ?? 'desconocido'}';
      case phaseCompleted:
        return 'Fase "${data?['phaseName'] ?? 'desconocida'}" completada';
      case productMoved:
        return 'Producto movido a fase "${data?['newPhase'] ?? 'desconocida'}"';
      case delayDetected:
        return 'Retraso detectado: ${data?['delayHours'] ?? 0} horas';
      case memberAssigned:
        return '${data?['memberName'] ?? 'Usuario'} asignado al lote';
      case memberRemoved:
        return '${data?['memberName'] ?? 'Usuario'} removido del lote';
      case invoiceIssued:
        return 'Factura emitida: ${data?['invoiceNumber'] ?? ''}';
      case paymentReceived:
        return 'Pago recibido: ${data?['amount'] ?? 0}€';
      case noteAdded:
        return 'Nueva nota añadida';
      case fileUploaded:
        return 'Archivo subido: ${data?['fileName'] ?? ''}';
      default:
        return 'Evento del sistema';
    }
  }

  /// Icono para cada tipo de evento
  static String getEventIcon(String eventType) {
    switch (eventType) {
      case batchCreated:
        return '✨';
      case batchStatusChanged:
        return '🔄';
      case phaseCompleted:
        return '✅';
      case productMoved:
        return '➡️';
      case delayDetected:
        return '⚠️';
      case memberAssigned:
        return '👤';
      case memberRemoved:
        return '👋';
      case invoiceIssued:
        return '💰';
      case paymentReceived:
        return '💳';
      case noteAdded:
        return '📝';
      case fileUploaded:
        return '📎';
      default:
        return 'ℹ️';
    }
  }
}