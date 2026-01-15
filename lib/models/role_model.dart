import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'permission_model.dart';
import 'permission_registry_model.dart';

/// Modelo de Rol
/// Define un rol con sus permisos asociados usando el sistema dinámico
class RoleModel {
  final String id;
  final String name;
  final String description;
  final String color; // Hex color
  final String icon; // Material Icons name
  final bool isDefault; // Rol predeterminado del sistema
  final bool isCustom; // Rol personalizado por la organización
  
  // Permisos del rol (ahora usando el sistema dinámico)
  final PermissionsModel permissions;
  
  // Metadata
  final String organizationId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    this.isDefault = false,
    this.isCustom = false,
    required this.permissions,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // PARCHE TEMPORAL PARA RoleModel.fromMap
// Este código debe reemplazar el método fromMap en role_model.dart (líneas 41-64)

factory RoleModel.fromMap(Map<String, dynamic> map, {String? docId}) {
  // Normalizar permisos usando el registry
  final permissionsMap = map['permissions'] as Map<String, dynamic>?;
  final normalizedPermissions = permissionsMap != null
      ? PermissionRegistry.normalizePermissions(permissionsMap)
      : PermissionRegistry.createEmptyPermissions();

    return RoleModel(
      id: docId ?? map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      color: map['color'] as String? ?? '#2196F3',
      icon: map['icon'] as String ?? 'person',
      isDefault: map['isDefault'] as bool? ?? false,
      isCustom: map['isCustom'] as bool? ?? false,
    permissions: PermissionsModel.fromMap(normalizedPermissions),
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
      'isDefault': isDefault,
      'isCustom': isCustom,
      'permissions': permissions.toMap(),
      'organizationId': organizationId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  RoleModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? isDefault,
    bool? isCustom,
    PermissionsModel? permissions,
    String? organizationId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isCustom: isCustom ?? this.isCustom,
      permissions: permissions ?? this.permissions,
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
      return Colors.blue;
    }
  }

  bool get canEdit => !isDefault;
  bool get canDelete => !isDefault && isCustom;

  /// Validar que los permisos tienen estructura correcta
  bool get hasValidPermissions {
    return PermissionRegistry.validatePermissionsStructure(permissions.toMap());
  }

  /// Normalizar permisos del rol
  RoleModel normalize() {
    if (hasValidPermissions) return this;
    
    return copyWith(
      permissions: permissions.normalize(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // ==================== ROLES PREDETERMINADOS ====================
  
  /// Crea los roles predeterminados del sistema usando el registry dinámico
  static List<RoleModel> getDefaultRoles({
    required String organizationId,
    required String createdBy,
  }) {
    final now = DateTime.now();

    return [
      // OWNER
      RoleModel(
        id: 'owner',
        name: 'Propietario',
        description: 'Acceso completo a toda la organización',
        color: '#FF6B6B',
        icon: 'crown',
        isDefault: true,
        isCustom: false,
        permissions: PermissionsModel.full(), // Permisos completos
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // ADMIN
      RoleModel(
        id: 'admin',
        name: 'Administrador',
        description: 'Gestión completa excepto eliminación de organización',
        color: '#4ECDC4',
        icon: 'shield',
        isDefault: true,
        isCustom: false,
        permissions: _getAdminPermissions(),
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // PRODUCTION MANAGER
      RoleModel(
        id: 'production_manager',
        name: 'Jefe de Producción',
        description: 'Gestión completa de producción y lotes',
        color: '#FFE66D',
        icon: 'engineering',
        isDefault: true,
        isCustom: false,
        permissions: _getProductionManagerPermissions(),
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // OPERATOR
      RoleModel(
        id: 'operator',
        name: 'Operario',
        description: 'Operación de fases asignadas',
        color: '#95E1D3',
        icon: 'build',
        isDefault: true,
        isCustom: false,
        permissions: _getOperatorPermissions(),
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // QUALITY CONTROL
      RoleModel(
        id: 'quality_control',
        name: 'Control de Calidad',
        description: 'Gestión de estados y calidad de productos',
        color: '#A8E6CF',
        icon: 'verified',
        isDefault: true,
        isCustom: false,
        permissions: _getQualityControlPermissions(),
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // CLIENT
      RoleModel(
        id: 'client',
        name: 'Cliente',
        description: 'Visualización de sus proyectos y productos',
        color: '#C7CEEA',
        icon: 'person',
        isDefault: true,
        isCustom: false,
        permissions: _getClientPermissions(),
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),
    ];
  }

  // ==================== PERMISOS PREDETERMINADOS POR ROL ====================

  /// Admin: casi todos los permisos
  static PermissionsModel _getAdminPermissions() {
    final fullPerms = PermissionRegistry.createFullPermissions();
    
    // Remover solo algunos permisos críticos de owner
    fullPerms['organization']?['deleteOrganization'] = false;
    
    return PermissionsModel.fromMap(fullPerms);
  }

  /// Production Manager: gestión completa de producción
  static PermissionsModel _getProductionManagerPermissions() {
    return PermissionsModel.fromMap({
      'kanban': {
        'view': true,
        'moveProducts': true,
        'moveProductsScope': PermissionScope.all.value,
        'editProductDetails': true,
        'editProductDetailsScope': PermissionScope.all.value,
      },
      'phases': {
        'view': true,
        'create': true,
        'edit': true,
        'delete': false,
        'assignToMembers': true,
        'manageTransitions': true,
      },
      'batches': {
        'view': true,
        'viewScope': PermissionScope.all.value,
        'create': true,
        'edit': true,
        'editScope': PermissionScope.all.value,
        'delete': true,
        'deleteScope': PermissionScope.all.value,
        'startProduction': true,
        'completeBatch': true,
      },
      'batch_products': {
        'view': true,
        'viewScope': PermissionScope.all.value,
        'create': true,
        'edit': true,
        'editScope': PermissionScope.all.value,
        'delete': true,
        'deleteScope': PermissionScope.all.value,
        'changeStatus': true,
        'changeStatusScope': PermissionScope.all.value,
        'changeUrgency': true,
        'changeUrgencyScope': PermissionScope.all.value,
      },
      'projects': {
        'view': true,
        'viewScope': PermissionScope.all.value,
        'create': true,
        'edit': true,
        'editScope': PermissionScope.all.value,
        'delete': true,
        'deleteScope': PermissionScope.all.value,
        'assignMembers': true,
      },
      'clients': {
        'view': true,
        'create': true,
        'edit': true,
        'delete': false,
      },
      'product_catalog': {
        'view': true,
        'create': true,
        'edit': true,
        'delete': false,
      },
      'chat': {
        'view': true,
        'send': true,
        'delete': true,
        'pin': true,
        'viewInternal': true,
      },
      'organization': {
        'viewMembers': true,
        'inviteMembers': true,
        'removeMembers': true,
        'manageRoles': false,
        'manageSettings': true,
      },
      'reports': {
        'view': true,
        'generate': true,
        'export': true,
      },
    });
  }

  /// Operator: solo operación de sus fases asignadas
  static PermissionsModel _getOperatorPermissions() {
    return PermissionsModel.fromMap({
      'kanban': {
        'view': true,
        'moveProducts': true,
        'moveProductsScope': PermissionScope.assigned.value, // Solo sus fases
        'editProductDetails': false,
        'editProductDetailsScope': PermissionScope.none.value,
      },
      'phases': {
        'view': true,
        'create': false,
        'edit': false,
        'delete': false,
        'assignToMembers': false,
        'manageTransitions': false,
      },
      'batches': {
        'view': true,
        'viewScope': PermissionScope.assigned.value,
        'create': false,
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'startProduction': false,
        'completeBatch': false,
      },
      'batch_products': {
        'view': true,
        'viewScope': PermissionScope.assigned.value,
        'create': false,
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'changeStatus': false,
        'changeStatusScope': PermissionScope.none.value,
        'changeUrgency': false,
        'changeUrgencyScope': PermissionScope.none.value,
      },
      'projects': {
        'view': true,
        'viewScope': PermissionScope.assigned.value,
        'create': false,
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'assignMembers': false,
      },
      'clients': {
        'view': true,
        'create': false,
        'edit': false,
        'delete': false,
      },
      'product_catalog': {
        'view': true,
        'create': false,
        'edit': false,
        'delete': false,
      },
      'chat': {
        'view': true,
        'send': true,
        'delete': false,
        'pin': false,
        'viewInternal': true,
      },
      'organization': {
        'viewMembers': true,
        'inviteMembers': false,
        'removeMembers': false,
        'manageRoles': false,
        'manageSettings': false,
      },
      'reports': {
        'view': false,
        'generate': false,
        'export': false,
      },
    });
  }

  /// Quality Control: puede ver todo y cambiar estados
  static PermissionsModel _getQualityControlPermissions() {
    return PermissionsModel.fromMap({
      'kanban': {
        'view': true,
        'moveProducts': false,
        'moveProductsScope': PermissionScope.none.value,
        'editProductDetails': false,
        'editProductDetailsScope': PermissionScope.none.value,
      },
      'phases': {
        'view': true,
        'create': false,
        'edit': false,
        'delete': false,
        'assignToMembers': false,
        'manageTransitions': false,
      },
      'batches': {
        'view': true,
        'viewScope': PermissionScope.all.value,
        'create': false,
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'startProduction': false,
        'completeBatch': false,
      },
      'batch_products': {
        'view': true,
        'viewScope': PermissionScope.all.value,
        'create': false,
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'changeStatus': true, // Puede cambiar estados (CAO, OK, Control)
        'changeStatusScope': PermissionScope.all.value,
        'changeUrgency': false,
        'changeUrgencyScope': PermissionScope.none.value,
      },
      'projects': {
        'view': true,
        'viewScope': PermissionScope.all.value,
        'create': false,
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'assignMembers': false,
      },
      'clients': {
        'view': true,
        'create': false,
        'edit': false,
        'delete': false,
      },
      'product_catalog': {
        'view': true,
        'create': false,
        'edit': false,
        'delete': false,
      },
      'chat': {
        'view': true,
        'send': true,
        'delete': false,
        'pin': false,
        'viewInternal': true,
      },
      'organization': {
        'viewMembers': true,
        'inviteMembers': false,
        'removeMembers': false,
        'manageRoles': false,
        'manageSettings': false,
      },
      'reports': {
        'view': true,
        'generate': false,
        'export': false,
      },
    });
  }

  /// Client: visualización limitada de sus datos
  static PermissionsModel _getClientPermissions() {
    return PermissionsModel.fromMap({
      'kanban': {
        'view': false,
        'moveProducts': false,
        'moveProductsScope': PermissionScope.none.value,
        'editProductDetails': false,
        'editProductDetailsScope': PermissionScope.none.value,
      },
      'phases': {
        'view': false,
        'create': false,
        'edit': false,
        'delete': false,
        'assignToMembers': false,
        'manageTransitions': false,
      },
      'batches': {
        'view': true,
        'viewScope': PermissionScope.assigned.value, // Solo sus lotes
        'create': false, // Se puede habilitar con permisos especiales
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'startProduction': false,
        'completeBatch': false,
      },
      'batch_products': {
        'view': true,
        'viewScope': PermissionScope.assigned.value, // Solo sus productos
        'create': false, // Se puede habilitar con permisos especiales
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'changeStatus': false,
        'changeStatusScope': PermissionScope.none.value,
        'changeUrgency': false,
        'changeUrgencyScope': PermissionScope.none.value,
      },
      'projects': {
        'view': true,
        'viewScope': PermissionScope.assigned.value,
        'create': false,
        'edit': false,
        'editScope': PermissionScope.none.value,
        'delete': false,
        'deleteScope': PermissionScope.none.value,
        'assignMembers': false,
      },
      'clients': {
        'view': false,
        'create': false,
        'edit': false,
        'delete': false,
      },
      'product_catalog': {
        'view': true, // Puede ver catálogo para pedir productos
        'create': false,
        'edit': false,
        'delete': false,
      },
      'chat': {
        'view': true,
        'send': true,
        'delete': false,
        'pin': false,
        'viewInternal': false, // No ve mensajes internos
      },
      'organization': {
        'viewMembers': false,
        'inviteMembers': false,
        'removeMembers': false,
        'manageRoles': false,
        'manageSettings': false,
      },
      'reports': {
        'view': false,
        'generate': false,
        'export': false,
      },
    });
  }
}