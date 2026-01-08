import 'package:cloud_firestore/cloud_firestore.dart';

enum PhaseStatus {
  pending,
  inProgress,
  completed;

  String get displayName {
    switch (this) {
      case PhaseStatus.pending:
        return 'Pendiente';
      case PhaseStatus.inProgress:
        return 'En Proceso';
      case PhaseStatus.completed:
        return 'Completado';
    }
  }

  static PhaseStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PhaseStatus.pending;
      case 'inprogress':
      case 'in_progress':
        return PhaseStatus.inProgress;
      case 'completed':
        return PhaseStatus.completed;
      default:
        return PhaseStatus.pending;
    }
  }

  String toMap() {
    return toString().split('.').last;
  }
}

/// Modelo principal de Fase de Producción (a nivel de organización)
class ProductionPhase {
  final String id;
  final String name;
  final String description;
  final int order;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // ==================== PERSONALIZACIÓN VISUAL ====================
  /// Color en formato hex (#RRGGBB)
  final String color;
  
  /// Nombre del icono (usamos Material Icons names)
  final String icon;
  
  /// Posición en el Kanban (para reordenar columnas visualmente)
  final int kanbanPosition;
  
  // ==================== KANBAN WIP LIMITS ====================
  /// Límite de Work-In-Progress (máximo de productos permitidos en esta fase)
  final int wipLimit;
  
  // ==================== SLA Y ALERTAS ====================
  /// Tiempo máximo permitido en horas para esta fase (SLA)
  final int? maxDurationHours;
  
  /// Umbral de advertencia como porcentaje del maxDurationHours (ej: 80 = alerta al 80%)
  final int? warningThresholdPercent;
  
  // ==================== MÉTRICAS CALCULADAS (Analytics) ====================
  /// Tiempo promedio real de productos en esta fase (calculado por Cloud Functions)
  final double? averageDurationHours;
  
  /// Tiempo mínimo registrado
  final double? minDurationHours;
  
  /// Tiempo máximo registrado
  final double? maxDurationHistoryHours;

  ProductionPhase({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    // Defaults para personalización
    this.color = '#2196F3',
    this.icon = 'work',
    this.kanbanPosition = 0,
    this.wipLimit = 10,
    // SLA opcionales
    this.maxDurationHours,
    this.warningThresholdPercent = 80,
    // Métricas (calculadas externamente)
    this.averageDurationHours,
    this.minDurationHours,
    this.maxDurationHistoryHours,
  });

  factory ProductionPhase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductionPhase(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      color: data['color'] ?? '#2196F3',
      icon: data['icon'] ?? 'work',
      kanbanPosition: data['kanbanPosition'] ?? 0,
      wipLimit: data['wipLimit'] ?? 10,
      maxDurationHours: data['maxDurationHours'],
      warningThresholdPercent: data['warningThresholdPercent'] ?? 80,
      averageDurationHours: data['averageDurationHours']?.toDouble(),
      minDurationHours: data['minDurationHours']?.toDouble(),
      maxDurationHistoryHours: data['maxDurationHistoryHours']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'order': order,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'color': color,
      'icon': icon,
      'kanbanPosition': kanbanPosition,
      'wipLimit': wipLimit,
      'maxDurationHours': maxDurationHours,
      'warningThresholdPercent': warningThresholdPercent,
      'averageDurationHours': averageDurationHours,
      'minDurationHours': minDurationHours,
      'maxDurationHistoryHours': maxDurationHistoryHours,
    };
  }

  ProductionPhase copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? icon,
    int? kanbanPosition,
    int? wipLimit,
    int? maxDurationHours,
    int? warningThresholdPercent,
    double? averageDurationHours,
    double? minDurationHours,
    double? maxDurationHistoryHours,
  }) {
    return ProductionPhase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      kanbanPosition: kanbanPosition ?? this.kanbanPosition,
      wipLimit: wipLimit ?? this.wipLimit,
      maxDurationHours: maxDurationHours ?? this.maxDurationHours,
      warningThresholdPercent: warningThresholdPercent ?? this.warningThresholdPercent,
      averageDurationHours: averageDurationHours ?? this.averageDurationHours,
      minDurationHours: minDurationHours ?? this.minDurationHours,
      maxDurationHistoryHours: maxDurationHistoryHours ?? this.maxDurationHistoryHours,
    );
  }

  // ==================== HELPERS ====================
  
  /// Calcula las horas de advertencia basado en el threshold
  int? get warningHours {
    if (maxDurationHours == null || warningThresholdPercent == null) return null;
    return ((maxDurationHours! * warningThresholdPercent!) / 100).round();
  }

  /// Verifica si tiene SLA configurado
  bool get hasSLA => maxDurationHours != null && maxDurationHours! > 0;

  /// Valida si un color hex es válido
  bool get hasValidColor {
    final hexColor = color.replaceAll('#', '');
    return hexColor.length == 6 && int.tryParse(hexColor, radix: 16) != null;
  }

  // ==================== FASES PREDETERMINADAS ====================
  
  /// Retorna las fases por defecto para una nueva organización
  static List<ProductionPhase> getDefaultPhases() {
    final now = DateTime.now();
    return [
      ProductionPhase(
        id: 'planned',
        name: 'Planned',
        description: 'Planificación inicial del pedido',
        order: 1,
        isActive: true,
        createdAt: now,
        color: '#9E9E9E',
        icon: 'assignment',
        wipLimit: 15,
        maxDurationHours: 24,
        kanbanPosition: 1,
      ),
      ProductionPhase(
        id: 'cutting',
        name: 'Cutting',
        description: 'Corte de materiales',
        order: 2,
        isActive: true,
        createdAt: now,
        color: '#FF9800',
        icon: 'content_cut',
        wipLimit: 10,
        maxDurationHours: 48,
        kanbanPosition: 2,
      ),
      ProductionPhase(
        id: 'skiving',
        name: 'Skiving',
        description: 'Rebajado de piel',
        order: 3,
        isActive: true,
        createdAt: now,
        color: '#2196F3',
        icon: 'layers',
        wipLimit: 8,
        maxDurationHours: 36,
        kanbanPosition: 3,
      ),
      ProductionPhase(
        id: 'assembly',
        name: 'Assembly',
        description: 'Ensamblaje del producto',
        order: 4,
        isActive: true,
        createdAt: now,
        color: '#4CAF50',
        icon: 'construction',
        wipLimit: 12,
        maxDurationHours: 72,
        kanbanPosition: 4,
      ),
      ProductionPhase(
        id: 'studio',
        name: 'Studio',
        description: 'Finalización y revisión',
        order: 5,
        isActive: true,
        createdAt: now,
        color: '#9C27B0',
        icon: 'palette',
        wipLimit: 10,
        maxDurationHours: 24,
        kanbanPosition: 5,
      ),
    ];
  }
}

/// Progreso de fase para un producto específico
class ProductPhaseProgress {
  final String id;
  final String productId;
  final String phaseId;
  final String phaseName;
  final int phaseOrder;
  final PhaseStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? startedByUserId;
  final String? startedByUserName;
  final String? completedByUserId;
  final String? completedByUserName;
  final String? notes;

  ProductPhaseProgress({
    required this.id,
    required this.productId,
    required this.phaseId,
    required this.phaseName,
    required this.phaseOrder,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.startedByUserId,
    this.startedByUserName,
    this.completedByUserId,
    this.completedByUserName,
    this.notes,
  });

  factory ProductPhaseProgress.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductPhaseProgress(
      id: doc.id,
      productId: data['productId'] ?? '',
      phaseId: data['phaseId'] ?? '',
      phaseName: data['phaseName'] ?? '',
      phaseOrder: data['phaseOrder'] ?? 0,
      status: PhaseStatus.fromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      startedByUserId: data['startedByUserId'],
      startedByUserName: data['startedByUserName'],
      completedByUserId: data['completedByUserId'],
      completedByUserName: data['completedByUserName'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'phaseId': phaseId,
      'phaseName': phaseName,
      'phaseOrder': phaseOrder,
      'status': status.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'startedByUserId': startedByUserId,
      'startedByUserName': startedByUserName,
      'completedByUserId': completedByUserId,
      'completedByUserName': completedByUserName,
      'notes': notes,
    };
  }

  ProductPhaseProgress copyWith({
    String? id,
    String? productId,
    String? phaseId,
    String? phaseName,
    int? phaseOrder,
    PhaseStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? startedByUserId,
    String? startedByUserName,
    String? completedByUserId,
    String? completedByUserName,
    String? notes,
  }) {
    return ProductPhaseProgress(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      phaseId: phaseId ?? this.phaseId,
      phaseName: phaseName ?? this.phaseName,
      phaseOrder: phaseOrder ?? this.phaseOrder,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      startedByUserId: startedByUserId ?? this.startedByUserId,
      startedByUserName: startedByUserName ?? this.startedByUserName,
      completedByUserId: completedByUserId ?? this.completedByUserId,
      completedByUserName: completedByUserName ?? this.completedByUserName,
      notes: notes ?? this.notes,
    );
  }

  // ==================== HELPERS ====================
  
  double get progressPercentage {
    switch (status) {
      case PhaseStatus.pending:
        return 0.0;
      case PhaseStatus.inProgress:
        return 0.5;
      case PhaseStatus.completed:
        return 1.0;
    }
  }

  bool get isPending => status == PhaseStatus.pending;
  bool get isInProgress => status == PhaseStatus.inProgress;
  bool get isCompleted => status == PhaseStatus.completed;

  /// Calcula las horas transcurridas en la fase actual
  int? get hoursInCurrentStatus {
    DateTime? referenceDate;
    
    if (isCompleted && completedAt != null && startedAt != null) {
      // Si está completada, calcular duración total
      return completedAt!.difference(startedAt!).inHours;
    } else if (isInProgress && startedAt != null) {
      // Si está en progreso, calcular desde inicio hasta ahora
      return DateTime.now().difference(startedAt!).inHours;
    }
    
    return null;
  }

  /// Verifica si la fase está pendiente por más de X horas desde creación
  bool isPendingTooLong(int maxPendingHours) {
    if (!isPending) return false;
    final hoursPending = DateTime.now().difference(createdAt).inHours;
    return hoursPending > maxPendingHours;
  }
}