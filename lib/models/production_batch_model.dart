import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado del lote de producción
enum BatchStatus {
  pending('pending', 'Pendiente'),
  inProgress('in_progress', 'En Producción'),
  completed('completed', 'Completado');

  final String value;
  final String displayName;
  const BatchStatus(this.value, this.displayName);

  static BatchStatus fromString(String value) {
    return BatchStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BatchStatus.pending,
    );
  }
}

/// Modelo de Lote de Producción (Orden de Fabricación)
class ProductionBatchModel {
  final String id;
  final String batchNumber; // Número de lote auto-generado (ej: LOT-2026-001)
  final String projectId;
  final String projectName;
  final String clientId;
  final String clientName;
  final String organizationId;
  final String status;
  final String? notes;
  final int totalProducts; // Total de productos en el lote
  final int completedProducts; // Productos completados
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos para futuras fases (SLA, Kanban)
  final int priority; // 1-5 (1=máxima)
  final String urgencyLevel; // "low", "medium", "high", "critical"
  final bool isDelayed;
  final double delayHours;
  final DateTime? expectedCompletionDate;
  final DateTime? startedAt; // Cuándo empezó producción real
  final DateTime? actualCompletionDate;

  ProductionBatchModel({
    required this.id,
    required this.batchNumber,
    required this.projectId,
    required this.projectName,
    required this.clientId,
    required this.clientName,
    required this.organizationId,
    required this.status,
    this.notes,
    this.totalProducts = 0,
    this.completedProducts = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.priority = 3,
    this.urgencyLevel = 'medium',
    this.isDelayed = false,
    this.delayHours = 0,
    this.expectedCompletionDate,
    this.startedAt,
    this.actualCompletionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchNumber': batchNumber,
      'projectId': projectId,
      'projectName': projectName,
      'clientId': clientId,
      'clientName': clientName,
      'organizationId': organizationId,
      'status': status,
      'notes': notes,
      'totalProducts': totalProducts,
      'completedProducts': completedProducts,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'priority': priority,
      'urgencyLevel': urgencyLevel,
      'isDelayed': isDelayed,
      'delayHours': delayHours,
      'expectedCompletionDate': expectedCompletionDate != null 
          ? Timestamp.fromDate(expectedCompletionDate!) 
          : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'actualCompletionDate': actualCompletionDate != null 
          ? Timestamp.fromDate(actualCompletionDate!) 
          : null,
    };
  }

  factory ProductionBatchModel.fromMap(Map<String, dynamic> map) {
    return ProductionBatchModel(
      id: map['id'] as String,
      batchNumber: map['batchNumber'] as String,
      projectId: map['projectId'] as String,
      projectName: map['projectName'] as String,
      clientId: map['clientId'] as String,
      clientName: map['clientName'] as String,
      organizationId: map['organizationId'] as String,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      totalProducts: map['totalProducts'] as int? ?? 0,
      completedProducts: map['completedProducts'] as int? ?? 0,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      priority: map['priority'] as int? ?? 3,
      urgencyLevel: map['urgencyLevel'] as String? ?? 'medium',
      isDelayed: map['isDelayed'] as bool? ?? false,
      delayHours: (map['delayHours'] as num?)?.toDouble() ?? 0,
      expectedCompletionDate: map['expectedCompletionDate'] != null
          ? (map['expectedCompletionDate'] as Timestamp).toDate()
          : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      actualCompletionDate: map['actualCompletionDate'] != null
          ? (map['actualCompletionDate'] as Timestamp).toDate()
          : null,
    );
  }

  ProductionBatchModel copyWith({
    String? id,
    String? batchNumber,
    String? projectId,
    String? projectName,
    String? clientId,
    String? clientName,
    String? organizationId,
    String? status,
    String? notes,
    int? totalProducts,
    int? completedProducts,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? priority,
    String? urgencyLevel,
    bool? isDelayed,
    double? delayHours,
    DateTime? expectedCompletionDate,
    DateTime? startedAt,
    DateTime? actualCompletionDate,
  }) {
    return ProductionBatchModel(
      id: id ?? this.id,
      batchNumber: batchNumber ?? this.batchNumber,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      organizationId: organizationId ?? this.organizationId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      totalProducts: totalProducts ?? this.totalProducts,
      completedProducts: completedProducts ?? this.completedProducts,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      isDelayed: isDelayed ?? this.isDelayed,
      delayHours: delayHours ?? this.delayHours,
      expectedCompletionDate: expectedCompletionDate ?? this.expectedCompletionDate,
      startedAt: startedAt ?? this.startedAt,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
    );
  }

  // Getters útiles
  BatchStatus get statusEnum => BatchStatus.fromString(status);
  String get statusDisplayName => statusEnum.displayName;

  /// Progreso del lote (0.0 a 1.0)
  double get progress {
    if (totalProducts == 0) return 0.0;
    return completedProducts / totalProducts;
  }

  /// Porcentaje de progreso (0 a 100)
  int get progressPercentage => (progress * 100).round();

  /// Indica si el lote está completo
  bool get isComplete => completedProducts >= totalProducts && totalProducts > 0;

  /// Productos pendientes
  int get pendingProducts => totalProducts - completedProducts;

  /// Si está en progreso
  bool get isPending => status == BatchStatus.pending.value;
  bool get isInProgress => status == BatchStatus.inProgress.value;
  bool get isCompleted => status == BatchStatus.completed.value;
}