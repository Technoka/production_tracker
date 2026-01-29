import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

/// Tipo de objeto pendiente de acción/aprobación
enum PendingObjectType {
  project(
    value: 'project',
    label: 'Proyecto',
    icon: Icons.folder_outlined,
    color: Colors.blue,
  ),
  productCatalog(
    value: 'product_catalog',
    label: 'Producto de Catálogo',
    icon: Icons.inventory_2_outlined,
    color: Colors.purple,
  ),
  batch(
    value: 'batch',
    label: 'Lote de Producción',
    icon: Icons.layers_outlined,
    color: Colors.indigo,
  ),
  batchProduct(
    value: 'batch_product',
    label: 'Producto en Lote',
    icon: Icons.category_outlined,
    color: Colors.teal,
  ),
  invoice(
    value: 'invoice',
    label: 'Factura',
    icon: Icons.receipt_long_outlined,
    color: Colors.orange,
  );

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const PendingObjectType({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  static PendingObjectType fromString(String? value) {
    return PendingObjectType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PendingObjectType.project,
    );
  }
}

/// Estado del objeto pendiente
enum PendingObjectStatus {
  pendingApproval(
    value: 'pending_approval',
    label: 'Pendiente de Aprobación',
    icon: Icons.hourglass_top_rounded,
    color: Colors.orange,
  ),
  approved(
    value: 'approved',
    label: 'Aprobado',
    icon: Icons.check_circle_outline_rounded,
    color: Colors.green,
  ),
  rejected(
    value: 'rejected',
    label: 'Rechazado',
    icon: Icons.cancel_outlined,
    color: Colors.red,
  ),
  expired(
    value: 'expired',
    label: 'Expirado',
    icon: Icons.timer_off_outlined,
    color: Colors.grey,
  );

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const PendingObjectStatus({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  static PendingObjectStatus fromString(String? value) {
    return PendingObjectStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PendingObjectStatus.pendingApproval,
    );
  }
}

/// Modelo de objeto pendiente de aprobación
class PendingObjectModel {
  final String id;
  final PendingObjectType objectType;
  final String collectionRoute;
  final Map<String, dynamic> modelData;
  final String createdBy;
  final String createdByName;
  final String? clientId;
  final DateTime createdAt;
  final PendingObjectStatus status;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? notificationId;
  final String? parentBatchId; // Solo para batch_products

  PendingObjectModel({
    required this.id,
    required this.objectType,
    required this.collectionRoute,
    required this.modelData,
    required this.createdBy,
    required this.createdByName,
    this.clientId,
    required this.createdAt,
    this.status = PendingObjectStatus.pendingApproval,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.rejectionReason,
    this.notificationId,
    this.parentBatchId,
  });

  /// Verificar si está pendiente
  bool get isPending => status == PendingObjectStatus.pendingApproval;

  /// Verificar si fue aprobado
  bool get isApproved => status == PendingObjectStatus.approved;

  /// Verificar si fue rechazado
  bool get isRejected => status == PendingObjectStatus.rejected;

  /// Verificar si ha expirado
  bool get isExpired => status == PendingObjectStatus.expired;

  /// Nombre del objeto (extraído de modelData)
  String get objectName {
    return modelData['name'] as String? ?? 
           modelData['title'] as String? ?? 
           'Sin nombre';
  }

  /// Copiar con nuevos valores
  PendingObjectModel copyWith({
    String? id,
    PendingObjectType? objectType,
    String? collectionRoute,
    Map<String, dynamic>? modelData,
    String? createdBy,
    String? createdByName,
    String? clientId,
    DateTime? createdAt,
    PendingObjectStatus? status,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? notificationId,
    String? parentBatchId,
  }) {
    return PendingObjectModel(
      id: id ?? this.id,
      objectType: objectType ?? this.objectType,
      collectionRoute: collectionRoute ?? this.collectionRoute,
      modelData: modelData ?? this.modelData,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notificationId: notificationId ?? this.notificationId,
      parentBatchId: parentBatchId ?? this.parentBatchId,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'objectType': objectType.value,
      'collectionRoute': collectionRoute,
      'modelData': modelData,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'clientId': clientId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.value,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
      'notificationId': notificationId,
      'parentBatchId': parentBatchId,
    };
  }

  /// Crear desde Map de Firestore
  factory PendingObjectModel.fromMap(String id, Map<String, dynamic> map) {
    return PendingObjectModel(
      id: id,
      objectType: PendingObjectType.fromString(
        map['objectType'] ?? 'project',
      ),
      collectionRoute: map['collectionRoute'] ?? '',
      modelData: Map<String, dynamic>.from(map['modelData'] ?? {}),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      clientId: map['clientId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: PendingObjectStatus.fromString(
        map['status'] ?? 'pending_approval',
      ),
      reviewedBy: map['reviewedBy'],
      reviewedByName: map['reviewedByName'],
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'],
      notificationId: map['notificationId'],
      parentBatchId: map['parentBatchId'],
    );
  }

  @override
  String toString() {
    return 'PendingObjectModel(id: $id, type: ${objectType.value}, name: $objectName, status: ${status.value})';
  }
}