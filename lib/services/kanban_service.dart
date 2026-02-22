import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';
import '../models/permission_model.dart';
import '../utils/message_events_helper.dart';
import 'organization_member_service.dart';

class KanbanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrganizationMemberService _memberService;

  KanbanService({required OrganizationMemberService memberService})
      : _memberService = memberService;

  // ==================== STREAM DE PRODUCTOS KANBAN ====================

  /// Stream de productos para Kanban, agrupados por fase
  Stream<Map<String, List<BatchProductModel>>> getKanbanProductsStream({
    required String organizationId,
    required String projectId,
    String? batchId,
    String? searchQuery,
    // bool onlyBlocked = false,
  }) {
    Query query = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .doc(batchId ?? 'default')
        .collection('batch_products')
        .orderBy('kanbanPosition');

    return query.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) =>
              BatchProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Aplicar filtros adicionales
      var filteredProducts = products;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredProducts = filteredProducts
            .where((p) =>
                p.productName.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      // if (onlyBlocked) {
      //   filteredProducts =
      //       filteredProducts.where((p) => p.isBlocked).toList();
      // }

      // Agrupar por fase actual
      final Map<String, List<BatchProductModel>> groupedByPhase = {};

      for (final product in filteredProducts) {
        final currentPhase = product.currentPhase;
        if (!groupedByPhase.containsKey(currentPhase)) {
          groupedByPhase[currentPhase] = [];
        }
        groupedByPhase[currentPhase]!.add(product);
      }

      return groupedByPhase;
    });
  }

  // ==================== MOVER PRODUCTO ====================

  /// Mover producto a nueva fase con validación RBAC.
  /// Recibe el [BatchProductModel] completo para evitar una lectura extra a Firestore.
  /// [allPhases] debe estar ordenado por [ProductionPhase.order] ascendente.
  /// Si es un rollback (fase destino anterior a la actual), todas las fases
  /// posteriores a la destino se resetean a "pending" con sus campos a null.
  /// [notes] es opcional y se pasa al evento de cambio de fase.
  Future<void> moveProductToPhase({
    required String organizationId,
    required BatchProductModel product,
    required ProductionPhase toPhase,
    required List<ProductionPhase> allPhases,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    final fromPhaseId = product.currentPhase;
    final toPhaseId = toPhase.id;

    if (fromPhaseId == toPhaseId) return;

    // ✅ VALIDAR PERMISOS GENERALES
    final canMove = await _memberService.can('kanban', 'moveProducts');
    if (!canMove) {
      throw Exception('No tienes permisos para mover productos');
    }

    // ✅ VALIDAR SCOPE
    final scope = await _memberService.getScope('kanban', 'moveProducts');
    if (scope == PermissionScope.assigned) {
      if (!_memberService.canManagePhase(fromPhaseId) ||
          !_memberService.canManagePhase(toPhaseId)) {
        throw Exception(
            'No tienes asignadas todas las fases necesarias para este movimiento');
      }
    }

    // Determinar si es avance o retroceso usando el orden de las fases
    final fromIndex = allPhases.indexWhere((p) => p.id == fromPhaseId);
    final toIndex = allPhases.indexWhere((p) => p.id == toPhaseId);
    final isRollback = toIndex < fromIndex;

    final productRef = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .doc(product.batchId)
        .collection('batch_products')
        .doc(product.id);

    // Construir el mapa de actualización
    final Map<String, dynamic> updates = {
      'currentPhase': toPhaseId,
      'currentPhaseName': toPhase.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isRollback) {
      // — ROLLBACK —
      // La fase destino pasa a in_progress (conserva startedAt si ya existía)
      updates['phaseProgress.$toPhaseId.status'] = 'in_progress';
      updates['phaseProgress.$toPhaseId.completedAt'] = null;
      updates['phaseProgress.$toPhaseId.completedBy'] = null;
      updates['phaseProgress.$toPhaseId.completedByName'] = null;

      // Todas las fases POSTERIORES a la destino (incluida la fase actual)
      // se resetean completamente a pending
      final phasesToReset = allPhases
          .where((p) => allPhases.indexOf(p) > toIndex)
          .map((p) => p.id)
          .toList();

      for (final phaseId in phasesToReset) {
        updates['phaseProgress.$phaseId.status'] = 'pending';
        updates['phaseProgress.$phaseId.startedAt'] = null;
        updates['phaseProgress.$phaseId.completedAt'] = null;
        updates['phaseProgress.$phaseId.completedBy'] = null;
        updates['phaseProgress.$phaseId.completedByName'] = null;
        updates['phaseProgress.$phaseId.notes'] = null;
      }
    } else {
      // — AVANCE —
      // Completar fase anterior
      updates['phaseProgress.$fromPhaseId.status'] = 'completed';
      updates['phaseProgress.$fromPhaseId.completedAt'] =
          FieldValue.serverTimestamp();
      updates['phaseProgress.$fromPhaseId.completedBy'] = userId;
      updates['phaseProgress.$fromPhaseId.completedByName'] = userName;

      // Iniciar nueva fase
      updates['phaseProgress.$toPhaseId.status'] = 'in_progress';
      updates['phaseProgress.$toPhaseId.startedAt'] =
          FieldValue.serverTimestamp();
    }

    await productRef.update(updates);

    // Generar evento — no bloqueante
    try {
      await MessageEventsHelper.onProductPhaseChanged(
        organizationId: organizationId,
        batchId: product.batchId,
        productId: product.id,
        productName: product.productName,
        productNumber: product.productNumber,
        productCode: product.productCode,
        oldPhaseName: product.currentPhaseName,
        newPhaseName: toPhase.name,
        changedBy: userName,
        validationData: notes != null ? {'notes': notes} : null,
      );
    } catch (e) {
      debugPrint('Error generating phase change event: $e');
    }
  }

  // ==================== VALIDACIONES ====================

  /// Verificar si se puede mover a fase (WIP limit)
  Future<bool> canMoveToPhase({
    required String organizationId,
    required String projectId,
    required String batchId,
    required String phaseId,
    required ProductionPhase phase,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .get();

      final productsInPhase = snapshot.docs
          .map((doc) => BatchProductModel.fromMap(doc.data()))
          .where((p) => p.currentPhase == phaseId)
          .length;

      return productsInPhase < phase.wipLimit;
    } catch (e) {
      return true; // En caso de error, permitir
    }
  }

  /// Verificar si usuario puede mover producto a una fase específica
  Future<bool> canUserMoveToPhase({
    required String phaseId,
  }) async {
    // Verificar permiso general
    final canMove = await _memberService.can('kanban', 'moveProducts');
    if (!canMove) return false;

    // Verificar scope
    final scope = await _memberService.getScope('kanban', 'moveProducts');

    switch (scope) {
      case PermissionScope.all:
        return true; // Admin puede mover a cualquier fase
      case PermissionScope.assigned:
        // Operario solo puede mover a sus fases asignadas
        return _memberService.canManagePhase(phaseId);
      case PermissionScope.none:
        return false;
    }
  }

  // ==================== BLOQUEO DE PRODUCTOS ====================

  /// Bloquear/desbloquear producto
  Future<void> toggleProductBlock({
    required String organizationId,
    required String projectId,
    required String batchId,
    required String productId,
    required bool isBlocked,
    String? blockReason,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canBlock =
          await _memberService.can('batch_products', 'changeStatus');
      if (!canBlock) {
        throw Exception('No tienes permisos para bloquear productos');
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .update({
        'isBlocked': isBlocked,
        'blockReason': blockReason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al actualizar estado de bloqueo: $e');
    }
  }

  // ==================== SWIMLANES ====================

  /// Cambiar swimlane de producto (para agrupación)
  Future<void> updateProductSwimlane({
    required String organizationId,
    required String projectId,
    required String batchId,
    required String productId,
    required String swimlane,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canEdit = await _memberService.can('batch_products', 'edit');
      if (!canEdit) {
        throw Exception('No tienes permisos para editar productos');
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .update({
        'swimlane': swimlane,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al actualizar swimlane: $e');
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener conteo de productos por fase
  Future<Map<String, int>> getProductCountByPhase({
    required String organizationId,
    required String projectId,
    required String batchId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .get();

      final products = snapshot.docs
          .map((doc) => BatchProductModel.fromMap(doc.data()))
          .toList();

      final Map<String, int> counts = {};

      for (final product in products) {
        final phase = product.currentPhase;
        counts[phase] = (counts[phase] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  /// Obtener estadísticas de Kanban
  Future<Map<String, dynamic>> getKanbanStats({
    required String organizationId,
    required String projectId,
    required String batchId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .get();

      final allProducts = snapshot.docs
          .map((doc) => BatchProductModel.fromMap(doc.data()))
          .toList();

      final activeProducts = allProducts.where((p) => !p.isCompleted).toList();

      final completedProducts = allProducts.where((p) => p.isCompleted).length;

      // final blockedProducts =
      //     allProducts.where((p) => p.isBlocked).length;

      return {
        'totalProducts': allProducts.length,
        'activeProducts': activeProducts.length,
        'completedProducts': completedProducts,
        // 'blockedProducts': blockedProducts,
      };
    } catch (e) {
      return {
        'totalProducts': 0,
        'activeProducts': 0,
        'completedProducts': 0,
        'blockedProducts': 0,
      };
    }
  }
}
