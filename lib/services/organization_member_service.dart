import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organization_member_model.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';
import '../models/permission_override_model.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/permission_utils.dart';

class OrganizationMemberService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache del miembro actual
  OrganizationMemberModel? _currentMember;
  RoleModel? _currentRole;

  // Cache por organización y usuario
  final Map<String, OrganizationMemberWithUser> _memberCache = {};

  // Getters públicos
  OrganizationMemberModel? get currentMember => _currentMember;
  RoleModel? get currentRole => _currentRole;
  bool get hasCurrentMember => _currentMember != null && _currentRole != null;

  // ==================== OBTENER MIEMBRO ACTUAL ====================

  /// Obtener miembro actual con rol y permisos
  Future<OrganizationMemberWithUser?> getCurrentMember(
    String organizationId,
    String userId,
  ) async {
    try {
      // Verificar cache primero
      final cacheKey = '$organizationId-$userId';
      if (_memberCache.containsKey(cacheKey)) {
        final cached = _memberCache[cacheKey]!;
        _currentMember = cached.member;
        _currentRole =
            await _getRoleModel(organizationId, cached.member.roleId);
        return cached;
      }

      // 1. Obtener OrganizationMemberModel
      final memberDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) return null;

      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      // 2. Obtener RoleModel
      final role = await _getRoleModel(organizationId, member.roleId);
      if (role == null) return null;

      // 3. Obtener datos de usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final user = UserModel.fromMap(userDoc.data()!);

      // 4. Crear objeto completo
      final memberWithUser = OrganizationMemberWithUser(
        member: member,
        userName: user.name,
        userEmail: user.email,
        userPhotoUrl: user.photoURL,
      );

      // 5. Cachear
      _currentMember = member;
      _currentRole = role;
      _memberCache[cacheKey] = memberWithUser;

      notifyListeners();
      return memberWithUser;
    } catch (e) {
      debugPrint('Error obteniendo miembro actual: $e');
      return null;
    }
  }

  /// Refrescar datos del miembro actual (forzar recarga desde Firebase)
  /// Refrescar datos del miembro actual (forzar recarga desde Firebase)
  Future<void> refreshCurrentMember(
      String organizationId, String userId) async {
    try {
      // Invalidar caché del miembro específico
      final cacheKey = '$organizationId-$userId';
      _memberCache.remove(cacheKey);

      // Si es el miembro actual, también limpiar esas variables
      if (_currentMember?.userId == userId) {
        _currentMember = null;
        _currentRole = null;
      }

      // Recargar desde Firebase (esto volverá a cachear)
      await getCurrentMember(organizationId, userId);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al refrescar permisos: $e');
    }
  }

  /// Stream del miembro actual (reactivo)
  Stream<OrganizationMemberWithUser?> watchCurrentMember(
    String organizationId,
    String userId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .asyncMap((memberDoc) async {
      if (!memberDoc.exists) return null;

      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      final role = await _getRoleModel(organizationId, member.roleId);
      if (role == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final user = UserModel.fromMap(userDoc.data()!);

      // Actualizar cache
      _currentMember = member;
      _currentRole = role;

      return OrganizationMemberWithUser(
        member: member,
        userName: user.name,
        userEmail: user.email,
        userPhotoUrl: user.photoURL,
      );
    });
  }

  // ==================== VALIDACIÓN DE PERMISOS ====================

  /// Validar permiso rápido (usa cache)
  Future<bool> can(String module, String action) async {
    if (_currentMember == null || _currentRole == null) return false;

    return PermissionUtils.can(
      member: _currentMember!,
      role: _currentRole!,
      module: module,
      action: action,
    );
  }

  /// Validar permiso con scope
  Future<bool> canWithScope(
    String module,
    String action, {
    required bool isAssignedToUser,
  }) async {
    if (_currentMember == null || _currentRole == null) return false;

    // Verificar permiso base
    if (!await can(module, action)) return false;

    // Verificar scope
    final scope = await getScope(module, action);

    switch (scope) {
      case PermissionScope.all:
        return true;
      case PermissionScope.assigned:
        return isAssignedToUser;
      case PermissionScope.none:
        return false;
    }
  }

  /// Obtener scope de un permiso
  Future<PermissionScope> getScope(String module, String action) async {
    if (_currentMember == null || _currentRole == null) {
      return PermissionScope.none;
    }

    return PermissionUtils.getScope(
      member: _currentMember!,
      role: _currentRole!,
      module: module,
      action: action,
    );
  }

  /// Verificar si el usuario está asignado a un recurso
  bool isAssignedTo(List<String> assignedMembers) {
    if (_currentMember == null) return false;
    return assignedMembers.contains(_currentMember!.userId);
  }

  /// Verificar si puede gestionar una fase específica
  bool canManagePhase(String phaseId) {
    if (_currentMember == null) return false;
    return _currentMember!.canManagePhase(phaseId);
  }

  // ==================== GESTIÓN DE MIEMBROS ====================

  /// Obtener un miembro específico
  Future<OrganizationMemberWithUser?> getMember(
    String organizationId,
    String userId,
  ) async {
    try {
      final cacheKey = '$organizationId-$userId';
      if (_memberCache.containsKey(cacheKey)) {
        return _memberCache[cacheKey];
      }

      final memberDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) return null;

      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final user = UserModel.fromMap(userDoc.data()!);

      final memberWithUser = OrganizationMemberWithUser(
        member: member,
        userName: user.name,
        userEmail: user.email,
        userPhotoUrl: user.photoURL,
      );

      _memberCache[cacheKey] = memberWithUser;
      return memberWithUser;
    } catch (e) {
      debugPrint('Error obteniendo miembro: $e');
      return null;
    }
  }

  /// Obtener todos los miembros activos de una organización
  Future<List<OrganizationMemberWithUser>> getMembers(
    String organizationId,
  ) async {
    try {
      final membersSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .where('isActive', isEqualTo: true)
          .get();

      final members = <OrganizationMemberWithUser>[];

      for (final memberDoc in membersSnapshot.docs) {
        final member = OrganizationMemberModel.fromMap(
          memberDoc.data(),
          docId: memberDoc.id,
        );

        final userDoc =
            await _firestore.collection('users').doc(member.userId).get();

        if (!userDoc.exists) continue;

        final user = UserModel.fromMap(userDoc.data()!);

        members.add(OrganizationMemberWithUser(
          member: member,
          userName: user.name,
          userEmail: user.email,
          userPhotoUrl: user.photoURL,
        ));
      }

      return members;
    } catch (e) {
      debugPrint('Error obteniendo miembros: $e');
      return [];
    }
  }

  /// Stream de miembros activos
  Stream<List<OrganizationMemberWithUser>> watchMembers(
    String organizationId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('members')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final members = <OrganizationMemberWithUser>[];

      for (final memberDoc in snapshot.docs) {
        final member = OrganizationMemberModel.fromMap(
          memberDoc.data(),
          docId: memberDoc.id,
        );

        final userDoc =
            await _firestore.collection('users').doc(member.userId).get();

        if (!userDoc.exists) continue;

        final user = UserModel.fromMap(userDoc.data()!);

        members.add(OrganizationMemberWithUser(
          member: member,
          userName: user.name,
          userEmail: user.email,
          userPhotoUrl: user.photoURL,
        ));
      }

      return members;
    });
  }

  // ==================== ACTUALIZACIÓN DE PERMISOS ====================

  /// Actualizar permission overrides de un usuario
  Future<bool> updateMemberOverrides(
    String organizationId,
    String userId,
    PermissionOverridesModel overrides,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .update({
        'permissionOverrides': overrides.toMap(),
      });

      // Invalidar cache
      invalidateCache(userId);
      return true;
    } catch (e) {
      debugPrint('Error actualizando overrides: $e');
      return false;
    }
  }

  /// Asignar/desasignar fases a un operario
  Future<bool> assignPhases(
    String organizationId,
    String userId,
    List<String> phaseIds,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .update({
        'assignedPhases': phaseIds,
        'canManageAllPhases': phaseIds.isEmpty,
      });

      // Invalidar cache
      invalidateCache(userId);
      return true;
    } catch (e) {
      debugPrint('Error asignando fases: $e');
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  /// Invalidar cache
  void invalidateCache([String? userId]) {
    if (userId != null) {
      _memberCache.removeWhere((key, _) => key.contains(userId));
    } else {
      _memberCache.clear();
    }
    notifyListeners();
  }

  /// Limpiar estado
  void clear() {
    _currentMember = null;
    _currentRole = null;
    _memberCache.clear();
    notifyListeners();
  }

  // ==================== HELPERS PRIVADOS ====================

  /// Obtener RoleModel de una organización
  Future<RoleModel?> _getRoleModel(
    String organizationId,
    String roleId,
  ) async {
    try {
      final roleDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc(roleId)
          .get();

      if (!roleDoc.exists) return null;

      return RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);
    } catch (e) {
      debugPrint('Error obteniendo rol: $e');
      return null;
    }
  }
}
