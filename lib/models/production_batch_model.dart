import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

/// Nivel de urgencia del lote
enum UrgencyLevel {
  low('low', 'Baja', 1, Colors.green),
  medium('medium', 'Media', 2, Colors.orange),
  high('high', 'Alta', 3, Colors.red),
  urgent('urgent', 'Urgente', 4, Color(0xFFB71C1C));

  final String value;
  final String displayName;
  final int numericValue;
  final Color color;
  
  const UrgencyLevel(this.value, this.displayName, this.numericValue, this.color);

  static UrgencyLevel fromString(String value) {
    return UrgencyLevel.values.firstWhere(
      (level) => level.value == value.toLowerCase(),
      orElse: () => UrgencyLevel.medium,
    );
  }
}

/// Modelo de Lote de Producción (Orden de Fabricación)
class ProductionBatchModel {
  final String id;
  final String batchNumber; // Número de lote auto-generado (ej: LOT-2026-001)
  final String batchPrefix; // Prefijo de 3 caracteres (ej: FL1)
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
  
  // CAMBIO: Se elimina priority, solo urgencyLevel
  final String urgencyLevel; // "low", "medium", "high", "urgent"
  
  // Campos para futuras fases (SLA)
  final bool isDelayed;
  final double delayHours;
  final DateTime? expectedCompletionDate;
  final DateTime? startedAt; // Cuándo empezó producción real
  final DateTime? actualCompletionDate;
  
  // NUEVO: Contador de productos para generar números secuenciales
  final int productSequenceCounter; // Último número usado
  final List<String> assignedMembers; // UIDs de miembros asignados

  ProductionBatchModel({
    required this.id,
    required this.batchNumber,
    required this.batchPrefix,
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
    this.urgencyLevel = 'medium',
    this.isDelayed = false,
    this.delayHours = 0,
    this.expectedCompletionDate,
    this.startedAt,
    this.actualCompletionDate,
    this.productSequenceCounter = 0,
    required this.assignedMembers,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchNumber': batchNumber,
      'batchPrefix': batchPrefix,
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
      'productSequenceCounter': productSequenceCounter,
      'assignedMembers': assignedMembers,
    };
  }

  factory ProductionBatchModel.fromMap(Map<String, dynamic> map) {
    return ProductionBatchModel(
      id: map['id'] as String,
      batchNumber: map['batchNumber'] as String,
      batchPrefix: map['batchPrefix'] as String? ?? '',
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
      productSequenceCounter: map['productSequenceCounter'] as int? ?? 0,
      assignedMembers: List<String>.from(map['assignedMembers'] as List),
    );
  }

  ProductionBatchModel copyWith({
    String? id,
    String? batchNumber,
    String? batchPrefix,
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
    String? urgencyLevel,
    bool? isDelayed,
    double? delayHours,
    DateTime? expectedCompletionDate,
    DateTime? startedAt,
    DateTime? actualCompletionDate,
    int? productSequenceCounter,
    List<String>? assignedMembers,
  }) {
    return ProductionBatchModel(
      id: id ?? this.id,
      batchNumber: batchNumber ?? this.batchNumber,
      batchPrefix: batchPrefix ?? this.batchPrefix,
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
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      isDelayed: isDelayed ?? this.isDelayed,
      delayHours: delayHours ?? this.delayHours,
      expectedCompletionDate: expectedCompletionDate ?? this.expectedCompletionDate,
      startedAt: startedAt ?? this.startedAt,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      productSequenceCounter: productSequenceCounter ?? this.productSequenceCounter,
      assignedMembers: assignedMembers ?? this.assignedMembers,
    );
  }

  // Getters útiles
  BatchStatus get statusEnum => BatchStatus.fromString(status);
  String get statusDisplayName => statusEnum.displayName;
  
  UrgencyLevel get urgencyEnum => UrgencyLevel.fromString(urgencyLevel);
  String get urgencyDisplayName => urgencyEnum.displayName;
  int get urgencyNumericValue => urgencyEnum.numericValue;
  Color get urgencyColor => urgencyEnum.color;

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
  
  /// Verificar si se puede añadir más productos (límite 10)
  bool get canAddMoreProducts => totalProducts < 10;
  
  bool get isAssigned => assignedMembers.isNotEmpty;
  int get memberCount => assignedMembers.length;

  bool isAssignedTo(String userId) => assignedMembers.contains(userId);
}

// Mantener helper para generar el número de lote
class BatchNumberHelper {
  /// Genera el número de lote basado en el prefijo
  /// Formato: XXXYYWW
  /// - XXX: Prefijo de 3 caracteres en mayúsculas
  /// - YY: Últimos 2 dígitos del año
  /// - WW: Número de semana del año (01-53)
  static String generateBatchNumber(String prefix) {
    final now = DateTime.now();
    
    // Asegurar que el prefijo tiene exactamente 3 caracteres
    String cleanPrefix = prefix.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleanPrefix.length > 3) {
      cleanPrefix = cleanPrefix.substring(0, 3);
    } else {
      cleanPrefix = cleanPrefix.padRight(3, '0');
    }
    
    // Obtener año (últimos 2 dígitos)
    final year = now.year.toString().substring(2);
    
    // Calcular número de semana ISO
    final week = _getISOWeekNumber(now).toString().padLeft(2, '0');
    
    return '$cleanPrefix$year$week';
  }
  
  /// Genera preview del número de lote mientras el usuario escribe
  static String previewBatchNumber(String partialPrefix) {
    final now = DateTime.now();
    
    // Limpiar y convertir a mayúsculas
    String cleanPrefix = partialPrefix.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Completar con guiones bajos si faltan caracteres
    if (cleanPrefix.length < 3) {
      cleanPrefix = cleanPrefix.padRight(3, '_');
    } else if (cleanPrefix.length > 3) {
      cleanPrefix = cleanPrefix.substring(0, 3);
    }
    
    final year = now.year.toString().substring(2);
    final week = _getISOWeekNumber(now).toString().padLeft(2, '0');
    
    return '$cleanPrefix$year$week';
  }
  
  /// Valida que el prefijo sea válido (3 caracteres alfanuméricos)
  static bool isValidPrefix(String prefix) {
    final cleaned = prefix.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return cleaned.length == 3;
  }
  
  /// Calcula el número de semana ISO 8601
  static int _getISOWeekNumber(DateTime date) {
    // Día del año
    final dayOfYear = int.parse(
      date.difference(DateTime(date.year, 1, 1)).inDays.toString(),
    ) + 1;
    
    // Día de la semana del 1 de enero (1 = lunes, 7 = domingo)
    final jan1WeekDay = DateTime(date.year, 1, 1).weekday;
    
    // Calcular semana
    int weekNumber = ((dayOfYear + jan1WeekDay - 2) / 7).ceil();
    
    // Ajustar si es necesario
    if (weekNumber == 0) {
      weekNumber = _getISOWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (weekNumber == 53) {
      final dec31WeekDay = DateTime(date.year, 12, 31).weekday;
      if (dec31WeekDay < 4) {
        weekNumber = 1;
      }
    }
    
    return weekNumber;
  }
}