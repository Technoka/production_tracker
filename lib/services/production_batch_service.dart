import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/production_batch_model.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';

class ProductionBatchService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<ProductionBatchModel> _batches = [];
  List<ProductionBatchModel> get batches => _batches;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ==================== GENERAR NÚMERO DE LOTE ====================

  /// Genera un número de lote único basado en la fecha y secuencia
  /// Formato: LOT-YYYY-NNN (ej: LOT-2026-001)
  Future<String> _generateBatchNumber(String organizationId) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      
      // Obtener el último lote del año actual
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .where('batchNumber', isGreaterThanOrEqualTo: 'LOT-$year-')
          .where('batchNumber', isLessThan: 'LOT-${year + 1}-')
          .orderBy('batchNumber', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;

      if (snapshot.docs.isNotEmpty) {
        final lastBatch = snapshot.docs.first.data();
        final lastBatchNumber = lastBatch['batchNumber'] as String;
        
        // Extraer el número del último lote (ej: "LOT-2026-005" -> 5)
        final parts = lastBatchNumber.split('-');
        if (parts.length == 3) {
          final lastNum = int.tryParse(parts[2]) ?? 0;
          nextNumber = lastNum + 1;
        }
      }

      // Formatear con ceros a la izquierda (3 dígitos)
      final formattedNumber = nextNumber.toString().padLeft(3, '0');
      return 'LOT-$year-$formattedNumber';
    } catch (e) {
      // Fallback: usar timestamp
      return 'LOT-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ==================== CREAR LOTE DE PRODUCCIÓN ====================

  Future<String?> createProductionBatch({
    required String organizationId,
    required String projectId,
    required String projectName,
    required String clientId,
    required String clientName,
    required String createdBy,
    String? notes,
    int priority = 3,
    String urgencyLevel = 'medium',
    DateTime? expectedCompletionDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final batchId = _uuid.v4();
      final batchNumber = await _generateBatchNumber(organizationId);

      final batch = ProductionBatchModel(
        id: batchId,
        batchNumber: batchNumber,
        projectId: projectId,
        projectName: projectName,
        clientId: clientId,
        clientName: clientName,
        organizationId: organizationId,
        status: BatchStatus.pending.value,
        notes: notes,
        totalProducts: 0,
        completedProducts: 0,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        priority: priority,
        urgencyLevel: urgencyLevel,
        expectedCompletionDate: expectedCompletionDate,
      );

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .set(batch.toMap());

      // Incrementar contador de lotes en el proyecto
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .update({
        'batchCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return batchId;
    } on FirebaseException catch (e) {
      _error = 'Error al crear lote: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== OBTENER LOTES ====================

  /// Stream de todos los lotes de una organización
  Stream<List<ProductionBatchModel>> watchBatches(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      _batches = snapshot.docs
          .map((doc) => ProductionBatchModel.fromMap(doc.data()))
          .toList();
      return _batches;
    });
  }

  /// Stream de lotes por proyecto
  Stream<List<ProductionBatchModel>> watchProjectBatches(
    String organizationId,
    String projectId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductionBatchModel.fromMap(doc.data()))
            .toList());
  }

  /// Stream de un lote específico
  Stream<ProductionBatchModel?> watchBatch(
    String organizationId,
    String batchId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .doc(batchId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProductionBatchModel.fromMap(doc.data()!);
    });
  }

  /// Obtener lote específico (one-time)
  Future<ProductionBatchModel?> getBatch(
    String organizationId,
    String batchId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ProductionBatchModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _error = 'Error al obtener lote: $e';
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTUALIZAR LOTE ====================

  Future<bool> updateBatch({
    required String organizationId,
    required String batchId,
    String? notes,
    int? priority,
    String? urgencyLevel,
    DateTime? expectedCompletionDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) updates['notes'] = notes;
      if (priority != null) updates['priority'] = priority;
      if (urgencyLevel != null) updates['urgencyLevel'] = urgencyLevel;
      if (expectedCompletionDate != null) {
        updates['expectedCompletionDate'] = Timestamp.fromDate(expectedCompletionDate);
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update(updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar lote: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar estado del lote
  Future<bool> updateBatchStatus(
    String organizationId,
    String batchId,
    String newStatus,
  ) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Si pasa a "in_progress" por primera vez, registrar startedAt
      if (newStatus == BatchStatus.inProgress.value) {
        final batch = await getBatch(organizationId, batchId);
        if (batch?.startedAt == null) {
          updates['startedAt'] = FieldValue.serverTimestamp();
        }
      }

      // Si se completa, registrar actualCompletionDate
      if (newStatus == BatchStatus.completed.value) {
        updates['actualCompletionDate'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update(updates);

      return true;
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== PRODUCTOS EN LOTE ====================

  /// Añadir producto al lote
  Future<String?> addProductToBatch({
    required String organizationId,
    required String batchId,
    required String productCatalogId,
    required String productName,
    String? productReference,
    String? description,
    required int quantity,
    required List<ProductionPhase> phases,
    String? color,
    String? material,
    String? specialDetails,
    double? unitPrice,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final productId = _uuid.v4();

      // Inicializar progreso de fases
      final phaseProgress = <String, PhaseProgressData>{};
      for (var phase in phases) {
        phaseProgress[phase.id] = PhaseProgressData(status: 'pending');
      }

      // Primera fase activa
      final firstPhase = phases.first;

      final product = BatchProductModel(
        id: productId,
        batchId: batchId,
        productCatalogId: productCatalogId,
        productName: productName,
        productReference: productReference,
        description: description,
        quantity: quantity,
        currentPhase: firstPhase.id,
        currentPhaseName: firstPhase.name,
        phaseProgress: phaseProgress,
        color: color,
        material: material,
        specialDetails: specialDetails,
        unitPrice: unitPrice,
        totalPrice: unitPrice != null ? unitPrice * quantity : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Crear producto en subcolección
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .set(product.toMap());

      // Incrementar contador de productos en el lote
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update({
        'totalProducts': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return productId;
    } catch (e) {
      _error = 'Error al añadir producto: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Stream de productos de un lote
  Stream<List<BatchProductModel>> watchBatchProducts(
    String organizationId,
    String batchId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .doc(batchId)
        .collection('batch_products')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BatchProductModel.fromMap(doc.data()))
            .toList());
  }

  /// Obtener producto específico
  Future<BatchProductModel?> getBatchProduct(
    String organizationId,
    String batchId,
    String productId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .get();

      if (doc.exists && doc.data() != null) {
        return BatchProductModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _error = 'Error al obtener producto: $e';
      notifyListeners();
      return null;
    }
  }

  /// Actualizar fase de un producto
  Future<bool> updateProductPhase({
    required String organizationId,
    required String batchId,
    required String productId,
    required String newPhaseId,
    required String newPhaseName,
    required String userId,
    required String userName,
    String? notes,
  }) async {
    try {
      // Obtener producto actual
      final product = await getBatchProduct(organizationId, batchId, productId);
      if (product == null) return false;

      // Actualizar progreso de fases
      final updatedProgress = Map<String, PhaseProgressData>.from(product.phaseProgress);

      // Marcar fase anterior como completada
      if (updatedProgress.containsKey(product.currentPhase)) {
        updatedProgress[product.currentPhase] = updatedProgress[product.currentPhase]!.copyWith(
          status: 'completed',
          completedAt: DateTime.now(),
          completedBy: userId,
          completedByName: userName,
          notes: notes,
        );
      }

      // Marcar nueva fase como en progreso
      if (updatedProgress.containsKey(newPhaseId)) {
        updatedProgress[newPhaseId] = updatedProgress[newPhaseId]!.copyWith(
          status: 'in_progress',
          startedAt: DateTime.now(),
        );
      }

      // Actualizar producto
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .update({
        'currentPhase': newPhaseId,
        'currentPhaseName': newPhaseName,
        'phaseProgress': updatedProgress.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Verificar si el producto se completó
      final allCompleted = updatedProgress.values.every((p) => p.status == 'completed');
      if (allCompleted) {
        await _incrementCompletedProducts(organizationId, batchId);
      }

      return true;
    } catch (e) {
      _error = 'Error al actualizar fase: $e';
      notifyListeners();
      return false;
    }
  }

  /// Incrementar contador de productos completados
  Future<void> _incrementCompletedProducts(
    String organizationId,
    String batchId,
  ) async {
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .doc(batchId)
        .update({
      'completedProducts': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Verificar si el lote se completó
    final batch = await getBatch(organizationId, batchId);
    if (batch != null && batch.isComplete && batch.status != BatchStatus.completed.value) {
      await updateBatchStatus(organizationId, batchId, BatchStatus.completed.value);
    }
  }

  /// Eliminar producto del lote
  Future<bool> deleteProductFromBatch(
    String organizationId,
    String batchId,
    String productId,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .delete();

      // Decrementar contador
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update({
        'totalProducts': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _error = 'Error al eliminar producto: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== ELIMINAR LOTE ====================

  Future<bool> deleteBatch(String organizationId, String batchId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Obtener el lote para saber el projectId
      final batch = await getBatch(organizationId, batchId);
      
      // Eliminar lote
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .delete();

      // Decrementar contador en proyecto
      if (batch != null) {
        await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(batch.projectId)
            .update({
          'batchCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar lote: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener estadísticas de lotes
  Future<Map<String, dynamic>> getBatchStatistics(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .get();

      final batches = snapshot.docs
          .map((doc) => ProductionBatchModel.fromMap(doc.data()))
          .toList();

      return {
        'total': batches.length,
        'pending': batches.where((b) => b.isPending).length,
        'inProgress': batches.where((b) => b.isInProgress).length,
        'completed': batches.where((b) => b.isCompleted).length,
        'delayed': batches.where((b) => b.isDelayed).length,
      };
    } catch (e) {
      _error = 'Error al obtener estadísticas: $e';
      notifyListeners();
      return {};
    }
  }

  // ==================== UTILIDADES ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _batches = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}