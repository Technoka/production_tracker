import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Mover producto a nueva fase con validación RBAC
  Future<void> moveProductToPhase({
    required String organizationId,
    required String projectId,
    required String batchId,
    required String productId,
    required String fromPhaseId,
    required String toPhaseId,
    required String toPhaseName,
    required int newPosition,
    required String userId,
    required String userName,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS GENERALES
      final canMove = await _memberService.can('kanban', 'moveProducts');
      if (!canMove) {
        throw Exception('No tienes permisos para mover productos');
      }

      // ✅ VALIDAR SCOPE (verificar si operario tiene fase asignada)
      final scope = await _memberService.getScope('kanban', 'moveProducts');

      if (scope == PermissionScope.assigned) {
        // Verificar que el operario tenga AMBAS fases asignadas
        final canManageFromPhase = _memberService.canManagePhase(fromPhaseId);
        final canManageToPhase = _memberService.canManagePhase(toPhaseId);

        if (!canManageFromPhase || !canManageToPhase) {
          throw Exception(
              'No tienes asignadas todas las fases necesarias para este movimiento');
        }
      }
      // Si scope == all, puede mover entre cualquier fase

      final productRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId);

      final productDoc = await productRef.get();
      if (!productDoc.exists) {
        throw Exception('Producto no encontrado');
      }

      final product = BatchProductModel.fromMap(productDoc.data()!);
      final updatedProgress =
          Map<String, PhaseProgressData>.from(product.phaseProgress);

      // Generar evento de movimiento de fase
      await MessageEventsHelper.onProductMoved(
        organizationId: organizationId,
        batchId: batchId,
        productId: productId,
        productName: product.productName,
        oldPhase: product.currentPhaseName,
        newPhase: toPhaseName,
        movedBy: userName,
      );

      // Completar fase anterior si existe y es diferente
      if (fromPhaseId != toPhaseId && updatedProgress.containsKey(fromPhaseId)) {
        updatedProgress[fromPhaseId] = updatedProgress[fromPhaseId]!.copyWith(
          status: 'completed',
          completedAt: DateTime.now(),
          completedBy: userId,
          completedByName: userName,
        );
      }

      // Iniciar nueva fase si no existe o está pendiente
      if (!updatedProgress.containsKey(toPhaseId)) {
        updatedProgress[toPhaseId] = PhaseProgressData(
          status: 'in_progress',
          startedAt: DateTime.now(),
        );
      } else if (updatedProgress[toPhaseId]!.status == 'pending') {
        updatedProgress[toPhaseId] = updatedProgress[toPhaseId]!.copyWith(
          status: 'in_progress',
          startedAt: DateTime.now(),
        );
      }

      // Si se completó una fase
      if (fromPhaseId != toPhaseId &&
          updatedProgress[fromPhaseId]?.status == 'completed') {
        await MessageEventsHelper.onPhaseCompleted(
          organizationId: organizationId,
          batchId: batchId,
          productId: productId,
          phaseName: product.currentPhaseName,
          completedBy: userName,
          productName: product.productName,
        );
      }

      // Actualizar producto
      await productRef.update({
        'currentPhase': toPhaseId,
        'currentPhaseName': toPhaseName,
        'phaseProgress': updatedProgress.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
        'kanbanPosition': newPosition,
        'updatedAt': Timestamp.now(),
      });

      // Reordenar otros productos en la columna destino
      await _reorderProductsInPhase(
        organizationId: organizationId,
        projectId: projectId,
        batchId: batchId,
        phaseId: toPhaseId,
        movedProductId: productId,
        newPosition: newPosition,
      );
    } catch (e) {
      throw Exception('Error al mover producto: $e');
    }
  }

  // ==================== REORDENAR PRODUCTOS ====================

  /// Reordenar productos dentro de una fase
  Future<void> _reorderProductsInPhase({
    required String organizationId,
    required String projectId,
    required String batchId,
    required String phaseId,
    required String movedProductId,
    required int newPosition,
  }) async {
    try {
      // Obtener todos los productos de esa fase
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .orderBy('kanbanPosition')
          .get();

      final products = snapshot.docs
          .map((doc) => BatchProductModel.fromMap(doc.data()))
          .where((p) => p.currentPhase == phaseId && p.id != movedProductId)
          .toList();

      // Reordenar posiciones
      final batch = _firestore.batch();
      int position = 0;

      for (var product in products) {
        if (position == newPosition) {
          position++; // Dejar espacio para el producto movido
        }

        if (product.kanbanPosition != position) {
          final ref = _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('production_batches')
              .doc(batchId)
              .collection('batch_products')
              .doc(product.id);

          batch.update(ref, {'kanbanPosition': position});
        }

        position++;
      }

      await batch.commit();
    } catch (e) {
      // No lanzar error, es operación secundaria
      print('Error reordenando productos: $e');
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
      final canBlock = await _memberService.can('products', 'changeStatus');
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
      final canEdit = await _memberService.can('products', 'edit');
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

      final activeProducts =
          allProducts.where((p) => !p.isCompleted).toList();

      final completedProducts =
          allProducts.where((p) => p.isCompleted).length;

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