import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/production_batch_model.dart';
import '../models/batch_product_model.dart';
import '../models/status_transition_model.dart';
import '../models/validation_config_model.dart';
import '../models/permission_model.dart';
import '../models/permission_override_model.dart';
import '../models/permission_registry_model.dart';
import 'product_status_service.dart';
import 'status_transition_service.dart';
import 'organization_member_service.dart';

/// Servicio para gestión de Lotes de Producción con soporte completo
/// de roles, permisos (incluyendo overrides) y validaciones de estado
class ProductionBatchService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductStatusService _statusService;
  final StatusTransitionService _transitionService;
  final OrganizationMemberService _memberService;
  final _uuid = const Uuid();

  List<ProductionBatchModel> _batches = [];
  List<ProductionBatchModel> get batches => _batches;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ProductionBatchService({
    required ProductStatusService statusService,
    required StatusTransitionService transitionService,
    required OrganizationMemberService memberService,
  })  : _statusService = statusService,
        _transitionService = transitionService,
        _memberService = memberService;

// ==================== VALIDACIÓN DE TRANSICIONES DE ESTADO ====================

  /// Valida si una transición de estado es permitida y si los datos proporcionados cumplen los requisitos.
  ///
  /// Retorna un mapa con:
  /// - 'isValid': bool
  /// - 'error': String? (si falla)
  /// - 'requiresValidation': bool (si necesita datos extra)
  /// - 'validationType': String? (tipo de validación requerida)
  /// - 'validationConfig': Map? (configuración para el UI)
  /// - 'requiresApproval': bool (si la lógica condicional pide aprobación)
  /// - 'requiredApprovers': List<String>? (roles que deben aprobar)
  Future<Map<String, dynamic>> validateStatusTransition({
    required String organizationId,
    required String fromStatusId,
    required String toStatusId,
    required String userName,
    required String userId,
    Map<String, dynamic>? validationData,
  }) async {
    try {
      // 1. Obtener la regla de transición definida
      final transition = await _transitionService.getTransitionBetweenStatuses(
        organizationId: organizationId,
        fromStatusId: fromStatusId,
        toStatusId: toStatusId,
      );

      // Si no existe una transición definida, no se permite (regla estricta)
      if (transition == null) {
        return {
          'isValid': false,
          'error': 'No existe una transición válida entre estos estados.',
          'requiresValidation': false,
        };
      }

      // 2. Verificar Roles permitidos (Nivel 1: Lista de roles en la transición)
      if (!transition.allowedRoles.contains(_memberService.currentRole!.id)) {
        return {
          'isValid': false,
          'error':
              'Tu rol (${_memberService.currentRole!.name}) no está autorizado para realizar esta transición.',
          'requiresValidation': false,
        };
      }

      // 3. Verificar Permisos Granulares (Nivel 2: Sistema de permisos dinámicos)
      // Si la transición requiere un permiso específico (ej: "products.changeUrgency")
      if (transition.requiresPermission != null) {
        final parts = transition.requiresPermission!.split('.');
        if (parts.length == 2) {
          final canChangeStatus =
              await _memberService.can('batch_products', 'changeStatus');
          if (!canChangeStatus) {
            return {
              'isValid': false,
              'error':
                  'No tienes el permiso requerido: ${transition.requiresPermission}',
            };
          }
        }
      }

      // 4. Evaluar Lógica Condicional (Si existe)
      // Ej: Si quantity > 5 entonces requiere aprobación de Admin
      if (transition.hasConditionalLogic && validationData != null) {
        // Evaluamos usando los datos proporcionados (ej: cantidad defectuosa ingresada)
        final conditionMet =
            transition.conditionalLogic!.evaluate(validationData);

        if (conditionMet) {
          final action = transition.conditionalLogic!.action;

          switch (action.type) {
            case ConditionalActionType.blockTransition:
              return {
                'isValid': false,
                'error': action.parameters?['reason'] ??
                    'Transición bloqueada por reglas de negocio.',
                'requiresValidation': false,
              };

            case ConditionalActionType.showWarning:
              // Solo añadimos warning, pero permitimos continuar si los datos son válidos
              // El return final manejará la validación de datos
              break; // Continuamos al paso 5

            case ConditionalActionType.requireApproval:
              // Retornamos válido PERO indicamos que se requiere un flujo de aprobación
              // El UI debe detectar 'requiresApproval' y cambiar el flujo.
              return {
                'isValid': true,
                'requiresValidation':
                    transition.validationType != ValidationType.simpleApproval,
                'validationType': transition.validationType.value,
                'validationConfig': transition.validationConfig.toMap(),
                'requiresApproval': true,
                'requiredApprovers': action.parameters?['requiredRoles'] ?? [],
              };

            case ConditionalActionType.requireAdditionalField:
              // Podríamos forzar un error si el campo no está, o manejarlo en UI.
              break;
              
            case ConditionalActionType.notifyRoles:
              // La transición continúa normalmente, solo notificamos
              // TODO: Aquí implementar sistema de notificaciones (Fase futura)
              // Por ahora solo registramos en logs
              debugPrint('Notificar a roles: ${action.parameters?['requiredRoles']}');
              break; // Continuamos al paso 5
          }
        }
      }

      // 5. Validar Datos de Entrada (Si la transición requiere datos)
      // Si validationType NO es simpleApproval, necesitamos validar los datos.
      if (transition.validationType != ValidationType.simpleApproval) {
        // Si no hay datos, indicamos que se requieren
        if (validationData == null) {
          return {
            'isValid': false,
            'requiresValidation': true, // UI debe mostrar formulario
            'validationType': transition.validationType.value,
            'validationConfig': transition.validationConfig.toMap(),
          };
        }

        // Si hay datos, validamos su contenido
        final validationError = _validateTransitionData(
          validationType: transition.validationType,
          config: transition.validationConfig,
          data: validationData,
        );

        if (validationError != null) {
          return {
            'isValid': false,
            'error': validationError,
            'requiresValidation': true,
            'validationType': transition.validationType.value,
            'validationConfig': transition.validationConfig.toMap(),
          };
        }
      }

      // 6. Todo correcto
      return {
        'isValid': true,
        'requiresValidation':
            transition.validationType != ValidationType.simpleApproval,
        'validationType': transition.validationType.value,
        'validationConfig': transition.validationConfig.toMap(),
      };
    } catch (e) {
      debugPrint('Error en validateStatusTransition: $e');
      return {
        'isValid': false,
        'error': 'Error interno validando la transición: $e',
        'requiresValidation': false,
      };
    }
  }

  /// Valida los datos recibidos contra la configuración (ValidationConfigModel).
  /// Retorna null si es válido, o un String con el mensaje de error.
  String? _validateTransitionData({
    required ValidationType validationType,
    required ValidationConfigModel config,
    required Map<String, dynamic> data,
  }) {
    switch (validationType) {
      case ValidationType.simpleApproval:
        return null; // No requiere datos

      case ValidationType.textRequired:
        return config.validateText(data['text'] as String?);

      case ValidationType.textOptional:
        // Solo valida si se escribió algo (ej: longitud max), si es null/vacío es válido
        final text = data['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return config.validateText(text);
        }
        return null;

      case ValidationType.quantityAndText:
        // Validar cantidad
        final qty = data['quantity'] is int
            ? data['quantity'] as int
            : int.tryParse(data['quantity'].toString());

        final qtyError = config.validateQuantity(qty);
        if (qtyError != null) return qtyError;

        // Validar texto
        return config.validateText(data['text'] as String?);

      case ValidationType.checklist:
        // Extraer mapa de respuestas. ValidationDataModel usa 'checklistAnswers'
        final rawAnswers = data['checklistAnswers'] ?? data['checkedItems'];
        final Map<String, bool> answers =
            rawAnswers != null ? Map<String, bool>.from(rawAnswers) : {};

        return config.validateChecklist(answers);

      case ValidationType.photoRequired:
        final photos = data['photoUrls'] as List?;
        final count = photos?.length ?? 0;
        return config.validatePhotos(count);

      case ValidationType.multiApproval:
        // Validar si hay suficientes aprobaciones en el array 'approvedBy'
        final approvedBy = data['approvedBy'] as List?;
        final count = approvedBy?.length ?? 0;
        final min = config.minApprovals ?? 1;

        if (count < min) {
          return 'Se requieren al menos $min aprobaciones (actuales: $count).';
        }
        return null;
    }
  }

  // ==================== LECTURA DE LOTES ====================

  /// Stream de lotes con scope-awareness
  Stream<List<ProductionBatchModel>> watchBatches(String organizationId,
      {String? userId}) async* {
    try {
      // Obtener scope del permiso
      final scope = await _memberService.getScope('batches', 'view');
      
      Query<Map<String, dynamic>> query = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches');

      // Aplicar filtro según scope
      switch (scope) {
        case PermissionScope.all:
          // Sin filtro adicional - ver todos
          break;
        case PermissionScope.assigned:
          // Solo lotes asignados
          if (userId != null) {
            query = query.where('assignedMembers', arrayContains: userId);
          } else {
            // Sin userId, no puede ver nada con scope assigned
            yield [];
            return;
          }
          break;
        case PermissionScope.none:
          // Sin acceso
          yield [];
          return;
      }

      yield* query
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        _batches = snapshot.docs
            .map((doc) => ProductionBatchModel.fromMap(doc.data()))
            .toList();
            // print('lista de batches: ${_batches}');
        return _batches;
      });
    } catch (e) {
      debugPrint('Error watching batches: $e');
      yield [];
    }
  }

  /// Stream de lote por id
  Stream<ProductionBatchModel?> watchBatch(
      String organizationId, String batchId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('production_batches')
        .doc(batchId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ProductionBatchModel.fromMap(snapshot.data()!);
    });
  }

  /// Obtener lote por ID
  Future<ProductionBatchModel?> getBatchById(
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

      if (!doc.exists) return null;
      return ProductionBatchModel.fromMap(doc.data()!);
    } catch (e) {
      _error = 'Error al obtener lote: $e';
      notifyListeners();
      return null;
    }
  }

  /// Obtener lotes por estado
  Future<List<ProductionBatchModel>> getBatchesByStatus(
    String organizationId,
    BatchStatus status,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .where('status', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductionBatchModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _error = 'Error al obtener lotes: $e';
      notifyListeners();
      return [];
    }
  }

  // ==================== CREACIÓN DE LOTES ====================

  /// Crear un nuevo lote
  Future<String?> createBatch({
    required String organizationId,
    required String userId,
    required String batchNumber,
    required String batchPrefix,
    required String projectId,
    required String projectName,
    required String clientId,
    required String clientName,
    required String createdBy,
    List<String>? assignedMembers,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // ✅ Verificar permisos
      final canCreate = await _memberService.can('batches', 'create');
      if (!canCreate) {
        _error = 'No tienes permisos para crear lotes';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final docRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc();

      final batchId = _uuid.v4();
      final batch = ProductionBatchModel(
        id: batchId,
        organizationId: organizationId,
        status: BatchStatus.pending.value,
        createdBy: userId,
        createdAt: DateTime.now(),
        batchNumber: batchNumber,
        batchPrefix: batchPrefix,
        projectId: projectId,
        projectName: projectName,
        clientId: clientId,
        clientName: clientName,
        updatedAt: DateTime.now(),
        totalProducts: 0,
        completedProducts: 0,
        notes: notes,
        assignedMembers: assignedMembers ?? [createdBy],
      );

      await docRef.set(batch.toMap());

      _isLoading = false;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== GESTIÓN DE PRODUCTOS EN LOTE ====================

  /// Añadir productos al lote
  Future<bool> addProductsToBatch({
    required String organizationId,
    required String batchId,
    required List<BatchProductModel> products,
    required String userId,
    required String userName,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS (AÑADIR ESTO)
      final batch = await getBatchById(organizationId, batchId);
      if (batch == null) {
        _error = 'Lote no encontrado';
        notifyListeners();
        return false;
      }

      final isAssigned = batch.assignedMembers.contains(userId);
      final canAdd = await _memberService.canWithScope(
        'batches',
        'addProducts',
        isAssignedToUser: isAssigned,
      );

      if (!canAdd) {
        _error = 'No tienes permisos para añadir productos a este lote';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // // Verificar que el lote está en draft
      // if (batch.status != BatchStatus.draft) {
      //   throw Exception('Solo se pueden añadir productos a lotes en borrador');
      // }

      // Obtener estado por defecto (Pendiente)
      final defaultStatus = await _statusService.getStatusById(
        organizationId,
        'pending',
      );

      if (defaultStatus == null) {
        throw Exception(
            'Estado por defecto no encontrado. Inicializa los estados primero.');
      }

      final productsBatch = _firestore.batch();

      for (final product in products) {
        final productDocRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('production_batches')
            .doc(batchId)
            .collection('batch_products')
            .doc();

        // Asignar estado inicial y crear historial
        final productWithStatus = product.copyWith(
          id: productDocRef.id,
          statusId: defaultStatus.id,
          statusName: defaultStatus.name,
          statusColorValue: defaultStatus.color,
          statusHistory: [
            StatusHistoryEntry(
              statusId: defaultStatus.id,
              statusName: defaultStatus.name,
              statusColor: defaultStatus.color,
              timestamp: DateTime.now(),
              userId: userId,
              userName: userName,
            ),
          ],
        );

        productsBatch.set(productDocRef, productWithStatus.toMap());
      }

      // Actualizar timestamp del lote
      final batchDocRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId);

      productsBatch.update(batchDocRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await productsBatch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
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
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BatchProductModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Obtener producto de lote por ID
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

      if (!doc.exists) return null;
      return BatchProductModel.fromMap(doc.data()!);
    } catch (e) {
      _error = 'Error al obtener producto: $e';
      notifyListeners();
      return null;
    }
  }

  // ==================== CAMBIO DE ESTADO DE PRODUCTO ====================

  /// Cambiar estado de un producto con validaciones completas
  Future<bool> changeProductStatus({
    required String organizationId,
    required String batchId,
    required String productId,
    required String toStatusId,
    required String userId,
    required String userName,
    Map<String, dynamic>? validationData,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // ✅ Verificar permisos con scope
      final product = await getBatchProduct(organizationId, batchId, productId);
      if (product == null) {
        _error = 'Producto no encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final canChange = await _memberService.can(
        'batch_products',
        'changeStatus',
      );

      if (!canChange) {
        _error = 'No tienes permisos para cambiar el estado de este producto';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final fromStatusId = product.statusId;

      // Obtener el nuevo estado
      final toStatus = await _statusService.getStatusById(
        organizationId,
        toStatusId,
      );

      if (toStatus == null) {
        throw Exception('Estado destino no encontrado');
      }

      final validationResult = await validateStatusTransition(
        organizationId: organizationId,
        fromStatusId: fromStatusId!,
        toStatusId: toStatusId,
        userName: userName,
        userId: userId,
        validationData: validationData,
      );

      if (validationResult['isValid'] != true) {
        throw Exception(validationResult['error'] ?? 'Transición no válida');
      }

      // Crear entrada de historial
      final historyEntry = StatusHistoryEntry(
        statusId: toStatusId,
        statusName: toStatus.name,
        statusColor: toStatus.color,
        timestamp: DateTime.now(),
        userId: userId,
        userName: userName,
        validationData: validationData,
      );

      // Actualizar producto
      final updatedProduct = product.copyWith(
        statusId: toStatusId,
        statusName: toStatus.name,
        statusColorValue: toStatus.color,
        statusHistory: [...product.statusHistory, historyEntry],
      );

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .update(updatedProduct.toMap());

      // Actualizar timestamp del lote
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== CAMBIO DE ESTADO DE LOTE ====================

  /// Cambiar estado del lote completo
  Future<bool> changeBatchStatus({
    required String organizationId,
    required String batchId,
    required BatchStatus newStatus,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final batch = await getBatchById(organizationId, batchId);
      if (batch == null) {
        _error = 'Lote no encontrado';
        notifyListeners();
        return false;
      }

      final isAssigned = batch.assignedMembers.contains(userId);
      final scope = await _memberService.getScope('batches', 'edit');

      // Validaciones según el nuevo estado
      if (newStatus == BatchStatus.inProgress) {
        // Verificar que tiene productos
        final productsSnapshot = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('production_batches')
            .doc(batchId)
            .collection('batch_products')
            .limit(1)
            .get();

        if (productsSnapshot.docs.isEmpty) {
          throw Exception('No se puede iniciar un lote sin productos');
        }
      } else if (newStatus == BatchStatus.inProgress) {
        // start batch
        final canStart = await _memberService.can('batches', 'startProduction');
        if (!canStart) {
          _error = 'No tienes permisos para iniciar producción';
          notifyListeners();
          return false;
        }

        // Validar scope
        if (scope == PermissionScope.assigned && !isAssigned) {
          _error = 'No estás asignado a este lote';
          notifyListeners();
          return false;
        }
      } else if (newStatus == BatchStatus.completed) {
        final canComplete =
            await _memberService.can('batches', 'completeBatch');
        if (!canComplete) {
          _error = 'No tienes permisos para completar lotes';
          notifyListeners();
          return false;
        }
        if (scope == PermissionScope.assigned && !isAssigned) {
          _error = 'No estás asignado a este lote';
          notifyListeners();
          return false;
        }
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update({
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == BatchStatus.inProgress && batch.startedAt == null)
          'startedAt': FieldValue.serverTimestamp(),
        if (newStatus == BatchStatus.completed)
          'completedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ACTUALIZACIÓN DE PRODUCTOS ====================

  /// Actualizar un producto del lote
  Future<bool> updateBatchProduct({
    required String organizationId,
    required String batchId,
    required String productId,
    required String userId,
    int? quantity,
    double? unitPrice,
    String? notes,
    Map<String, dynamic>? customization,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final canEdit = await _memberService.can('batch_products', 'edit');
      if (!canEdit) {
        _error = 'No tienes permisos para editar productos';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (quantity != null) updates['quantity'] = quantity;
      if (unitPrice != null) {
        updates['unitPrice'] = unitPrice;
        if (quantity != null) {
          updates['totalPrice'] = quantity * unitPrice;
        }
      }
      if (notes != null) updates['notes'] = notes;
      if (customization != null) updates['customization'] = customization;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .update(updates);

      // Actualizar timestamp del lote
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar producto del lote
  Future<bool> removeBatchProduct({
    required String organizationId,
    required String batchId,
    required String productId,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final canDelete = await _memberService.can('batch_products', 'delete');
      if (!canDelete) {
        _error = 'No tienes permisos para eliminar productos de lote';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verificar que el lote existe
      final batch = await getBatchById(organizationId, batchId);
      if (batch == null) {
        throw Exception('Lote no encontrado');
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .doc(productId)
          .delete();

      // Actualizar timestamp del lote
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ELIMINACIÓN DE LOTE ====================

  /// Eliminar un lote completo
  Future<bool> deleteBatch({
    required String organizationId,
    required String batchId,
    required String userId,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS CON SCOPE (AÑADIR ESTO)
      final batch = await getBatchById(organizationId, batchId);
      if (batch == null) {
        _error = 'Lote no encontrado';
        notifyListeners();
        return false;
      }

      final isAssigned = batch.assignedMembers.contains(userId);
      final canDelete = await _memberService.canWithScope(
        'batches',
        'delete',
        isAssignedToUser: isAssigned,
      );

      if (!canDelete) {
        _error = 'No tienes permisos para eliminar este lote';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Eliminar todos los productos primero
      final productsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .get();

      final productsList = _firestore.batch();

      for (final doc in productsSnapshot.docs) {
        productsList.delete(doc.reference);
      }

      // Eliminar el lote
      final batchRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId);

      productsList.delete(batchRef);

      await productsList.commit();

      batchRef.delete(); // delete the actual batch document

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ACTUALIZACIÓN DE LOTE ====================

  /// Actualizar información del lote
  Future<bool> updateBatch({
    required String organizationId,
    required String batchId,
    required String userId,
    String? name,
    String? notes,
  }) async {
    try {
      // ✅ VALIDAR PERMISOS CON SCOPE (AÑADIR ESTO)
      final batch = await getBatchById(organizationId, batchId);
      if (batch == null) {
        _error = 'Lote no encontrado';
        notifyListeners();
        return false;
      }

      // Verificar si el usuario está asignado
      final isAssigned = batch.assignedMembers.contains(userId);
      final canEdit = await _memberService.canWithScope(
        'batches',
        'edit',
        isAssignedToUser: isAssigned,
      );

      if (!canEdit) {
        _error = 'No tienes permisos para editar este lote';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (notes != null) updates['notes'] = notes;

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
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener estadísticas de un lote
  Future<Map<String, dynamic>> getBatchStats(
    String organizationId,
    String batchId,
  ) async {
    try {
      final productsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('production_batches')
          .doc(batchId)
          .collection('batch_products')
          .get();

      final products = productsSnapshot.docs
          .map((doc) => BatchProductModel.fromMap(doc.data()))
          .toList();

      // Agrupar por estado
      final statusCount = <String, int>{};
      for (final product in products) {
        statusCount[product.statusDisplayName] =
            (statusCount[product.statusName] ?? 0) + 1;
      }

      // Calcular totales
      final totalQuantity = products.fold<int>(
        0,
        (sum, p) => sum + p.quantity,
      );

      // Corregir el error de tipo en totalPrice
      final totalValue = products.fold<double>(
        0.0,
        (sum, p) => sum + (p.totalPrice ?? 0.0),
      );

      return {
        'totalProducts': products.length,
        'totalQuantity': totalQuantity,
        'totalValue': totalValue,
        'statusDistribution': statusCount,
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
