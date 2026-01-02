import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Estados del producto en el ciclo completo
enum ProductStatus {
  pending('pending', 'Pendiente', Colors.grey),
  cao('cao', 'CAO', Colors.red),
  hold('hold', 'Hold', Colors.orange),
  control('control', 'Control', Colors.blue),
  ok('ok', 'OK', Colors.green);

  final String value;
  final String displayName;
  final Color color;
  
  const ProductStatus(this.value, this.displayName, this.color);

  static ProductStatus fromString(String value) {
    return ProductStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => ProductStatus.pending,
    );
  }
}

/// Modelo de Producto dentro de un Lote de Producción
class BatchProductModel {
  final String id;
  final String batchId;
  final String productCatalogId; // Referencia al catálogo de productos
  final String productName;
  final String? productReference; // Referencia del catálogo
  final String? description;
  final int quantity;
  final String currentPhase; // Fase actual (phaseId)
  final String currentPhaseName;
  final Map<String, PhaseProgressData> phaseProgress; // phaseId -> progress
  
  // Personalización
  final String? color;
  final String? material;
  final String? specialDetails;
  
  // Precio (opcional, visible solo para roles autorizados)
  final double? unitPrice;
  final double? totalPrice;
  
  // Estado y bloqueo
  final bool isBlocked;
  final String? blockReason;
  
  // Control de calidad (para futuras fases)
  final String qualityStatus; // "pending", "approved", "rejected"
  final String? qualityNotes;
  final String? qualityCheckedBy;
  final DateTime? qualityCheckedAt;
  
  // Kanban (para futuras fases)
  final int kanbanPosition;
  final String? swimlane;
  
  // SLA (para futuras fases)
  final bool isDelayed;
  final double delayHours;
  final double? expectedDuration;
  final double? actualDuration;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // NUEVOS CAMPOS para estados
  final String productStatus; // "pending", "cao", "hold", "control", "ok"
  final DateTime? sentToClientAt; // Cuándo se envió al cliente
  final DateTime? evaluatedAt; // Cuándo el cliente lo evaluó
  final int returnedCount; // Productos devueltos (si CAO)
  final int repairedCount; // De los devueltos, cuántos se repararon
  final int discardedCount; // De los devueltos, cuántos son basura
  final String? returnReason; // Motivo de devolución

  BatchProductModel({
    required this.id,
    required this.batchId,
    required this.productCatalogId,
    required this.productName,
    this.productReference,
    this.description,
    required this.quantity,
    required this.currentPhase,
    required this.currentPhaseName,
    required this.phaseProgress,
    this.color,
    this.material,
    this.specialDetails,
    this.unitPrice,
    this.totalPrice,
    this.isBlocked = false,
    this.blockReason,
    this.qualityStatus = 'pending',
    this.qualityNotes,
    this.qualityCheckedBy,
    this.qualityCheckedAt,
    this.kanbanPosition = 0,
    this.swimlane,
    this.isDelayed = false,
    this.delayHours = 0,
    this.expectedDuration,
    this.actualDuration,
    required this.createdAt,
    required this.updatedAt,
    this.productStatus = 'pending',
    this.sentToClientAt,
    this.evaluatedAt,
    this.returnedCount = 0,
    this.repairedCount = 0,
    this.discardedCount = 0,
    this.returnReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'productCatalogId': productCatalogId,
      'productName': productName,
      'productReference': productReference,
      'description': description,
      'quantity': quantity,
      'currentPhase': currentPhase,
      'currentPhaseName': currentPhaseName,
      'phaseProgress': phaseProgress.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'color': color,
      'material': material,
      'specialDetails': specialDetails,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'isBlocked': isBlocked,
      'blockReason': blockReason,
      'qualityStatus': qualityStatus,
      'qualityNotes': qualityNotes,
      'qualityCheckedBy': qualityCheckedBy,
      'qualityCheckedAt': qualityCheckedAt != null
          ? Timestamp.fromDate(qualityCheckedAt!)
          : null,
      'kanbanPosition': kanbanPosition,
      'swimlane': swimlane,
      'isDelayed': isDelayed,
      'delayHours': delayHours,
      'expectedDuration': expectedDuration,
      'actualDuration': actualDuration,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'productStatus': productStatus,
      'sentToClientAt': sentToClientAt != null
          ? Timestamp.fromDate(sentToClientAt!)
          : null,
      'evaluatedAt': evaluatedAt != null
          ? Timestamp.fromDate(evaluatedAt!)
          : null,
      'returnedCount': returnedCount,
      'repairedCount': repairedCount,
      'discardedCount': discardedCount,
      'returnReason': returnReason,
    };
  }

  factory BatchProductModel.fromMap(Map<String, dynamic> map) {
    return BatchProductModel(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      productCatalogId: map['productCatalogId'] as String,
      productName: map['productName'] as String,
      productReference: map['productReference'] as String?,
      description: map['description'] as String?,
      quantity: map['quantity'] as int,
      currentPhase: map['currentPhase'] as String,
      currentPhaseName: map['currentPhaseName'] as String,
      phaseProgress: (map['phaseProgress'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          PhaseProgressData.fromMap(value as Map<String, dynamic>),
        ),
      ),
      color: map['color'] as String?,
      material: map['material'] as String?,
      specialDetails: map['specialDetails'] as String?,
      unitPrice: map['unitPrice'] != null ? (map['unitPrice'] as num).toDouble() : null,
      totalPrice: map['totalPrice'] != null ? (map['totalPrice'] as num).toDouble() : null,
      isBlocked: map['isBlocked'] as bool? ?? false,
      blockReason: map['blockReason'] as String?,
      qualityStatus: map['qualityStatus'] as String? ?? 'pending',
      qualityNotes: map['qualityNotes'] as String?,
      qualityCheckedBy: map['qualityCheckedBy'] as String?,
      qualityCheckedAt: map['qualityCheckedAt'] != null
          ? (map['qualityCheckedAt'] as Timestamp).toDate()
          : null,
      kanbanPosition: map['kanbanPosition'] as int? ?? 0,
      swimlane: map['swimlane'] as String?,
      isDelayed: map['isDelayed'] as bool? ?? false,
      delayHours: (map['delayHours'] as num?)?.toDouble() ?? 0,
      expectedDuration: map['expectedDuration'] != null
          ? (map['expectedDuration'] as num).toDouble()
          : null,
      actualDuration: map['actualDuration'] != null
          ? (map['actualDuration'] as num).toDouble()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      productStatus: map['productStatus'] as String? ?? 'pending',
      sentToClientAt: map['sentToClientAt'] != null
          ? (map['sentToClientAt'] as Timestamp).toDate()
          : null,
      evaluatedAt: map['evaluatedAt'] != null
          ? (map['evaluatedAt'] as Timestamp).toDate()
          : null,
      returnedCount: map['returnedCount'] as int? ?? 0,
      repairedCount: map['repairedCount'] as int? ?? 0,
      discardedCount: map['discardedCount'] as int? ?? 0,
      returnReason: map['returnReason'] as String?,
    );
  }

  BatchProductModel copyWith({
    String? id,
    String? batchId,
    String? productCatalogId,
    String? productName,
    String? productReference,
    String? description,
    int? quantity,
    String? currentPhase,
    String? currentPhaseName,
    Map<String, PhaseProgressData>? phaseProgress,
    String? color,
    String? material,
    String? specialDetails,
    double? unitPrice,
    double? totalPrice,
    bool? isBlocked,
    String? blockReason,
    String? qualityStatus,
    String? qualityNotes,
    String? qualityCheckedBy,
    DateTime? qualityCheckedAt,
    int? kanbanPosition,
    String? swimlane,
    bool? isDelayed,
    double? delayHours,
    double? expectedDuration,
    double? actualDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productStatus,
    DateTime? sentToClientAt,
    DateTime? evaluatedAt,
    int? returnedCount,
    int? repairedCount,
    int? discardedCount,
    String? returnReason,
  }) {
    return BatchProductModel(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      productCatalogId: productCatalogId ?? this.productCatalogId,
      productName: productName ?? this.productName,
      productReference: productReference ?? this.productReference,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      currentPhase: currentPhase ?? this.currentPhase,
      currentPhaseName: currentPhaseName ?? this.currentPhaseName,
      phaseProgress: phaseProgress ?? this.phaseProgress,
      color: color ?? this.color,
      material: material ?? this.material,
      specialDetails: specialDetails ?? this.specialDetails,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
      qualityStatus: qualityStatus ?? this.qualityStatus,
      qualityNotes: qualityNotes ?? this.qualityNotes,
      qualityCheckedBy: qualityCheckedBy ?? this.qualityCheckedBy,
      qualityCheckedAt: qualityCheckedAt ?? this.qualityCheckedAt,
      kanbanPosition: kanbanPosition ?? this.kanbanPosition,
      swimlane: swimlane ?? this.swimlane,
      isDelayed: isDelayed ?? this.isDelayed,
      delayHours: delayHours ?? this.delayHours,
      expectedDuration: expectedDuration ?? this.expectedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productStatus: productStatus ?? this.productStatus,
      sentToClientAt: sentToClientAt ?? this.sentToClientAt,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      returnedCount: returnedCount ?? this.returnedCount,
      repairedCount: repairedCount ?? this.repairedCount,
      discardedCount: discardedCount ?? this.discardedCount,
      returnReason: returnReason ?? this.returnReason,
    );
  }

  /// Progreso total del producto (0.0 a 1.0)
double get totalProgress {
    // CAMBIO: Si está en Studio, es 100% automáticamente
    if (currentPhase == 'studio') return 1.0;

    if (phaseProgress.isEmpty) return 0.0;
    
    int completedPhases = phaseProgress.values
        .where((phase) => phase.status == 'completed')
        .length;
    
    return completedPhases / phaseProgress.length;
  }

  /// Porcentaje de progreso (0 a 100)
  int get progressPercentage => (totalProgress * 100).round();

  /// Si el producto está completado (todas las fases)
  bool get isCompleted {
    return phaseProgress.values.every((phase) => phase.status == 'completed');
  }

  /// Número de fases completadas
  int get completedPhasesCount {
    return phaseProgress.values
        .where((phase) => phase.status == 'completed')
        .length;
  }

  /// Número total de fases
  int get totalPhasesCount => phaseProgress.length;

  
  ProductStatus get statusEnum => ProductStatus.fromString(productStatus);
  String get statusDisplayName => statusEnum.displayName;
  Color get statusColor => statusEnum.color;
  
  bool get isPending => productStatus == 'pending';
  bool get isHold => productStatus == 'hold';
  bool get isCAO => productStatus == 'cao';
  bool get isControl => productStatus == 'control';
  bool get isOK => productStatus == 'ok';
  
  bool get isInStudio => currentPhase == 'studio';
  bool get hasBeenSent => sentToClientAt != null;
  bool get hasBeenEvaluated => evaluatedAt != null;
  bool get hasReturns => returnedCount > 0;
  
  // Validar que reparados + basura = devueltos
  bool get isReturnBalanced => (repairedCount + discardedCount) == returnedCount;
}



/// Datos de progreso por fase
class PhaseProgressData {
  final String status; // "pending", "in_progress", "completed"
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completedBy;
  final String? completedByName;
  final String? notes;

  PhaseProgressData({
    required this.status,
    this.startedAt,
    this.completedAt,
    this.completedBy,
    this.completedByName,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'completedByName': completedByName,
      'notes': notes,
    };
  }

  factory PhaseProgressData.fromMap(Map<String, dynamic> map) {
    return PhaseProgressData(
      status: map['status'] as String,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      completedBy: map['completedBy'] as String?,
      completedByName: map['completedByName'] as String?,
      notes: map['notes'] as String?,
    );
  }

  PhaseProgressData copyWith({
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completedBy,
    String? completedByName,
    String? notes,
  }) {
    return PhaseProgressData(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      completedByName: completedByName ?? this.completedByName,
      notes: notes ?? this.notes,
    );
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
}