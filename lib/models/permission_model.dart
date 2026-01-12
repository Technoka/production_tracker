import 'package:cloud_firestore/cloud_firestore.dart';
import 'permission_registry_model.dart';

/// Re-exportar tipos del registry para fácil acceso
export 'permission_registry_model.dart' show PermissionScope, PermissionActionType;

/// Modelo simplificado de Permisos usando el Registry dinámico
/// 
/// Este modelo es ahora solo un wrapper sobre Map<String, dynamic>
/// que utiliza PermissionRegistry para validación y estructura
class PermissionsModel {
  final Map<String, dynamic> _permissions;

  PermissionsModel([Map<String, dynamic>? permissions])
      : _permissions = permissions != null
            ? PermissionRegistry.normalizePermissions(permissions)
            : PermissionRegistry.createEmptyPermissions();

  /// Crear permisos vacíos
  factory PermissionsModel.empty() {
    return PermissionsModel(PermissionRegistry.createEmptyPermissions());
  }

  /// Crear permisos completos (Owner)
  factory PermissionsModel.full() {
    return PermissionsModel(PermissionRegistry.createFullPermissions());
  }

  /// Crear desde mapa
  factory PermissionsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PermissionsModel.empty();
    return PermissionsModel(map);
  }

  /// Exportar a mapa
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_permissions);

  /// Obtener helper dinámico
  DynamicPermissions get dynamicHelper => DynamicPermissions(_permissions);

  /// Copiar con cambios
  PermissionsModel copyWith(Map<String, dynamic> changes) {
    final newPermissions = Map<String, dynamic>.from(_permissions);
    
    for (final moduleKey in changes.keys) {
      if (!newPermissions.containsKey(moduleKey)) {
        newPermissions[moduleKey] = <String, dynamic>{};
      }
      
      final moduleChanges = changes[moduleKey] as Map<String, dynamic>;
      final modulePerms = newPermissions[moduleKey] as Map<String, dynamic>;
      
      modulePerms.addAll(moduleChanges);
    }
    
    return PermissionsModel(newPermissions);
  }

  /// Merge con overrides
  PermissionsModel mergeWithOverrides(PermissionsModel overrides) {
    return PermissionsModel(
      dynamicHelper.mergeWith(overrides.dynamicHelper).toMap(),
    );
  }

  // ==================== HELPERS DE ACCESO RÁPIDO ====================
  // Mantenemos algunos helpers para compatibilidad con código existente

  /// Verificar permiso booleano
  bool can(String moduleKey, String actionKey) {
    return dynamicHelper.can(moduleKey, actionKey);
  }

  /// Obtener scope de un permiso
  PermissionScope getScope(String moduleKey, String actionKey) {
    return dynamicHelper.getScope(moduleKey, actionKey);
  }

  /// Verificar con scope
  bool canWithScope({
    required String moduleKey,
    required String actionKey,
    required bool isAssigned,
  }) {
    return dynamicHelper.canWithScope(
      moduleKey: moduleKey,
      actionKey: actionKey,
      isAssigned: isAssigned,
    );
  }

  // ==================== HELPERS LEGACY (mantener por compatibilidad) ====================
  // Estos métodos facilitan la migración del código existente

  /// KANBAN
  bool get canViewKanban => can('kanban', 'view');
  bool get canMoveProducts => can('kanban', 'moveProducts');
  PermissionScope get moveProductsScope => getScope('kanban', 'moveProducts');
  bool get canEditProductDetails => can('kanban', 'editProductDetails');
  PermissionScope get editProductDetailsScope => getScope('kanban', 'editProductDetails');

  /// PHASES
  bool get canViewPhases => can('phases', 'view');
  bool get canCreatePhases => can('phases', 'create');
  bool get canEditPhases => can('phases', 'edit');
  bool get canDeletePhases => can('phases', 'delete');
  bool get canAssignPhases => can('phases', 'assignToMembers');
  bool get canManageTransitions => can('phases', 'manageTransitions');

  /// BATCHES
  bool get canViewBatches => can('batches', 'view');
  PermissionScope get viewBatchesScope => getScope('batches', 'view');
  bool get canCreateBatches => can('batches', 'create');
  bool get canEditBatches => can('batches', 'edit');
  PermissionScope get editBatchesScope => getScope('batches', 'edit');
  bool get canDeleteBatches => can('batches', 'delete');
  PermissionScope get deleteBatchesScope => getScope('batches', 'delete');
  bool get canStartProduction => can('batches', 'startProduction');
  bool get canCompleteBatch => can('batches', 'completeBatch');

  /// PRODUCTS
  bool get canViewProducts => can('batch_products', 'view');
  PermissionScope get viewProductsScope => getScope('batch_products', 'view');
  bool get canCreateProducts => can('batch_products', 'create');
  bool get canEditProducts => can('batch_products', 'edit');
  PermissionScope get editProductsScope => getScope('batch_products', 'edit');
  bool get canDeleteProducts => can('batch_products', 'delete');
  PermissionScope get deleteProductsScope => getScope('batch_products', 'delete');
  bool get canChangeProductStatus => can('batch_products', 'changeStatus');
  PermissionScope get changeProductStatusScope => getScope('batch_products', 'changeStatus');
  bool get canChangeProductUrgency => can('batch_products', 'changeUrgency');
  PermissionScope get changeProductUrgencyScope => getScope('batch_products', 'changeUrgency');

  /// PROJECTS
  bool get canViewProjects => can('projects', 'view');
  PermissionScope get viewProjectsScope => getScope('projects', 'view');
  bool get canCreateProjects => can('projects', 'create');
  bool get canEditProjects => can('projects', 'edit');
  PermissionScope get editProjectsScope => getScope('projects', 'edit');
  bool get canDeleteProjects => can('projects', 'delete');
  PermissionScope get deleteProjectsScope => getScope('projects', 'delete');
  bool get canAssignProjectMembers => can('projects', 'assignMembers');

  /// CLIENTS
  bool get canViewClients => can('clients', 'view');
  bool get canCreateClients => can('clients', 'create');
  bool get canEditClients => can('clients', 'edit');
  bool get canDeleteClients => can('clients', 'delete');

  /// CATALOG
  bool get canViewCatalog => can('product_catalog', 'view');
  bool get canCreateCatalogItems => can('product_catalog', 'create');
  bool get canEditCatalogItems => can('product_catalog', 'edit');
  bool get canDeleteCatalogItems => can('product_catalog', 'delete');

  /// CHAT
  bool get canViewChat => can('chat', 'view');
  bool get canSendMessages => can('chat', 'send');
  bool get canDeleteMessages => can('chat', 'delete');
  bool get canPinMessages => can('chat', 'pin');
  bool get canViewInternalMessages => can('chat', 'viewInternal');

  /// ORGANIZATION
  bool get canViewMembers => can('organization', 'viewMembers');
  bool get canInviteMembers => can('organization', 'inviteMembers');
  bool get canRemoveMembers => can('organization', 'removeMembers');
  bool get canManageRoles => can('organization', 'manageRoles');
  bool get canManageSettings => can('organization', 'manageSettings');

  /// REPORTS
  bool get canViewReports => can('reports', 'view');
  bool get canGenerateReports => can('reports', 'generate');
  bool get canExportReports => can('reports', 'export');

  // ==================== VALIDACIÓN ====================

  /// Validar estructura
  bool get isValid => PermissionRegistry.validatePermissionsStructure(_permissions);

  /// Normalizar permisos (añadir campos faltantes)
  PermissionsModel normalize() {
    return PermissionsModel(
      PermissionRegistry.normalizePermissions(_permissions),
    );
  }
}
