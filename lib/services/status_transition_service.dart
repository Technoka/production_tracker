import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/status_transition_model.dart';
import '../models/validation_config_model.dart';

/// Servicio para gestión de Transiciones entre Estados
class StatusTransitionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StatusTransitionModel> _transitions = [];
  List<StatusTransitionModel> get transitions => _transitions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ==================== INICIALIZACIÓN ====================

  /// Inicializa transiciones predeterminadas para una organización
  Future<bool> initializeDefaultTransitions({
    required String organizationId,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final defaultTransitions = _getDefaultTransitions(
        organizationId: organizationId,
        createdBy: createdBy,
      );

      final batch = _firestore.batch();

      for (final transition in defaultTransitions) {
        final docRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('status_transitions')
            .doc();

        batch.set(docRef, transition.copyWith(id: docRef.id).toMap());
      }

      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al inicializar transiciones: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Transiciones predeterminadas del sistema
  List<StatusTransitionModel> _getDefaultTransitions({
    required String organizationId,
    required String createdBy,
  }) {
    final now = DateTime.now();

    return [
      // PENDING → cualquier estado (inicio de producción)
      StatusTransitionModel(
        id: 'temp',
        fromStatusId: 'pending',
        toStatusId: 'hold',
        fromStatusName: 'Pendiente',
        toStatusName: 'Hold',
        validationType: ValidationType.simpleApproval,
        validationConfig: ValidationConfigModel(),
        allowedRoles: ['owner', 'admin', 'production_manager'],
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // HOLD → OK (aprobación simple)
      StatusTransitionModel(
        id: 'temp',
        fromStatusId: 'hold',
        toStatusId: 'ok',
        fromStatusName: 'Hold',
        toStatusName: 'OK',
        validationType: ValidationType.simpleApproval,
        validationConfig: ValidationConfigModel(),
        allowedRoles: ['owner', 'admin', 'quality_control'],
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // HOLD → CAO (cantidad + texto + lógica condicional)
      StatusTransitionModel(
        id: 'temp',
        fromStatusId: 'hold',
        toStatusId: 'cao',
        fromStatusName: 'Hold',
        toStatusName: 'CAO',
        validationType: ValidationType.quantityAndText,
        validationConfig: ValidationConfigModel(
          quantityLabel: 'Cantidad defectuosa',
          quantityMin: 1,
          quantityPlaceholder: 'Ej: 3',
          textLabel: 'Descripción del defecto',
          textMinLength: 10,
          textMaxLength: 500,
          textPlaceholder: 'Describe el problema...',
        ),
        conditionalLogic: ConditionalLogic(
          field: 'quantity',
          operator: ConditionOperator.greaterThan,
          value: 5,
          action: ConditionalAction(
            type: ConditionalActionType.requireApproval,
            parameters: {
              'requiredRoles': ['admin', 'production_manager'],
            },
          ),
        ),
        allowedRoles: ['owner', 'admin', 'quality_control'],
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // CAO → CONTROL (para clasificación)
      StatusTransitionModel(
        id: 'temp',
        fromStatusId: 'cao',
        toStatusId: 'control',
        fromStatusName: 'CAO',
        toStatusName: 'Control',
        validationType: ValidationType.simpleApproval,
        validationConfig: ValidationConfigModel(),
        allowedRoles: ['owner', 'admin', 'quality_control'],
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),

      // CONTROL → OK (después de clasificar)
      StatusTransitionModel(
        id: 'temp',
        fromStatusId: 'control',
        toStatusId: 'ok',
        fromStatusName: 'Control',
        toStatusName: 'OK',
        validationType: ValidationType.simpleApproval,
        validationConfig: ValidationConfigModel(),
        allowedRoles: ['owner', 'admin', 'quality_control'],
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: now,
      ),
    ];
  }

  // ==================== LECTURA ====================

  /// Stream de todas las transiciones activas
  Stream<List<StatusTransitionModel>> watchTransitions(String organizationId) {
    return _firestore
      .collection('organizations')
      .doc(organizationId)
      .collection('status_transitions')
      .orderBy('fromStatusId')
      .orderBy('toStatusId')
      .snapshots()
      .map((snapshot) {
    _transitions = snapshot.docs
        .map((doc) => StatusTransitionModel.fromMap(doc.data(), docId: doc.id))
        .toList();
    return _transitions;
  });
  }

  /// Obtener transiciones disponibles desde un estado
  Future<List<StatusTransitionModel>> getAvailableTransitions({
    required String organizationId,
    required String fromStatusId,
    String? userRoleId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('status_transitions')
          .where('fromStatusId', isEqualTo: fromStatusId)
          .where('isActive', isEqualTo: true)
          .get();

      var transitions = snapshot.docs
          .map((doc) => StatusTransitionModel.fromMap(doc.data(), docId: doc.id))
          .toList();

      // Filtrar por rol si se proporciona
      if (userRoleId != null) {
        transitions = transitions
            .where((t) => t.allowedRoles.contains(userRoleId))
            .toList();
      }

      return transitions;
    } catch (e) {
      _error = 'Error al obtener transiciones: $e';
      notifyListeners();
      return [];
    }
  }

  /// Obtener una transición específica
  Future<StatusTransitionModel?> getTransition(
    String organizationId,
    String transitionId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('status_transitions')
          .doc(transitionId)
          .get();

      if (!doc.exists) return null;
      return StatusTransitionModel.fromMap(doc.data()!, docId: doc.id);
    } catch (e) {
      _error = 'Error al obtener transición: $e';
      notifyListeners();
      return null;
    }
  }

  /// Obtener transición entre dos estados específicos
  Future<StatusTransitionModel?> getTransitionBetweenStatuses({
    required String organizationId,
    required String fromStatusId,
    required String toStatusId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('status_transitions')
          .where('fromStatusId', isEqualTo: fromStatusId)
          .where('toStatusId', isEqualTo: toStatusId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return StatusTransitionModel.fromMap(
        snapshot.docs.first.data(),
        docId: snapshot.docs.first.id,
      );
    } catch (e) {
      _error = 'Error al obtener transición: $e';
      notifyListeners();
      return null;
    }
  }

  // ==================== CREACIÓN ====================

  /// Crear una transición personalizada
  Future<String?> createTransition({
    required String organizationId,
    required String fromStatusId,
    required String toStatusId,
    required String fromStatusName,
    required String toStatusName,
    required ValidationType validationType,
    required ValidationConfigModel validationConfig,
    ConditionalLogic? conditionalLogic,
    required List<String> allowedRoles,
    String? requiresPermission,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validar que no exista ya una transición igual
      final existing = await getTransitionBetweenStatuses(
        organizationId: organizationId,
        fromStatusId: fromStatusId,
        toStatusId: toStatusId,
      );

      if (existing != null) {
        _error = 'Ya existe una transición entre estos estados';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final docRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('status_transitions')
          .doc();

      final transition = StatusTransitionModel(
        id: docRef.id,
        fromStatusId: fromStatusId,
        toStatusId: toStatusId,
        fromStatusName: fromStatusName,
        toStatusName: toStatusName,
        validationType: validationType,
        validationConfig: validationConfig,
        conditionalLogic: conditionalLogic,
        allowedRoles: allowedRoles,
        requiresPermission: requiresPermission,
        isActive: true,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await docRef.set(transition.toMap());

      _isLoading = false;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = 'Error al crear transición: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTUALIZACIÓN ====================

  /// Actualizar una transición
  Future<bool> updateTransition({
    required String organizationId,
    required String transitionId,
    ValidationType? validationType,
    ValidationConfigModel? validationConfig,
    ConditionalLogic? conditionalLogic,
    List<String>? allowedRoles,
    String? requiresPermission,
    bool? isActive,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (validationType != null) {
        updates['validationType'] = validationType.value;
      }
      if (validationConfig != null) {
        updates['validationConfig'] = validationConfig.toMap();
      }
      if (conditionalLogic != null) {
        updates['conditionalLogic'] = conditionalLogic.toMap();
      }
      if (allowedRoles != null) {
        updates['allowedRoles'] = allowedRoles;
      }
      if (requiresPermission != null) {
        updates['requiresPermission'] = requiresPermission;
      }
      if (isActive != null) {
        updates['isActive'] = isActive;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('status_transitions')
          .doc(transitionId)
          .update(updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar transición: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== VALIDACIÓN ====================

  /// Validar si un usuario puede ejecutar una transición
  Future<bool> canUserExecuteTransition({
    required String organizationId,
    required String transitionId,
    required String userRoleId,
  }) async {
    try {
      final transition = await getTransition(organizationId, transitionId);
      if (transition == null) return false;

      return transition.allowedRoles.contains(userRoleId);
    } catch (e) {
      return false;
    }
  }

  /// Validar datos de una transición
  Map<String, String?> validateTransitionData({
    required StatusTransitionModel transition,
    required ValidationDataModel validationData,
  }) {
    final errors = <String, String?>{};

    switch (transition.validationType) {
      case ValidationType.simpleApproval:
        // No requiere validación adicional
        break;

      case ValidationType.textRequired:
        final textError = transition.validationConfig.validateText(
          validationData.text,
        );
        if (textError != null) errors['text'] = textError;
        break;

      case ValidationType.textOptional:
        // Opcional, pero si se proporciona debe ser válido
        if (validationData.text != null && validationData.text!.isNotEmpty) {
          final textError = transition.validationConfig.validateText(
            validationData.text,
          );
          if (textError != null) errors['text'] = textError;
        }
        break;

      case ValidationType.quantityAndText:
        final quantityError = transition.validationConfig.validateQuantity(
          validationData.quantity,
        );
        if (quantityError != null) errors['quantity'] = quantityError;

        final textError = transition.validationConfig.validateText(
          validationData.text,
        );
        if (textError != null) errors['text'] = textError;
        break;

      case ValidationType.checklist:
        final checklistError = transition.validationConfig.validateChecklist(
          validationData.checklistAnswers ?? {},
        );
        if (checklistError != null) errors['checklist'] = checklistError;
        break;

      case ValidationType.photoRequired:
        final photoError = transition.validationConfig.validatePhotos(
          validationData.photoUrls?.length ?? 0,
        );
        if (photoError != null) errors['photos'] = photoError;
        break;

      case ValidationType.multiApproval:
        final approvedCount = validationData.approvedBy?.length ?? 0;
        final minApprovals = transition.validationConfig.minApprovals ?? 1;
        if (approvedCount < minApprovals) {
          errors['approvals'] = 'Se requieren al menos $minApprovals aprobaciones';
        }
        break;
    }

    return errors;
  }

  /// Evaluar lógica condicional
  bool evaluateConditionalLogic({
    required StatusTransitionModel transition,
    required Map<String, dynamic> productData,
  }) {
    if (!transition.hasConditionalLogic) return true;

    return transition.conditionalLogic!.evaluate(productData);
  }

  // ==================== ELIMINACIÓN ====================

  /// Eliminar una transición
  Future<bool> deleteTransition(
    String organizationId,
    String transitionId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('status_transitions')
          .doc(transitionId)
          .delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar transición: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _transitions = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}