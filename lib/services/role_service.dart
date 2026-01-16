import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';

/// Servicio para gestión de Roles
class RoleService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RoleModel> _roles = [];
  List<RoleModel> get roles => _roles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ==================== INICIALIZACIÓN ====================

  /// Inicializa roles predeterminados para una organización
  Future<bool> initializeDefaultRoles({
    required String organizationId,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final defaultRoles = RoleModel.getDefaultRoles(
        organizationId: organizationId,
        createdBy: createdBy,
      );

      final batch = _firestore.batch();

      for (final role in defaultRoles) {
        final docRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('roles')
            .doc(role.id);

        batch.set(docRef, role.toMap());
      }

      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al inicializar roles: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== LECTURA ====================

  /// Stream de todos los roles
  Stream<List<RoleModel>> watchRoles(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('roles')
        .snapshots()
        .map((snapshot) {
      _roles = snapshot.docs
          .map((doc) => RoleModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      return _roles;
    });
  }

  /// Obtener todos los roles
  Future<List<RoleModel>> getAllRoles(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .get();

      return snapshot.docs
          .map((doc) => RoleModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      _error = 'Error al obtener roles: $e';
      notifyListeners();
      return [];
    }
  }

  /// Obtener un rol por ID
  Future<RoleModel?> getRoleById(
    String organizationId,
    String roleId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc(roleId)
          .get();

      if (!doc.exists) {
        print('Rol no encontrado: $roleId en org: $organizationId');
        return null;
      }
      
      final data = doc.data();
      if (data == null) {
        print('Datos del rol son null para roleId: $roleId');
        return null;
      }
      
      return RoleModel.fromMap(data, docId: doc.id);
    } catch (e, stackTrace) {
      _error = 'Error al obtener rol: $e';
      print('Error obteniendo rol $roleId: $e');
      print('StackTrace: $stackTrace');
      notifyListeners();
      return null;
    }
  }

  /// Obtener solo roles personalizados (no predeterminados)
  Future<List<RoleModel>> getCustomRoles(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .where('isCustom', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => RoleModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      _error = 'Error al obtener roles personalizados: $e';
      notifyListeners();
      return [];
    }
  }

  // ==================== CREACIÓN ====================

  /// Crear un rol personalizado
  Future<String?> createRole({
    required String organizationId,
    required String name,
    required String description,
    required String color,
    required String icon,
    required PermissionsModel permissions,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validar que el nombre no exista
      final existingRoles = await getAllRoles(organizationId);
      if (existingRoles.any((r) => r.name.toLowerCase() == name.toLowerCase())) {
        _error = 'Ya existe un rol con ese nombre';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final docRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc();

      final role = RoleModel(
        id: docRef.id,
        name: name,
        description: description,
        color: color,
        icon: icon,
        isDefault: false,
        isCustom: true,
        permissions: permissions,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await docRef.set(role.toMap());

      _isLoading = false;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = 'Error al crear rol: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Duplicar un rol existente
  Future<String?> duplicateRole({
    required String organizationId,
    required String sourceRoleId,
    required String newName,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final sourceRole = await getRoleById(organizationId, sourceRoleId);
      if (sourceRole == null) {
        _error = 'Rol origen no encontrado';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      return await createRole(
        organizationId: organizationId,
        name: newName,
        description: 'Copia de ${sourceRole.name}',
        color: sourceRole.color,
        icon: sourceRole.icon,
        permissions: sourceRole.permissions,
        createdBy: createdBy,
      );
    } catch (e) {
      _error = 'Error al duplicar rol: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTUALIZACIÓN ====================

  /// Actualizar un rol
  Future<bool> updateRole({
    required String organizationId,
    required String roleId,
    String? name,
    String? description,
    String? color,
    String? icon,
    PermissionsModel? permissions,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar que no sea un rol predeterminado
      final role = await getRoleById(organizationId, roleId);
      if (role == null) {
        _error = 'Rol no encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (role.isDefault) {
        _error = 'No se pueden modificar roles predeterminados';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (color != null) updates['color'] = color;
      if (icon != null) updates['icon'] = icon;
      if (permissions != null) updates['permissions'] = permissions.toMap();

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc(roleId)
          .update(updates);

      // Actualizar todos los miembros que tienen este rol
      if (name != null || color != null) {
        await _updateMembersWithRole(
          organizationId,
          roleId,
          name,
          color,
        );
      }

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

  /// Actualizar miembros cuando cambia un rol
  Future<void> _updateMembersWithRole(
    String organizationId,
    String roleId,
    String? newName,
    String? newColor,
  ) async {
    try {
      final membersSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .where('roleId', isEqualTo: roleId)
          .get();

      final batch = _firestore.batch();

      for (final memberDoc in membersSnapshot.docs) {
        final updates = <String, dynamic>{};
        if (newName != null) updates['roleName'] = newName;
        if (newColor != null) updates['roleColor'] = newColor;

        if (updates.isNotEmpty) {
          batch.update(memberDoc.reference, updates);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error al actualizar miembros con rol: $e');
    }
  }

  // ==================== ELIMINACIÓN ====================

  /// Eliminar un rol personalizado
  Future<bool> deleteRole(
    String organizationId,
    String roleId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar que no sea un rol predeterminado
      final role = await getRoleById(organizationId, roleId);
      if (role == null) {
        _error = 'Rol no encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (role.isDefault) {
        _error = 'No se pueden eliminar roles predeterminados';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verificar que no haya miembros con este rol
      final membersWithRole = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .where('roleId', isEqualTo: roleId)
          .limit(1)
          .get();

      if (membersWithRole.docs.isNotEmpty) {
        _error = 'No se puede eliminar el rol porque hay miembros asignados';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc(roleId)
          .delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar rol: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener conteo de miembros por rol
  Future<Map<String, int>> getMemberCountByRole(
    String organizationId,
  ) async {
    try {
      final membersSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .get();

      final counts = <String, int>{};

      for (final memberDoc in membersSnapshot.docs) {
        final roleId = memberDoc.data()['roleId'] as String?;
        if (roleId != null) {
          counts[roleId] = (counts[roleId] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  // ==================== VALIDACIONES ====================

  /// Verificar si un nombre de rol ya existe
  Future<bool> roleNameExists(
    String organizationId,
    String name, {
    String? excludeRoleId,
  }) async {
    try {
      final roles = await getAllRoles(organizationId);

      if (excludeRoleId != null) {
        return roles.any(
          (r) => r.name.toLowerCase() == name.toLowerCase() && r.id != excludeRoleId,
        );
      }

      return roles.any((r) => r.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _roles = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}