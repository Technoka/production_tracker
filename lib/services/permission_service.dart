import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/organization_member_model.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';
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

      final role = await _roleService.getRoleById(organizationId, member.roleId);
      if (role == null) {
        yield null;
        continue;
      }

      yield member.getEffectivePermissions(role);
    }
  }

  // ==================== GESTIÓN DE MIEMBROS ====================

  /// Añadir miembro a la organización
  Future<bool> addMember({
    required String userId,
    required String organizationId,
    required String roleId,
    PermissionsModel? permissionOverrides,
    List<String>? assignedPhases,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Obtener rol para desnormalizar datos
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
  Future<bool> updateMemberPermissionOverrides({
    required String userId,
    required String organizationId,
    required PermissionsModel permissionOverrides,
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
          .map((doc) => OrganizationMemberModel.fromMap(doc.data(), docId: doc.id))
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
    notifyListeners();
  }
}