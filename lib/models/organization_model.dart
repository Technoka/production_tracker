import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String description;
  final String ownerId; // UID del creador/administrador principal
  final String inviteCode; // Código único para invitaciones
  final List<String> adminIds; // UIDs de administradores
  final List<String> memberIds; // UIDs de todos los miembros
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.inviteCode,
    required this.adminIds,
    required this.memberIds,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      ownerId: map['ownerId'] as String,
      inviteCode: map['inviteCode'] as String,
      adminIds: List<String>.from(map['adminIds'] as List),
      memberIds: List<String>.from(map['memberIds'] as List),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? inviteCode,
    List<String>? adminIds,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Verificaciones de permisos
  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || isOwner(userId);
  bool isMember(String userId) => memberIds.contains(userId);
  
  int get totalMembers => memberIds.length;
  int get totalAdmins => adminIds.length;
}

// Modelo para invitaciones pendientes
class InvitationModel {
  final String id;
  final String organizationId;
  final String organizationName;
  final String email;
  final String invitedBy; // UID de quien envió la invitación
  final String invitedByName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final InvitationStatus status;

  InvitationModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.email,
    required this.invitedBy,
    required this.invitedByName,
    required this.createdAt,
    this.expiresAt,
    this.status = InvitationStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'email': email,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'status': status.value,
    };
  }

  factory InvitationModel.fromMap(Map<String, dynamic> map) {
    return InvitationModel(
      id: map['id'] as String,
      organizationId: map['organizationId'] as String,
      organizationName: map['organizationName'] as String,
      email: map['email'] as String,
      invitedBy: map['invitedBy'] as String,
      invitedByName: map['invitedByName'] as String,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      status: InvitationStatus.fromString(map['status'] as String),
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isPending => status == InvitationStatus.pending && !isExpired;
}

enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  final String value;
  const InvitationStatus(this.value);

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}