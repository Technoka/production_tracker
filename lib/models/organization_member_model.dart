import 'package:cloud_firestore/cloud_firestore.dart';
import 'permission_model.dart';
import 'role_model.dart';

/// Modelo de Miembro de Organización
/// Conecta un usuario con un rol y permite personalizar permisos
class OrganizationMemberModel {
  final String userId;
  final String organizationId;
  
  // Rol asignado
  final String roleId;
  final String roleName; // Desnormalizado para UI
  final String roleColor; // Desnormalizado para UI
  
  // Legacy: mantener por compatibilidad
  final String? legacyRole; // 'admin', 'operator', etc.
  
  // Permisos personalizados (overrides del rol base)
  final PermissionsModel? permissionOverrides;
  
  // Fases asignadas (para operarios)
  final List<String> assignedPhases;
  final bool canManageAllPhases;
  
  // Metadata
  final DateTime joinedAt;
  final bool isActive;
  final DateTime? lastActiveAt;

  OrganizationMemberModel({
    required this.userId,
    required this.organizationId,
    required this.roleId,
    required this.roleName,
    required this.roleColor,
    this.legacyRole,
    this.permissionOverrides,
    this.assignedPhases = const [],
    this.canManageAllPhases = true,
    required this.joinedAt,
    this.isActive = true,
    this.lastActiveAt,
  });

  factory OrganizationMemberModel.fromMap(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    return OrganizationMemberModel(
      userId: docId ?? map['userId'] as String,
      organizationId: map['organizationId'] as String,
      roleId: map['roleId'] as String,
      roleName: map['roleName'] as String,
      roleColor: map['roleColor'] as String,
      legacyRole: map['role'] as String?, // Campo legacy
      permissionOverrides: map['permissionOverrides'] != null
          ? PermissionsModel.fromMap(
              map['permissionOverrides'] as Map<String, dynamic>,
            )
          : null,
      assignedPhases: map['assignedPhases'] != null
          ? List<String>.from(map['assignedPhases'] as List)
          : const [],
      canManageAllPhases: map['canManageAllPhases'] as bool? ?? true,
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
      lastActiveAt: map['lastActiveAt'] != null
          ? (map['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'organizationId': organizationId,
      'roleId': roleId,
      'roleName': roleName,
      'roleColor': roleColor,
      if (legacyRole != null) 'role': legacyRole, // Mantener compatibilidad
      if (permissionOverrides != null)
        'permissionOverrides': permissionOverrides!.toMap(),
      'assignedPhases': assignedPhases,
      'canManageAllPhases': canManageAllPhases,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      if (lastActiveAt != null) 'lastActiveAt': Timestamp.fromDate(lastActiveAt!),
    };
  }

  OrganizationMemberModel copyWith({
    String? userId,
    String? organizationId,
    String? roleId,
    String? roleName,
    String? roleColor,
    String? legacyRole,
    PermissionsModel? permissionOverrides,
    List<String>? assignedPhases,
    bool? canManageAllPhases,
    DateTime? joinedAt,
    bool? isActive,
    DateTime? lastActiveAt,
  }) {
    return OrganizationMemberModel(
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      roleColor: roleColor ?? this.roleColor,
      legacyRole: legacyRole ?? this.legacyRole,
      permissionOverrides: permissionOverrides ?? this.permissionOverrides,
      assignedPhases: assignedPhases ?? this.assignedPhases,
      canManageAllPhases: canManageAllPhases ?? this.canManageAllPhases,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  // ==================== HELPERS ====================

  /// Verifica si tiene fases asignadas
  bool get hasAssignedPhases => assignedPhases.isNotEmpty;

  /// Verifica si puede gestionar una fase específica
  bool canManagePhase(String phaseId) {
    if (canManageAllPhases) return true;
    return assignedPhases.contains(phaseId);
  }

  /// Verifica si tiene overrides de permisos
  bool get hasPermissionOverrides => permissionOverrides != null;

  /// Obtiene los permisos efectivos (rol + overrides)
  PermissionsModel getEffectivePermissions(RoleModel role) {
    if (permissionOverrides == null) {
      return role.permissions;
    }
    
    // Merge: Los overrides sobrescriben los permisos del rol
    return role.permissions.mergeWithOverrides(permissionOverrides!);
  }

  /// Verifica si es propietario de la organización
  bool isOwner(String ownerId) => userId == ownerId;

  /// Verifica si tiene rol de admin
  bool get isAdmin => roleId == 'admin' || roleId == 'owner';

  /// Verifica si tiene rol de production manager
  bool get isProductionManager => roleId == 'production_manager';

  /// Verifica si tiene rol de operator
  bool get isOperator => roleId == 'operator';

  /// Verifica si tiene rol de quality control
  bool get isQualityControl => roleId == 'quality_control';

  /// Verifica si tiene rol de cliente
  bool get isClient => roleId == 'client';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationMemberModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          organizationId == other.organizationId;

  @override
  int get hashCode => userId.hashCode ^ organizationId.hashCode;
}

/// Modelo extendido con información del usuario
/// Combina OrganizationMemberModel con datos básicos del usuario
class OrganizationMemberWithUser {
  final OrganizationMemberModel member;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  OrganizationMemberWithUser({
    required this.member,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  // Acceso directo a propiedades del miembro
  String get userId => member.userId;
  String get organizationId => member.organizationId;
  String get roleId => member.roleId;
  String get roleName => member.roleName;
  String get roleColor => member.roleColor;
  DateTime get joinedAt => member.joinedAt;
  bool get isActive => member.isActive;
  
  // Helpers
  bool get isAdmin => member.isAdmin;
  bool get isOperator => member.isOperator;
  bool get isClient => member.isClient;

  /// Iniciales del usuario para avatar
  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }
}

/// Modelo para solicitudes de cambio de rol/permisos pendientes
/// (Útil para sistema de aprobaciones si lo implementas)
class RoleChangeRequest {
  final String id;
  final String userId;
  final String userName;
  final String organizationId;
  
  // Cambio solicitado
  final String? currentRoleId;
  final String requestedRoleId;
  final String requestedRoleName;
  final PermissionsModel? requestedPermissionOverrides;
  
  // Razón del cambio
  final String reason;
  
  // Estado
  final RequestStatus status;
  final String requestedBy;
  final String? approvedBy;
  final String? rejectedBy;
  final String? rejectionReason;
  
  // Fechas
  final DateTime createdAt;
  final DateTime? processedAt;

  RoleChangeRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.organizationId,
    this.currentRoleId,
    required this.requestedRoleId,
    required this.requestedRoleName,
    this.requestedPermissionOverrides,
    required this.reason,
    this.status = RequestStatus.pending,
    required this.requestedBy,
    this.approvedBy,
    this.rejectedBy,
    this.rejectionReason,
    required this.createdAt,
    this.processedAt,
  });

  factory RoleChangeRequest.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RoleChangeRequest(
      id: docId ?? map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      organizationId: map['organizationId'] as String,
      currentRoleId: map['currentRoleId'] as String?,
      requestedRoleId: map['requestedRoleId'] as String,
      requestedRoleName: map['requestedRoleName'] as String,
      requestedPermissionOverrides: map['requestedPermissionOverrides'] != null
          ? PermissionsModel.fromMap(
              map['requestedPermissionOverrides'] as Map<String, dynamic>,
            )
          : null,
      reason: map['reason'] as String,
      status: RequestStatus.fromString(map['status'] as String),
      requestedBy: map['requestedBy'] as String,
      approvedBy: map['approvedBy'] as String?,
      rejectedBy: map['rejectedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'organizationId': organizationId,
      if (currentRoleId != null) 'currentRoleId': currentRoleId,
      'requestedRoleId': requestedRoleId,
      'requestedRoleName': requestedRoleName,
      if (requestedPermissionOverrides != null)
        'requestedPermissionOverrides': requestedPermissionOverrides!.toMap(),
      'reason': reason,
      'status': status.value,
      'requestedBy': requestedBy,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (rejectedBy != null) 'rejectedBy': rejectedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      if (processedAt != null) 'processedAt': Timestamp.fromDate(processedAt!),
    };
  }

  RoleChangeRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? organizationId,
    String? currentRoleId,
    String? requestedRoleId,
    String? requestedRoleName,
    PermissionsModel? requestedPermissionOverrides,
    String? reason,
    RequestStatus? status,
    String? requestedBy,
    String? approvedBy,
    String? rejectedBy,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return RoleChangeRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      organizationId: organizationId ?? this.organizationId,
      currentRoleId: currentRoleId ?? this.currentRoleId,
      requestedRoleId: requestedRoleId ?? this.requestedRoleId,
      requestedRoleName: requestedRoleName ?? this.requestedRoleName,
      requestedPermissionOverrides:
          requestedPermissionOverrides ?? this.requestedPermissionOverrides,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  bool get isPending => status == RequestStatus.pending;
  bool get isApproved => status == RequestStatus.approved;
  bool get isRejected => status == RequestStatus.rejected;
}

/// Estado de solicitud
enum RequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  final String value;
  const RequestStatus(this.value);

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RequestStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pendiente';
      case RequestStatus.approved:
        return 'Aprobada';
      case RequestStatus.rejected:
        return 'Rechazada';
      case RequestStatus.cancelled:
        return 'Cancelada';
    }
  }
}

/// Helper para migrar del sistema legacy al nuevo
class MemberMigrationHelper {
  /// Convierte un rol legacy a roleId nuevo
  static String legacyRoleToRoleId(String legacyRole) {
    switch (legacyRole.toLowerCase()) {
      case 'admin':
        return 'admin';
      case 'production_manager':
        return 'production_manager';
      case 'operator':
        return 'operator';
      case 'accountant':
        return 'quality_control'; // Mapear accountant a quality control
      case 'client':
        return 'client';
      case 'manufacturer':
        return 'production_manager'; // Mapear manufacturer a production manager
      default:
        return 'operator'; // Default seguro
    }
  }

  /// Crea un miembro nuevo desde datos legacy
  static OrganizationMemberModel fromLegacyData({
    required String userId,
    required String organizationId,
    required String legacyRole,
    required List<RoleModel> availableRoles,
    required DateTime joinedAt,
  }) {
    final roleId = legacyRoleToRoleId(legacyRole);
    final role = availableRoles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => availableRoles.first,
    );

    return OrganizationMemberModel(
      userId: userId,
      organizationId: organizationId,
      roleId: role.id,
      roleName: role.name,
      roleColor: role.color,
      legacyRole: legacyRole,
      joinedAt: joinedAt,
    );
  }
}