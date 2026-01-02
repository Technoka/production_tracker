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

/// Formato: XXXYYWW (ej: FL12601)
Future<String> generateBatchNumber(String prefix) async {
  return BatchNumberHelper.generateBatchNumber(prefix);
}

// AÑADIR nuevo método para actualizar fase con posibilidad de retroceder:
Future<bool> updateProductPhaseWithRollback({
  required String organizationId,
  required String batchId,
  required String productId,
  required String newPhaseId,
  required String newPhaseName,
  required String userId,
  required String userName,
  required bool isRollback, // Si es retroceso
  String? notes,
}) async {
  try {
    final product = await getBatchProduct(organizationId, batchId, productId);
    if (product == null) return false;

    final updatedProgress = Map<String, PhaseProgressData>.from(product.phaseProgress);

    if (isRollback) {
      // Retroceso: marcar fase actual como pendiente, nueva fase como en progreso
      if (updatedProgress.containsKey(product.currentPhase)) {
        updatedProgress[product.currentPhase] = PhaseProgressData(
          status: 'pending',
        );
      }
      
      if (updatedProgress.containsKey(newPhaseId)) {
        updatedProgress[newPhaseId] = updatedProgress[newPhaseId]!.copyWith(
          status: 'in_progress',
          startedAt: DateTime.now(),
          notes: notes, // Guardar motivo del retroceso
        );
      }
    } else {
      // Avance normal
      if (updatedProgress.containsKey(product.currentPhase)) {
        updatedProgress[product.currentPhase] = updatedProgress[product.currentPhase]!.copyWith(
          status: 'completed',
          completedAt: DateTime.now(),
          completedBy: userId,
          completedByName: userName,
          notes: notes,
        );
      }

      if (updatedProgress.containsKey(newPhaseId)) {
        updatedProgress[newPhaseId] = updatedProgress[newPhaseId]!.copyWith(
          status: 'in_progress',
          startedAt: DateTime.now(),
        );
      }
    }

    // Si llega a Studio, marcar como 100% completado automáticamente
    String newStatus = product.productStatus;
    if (newPhaseId == 'studio' && !isRollback) {
      // Completar Studio automáticamente
      updatedProgress['studio'] = updatedProgress['studio']!.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
        completedBy: userId,
        completedByName: userName,
      );
      // El estado sigue siendo 'pending' hasta que se envíe
    }

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
      'productStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Verificar si completó todas las fases (incluyendo Studio)
    final allCompleted = updatedProgress.values.every((p) => p.status == 'completed');
    if (allCompleted && !isRollback) {
      await _incrementCompletedProducts(organizationId, batchId);
    }

    return true;
  } catch (e) {
    _error = 'Error al actualizar fase: $e';
    notifyListeners();
    return false;
  }
}

// AÑADIR métodos para gestionar estados del producto:

/// Enviar producto al cliente (pasa a Hold)
Future<bool> sendProductToClient({
  required String organizationId,
  required String batchId,
  required String productId,
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
      'productStatus': 'hold',
      'sentToClientAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    _error = 'Error al enviar producto: $e';
    notifyListeners();
    return false;
  }
}

/// Aprobar producto (Hold -> OK)
Future<bool> approveProduct({
  required String organizationId,
  required String batchId,
  required String productId,
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
      'productStatus': 'ok',
      'evaluatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    _error = 'Error al aprobar producto: $e';
    notifyListeners();
    return false;
  }
}

/// Rechazar producto (Hold -> CAO)
Future<bool> rejectProduct({
  required String organizationId,
  required String batchId,
  required String productId,
  required int returnedCount,
  required String returnReason,
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
      'productStatus': 'cao',
      'evaluatedAt': FieldValue.serverTimestamp(),
      'returnedCount': returnedCount,
      'returnReason': returnReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    _error = 'Error al rechazar producto: $e';
    notifyListeners();
    return false;
  }
}

/// Clasificar productos devueltos
Future<bool> classifyReturns({
  required String organizationId,
  required String batchId,
  required String productId,
  required int repairedCount,
  required int discardedCount,
}) async {
  try {
    // Validar que sumen correctamente
    final product = await getBatchProduct(organizationId, batchId, productId);
    if (product == null) return false;
    
    if ((repairedCount + discardedCount) != product.returnedCount) {
      _error = 'La suma de reparados y descartados debe ser igual a devueltos';
      notifyListeners();
      return false;
    }

    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .doc(batchId)
        .collection('batch_products')
        .doc(productId)
        .update({
      'repairedCount': repairedCount,
      'discardedCount': discardedCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    _error = 'Error al clasificar devoluciones: $e';
    notifyListeners();
    return false;
  }
}

/// Pasar producto a Control
Future<bool> moveToControl({
  required String organizationId,
  required String batchId,
  required String productId,
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
      'productStatus': 'control',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    _error = 'Error al mover a control: $e';
    notifyListeners();
    return false;
  }
}

  // ==================== CREAR LOTE DE PRODUCCIÓN ====================

// ACTUALIZAR el método createProductionBatch:
Future<String?> createProductionBatch({
  required String organizationId,
  required String projectId,
  required String projectName,
  required String clientId,
  required String clientName,
  required String createdBy,
  required String batchPrefix, // NUEVO: prefijo del usuario
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
    final batchNumber = await generateBatchNumber(batchPrefix); // USAR NUEVO MÉTODO

    final batch = ProductionBatchModel(
      id: batchId,
      batchNumber: batchNumber,
      batchPrefix: batchPrefix, // GUARDAR PREFIJO
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
  } catch (e) {
    _error = 'Error al crear lote: $e';
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