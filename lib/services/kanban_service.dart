import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';
import '../models/user_model.dart';

class KanbanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de productos para Kanban, agrupados por fase
  Stream<Map<String, List<BatchProductModel>>> getKanbanProductsStream({
    required String organizationId,
    required String projectId,
    String? batchId,
    String? searchQuery,
    bool onlyBlocked = false,
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
          .map((doc) => BatchProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Aplicar filtros adicionales
      var filteredProducts = products;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredProducts = filteredProducts.where((p) =>
            p.productName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }

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

  // Mover producto a nueva fase
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
      final updatedProgress = Map<String, PhaseProgressData>.from(product.phaseProgress);

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

  // Reordenar productos dentro de una fase
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

  // Verificar si se puede mover a fase (WIP limit)
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

  // Obtener conteo de productos por fase
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

  // Bloquear/desbloquear producto
  Future<void> toggleProductBlock({
    required String organizationId,
    required String projectId,
    required String batchId,
    required String productId,
    required bool isBlocked,
    String? blockReason,
  }) async {
    try {
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

  // Verificar permisos de usuario para mover a fase
  bool canUserMoveToPhase({
    required UserModel user,
    required String phaseId,
  }) {
    // Admin y production manager pueden mover a cualquier fase
    if (user.isAdmin || user.isProductionManager || user.isManufacturer) {
      return true;
    }

    // Operario solo puede mover a sus fases asignadas
    // NOTA: Necesitarás añadir el campo assignedPhases al UserModel
    // Por ahora, permitimos a operarios mover productos
    if (user.isOperator || user.isAdmin) {
      return true; // TODO: Implementar assignedPhases
    }

    // Cliente no puede mover productos
    return false;
  }

  // Cambiar swimlane de producto (para agrupación)
  Future<void> updateProductSwimlane({
    required String organizationId,
    required String projectId,
    required String batchId,
    required String productId,
    required String swimlane,
  }) async {
    try {
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

  // Obtener estadísticas de Kanban
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

      final activeProducts = allProducts
          .where((p) => !p.isCompleted)
          .toList();

      final completedProducts = allProducts
          .where((p) => p.isCompleted)
          .length;

      return {
        'totalProducts': allProducts.length,
        'activeProducts': activeProducts.length,
        'completedProducts': completedProducts,
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