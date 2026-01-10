import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Permisos especiales para clientes
/// 
/// Permite dar acceso especial a ciertos clientes para que puedan
/// crear lotes o productos con aprobación
class ClientSpecialPermissions {
  final bool canCreateBatches; // Puede crear lotes (con aprobación)
  final bool canCreateProducts; // Puede crear productos personalizados (con aprobación)
  final bool requiresApproval; // Si sus acciones requieren aprobación
  final bool canViewAllProjects; // Puede ver todos los proyectos o solo los suyos

  const ClientSpecialPermissions({
    this.canCreateBatches = false,
    this.canCreateProducts = false,
    this.requiresApproval = true,
    this.canViewAllProjects = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'canCreateBatches': canCreateBatches,
      'canCreateProducts': canCreateProducts,
      'requiresApproval': requiresApproval,
      'canViewAllProjects': canViewAllProjects,
    };
  }

  factory ClientSpecialPermissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ClientSpecialPermissions();
    }

    return ClientSpecialPermissions(
      canCreateBatches: map['canCreateBatches'] as bool? ?? false,
      canCreateProducts: map['canCreateProducts'] as bool? ?? false,
      requiresApproval: map['requiresApproval'] as bool? ?? true,
      canViewAllProjects: map['canViewAllProjects'] as bool? ?? false,
    );
  }

  ClientSpecialPermissions copyWith({
    bool? canCreateBatches,
    bool? canCreateProducts,
    bool? requiresApproval,
    bool? canViewAllProjects,
  }) {
    return ClientSpecialPermissions(
      canCreateBatches: canCreateBatches ?? this.canCreateBatches,
      canCreateProducts: canCreateProducts ?? this.canCreateProducts,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      canViewAllProjects: canViewAllProjects ?? this.canViewAllProjects,
    );
  }

  /// Cliente tiene algún permiso especial
  bool get hasAnyPermission =>
      canCreateBatches || canCreateProducts || canViewAllProjects;

  /// Cliente no tiene permisos especiales
  bool get isStandard => !hasAnyPermission;
}

class ClientModel {
  final String id;
  final String name;
  final String company;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? notes;
  final String organizationId; // Organización propietaria
  final String createdBy; // UID del usuario que lo creó
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? userId; // para portal del cliente
  
  // NUEVOS CAMPOS - Permisos especiales y UI
  final String? color; // Color identificativo (hex)
  final ClientSpecialPermissions specialPermissions; // Permisos especiales

  ClientModel({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    this.notes,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.userId,
    this.color,
    this.specialPermissions = const ClientSpecialPermissions(),
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'notes': notes,
      'organizationId': organizationId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'userId': userId,
      'color': color,
      'specialPermissions': specialPermissions.toMap(),
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      company: map['company'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      postalCode: map['postalCode'] as String?,
      country: map['country'] as String?,
      notes: map['notes'] as String?,
      organizationId: map['organizationId'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      isActive: map['isActive'] as bool? ?? true,
      userId: map['userId'] as String?,
      color: map['color'] as String?,
      specialPermissions: ClientSpecialPermissions.fromMap(
        map['specialPermissions'] as Map<String, dynamic>?,
      ),
    );
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? company,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? notes,
    String? organizationId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? userId,
    String? color,
    ClientSpecialPermissions? specialPermissions,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      notes: notes ?? this.notes,
      organizationId: organizationId ?? this.organizationId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      color: color ?? this.color,
      specialPermissions: specialPermissions ?? this.specialPermissions,
    );
  }

  // ==================== GETTERS EXISTENTES ====================
  
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  bool get hasAddress => address != null && address!.trim().isNotEmpty;
  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasCity => city != null && city!.trim().isNotEmpty;
  bool get hasPostalCode => postalCode != null && postalCode!.trim().isNotEmpty;
  bool get hasCountry => country != null && country!.trim().isNotEmpty;
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  // ==================== NUEVOS GETTERS ====================

  /// Obtener color como objeto Color (si existe)
  Color? get colorValue {
    if (color == null) return null;
    try {
      return Color(int.parse(color!.replaceAll('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  /// Cliente tiene cuenta de usuario activa
  bool get hasUserAccount => userId != null;

  /// Cliente tiene permisos especiales
  bool get hasSpecialPermissions => specialPermissions.hasAnyPermission;

  /// Cliente puede crear lotes
  bool get canCreateBatches => specialPermissions.canCreateBatches;

  /// Cliente puede crear productos personalizados
  bool get canCreateProducts => specialPermissions.canCreateProducts;

  /// Cliente requiere aprobación para sus acciones
  bool get requiresApproval => specialPermissions.requiresApproval;

  /// Cliente puede ver todos los proyectos
  bool get canViewAllProjects => specialPermissions.canViewAllProjects;

  /// Cliente es estándar (sin permisos especiales)
  bool get isStandardClient => specialPermissions.isStandard;

  // ==================== OPERADORES ====================

  //Arreglar dropdown con objetos repetidos
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}