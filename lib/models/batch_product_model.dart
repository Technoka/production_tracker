// ... Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'production_batch_model.dart';

/// Estados del producto en el ciclo completo (LEGACY - mantener por compatibilidad)
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

/// Entrada en el historial de estados
class StatusHistoryEntry {
  final String statusId;
  final String statusName;
  final String statusColor;
  final String statusIcon;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final Map<String, dynamic>? validationData; // Datos de la validación aplicada
  final String? notes;

  StatusHistoryEntry({
    required this.statusId,
    required this.statusName,
    required this.statusColor,
    required this.statusIcon,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.validationData,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'statusName': statusName,
      'statusColor': statusColor,
      'statusIcon': statusIcon,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'userName': userName,
      'validationData': validationData != null ? validationData : null,
      'notes': notes,
    };
  }

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      statusId: map['statusId'] as String,
      statusName: map['statusName'] as String,
      statusColor: map['statusColor'] as String? ?? '#757575',
      statusIcon: map['statusIcon'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      validationData: map['validationData'] != null ? map['validationData'] as Map<String, dynamic>? : null,
      notes: map['notes'] != null ? map['notes'] as String? : null,
    );
  }
}

/// Modelo de Producto dentro de un Lote de Producción
class BatchProductModel {
  // ... Campos existentes
  final String id;
  final String batchId;
  final String productCatalogId;
  final String productName;
  final String? productReference;
  final String? family;
  final String? description;
  final int quantity;
  final String currentPhase; // Fase actual (phaseId)
  final String currentPhaseName;
  final Map<String, PhaseProgressData> phaseProgress;
  final int productNumber;
  final String productCode;
  final String? color;
  final String? material;
  final String? specialDetails;
  final double? unitPrice;
  final double? totalPrice;
  final String qualityStatus;
  final String? qualityNotes;
  final String? qualityCheckedBy;
  final DateTime? qualityCheckedAt;
  final int kanbanPosition;
  final String? swimlane;
  final bool isDelayed;
  final double delayHours;
  final double? expectedDuration;
  final double? actualDuration;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // DEPRECAR GRADUALMENTE (mantener por compatibilidad)
  final String productStatus; // "pending", "cao", "hold", "control", "ok"
  
  // NUEVOS CAMPOS - Estados personalizables
  final String? statusId; // ID del estado personalizado
  final String? statusName; // Nombre desnormalizado del estado
  final String? statusColor; // Color desnormalizado (hex)
  final String? statusIcon;
  final List<StatusHistoryEntry> statusHistory; // Historial de cambios de estado
  
  final DateTime? sentToClientAt;
  final DateTime? evaluatedAt;
  final int returnedCount;
  final int repairedCount;
  final int discardedCount;
  final String? returnReason;
  final DateTime? expectedDeliveryDate;
  final String urgencyLevel;
  final String? productNotes;

  BatchProductModel({
    required this.id,
    required this.batchId,
    required this.productCatalogId,
    required this.productName,
    this.productReference,
    this.family,
    this.description,
    required this.quantity,
    required this.currentPhase,
    required this.currentPhaseName,
    required this.phaseProgress,
    required this.productNumber,
    required this.productCode,
    this.color,
    this.material,
    this.specialDetails,
    this.unitPrice,
    this.totalPrice,
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
    this.statusId,
    this.statusName,
    this.statusColor,
    this.statusIcon,
    this.statusHistory = const [],
    this.sentToClientAt,
    this.evaluatedAt,
    this.returnedCount = 0,
    this.repairedCount = 0,
    this.discardedCount = 0,
    this.returnReason,
    this.expectedDeliveryDate,
    this.urgencyLevel = 'medium',
    this.productNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'productCatalogId': productCatalogId,
      'productName': productName,
      'productReference': productReference,
      'family': family,
      'description': description,
      'quantity': quantity,
      'currentPhase': currentPhase,
      'currentPhaseName': currentPhaseName,
      'phaseProgress': phaseProgress.map((key, value) => MapEntry(key, value.toMap())),
      'productNumber': productNumber,
      'productCode': productCode,
      'color': color,
      'material': material,
      'specialDetails': specialDetails,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'qualityStatus': qualityStatus,
      'qualityNotes': qualityNotes,
      'qualityCheckedBy': qualityCheckedBy,
      'qualityCheckedAt': qualityCheckedAt != null ? Timestamp.fromDate(qualityCheckedAt!) : null,
      'kanbanPosition': kanbanPosition,
      'swimlane': swimlane,
      'isDelayed': isDelayed,
      'delayHours': delayHours,
      'expectedDuration': expectedDuration,
      'actualDuration': actualDuration,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'productStatus': productStatus, // Legacy
      'statusId': statusId, // Nuevo
      'statusName': statusName, // Nuevo
      'statusColor': statusColor, // Nuevo
      'statusIcon': statusIcon,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(), // Nuevo
      'sentToClientAt': sentToClientAt != null ? Timestamp.fromDate(sentToClientAt!) : null,
      'evaluatedAt': evaluatedAt != null ? Timestamp.fromDate(evaluatedAt!) : null,
      'returnedCount': returnedCount,
      'repairedCount': repairedCount,
      'discardedCount': discardedCount,
      'returnReason': returnReason,
      'expectedDeliveryDate': expectedDeliveryDate != null ? Timestamp.fromDate(expectedDeliveryDate!) : null,
      'urgencyLevel': urgencyLevel,
      'productNotes': productNotes,
    };
  }

  factory BatchProductModel.fromMap(Map<String, dynamic> map) {
    // Parsear historial de estados
    List<StatusHistoryEntry> history = [];
    if (map['statusHistory'] != null) {
      final historyList = map['statusHistory'] as List;
      history = historyList
          .map((e) => StatusHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return BatchProductModel(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      productCatalogId: map['productCatalogId'] as String,
      productName: map['productName'] as String,
      productReference: map['productReference'] as String?,
      family: map['family'] as String?,
      description: map['description'] as String?,
      quantity: map['quantity'] as int,
      currentPhase: map['currentPhase'] as String,
      currentPhaseName: map['currentPhaseName'] as String,
      phaseProgress: (map['phaseProgress'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PhaseProgressData.fromMap(value as Map<String, dynamic>)),
      ),
      productNumber: map['productNumber'] as int? ?? 1,
      productCode: map['productCode'] as String? ?? '',
      color: map['color'] as String?,
      material: map['material'] as String?,
      specialDetails: map['specialDetails'] as String?,
      unitPrice: map['unitPrice'] != null ? (map['unitPrice'] as num).toDouble() : null,
      totalPrice: map['totalPrice'] != null ? (map['totalPrice'] as num).toDouble() : null,
      qualityStatus: map['qualityStatus'] as String? ?? 'pending',
      qualityNotes: map['qualityNotes'] as String?,
      qualityCheckedBy: map['qualityCheckedBy'] as String?,
      qualityCheckedAt: map['qualityCheckedAt'] != null ? (map['qualityCheckedAt'] as Timestamp).toDate() : null,
      kanbanPosition: map['kanbanPosition'] as int? ?? 0,
      swimlane: map['swimlane'] as String?,
      isDelayed: map['isDelayed'] as bool? ?? false,
      delayHours: (map['delayHours'] as num?)?.toDouble() ?? 0,
      expectedDuration: map['expectedDuration'] != null ? (map['expectedDuration'] as num).toDouble() : null,
      actualDuration: map['actualDuration'] != null ? (map['actualDuration'] as num).toDouble() : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      productStatus: map['productStatus'] as String? ?? 'pending',
      statusId: map['statusId'] as String?,
      statusName: map['statusName'] as String?,
      statusColor: map['statusColor'] as String?,
      statusIcon: map['statusIcon'] as String?,
      statusHistory: history,
      sentToClientAt: map['sentToClientAt'] != null ? (map['sentToClientAt'] as Timestamp).toDate() : null,
      evaluatedAt: map['evaluatedAt'] != null ? (map['evaluatedAt'] as Timestamp).toDate() : null,
      returnedCount: map['returnedCount'] as int? ?? 0,
      repairedCount: map['repairedCount'] as int? ?? 0,
      discardedCount: map['discardedCount'] as int? ?? 0,
      returnReason: map['returnReason'] as String?,
      expectedDeliveryDate: map['expectedDeliveryDate'] != null ? (map['expectedDeliveryDate'] as Timestamp).toDate() : null,
      urgencyLevel: map['urgencyLevel'] as String? ?? 'medium',
      productNotes: map['productNotes'] as String?,
    );
  }

  BatchProductModel copyWith({
    String? id,
    String? batchId,
    String? productCatalogId,
    String? productName,
    String? productReference,
    String? family,
    String? description,
    int? quantity,
    String? currentPhase,
    String? currentPhaseName,
    Map<String, PhaseProgressData>? phaseProgress,
    int? productNumber,
    String? productCode,
    String? color,
    String? material,
    String? specialDetails,
    double? unitPrice,
    double? totalPrice,
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
    String? statusId,
    String? statusName,
    String? statusColorValue, // Renombrado el parámetro para evitar conflicto
    String? statusIcon,
    List<StatusHistoryEntry>? statusHistory,
    DateTime? sentToClientAt,
    DateTime? evaluatedAt,
    int? returnedCount,
    int? repairedCount,
    int? discardedCount,
    String? returnReason,
    DateTime? expectedDeliveryDate,
    String? urgencyLevel,
    String? productNotes,
  }) {
    return BatchProductModel(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      productCatalogId: productCatalogId ?? this.productCatalogId,
      productName: productName ?? this.productName,
      productReference: productReference ?? this.productReference,
      family: family ?? this.family,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      currentPhase: currentPhase ?? this.currentPhase,
      currentPhaseName: currentPhaseName ?? this.currentPhaseName,
      phaseProgress: phaseProgress ?? this.phaseProgress,
      productNumber: productNumber ?? this.productNumber,
      productCode: productCode ?? this.productCode,
      color: color ?? this.color,
      material: material ?? this.material,
      specialDetails: specialDetails ?? this.specialDetails,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
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
      statusId: statusId ?? this.statusId,
      statusName: statusName ?? this.statusName,
      statusColor: statusColorValue ?? this.statusColor, // Usar parámetro renombrado
      statusHistory: statusHistory ?? this.statusHistory,
      sentToClientAt: sentToClientAt ?? this.sentToClientAt,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      returnedCount: returnedCount ?? this.returnedCount,
      repairedCount: repairedCount ?? this.repairedCount,
      discardedCount: discardedCount ?? this.discardedCount,
      returnReason: returnReason ?? this.returnReason,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      productNotes: productNotes ?? this.productNotes,
    );
  }

  /// Progreso total del producto (0.0 a 1.0)
  double get totalProgress {
    // Si está en Studio, es 100% automáticamente
    if (currentPhase == 'studio') return 1.0;

    if (phaseProgress.isEmpty) return 0.0;
    
    int completedPhases = phaseProgress.values
        .where((phase) => phase.status == 'completed')
        .length;
    
    return completedPhases / phaseProgress.length;
  }

  /// Devuelve la diferencia de días entre la fecha de creación y hoy
  int getDaysInCurrentPhase() {
    final now = DateTime.now();
    return now.difference(createdAt).inDays;
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

  // ==================== HELPERS DE ESTADO (LEGACY) ====================
  ProductStatus get statusEnum => ProductStatus.fromString(productStatus);
  String get statusDisplayName => statusEnum.displayName;
  Color get statusLegacyColor => statusEnum.color; // Renombrado para evitar conflicto
  
  bool get isPending => productStatus == 'pending';
  bool get isHold => productStatus == 'hold';
  bool get isCAO => productStatus == 'cao';
  bool get isControl => productStatus == 'control';
  bool get isOK => productStatus == 'ok';

  // ==================== HELPERS DE ESTADO (NUEVO SISTEMA) ====================
  
  /// Usar estado personalizado si existe, sino usar legacy
  String get effectiveStatusName => statusName ?? statusDisplayName;
  
  /// Usar color personalizado si existe, sino usar legacy
  Color get effectiveStatusColor {
    if (statusColor != null) {
      try {
        return Color(int.parse(statusColor!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Si falla el parsing, usar color legacy
        return statusLegacyColor;
      }
    }
    return statusLegacyColor;
  }
  
  /// Si usa el nuevo sistema de estados
  bool get usesCustomStatus => statusId != null;
  
  /// Obtener último cambio de estado del historial
  StatusHistoryEntry? get lastStatusChange {
    if (statusHistory.isEmpty) return null;
    return statusHistory.last;
  }
  
  /// Obtener todos los estados por los que ha pasado
  List<String> get statusesVisited {
    return statusHistory.map((e) => e.statusName).toList();
  }
  
  // ==================== HELPERS EXISTENTES ====================
  bool get isInStudio => currentPhase == 'studio';
  bool get hasBeenSent => sentToClientAt != null;
  bool get hasBeenEvaluated => evaluatedAt != null;
  bool get hasReturns => returnedCount > 0;
  
  // Validar que reparados + basura = devueltos
  bool get isReturnBalanced => (repairedCount + discardedCount) == returnedCount;
  
  // Helpers de urgencia:
  UrgencyLevel get urgencyEnum => UrgencyLevel.fromString(urgencyLevel);
  String get urgencyDisplayName => urgencyEnum.displayName;
  int get urgencyNumericValue => urgencyEnum.numericValue;
  Color get urgencyColor => urgencyEnum.color;
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
      status: map['status'] as String? ?? 'pending',
      startedAt: map['startedAt'] != null 
          ? (map['startedAt'] is Timestamp 
              ? (map['startedAt'] as Timestamp).toDate() 
              : null)
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] is Timestamp 
              ? (map['completedAt'] as Timestamp).toDate() 
              : null)
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
  bool get isControl => status == 'control';
  
}