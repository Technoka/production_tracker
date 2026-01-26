import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'permission_override_model.dart';
import 'permission_registry_client_extension.dart';

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
  final String organizationId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? userId; // para portal del cliente
  
  // UI
  final String? color; // Color identificativo (hex)
  
  // NUEVO SISTEMA DE PERMISOS - Dinámico vinculado a permission_registry
  /// Map de permisos del cliente en formato: 'module.action' -> valor
  /// Para permisos boolean: 'batches.create' -> true/false
  /// Para permisos scoped: 'projects.view' -> 'all'/'assigned'/'none'
  final Map<String, dynamic> clientPermissions;

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
    Map<String, dynamic>? clientPermissions,
  }) : clientPermissions = clientPermissions ?? {};

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
      'clientPermissions': clientPermissions,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    // Intentar cargar permisos nuevos primero
    Map<String, dynamic> permissions = {};
    
    if (map.containsKey('clientPermissions') && map['clientPermissions'] != null) {
      permissions = Map<String, dynamic>.from(map['clientPermissions'] as Map);
    }

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
      clientPermissions: permissions,
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
    Map<String, dynamic>? clientPermissions,
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
      clientPermissions: clientPermissions ?? this.clientPermissions,
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

  // ==================== NUEVOS GETTERS - UI ====================

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

  // ==================== NUEVOS GETTERS - PERMISOS ====================

  /// Cliente tiene algún permiso especial configurado
  bool get hasSpecialPermissions => clientPermissions.isNotEmpty;

  /// Verificar si el cliente tiene un permiso específico
  /// Formato: 'module.action' (ej: 'batches.create')
  bool hasPermission(String permissionKey) {
    return clientPermissions.containsKey(permissionKey) &&
        clientPermissions[permissionKey] == true;
  }

  /// Obtener scope de un permiso (si es scoped)
  /// Retorna 'all', 'assigned', 'none' o null si no existe
  String? getPermissionScope(String permissionKey) {
    if (!clientPermissions.containsKey(permissionKey)) return null;
    final value = clientPermissions[permissionKey];
    if (value is String) return value;
    return null;
  }

  /// Convertir permisos del cliente a Permission Overrides
  /// Para aplicar a miembros con rol 'client' asociados a este cliente
  PermissionOverridesModel getPermissionOverrides(String userId) {
    final overrides = <String, PermissionOverrideEntry>{};
    
    for (final entry in clientPermissions.entries) {
      final parts = entry.key.split('.');
      if (parts.length != 2) continue;
      
      final moduleKey = parts[0];
      final actionKey = parts[1];
      final value = entry.value;
      
      if (value is bool && value == true) {
        // Permiso boolean habilitado - crear enable override
        final override = PermissionOverridesModel.createEnableOverride(
          moduleKey: moduleKey,
          actionKey: actionKey,
          createdBy: userId,
          reason: 'Client special permission: $id',
        );
        overrides[override.key] = override;
      } else if (value is String) {
        // Permiso scoped - crear scope override
        PermissionScope scope;
        switch (value) {
          case 'all':
            scope = PermissionScope.all;
            break;
          case 'assigned':
            scope = PermissionScope.assigned;
            break;
          case 'none':
            scope = PermissionScope.none;
            break;
          default:
            scope = PermissionScope.none;
        }
        
        final override = PermissionOverridesModel.createScopeOverride(
          moduleKey: moduleKey,
          actionKey: actionKey,
          newScope: scope,
          createdBy: userId,
          reason: 'Client special permission: $id',
        );
        overrides[override.key] = override;
      }
    }
    
    return PermissionOverridesModel(overrides: overrides);
  }

  /// Lista de permisos habilitados legibles
  List<String> get enabledPermissionsDisplay {
    final permissions = <String>[];
    final applicable = PermissionRegistryClientExtension.getClientApplicablePermissions();
    
    for (final applicablePermission in applicable) {
      final key = applicablePermission.fullKey;
      if (clientPermissions.containsKey(key)) {
        final value = clientPermissions[key];
        if (value == true || (value is String && value != 'none')) {
          permissions.add(applicablePermission.displayName);
        }
      }
    }
    
    return permissions;
  }

  // ==================== OPERADORES ====================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}