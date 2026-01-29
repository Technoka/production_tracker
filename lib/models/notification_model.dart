import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Tipo de notificación
enum NotificationType {
  approvalRequest(
    value: 'approval_request',
    label: 'Solicitud de Aprobación',
    icon: Icons.approval_outlined,
    color: Colors.orange,
  ),
  approvalResponse(
    value: 'approval_response',
    label: 'Respuesta de Aprobación',
    icon: Icons.check_circle_outline,
    color: Colors.green,
  ),
  info(
    value: 'info',
    label: 'Información',
    icon: Icons.info_outline,
    color: Colors.blue,
  ),
  alert(
    value: 'alert',
    label: 'Alerta',
    icon: Icons.warning_amber_outlined,
    color: Colors.red,
  ),
  slaWarning(
    value: 'sla_warning',
    label: 'Advertencia de SLA',
    icon: Icons.timer_outlined,
    color: Colors.amber,
  ),
  message(
    value: 'message',
    label: 'Nuevo Mensaje',
    icon: Icons.chat_bubble_outline,
    color: Colors.indigo,
  ),
  invoice(
    value: 'invoice',
    label: 'Facturación',
    icon: Icons.receipt_long_outlined,
    color: Colors.purple,
  );

  // Propiedades declaradas en el constructor
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const NotificationType({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.info,
    );
  }
}

// Estado de la notificación
enum NotificationStatus {
  pending(
    value: 'pending',
    label: 'Pendiente',
    color: Colors.orange,
    icon: Icons.hourglass_empty_rounded,
  ),
  resolved(
    value: 'resolved',
    label: 'Resuelto',
    color: Colors.green,
    icon: Icons.check_circle_outline_rounded,
  ),
  expired(
    value: 'expired',
    label: 'Expirado',
    color: Colors.grey,
    icon: Icons.timer_off_outlined,
  );

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const NotificationStatus({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  // Factory seguro para Firestore
  static NotificationStatus fromString(String? value) {
    return NotificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationStatus.pending,
    );
  }
}

// Prioridad de la notificación
enum NotificationPriority {
  low(
    value: 'low',
    label: 'Baja',
    color: Colors.blueGrey,
    icon: Icons.arrow_downward_rounded,
  ),
  medium(
    value: 'medium',
    label: 'Media',
    color: Colors.blue,
    icon: Icons.remove_rounded,
  ),
  high(
    value: 'high',
    label: 'Alta',
    color: Colors.orange,
    icon: Icons.arrow_upward_rounded,
  ),
  urgent(
    value: 'urgent',
    label: 'Urgente',
    color: Colors.red,
    icon: Icons.campaign_rounded,
  );

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const NotificationPriority({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  static NotificationPriority fromString(String? value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationPriority.medium,
    );
  }

  // Helper para ordenar prioridades
  int get sortWeight {
    switch (this) {
      case NotificationPriority.urgent:
        return 4;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.medium:
        return 2;
      case NotificationPriority.low:
        return 1;
    }
  }
}

// Acción disponible en una notificación
class NotificationAction {
  final String type;
  final String label;
  final bool enabled;

  const NotificationAction({
    required this.type,
    required this.label,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'enabled': enabled,
    };
  }

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      type: map['type'] ?? '',
      label: map['label'] ?? '',
      enabled: map['enabled'] ?? true,
    );
  }
}

// Modelo de notificación
class NotificationModel {
  final String id;
  final NotificationType type;
  final List<String> destinationUserIds;
  final List<String> readBy;
  final NotificationStatus status;
  final NotificationPriority priority;
  final String title;
  final String message;
  final Map<String, dynamic> metadata;
  final List<NotificationAction> actions;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.destinationUserIds,
    this.readBy = const [],
    required this.status,
    this.priority = NotificationPriority.medium,
    required this.title,
    required this.message,
    this.metadata = const {},
    this.actions = const [],
    required this.createdAt,
    this.resolvedAt,
    this.expiresAt,
  });

  /// Verificar si un usuario ha leído la notificación
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  /// Verificar si un usuario es destinatario
  bool isForUser(String userId) {
    return destinationUserIds.contains(userId);
  }

  /// Verificar si está pendiente
  bool get isPending => status == NotificationStatus.pending;

  /// Verificar si está resuelta
  bool get isResolved => status == NotificationStatus.resolved;

  /// Verificar si ha expirado
  bool get isExpired => status == NotificationStatus.expired;

  /// Verificar si es de alta prioridad
  bool get isHighPriority =>
      priority == NotificationPriority.high ||
      priority == NotificationPriority.urgent;

  /// Copiar con nuevos valores
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    List<String>? destinationUserIds,
    List<String>? readBy,
    NotificationStatus? status,
    NotificationPriority? priority,
    String? title,
    String? message,
    Map<String, dynamic>? metadata,
    List<NotificationAction>? actions,
    DateTime? createdAt,
    DateTime? resolvedAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      destinationUserIds: destinationUserIds ?? this.destinationUserIds,
      readBy: readBy ?? this.readBy,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'destinationUserIds': destinationUserIds,
      'readBy': readBy,
      'status': status.value,
      'priority': priority.value,
      'title': title,
      'message': message,
      'metadata': metadata,
      'actions': actions.map((a) => a.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Crear desde Map de Firestore
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      type: NotificationType.fromString(map['type'] ?? 'info'),
      destinationUserIds: List<String>.from(map['destinationUserIds'] ?? []),
      readBy: List<String>.from(map['readBy'] ?? []),
      status:
          NotificationStatus.fromString(map['status'] ?? 'pending'),
      priority: NotificationPriority.fromString(
        map['priority'] ?? 'medium',
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      actions: (map['actions'] as List<dynamic>?)
              ?.map(
                  (a) => NotificationAction.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: ${type.value}, title: $title, status: ${status.value})';
  }
}
