import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_status_model.dart';
import 'organization_member_service.dart';

/// Servicio para gestión de Estados de Producto
class ProductStatusService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrganizationMemberService _memberService;

  ProductStatusService({required OrganizationMemberService memberService})
      : _memberService = memberService;

  List<ProductStatusModel> _statuses = [];
  List<ProductStatusModel> get statuses => _statuses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ==================== INICIALIZACIÓN ====================

  /// Inicializa estados predeterminados para una organización
  Future<bool> initializeDefaultStatuses({
    required String organizationId,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final defaultStatuses = ProductStatusModel.getDefaultStatuses(
        organizationId: organizationId,
        createdBy: createdBy,
      );

      final batch = _firestore.batch();

      for (final status in defaultStatuses) {
        final docRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('product_statuses')
            .doc(status.id);

        batch.set(docRef, status.toMap());
      }

      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al inicializar estados: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== LECTURA ====================

  /// Stream de todos los estados activos
  Stream<List<ProductStatusModel>> watchStatuses(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('product_statuses')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      _statuses = snapshot.docs
          .map((doc) => ProductStatusModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      return _statuses;
    });
  }

  /// Obtener todos los estados (incluidos inactivos)
  Future<List<ProductStatusModel>> getAllStatuses(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ProductStatusModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      _error = 'Error al obtener estados: $e';
      notifyListeners();
      return [];
    }
  }

  /// Obtener solo estados activos
  Future<List<ProductStatusModel>> getActiveStatuses(
      String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ProductStatusModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      _error = 'Error al obtener estados activos: $e';
      notifyListeners();
      return [];
    }
  }

  /// Obtener un estado por ID
  Future<ProductStatusModel?> getStatusById(
    String organizationId,
    String statusId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .doc(statusId)
          .get();

      if (!doc.exists) return null;
      return ProductStatusModel.fromMap(doc.data()!, docId: doc.id);
    } catch (e) {
      _error = 'Error al obtener estado: $e';
      notifyListeners();
      return null;
    }
  }

  // ==================== CREACIÓN ====================

  /// Crear un estado personalizado
  Future<String?> createStatus({
    required String organizationId,
    required String name,
    required String description,
    required String color,
    required String icon,
    required int order,
    required String createdBy,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      // TODO: añadir este permiso en la base de datos y en todos los roles.
      final canCreate = await _memberService.can('organization', 'manageProductStatuses');
      if (!canCreate) {
        _error = 'No tienes permisos para crear estados';
        notifyListeners();
        return null;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validar color
      if (!ProductStatusModel.isValidHexColor(color)) {
        _error = 'Color inválido. Use formato #RRGGBB';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final docRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .doc();

      final status = ProductStatusModel(
        id: docRef.id,
        name: name,
        description: description,
        color: color,
        icon: icon,
        order: order,
        isActive: true,
        isSystem: false,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await docRef.set(status.toMap());

      _isLoading = false;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = 'Error al crear estado: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTUALIZACIÓN ====================

  /// Actualizar un estado
  Future<bool> updateStatus({
    required String organizationId,
    required String statusId,
    String? name,
    String? description,
    String? color,
    String? icon,
    int? order,
    bool? isActive,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canEdit = await _memberService.can('organization', 'manageProductStatuses');
      if (!canEdit) {
        _error = 'No tienes permisos para editar estados';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar que no sea un estado del sistema
      final status = await getStatusById(organizationId, statusId);
      if (status == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validar color si se proporciona
      if (color != null && !ProductStatusModel.isValidHexColor(color)) {
        _error = 'Color inválido. Use formato #RRGGBB';
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
      if (order != null) updates['order'] = order;
      if (isActive != null) updates['isActive'] = isActive;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .doc(statusId)
          .update(updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Activar/desactivar estado
  Future<bool> toggleStatusActive(
    String organizationId,
    String statusId,
    bool isActive,
  ) async {
    try {
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // ✅ VALIDAR PERMISOS
      final canEdit = await _memberService.can('organization', 'manageProductStatuses');
      if (!canEdit) {
        _error = 'No tienes permisos para reordenar estados';
        notifyListeners();
        return false;
      }

    

      _isLoading = false;
      notifyListeners();
      return updateStatus(
      organizationId: organizationId,
      statusId: statusId,
      isActive: isActive,
    );
    } catch (e) {
      _error = 'Error al activar/desactivar estado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reordenar estados
  Future<bool> reorderStatuses(
    String organizationId,
    List<String> orderedStatusIds,
  ) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canEdit = await _memberService.can('organization', 'manageProductStatuses');
      if (!canEdit) {
        _error = 'No tienes permisos para reordenar estados';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final batch = _firestore.batch();

      for (int i = 0; i < orderedStatusIds.length; i++) {
        final docRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('product_statuses')
            .doc(orderedStatusIds[i]);

        batch.update(docRef, {
          'order': i + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al reordenar estados: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ELIMINACIÓN ====================

  /// Eliminar un estado (solo si no es del sistema)
  Future<bool> deleteStatus(
    String organizationId,
    String statusId,
  ) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canDelete = await _memberService.can('organization', 'manageProductStatuses');
      if (!canDelete) {
        _error = 'No tienes permisos para eliminar estados';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar que no sea un estado del sistema
      final status = await getStatusById(organizationId, statusId);
      if (status == null) {
        _error = 'Estado no encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (status.isSystem) {
        _error = 'No se pueden eliminar estados del sistema';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // TODO: Verificar que no haya productos usando este estado
      // Esto se debe implementar cuando tengas el servicio de productos actualizado

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .doc(statusId)
          .delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar estado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verificar si un estado puede ser eliminado (no tiene productos asociados)
Future<bool> canDeleteStatus(
  String organizationId,
  String statusId,
) async {
  try {
    // Consultar si hay productos con este statusId en algún lote
    final batchesSnapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .get();

    // Revisar cada lote
    for (final batchDoc in batchesSnapshot.docs) {
      final productsSnapshot = await batchDoc.reference
          .collection('batch_products')
          .where('statusId', isEqualTo: statusId)
          .limit(1)
          .get();

      if (productsSnapshot.docs.isNotEmpty) {
        return false; // Hay al menos un producto usando este estado
      }
    }

    return true; // No hay productos usando este estado
  } catch (e) {
    debugPrint('Error checking if status can be deleted: $e');
    return false;
  }
}

  // ==================== VALIDACIONES ====================

  /// Verificar si un estado existe
  Future<bool> statusExists(
    String organizationId,
    String statusId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .doc(statusId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si un nombre de estado ya existe
  Future<bool> statusNameExists(
    String organizationId,
    String name, {
    String? excludeStatusId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_statuses')
          .where('name', isEqualTo: name)
          .get();

      if (excludeStatusId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeStatusId);
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener conteo de productos por estado
  Future<Map<String, int>> getProductCountByStatus(
    String organizationId,
  ) async {
    try {
      // TODO: Implementar cuando tengas productos con statusId
      // Por ahora retorna un mapa vacío
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==================== UTILIDADES ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _statuses = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}