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

class ProductionPhase {
  final String id;
  final String name;
  final String description;
  final int order;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Campos Kanban (FASE 6)
  final String color;
  final String icon;
  final int wipLimit;
  final int kanbanPosition;
  
  // Campos para SLA (FASE 5 - futuro)
  final int? maxDurationHours;
  final int? warningThresholdPercent;
  final double? averageDurationHours;
  final int? minDurationHours;
  final int? maxDurationHistoryHours;

  ProductionPhase({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    required this.order,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.color = '#2196F3',
    this.icon = 'work',
    this.wipLimit = 10,
    this.kanbanPosition = 0,
    this.maxDurationHours,
    this.warningThresholdPercent,
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
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      color: data['color'] ?? '#2196F3',
      icon: data['icon'] ?? 'work',
      wipLimit: data['wipLimit'] ?? 10,
      kanbanPosition: data['kanbanPosition'] ?? 0,
      maxDurationHours: data['maxDurationHours'],
      warningThresholdPercent: data['warningThresholdPercent'],
      averageDurationHours: data['averageDurationHours']?.toDouble(),
      minDurationHours: data['minDurationHours'],
      maxDurationHistoryHours: data['maxDurationHistoryHours'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isActive': isActive,
      'description': description,
      'order': order,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'color': color,
      'icon': icon,
      'wipLimit': wipLimit,
      'kanbanPosition': kanbanPosition,
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
    bool? isActive,
    String? description,
    int? order,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? icon,
    int? wipLimit,
    int? kanbanPosition,
    int? maxDurationHours,
    int? warningThresholdPercent,
    double? averageDurationHours,
    int? minDurationHours,
    int? maxDurationHistoryHours,
  }) {
    return ProductionPhase(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      order: order ?? this.order,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      wipLimit: wipLimit ?? this.wipLimit,
      kanbanPosition: kanbanPosition ?? this.kanbanPosition,
      maxDurationHours: maxDurationHours ?? this.maxDurationHours,
      warningThresholdPercent: warningThresholdPercent ?? this.warningThresholdPercent,
      averageDurationHours: averageDurationHours ?? this.averageDurationHours,
      minDurationHours: minDurationHours ?? this.minDurationHours,
      maxDurationHistoryHours: maxDurationHistoryHours ?? this.maxDurationHistoryHours,
    );
  }
  
  static List<ProductionPhase> getDefaultPhases() {
    final now = DateTime.now();
    return [
      ProductionPhase(
        id: 'planned',
        name: 'Planned',
        order: 1,
        isActive: true,
        description: 'Planificación inicial del pedido',
        createdAt: now,
      ),
      ProductionPhase(
        id: 'cutting',
        name: 'Cutting',
        order: 2,
        isActive: true,
        description: 'Corte de materiales',
        createdAt: now,
      ),
      ProductionPhase(
        id: 'skiving',
        name: 'Skiving',
        order: 3,
        isActive: true,
        description: 'Rebajado de piel',
        createdAt: now,
      ),
      ProductionPhase(
        id: 'assembly',
        name: 'Assembly',
        order: 4,
        isActive: true,
        description: 'Ensamblaje del producto',
        createdAt: now,
      ),
      ProductionPhase(
        id: 'studio',
        name: 'Studio',
        order: 5,
        isActive: true,
        description: 'Finalización',
        createdAt: now,
      ),
    ];
  }
}

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
}