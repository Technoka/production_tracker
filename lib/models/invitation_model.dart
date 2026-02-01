import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para invitaciones directas a organizaciones
/// 
/// Los admins crean invitaciones con código y rol predefinido.
/// Los usuarios nuevos usan el código para unirse automáticamente.
class InvitationModel {
  final String id;
  final String organizationId;
  final String code; // Código único (ej: "INV-ABC123")
  final String type; // 'direct' (por ahora solo este tipo)
  
  // Configuración
  final String roleId; // Rol predefinido que se asignará
  final String? clientId; // ID del cliente asociado (si rol es 'client')
  final String? clientName; // Nombre del cliente asociado (si rol es 'client')
  final String createdBy; // userId del admin que creó
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses; // Cuántas veces puede usarse (default: 1)
  
  // Estado
  final String status; // 'active', 'used', 'expired', 'revoked'
  final int usedCount; // Veces que se ha usado
  final List<String> usedBy; // Array de userIds que usaron
  
  // Metadata
  final String? description; // Ej: "Invitación para Juan - Operario Corte"

  InvitationModel({
    required this.id,
    required this.organizationId,
    required this.code,
    this.type = 'direct',
    required this.roleId,
    this.clientId,
    this.clientName,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.maxUses = 1,
    this.status = 'active',
    this.usedCount = 0,
    this.usedBy = const [],
    this.description,
  });

  /// Crear desde Map (Firestore)
  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id: id,
      organizationId: map['organizationId'] ?? '',
      code: map['code'] ?? '',
      type: map['type'] ?? 'direct',
      roleId: map['roleId'] ?? 'operator',
      clientId: map['clientId'],
      clientName: map['clientName'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? 
          DateTime.now().add(const Duration(days: 7)),
      maxUses: map['maxUses'] ?? 1,
      status: map['status'] ?? 'active',
      usedCount: map['usedCount'] ?? 0,
      usedBy: List<String>.from(map['usedBy'] ?? []),
      description: map['description'],
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'code': code,
      'type': type,
      'roleId': roleId,
      'clientId': clientId,
      'clientName': clientName,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'maxUses': maxUses,
      'status': status,
      'usedCount': usedCount,
      'usedBy': usedBy,
      'description': description,
    };
  }

  /// Verificar si está activa
  bool get isActive => status == 'active';

  /// Verificar si ha expirado
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);

  /// Verificar si fue revocada
  bool get isRevoked => status == 'revoked';

  /// Verificar si alcanzó el máximo de usos
  bool get hasReachedMaxUses => usedCount >= maxUses;

  /// Verificar si puede ser usada
  bool get canBeUsed => 
      isActive && !isExpired && !isRevoked && !hasReachedMaxUses;

  /// Días restantes hasta expiración
  int get daysUntilExpiration {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// Usos restantes
  int get remainingUses {
    final remaining = maxUses - usedCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Copiar con nuevos valores
  InvitationModel copyWith({
    String? id,
    String? organizationId,
    String? code,
    String? type,
    String? roleId,
    String? clientId,
    String? clientName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? maxUses,
    String? status,
    int? usedCount,
    List<String>? usedBy,
    String? description,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      code: code ?? this.code,
      type: type ?? this.type,
      roleId: roleId ?? this.roleId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      status: status ?? this.status,
      usedCount: usedCount ?? this.usedCount,
      usedBy: usedBy ?? this.usedBy,
      description: description ?? this.description,
    );
  }
}