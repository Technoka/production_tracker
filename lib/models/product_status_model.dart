import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modelo de Estado de Producto
/// Define los estados posibles que puede tener un producto en su ciclo de vida
class ProductStatusModel {
  final String id;
  final String name;
  final String description;
  final String color; // Hex color: #RRGGBB
  final String icon; // Material Icons name
  final int order; // Orden de visualización
  final bool isActive;
  final bool isSystem; // true = estado del sistema (no se puede eliminar)
  
  // Metadata
  final String organizationId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductStatusModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.order,
    this.isActive = true,
    this.isSystem = false,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductStatusModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ProductStatusModel(
      id: docId ?? map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      color: map['color'] as String,
      icon: map['icon'] as String,
      order: map['order'] as int,
      isActive: map['isActive'] as bool? ?? true,
      isSystem: map['isSystem'] as bool? ?? false,
      organizationId: map['organizationId'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'order': order,
      'isActive': isActive,
      'isSystem': isSystem,
      'organizationId': organizationId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ProductStatusModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    int? order,
    bool? isActive,
    bool? isSystem,
    String? organizationId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductStatusModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      isSystem: isSystem ?? this.isSystem,
      organizationId: organizationId ?? this.organizationId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helpers
  Color get colorValue {
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  bool get canDelete => !isSystem;
  bool get canEdit => !isSystem;

  // ==================== ESTADOS PREDETERMINADOS ====================
  
  /// Crea los estados predeterminados del sistema
  static List<ProductStatusModel> getDefaultStatuses({
    required String organizationId,
    required String createdBy,
  }) {
    final now = DateTime.now();
    
    return [
      ProductStatusModel(
        id: 'pending',
        name: 'Pendiente',
        description: 'Producto en espera de iniciar producción',
        color: '#9E9E9E',
        icon: 'schedule',
        order: 1,
        isActive: true,
        isSystem: true,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),
      ProductStatusModel(
        id: 'hold',
        name: 'Hold',
        description: 'Producto enviado al cliente para evaluación',
        color: '#FF9800',
        icon: 'pause_circle',
        order: 2,
        isActive: true,
        isSystem: true,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),
      ProductStatusModel(
        id: 'cao',
        name: 'CAO',
        description: 'Producto con defectos reportados por el cliente',
        color: '#F44336',
        icon: 'error',
        order: 3,
        isActive: true,
        isSystem: true,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),
      ProductStatusModel(
        id: 'control',
        name: 'Control',
        description: 'Producto en control de calidad para clasificación',
        color: '#2196F3',
        icon: 'fact_check',
        order: 4,
        isActive: true,
        isSystem: true,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),
      ProductStatusModel(
        id: 'ok',
        name: 'OK',
        description: 'Producto aprobado y finalizado',
        color: '#4CAF50',
        icon: 'check_circle',
        order: 5,
        isActive: true,
        isSystem: true,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),
    ];
  }

  // Validación de color hex
  static bool isValidHexColor(String color) {
    final hexColor = color.replaceAll('#', '');
    return hexColor.length == 6 && int.tryParse(hexColor, radix: 16) != null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductStatusModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Modelo para historial de cambios de estado
class StatusHistoryEntry {
  final String statusId;
  final String statusName;
  final DateTime timestamp;
  final String userId;
  final String userName;
  
  // Datos de validación del cambio de estado
  final Map<String, dynamic>? validationData;

  StatusHistoryEntry({
    required this.statusId,
    required this.statusName,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.validationData,
  });

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      statusId: map['statusId'] as String,
      statusName: map['statusName'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      validationData: map['validationData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'statusName': statusName,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'userName': userName,
      'validationData': validationData,
    };
  }

  StatusHistoryEntry copyWith({
    String? statusId,
    String? statusName,
    DateTime? timestamp,
    String? userId,
    String? userName,
    Map<String, dynamic>? validationData,
  }) {
    return StatusHistoryEntry(
      statusId: statusId ?? this.statusId,
      statusName: statusName ?? this.statusName,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      validationData: validationData ?? this.validationData,
    );
  }
}