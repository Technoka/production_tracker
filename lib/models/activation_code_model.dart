import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para códigos de activación de organizaciones
/// 
/// Estos códigos son generados manualmente por el admin después de
/// que una empresa paga. Permiten crear una nueva organización.
class ActivationCodeModel {
  final String id;
  final String code; // Código único (ej: "ORG-2025-ABC123")
  final String status; // 'active', 'used', 'expired'
  final DateTime createdAt;
  final DateTime expiresAt;
  final String createdBy; // 'admin' o userId del admin
  
  // Datos de la empresa (prellenados por el admin)
  final String companyName;
  final int? maxMembers; // Límite de miembros (para plan enterprise)
  
  // Uso
  final String? usedBy; // userId del usuario que lo usó
  final DateTime? usedAt;
  final String? organizationId; // Se llena al usarse

  ActivationCodeModel({
    required this.id,
    required this.code,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.createdBy,
    required this.companyName,
    this.maxMembers,
    this.usedBy,
    this.usedAt,
    this.organizationId,
  });

  /// Crear desde Map (Firestore)
  factory ActivationCodeModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivationCodeModel(
      id: id,
      code: map['code'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? 
          DateTime.now().add(const Duration(days: 7)),
      createdBy: map['createdBy'] ?? 'admin',
      companyName: map['companyName'] ?? '',
      maxMembers: map['maxMembers'],
      usedBy: map['usedBy'],
      usedAt: (map['usedAt'] as Timestamp?)?.toDate(),
      organizationId: map['organizationId'],
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdBy': createdBy,
      'companyName': companyName,
      'maxMembers': maxMembers,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'organizationId': organizationId,
    };
  }

  /// Verificar si está activo
  bool get isActive => status == 'active';

  /// Verificar si fue usado
  bool get isUsed => status == 'used';

  /// Verificar si ha expirado
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);

  /// Verificar si puede ser usado
  bool get canBeUsed => isActive && !isExpired && usedBy == null;

  /// Días restantes hasta expiración
  int get daysUntilExpiration {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// Copiar con nuevos valores
  ActivationCodeModel copyWith({
    String? id,
    String? code,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? createdBy,
    String? companyName,
    int? maxMembers,
    String? usedBy,
    DateTime? usedAt,
    String? organizationId,
  }) {
    return ActivationCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
      companyName: companyName ?? this.companyName,
      maxMembers: maxMembers ?? this.maxMembers,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}