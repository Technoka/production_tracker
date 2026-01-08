import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de alerta SLA
enum SLAAlertType {
  slaExceeded,      // SLA superado
  slaWarning,       // Advertencia cercana al SLA
  phaseBlocked,     // Fase bloqueada
  wipLimitExceeded; // Límite WIP superado

  String get displayName {
    switch (this) {
      case SLAAlertType.slaExceeded:
        return 'SLA Superado';
      case SLAAlertType.slaWarning:
        return 'Advertencia SLA';
      case SLAAlertType.phaseBlocked:
        return 'Fase Bloqueada';
      case SLAAlertType.wipLimitExceeded:
        return 'Límite WIP Superado';
    }
  }

  static SLAAlertType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'slaexceeded':
      case 'sla_exceeded':
        return SLAAlertType.slaExceeded;
      case 'slawarning':
      case 'sla_warning':
        return SLAAlertType.slaWarning;
      case 'phaseblocked':
      case 'phase_blocked':
        return SLAAlertType.phaseBlocked;
      case 'wiplimitexceeded':
      case 'wip_limit_exceeded':
        return SLAAlertType.wipLimitExceeded;
      default:
        return SLAAlertType.slaWarning;
    }
  }

  String toMap() {
    return toString().split('.').last;
  }
}

/// Severidad de la alerta
enum SLAAlertSeverity {
  warning,   // Advertencia (cerca del límite)
  critical;  // Crítico (límite superado)

  String get displayName {
    switch (this) {
      case SLAAlertSeverity.warning:
        return 'Advertencia';
      case SLAAlertSeverity.critical:
        return 'Crítico';
    }
  }

  static SLAAlertSeverity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'warning':
        return SLAAlertSeverity.warning;
      case 'critical':
        return SLAAlertSeverity.critical;
      default:
        return SLAAlertSeverity.warning;
    }
  }

  String toMap() {
    return toString().split('.').last;
  }
}

/// Estado de la alerta
enum SLAAlertStatus {
  active,         // Activa (sin revisar)
  acknowledged,   // Reconocida (vista pero no resuelta)
  resolved;       // Resuelta

  String get displayName {
    switch (this) {
      case SLAAlertStatus.active:
        return 'Activa';
      case SLAAlertStatus.acknowledged:
        return 'Reconocida';
      case SLAAlertStatus.resolved:
        return 'Resuelta';
    }
  }

  static SLAAlertStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SLAAlertStatus.active;
      case 'acknowledged':
        return SLAAlertStatus.acknowledged;
      case 'resolved':
        return SLAAlertStatus.resolved;
      default:
        return SLAAlertStatus.active;
    }
  }

  String toMap() {
    return toString().split('.').last;
  }
}

/// Tipo de entidad afectada
enum SLAEntityType {
  project,
  product,
  phase;

  static SLAEntityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'project':
        return SLAEntityType.project;
      case 'product':
        return SLAEntityType.product;
      case 'phase':
        return SLAEntityType.phase;
      default:
        return SLAEntityType.product;
    }
  }

  String toMap() {
    return toString().split('.').last;
  }
}

/// Modelo de Alerta SLA
class SLAAlert {
  final String id;
  final String organizationId;
  
  // Entidad afectada
  final SLAEntityType entityType;
  final String entityId;
  final String entityName;
  
  // Tipo y severidad
  final SLAAlertType alertType;
  final SLAAlertSeverity severity;
  
  // Detalles del SLA
  final double currentValue;      // Horas actuales
  final double thresholdValue;    // Límite SLA en horas
  final double deviationPercent;  // % de desviación
  
  // Estado
  final SLAAlertStatus status;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  
  // Notificaciones
  final List<String> notifiedUsers;
  final DateTime? notifiedAt;
  
  // Metadata
  final DateTime createdAt;
  final String? projectId;        // Para filtrado rápido
  final String? phaseId;          // Para filtrado rápido
  final String? productId;        // Para filtrado rápido

  SLAAlert({
    required this.id,
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.alertType,
    required this.severity,
    required this.currentValue,
    required this.thresholdValue,
    required this.deviationPercent,
    this.status = SLAAlertStatus.active,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.notifiedUsers = const [],
    this.notifiedAt,
    required this.createdAt,
    this.projectId,
    this.phaseId,
    this.productId,
  });

  factory SLAAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SLAAlert(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      entityType: SLAEntityType.fromString(data['entityType'] ?? 'product'),
      entityId: data['entityId'] ?? '',
      entityName: data['entityName'] ?? '',
      alertType: SLAAlertType.fromString(data['alertType'] ?? 'sla_warning'),
      severity: SLAAlertSeverity.fromString(data['severity'] ?? 'warning'),
      currentValue: (data['currentValue'] ?? 0).toDouble(),
      thresholdValue: (data['thresholdValue'] ?? 0).toDouble(),
      deviationPercent: (data['deviationPercent'] ?? 0).toDouble(),
      status: SLAAlertStatus.fromString(data['status'] ?? 'active'),
      acknowledgedBy: data['acknowledgedBy'],
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolutionNotes: data['resolutionNotes'],
      notifiedUsers: data['notifiedUsers'] != null
          ? List<String>.from(data['notifiedUsers'])
          : [],
      notifiedAt: (data['notifiedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      projectId: data['projectId'],
      phaseId: data['phaseId'],
      productId: data['productId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'entityType': entityType.toMap(),
      'entityId': entityId,
      'entityName': entityName,
      'alertType': alertType.toMap(),
      'severity': severity.toMap(),
      'currentValue': currentValue,
      'thresholdValue': thresholdValue,
      'deviationPercent': deviationPercent,
      'status': status.toMap(),
      'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt': acknowledgedAt != null 
          ? Timestamp.fromDate(acknowledgedAt!) 
          : null,
      'resolvedAt': resolvedAt != null 
          ? Timestamp.fromDate(resolvedAt!) 
          : null,
      'resolutionNotes': resolutionNotes,
      'notifiedUsers': notifiedUsers,
      'notifiedAt': notifiedAt != null 
          ? Timestamp.fromDate(notifiedAt!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'projectId': projectId,
      'phaseId': phaseId,
      'productId': productId,
    };
  }

  SLAAlert copyWith({
    String? id,
    String? organizationId,
    SLAEntityType? entityType,
    String? entityId,
    String? entityName,
    SLAAlertType? alertType,
    SLAAlertSeverity? severity,
    double? currentValue,
    double? thresholdValue,
    double? deviationPercent,
    SLAAlertStatus? status,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    List<String>? notifiedUsers,
    DateTime? notifiedAt,
    DateTime? createdAt,
    String? projectId,
    String? phaseId,
    String? productId,
  }) {
    return SLAAlert(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      currentValue: currentValue ?? this.currentValue,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      deviationPercent: deviationPercent ?? this.deviationPercent,
      status: status ?? this.status,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      notifiedUsers: notifiedUsers ?? this.notifiedUsers,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      createdAt: createdAt ?? this.createdAt,
      projectId: projectId ?? this.projectId,
      phaseId: phaseId ?? this.phaseId,
      productId: productId ?? this.productId,
    );
  }

  // ==================== HELPERS ====================

  bool get isActive => status == SLAAlertStatus.active;
  bool get isAcknowledged => status == SLAAlertStatus.acknowledged;
  bool get isResolved => status == SLAAlertStatus.resolved;

  bool get isCritical => severity == SLAAlertSeverity.critical;
  bool get isWarning => severity == SLAAlertSeverity.warning;

  /// Calcula las horas de exceso sobre el límite
  double get excessHours => currentValue - thresholdValue;

  /// Verifica si ya fue notificada
  bool get hasBeenNotified => notifiedAt != null;

  /// Tiempo transcurrido desde la creación
  Duration get ageOfAlert => DateTime.now().difference(createdAt);

  /// Descripción legible de la alerta
  String get description {
    switch (alertType) {
      case SLAAlertType.slaExceeded:
        return 'El SLA ha sido superado por ${excessHours.toStringAsFixed(1)}h';
      case SLAAlertType.slaWarning:
        return 'Se aproxima al límite SLA (${deviationPercent.toStringAsFixed(0)}%)';
      case SLAAlertType.phaseBlocked:
        return 'La fase está bloqueada';
      case SLAAlertType.wipLimitExceeded:
        return 'Se ha superado el límite WIP';
    }
  }
}