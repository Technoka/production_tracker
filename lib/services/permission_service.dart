import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/organization_member_model.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';
import '../models/permission_override_model.dart';
import 'role_service.dart';

/// Servicio para gestión de Permisos y Miembros
class PermissionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();

  OrganizationMemberModel? _currentMember;
  OrganizationMemberModel? get currentMember => _currentMember;

  RoleModel? _currentRole;
  RoleModel? get currentRole => _currentRole;

  PermissionsModel? _effectivePermissions;
  PermissionsModel? get effectivePermissions => _effectivePermissions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ==================== CACHÉ DE PERMISOS COMUNES ====================
  
  Map<String, bool> _cachedPermissions = {};

  // Getters rápidos para permisos comunes (acceso O(1))
  
  // BATCHES
  bool get canViewBatches => _getCached('batches_view');
  bool get canCreateBatches => _getCached('batches_create');
  bool get canEditBatches => _getCached('batches_edit');
  bool get canDeleteBatches => _getCached('batches_delete');
  bool get canStartProduction => _getCached('batches_startProduction');
  bool get canCompleteBatch => _getCached('batches_completeBatch');

  // BATCH PRODUCTS
  bool get canViewBatchProducts => _getCached('batch_products_view');
  bool get canCreateBatchProducts => _getCached('batch_products_create');
  bool get canEditBatchProducts => _getCached('batch_products_edit');
  bool get canDeleteBatchProducts => _getCached('batch_products_delete');
  bool get canChangeProductStatus => _getCached('batch_products_changeStatus');
  bool get canChangeProductUrgency => _getCached('batch_products_changeUrgency');

  // PROJECTS
  bool get canViewProjects => _getCached('projects_view');
  bool get canCreateProjects => _getCached('projects_create');
  bool get canEditProjects => _getCached('projects_edit');
  bool get canDeleteProjects => _getCached('projects_delete');

  // CLIENTS
  bool get canViewClients => _getCached('clients_view');
  bool get canCreateClients => _getCached('clients_create');
  bool get canEditClients => _getCached('clients_edit');
  bool get canDeleteClients => _getCached('clients_delete');

  // CATALOG
  bool get canViewCatalog => _getCached('product_catalog_view');
  bool get canCreateCatalogProducts => _getCached('product_catalog_create');
  bool get canEditCatalogProducts => _getCached('product_catalog_edit');
  bool get canDeleteCatalogProducts => _getCached('product_catalog_delete');

  // PHASES
  bool get canViewPhases => _getCached('phases_view');
  bool get canManagePhases => _getCached('phases_manage');

  // KANBAN
  bool get canViewKanban => _getCached('kanban_view');
  bool get canMoveProducts => _getCached('kanban_moveProducts');

  // ORGANIZATION
  bool get canManageMembers => _getCached('organization_manageMembers');
  bool get canManageRoles => _getCached('organization_manageRoles');
  bool get canManageSettings => _getCached('organization_manageSettings');
  bool get canManageProductStatuses => _getCached('organization_manageProductStatuses');
  bool get canApproveClientRequests => _getCached('organization_approveClientRequests');

  // CHAT
  bool get canViewChat => _getCached('chat_view');
  bool get canSendMessages => _getCached('chat_send');

  // REPORTS
  bool get canViewReports => _getCached('reports_view');
  bool get canGenerateReports => _getCached('reports_generate');
  bool get canExportReports => _getCached('reports_export');

  /// Obtener permiso cacheado
  bool _getCached(String key) {
    return _cachedPermissions[key] ?? false;
  }

  /// Cachear permisos comunes para acceso rápido
  void _cacheCommonPermissions() {
    if (_effectivePermissions == null) {
      _cachedPermissions = {};
      return;
    }

    _cachedPermissions = {
      // BATCHES
      'batches_view': _effectivePermissions!.can('batches', 'view'),
      'batches_create': _effectivePermissions!.can('batches', 'create'),
      'batches_edit': _effectivePermissions!.can('batches', 'edit'),
      'batches_delete': _effectivePermissions!.can('batches', 'delete'),

      // BATCH PRODUCTS
      'batch_products_view': _effectivePermissions!.can('batch_products', 'view'),
      'batch_products_create': _effectivePermissions!.can('batch_products', 'create'),
      'batch_products_edit': _effectivePermissions!.can('batch_products', 'edit'),
      'batch_products_delete': _effectivePermissions!.can('batch_products', 'delete'),
      'batch_products_changeStatus': _effectivePermissions!.can('batch_products', 'changeStatus'),
      'batch_products_changeUrgency': _effectivePermissions!.can('batch_products', 'changeUrgency'),

      // PROJECTS
      'projects_view': _effectivePermissions!.can('projects', 'view'),
      'projects_create': _effectivePermissions!.can('projects', 'create'),
      'projects_edit': _effectivePermissions!.can('projects', 'edit'),
      'projects_delete': _effectivePermissions!.can('projects', 'delete'),

      // CLIENTS
      'clients_view': _effectivePermissions!.can('clients', 'view'),
      'clients_create': _effectivePermissions!.can('clients', 'create'),
      'clients_edit': _effectivePermissions!.can('clients', 'edit'),
      'clients_delete': _effectivePermissions!.can('clients', 'delete'),

      // CATALOG
      'product_catalog_view': _effectivePermissions!.can('product_catalog', 'view'),
      'product_catalog_create': _effectivePermissions!.can('product_catalog', 'create'),
      'product_catalog_edit': _effectivePermissions!.can('product_catalog', 'edit'),
      'product_catalog_delete': _effectivePermissions!.can('product_catalog', 'delete'),

      // PHASES
      'phases_view': _effectivePermissions!.can('phases', 'view'),
      'phases_manage': _effectivePermissions!.can('phases', 'manage'),

      // KANBAN
      'kanban_view': _effectivePermissions!.can('kanban', 'view'),
      'kanban_moveProducts': _effectivePermissions!.can('kanban', 'moveProducts'),

      // ORGANIZATION
      'organization_manageMembers': _effectivePermissions!.can('organization', 'manageMembers'),
      'organization_manageRoles': _effectivePermissions!.can('organization', 'manageRoles'),
      'organization_manageSettings': _effectivePermissions!.can('organization', 'manageSettings'),
      'organization_manageProductStatuses': _effectivePermissions!.can('organization', 'manageProductStatuses'),
      'organization_approveClientRequests': _effectivePermissions!.can('organization', 'approveClientRequests'),
      
      // CHAT
      'chat_view': _effectivePermissions!.can('chat', 'view'),
      'chat_send': _effectivePermissions!.can('chat', 'send'),

      // REPORTS
      'reports_view': _effectivePermissions!.can('reports', 'view'),
      'reports_generate': _effectivePermissions!.can('reports', 'generate'),
      'reports_export': _effectivePermissions!.can('reports', 'export'),
    };
  }

  // ==================== INICIALIZACIÓN ====================

  /// Cargar permisos efectivos del usuario actual
  Future<void> loadCurrentUserPermissions({
    required String userId,
    required String organizationId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Obtener miembro
      final memberDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) {
        _error = 'Miembro no encontrado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentMember = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      // Obtener rol
      _currentRole = await _roleService.getRoleById(
        organizationId,
        _currentMember!.roleId,
      );

      if (_currentRole != null) {
        // Calcular permisos efectivos (rol + overrides)
        _effectivePermissions = _currentMember!.getEffectivePermissions(_currentRole!);
      }

      // ✅ CACHEAR PERMISOS COMUNES
        _cacheCommonPermissions();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar permisos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Stream de permisos del usuario
  Stream<PermissionsModel?> watchUserPermissions({
    required String userId,
    required String organizationId,
  }) async* {
    await for (final memberDoc in _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('members')
        .doc(userId)
        .snapshots()) {
      if (!memberDoc.exists) {
        yield null;
        continue;
      }

      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      final role =
          await _roleService.getRoleById(organizationId, member.roleId);
      if (role == null) {
        yield null;
        continue;
      }

      yield member.getEffectivePermissions(role);
    }
  }

  // ==================== GESTIÓN DE MIEMBROS ====================

  /// Añadir miembro a la organización
  /// Corregido para aceptar PermissionOverridesModel
  Future<bool> addMember({
    required String userId,
    required String organizationId,
    required String roleId,
    PermissionOverridesModel? permissionOverrides, // Tipo corregido
    List<String>? assignedPhases,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Obtener rol para desnormalizar datos (nombre y color)
      final role = await _roleService.getRoleById(organizationId, roleId);
      if (role == null) {
        _error = 'Rol no encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final member = OrganizationMemberModel(
        userId: userId,
        organizationId: organizationId,
        roleId: roleId,
        roleName: role.name,
        roleColor: role.color,
        permissionOverrides: permissionOverrides,
        assignedPhases: assignedPhases ?? [],
        canManageAllPhases: assignedPhases == null || assignedPhases.isEmpty,
        joinedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .set(member.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al añadir miembro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar rol de un miembro
  Future<bool> updateMemberRole({
    required String userId,
    required String organizationId,
    required String newRoleId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Obtener nuevo rol
      final newRole = await _roleService.getRoleById(organizationId, newRoleId);
      if (newRole == null) {
        _error = 'Rol no encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .update({
        'roleId': newRoleId,
        'roleName': newRole.name,
        'roleColor': newRole.color,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar rol: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar overrides de permisos de un miembro
  /// Corregido para aceptar PermissionOverridesModel
  Future<bool> updateMemberPermissionOverrides({
    required String userId,
    required String organizationId,
    required PermissionOverridesModel permissionOverrides, // Tipo corregido
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .update({
        'permissionOverrides': permissionOverrides.toMap(),
      });

      // Si el usuario actualizado es el actual, recargar permisos
      if (_currentMember?.userId == userId) {
        await loadCurrentUserPermissions(
          userId: userId,
          organizationId: organizationId,
        );
      }



      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar permisos: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar fases asignadas de un miembro
  Future<bool> updateMemberAssignedPhases({
    required String userId,
    required String organizationId,
    required List<String> assignedPhases,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .update({
        'assignedPhases': assignedPhases,
        'canManageAllPhases': assignedPhases.isEmpty,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar fases: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener miembro
  Future<OrganizationMemberModel?> getMember({
    required String userId,
    required String organizationId,
  }) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return OrganizationMemberModel.fromMap(doc.data()!, docId: doc.id);
    } catch (e) {
      _error = 'Error al obtener miembro: $e';
      notifyListeners();
      return null;
    }
  }

  /// Obtener todos los miembros de una organización
  Future<List<OrganizationMemberModel>> getOrganizationMembers(
    String organizationId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .get();

      return snapshot.docs
          .map((doc) =>
              OrganizationMemberModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      _error = 'Error al obtener miembros: $e';
      notifyListeners();
      return [];
    }
  }

  // ==================== VERIFICACIÓN DE PERMISOS (ACTUALIZADO) ====================

  /// Verificar si el usuario actual tiene un permiso específico
  ///
  /// Usa el sistema dinámico de PermissionRegistry
  ///
  /// Ejemplos:
  /// - hasPermission('kanban', 'view')
  /// - hasPermission('batches', 'create')
  /// - hasPermission('products', 'changeStatus')
  bool hasPermission(String module, String action) {
    if (_effectivePermissions == null) return false;

    // Usar el helper dinámico del modelo de permisos
    return _effectivePermissions!.can(module, action);
  }

  /// Verificar scope de un permiso
  ///
  /// Usa el sistema dinámico de PermissionRegistry
  ///
  /// Retorna:
  /// - PermissionScope.all: puede ver/editar todos los recursos
  /// - PermissionScope.assigned: solo recursos asignados
  /// - PermissionScope.none: sin acceso
  ///
  /// Ejemplos:
  /// - getPermissionScope('kanban', 'moveProducts')
  /// - getPermissionScope('batches', 'view')
  /// - getPermissionScope('products', 'changeStatus')
  PermissionScope getPermissionScope(String module, String action) {
    if (_effectivePermissions == null) return PermissionScope.none;

    // Usar el helper dinámico del modelo de permisos
    return _effectivePermissions!.getScope(module, action);
  }

  /// Verificar permiso considerando el scope y si el recurso está asignado
  ///
  /// Útil para queries condicionales
  ///
  /// Ejemplo:
  /// ```dart
  /// final canView = permissionService.canWithScope(
  ///   module: 'batches',
  ///   action: 'view',
  ///   isAssigned: batch.assignedMembers.contains(userId),
  /// );
  /// ```
  bool canWithScope({
    required String module,
    required String action,
    required bool isAssigned,
  }) {
    if (_effectivePermissions == null) return false;

    return _effectivePermissions!.canWithScope(
      moduleKey: module,
      actionKey: action,
      isAssigned: isAssigned,
    );
  }

  /// Verificar si puede gestionar una fase específica
  bool canManagePhase(String phaseId) {
    if (_currentMember == null) return false;
    return _currentMember!.canManagePhase(phaseId);
  }

  // ==================== UTILIDADES ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _currentMember = null;
    _currentRole = null;
    _effectivePermissions = null;
    _error = null;
    _isLoading = false;
    _cachedPermissions = {};
    notifyListeners();
  }
}
