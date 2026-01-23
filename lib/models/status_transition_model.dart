import 'package:cloud_firestore/cloud_firestore.dart';
import 'validation_config_model.dart';

/// Modelo de Transición entre Estados
/// Define las reglas para cambiar de un estado a otro
class StatusTransitionModel {
  final String id;
  final String fromStatusId;
  final String toStatusId;
  
  // Nombres desnormalizados para mostrar en UI
  final String fromStatusName;
  final String toStatusName;
  
  // Validación
  final ValidationType validationType;
  final ValidationConfigModel validationConfig;
  
  // Lógica condicional
  final ConditionalLogic? conditionalLogic;
  
  // Permisos
  final List<String> allowedRoles; // IDs de roles que pueden ejecutar esta transición
  final String? requiresPermission; // Permiso específico requerido
  
  // Metadata
  final bool isActive;
  final String organizationId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StatusTransitionModel({
    required this.id,
    required this.fromStatusId,
    required this.toStatusId,
    required this.fromStatusName,
    required this.toStatusName,
    required this.validationType,
    required this.validationConfig,
    this.conditionalLogic,
    required this.allowedRoles,
    this.requiresPermission,
    this.isActive = true,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory StatusTransitionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return StatusTransitionModel(
      id: docId ?? map['id'] as String,
      fromStatusId: map['fromStatusId'] as String,
      toStatusId: map['toStatusId'] as String,
      fromStatusName: map['fromStatusName'] as String,
      toStatusName: map['toStatusName'] as String,
      validationType: ValidationType.fromString(map['validationType'] as String),
      validationConfig: ValidationConfigModel.fromMap(
        map['validationConfig'] as Map<String, dynamic>
      ),
      conditionalLogic: map['conditionalLogic'] != null
          ? ConditionalLogic.fromMap(map['conditionalLogic'] as Map<String, dynamic>)
          : null,
      allowedRoles: List<String>.from(map['allowedRoles'] as List),
      requiresPermission: map['requiresPermission'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      organizationId: map['organizationId'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromStatusId': fromStatusId,
      'toStatusId': toStatusId,
      'fromStatusName': fromStatusName,
      'toStatusName': toStatusName,
      'validationType': validationType.value,
      'validationConfig': validationConfig.toMap(),
      if (conditionalLogic != null) 'conditionalLogic': conditionalLogic!.toMap(),
      'allowedRoles': allowedRoles,
      if (requiresPermission != null) 'requiresPermission': requiresPermission,
      'isActive': isActive,
      'organizationId': organizationId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  StatusTransitionModel copyWith({
    String? id,
    String? fromStatusId,
    String? toStatusId,
    String? fromStatusName,
    String? toStatusName,
    ValidationType? validationType,
    ValidationConfigModel? validationConfig,
    ConditionalLogic? conditionalLogic,
    List<String>? allowedRoles,
    String? requiresPermission,
    bool? isActive,
    String? organizationId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StatusTransitionModel(
      id: id ?? this.id,
      fromStatusId: fromStatusId ?? this.fromStatusId,
      toStatusId: toStatusId ?? this.toStatusId,
      fromStatusName: fromStatusName ?? this.fromStatusName,
      toStatusName: toStatusName ?? this.toStatusName,
      validationType: validationType ?? this.validationType,
      validationConfig: validationConfig ?? this.validationConfig,
      conditionalLogic: conditionalLogic ?? this.conditionalLogic,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      requiresPermission: requiresPermission ?? this.requiresPermission,
      isActive: isActive ?? this.isActive,
      organizationId: organizationId ?? this.organizationId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== HELPERS ====================
  
  /// Verifica si un usuario con un rol puede ejecutar esta transición
  bool canUserExecute(String userRoleId) {
    return allowedRoles.contains(userRoleId);
  }

  /// Obtiene una descripción legible de la transición
  String get description {
    return 'De $fromStatusName → $toStatusName';
  }

  /// Verifica si requiere lógica condicional adicional
  bool get hasConditionalLogic => conditionalLogic != null;
}

/// Lógica condicional para transiciones
/// Ejemplo: "Si cantidad > 5 → requiere aprobación adicional"
class ConditionalLogic {
  final String field; // Campo a evaluar: 'quantity', 'returnedCount', etc.
  final ConditionOperator operator;
  final dynamic value; // Valor a comparar
  final ConditionalAction action; // Acción a tomar si se cumple la condición

  ConditionalLogic({
    required this.field,
    required this.operator,
    required this.value,
    required this.action,
  });

  factory ConditionalLogic.fromMap(Map<String, dynamic> map) {
    return ConditionalLogic(
      field: map['field'] as String,
      operator: ConditionOperator.fromString(map['operator'] as String),
      value: map['value'],
      action: ConditionalAction.fromMap(map['action'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'operator': operator.value,
      'value': value,
      'action': action.toMap(),
    };
  }

  ConditionalLogic copyWith({
    String? field,
    ConditionOperator? operator,
    dynamic value,
    ConditionalAction? action,
  }) {
    return ConditionalLogic(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      action: action ?? this.action,
    );
  }

  /// Evalúa la condición con los datos proporcionados
  bool evaluate(Map<String, dynamic> data) {
    final fieldValue = data[field];
    if (fieldValue == null) return false;

    switch (operator) {
      case ConditionOperator.equals:
        return fieldValue == value;
      case ConditionOperator.notEquals:
        return fieldValue != value;
      case ConditionOperator.greaterThan:
        return (fieldValue as num) > (value as num);
      case ConditionOperator.greaterThanOrEqual:
        return (fieldValue as num) >= (value as num);
      case ConditionOperator.lessThan:
        return (fieldValue as num) < (value as num);
      case ConditionOperator.lessThanOrEqual:
        return (fieldValue as num) <= (value as num);
      case ConditionOperator.contains:
        return (fieldValue as String).contains(value as String);
    }
  }

  /// Descripción legible de la condición
  String get description {
    return 'Si $field ${operator.displayName} $value → ${action.description}';
  }
}

/// Operadores de condición
enum ConditionOperator {
  equals('equals'),
  notEquals('not_equals'),
  greaterThan('greater_than'),
  greaterThanOrEqual('greater_than_or_equal'),
  lessThan('less_than'),
  lessThanOrEqual('less_than_or_equal'),
  contains('contains');

  final String value;
  const ConditionOperator(this.value);

  static ConditionOperator fromString(String value) {
    return ConditionOperator.values.firstWhere(
      (op) => op.value == value,
      orElse: () => ConditionOperator.equals,
    );
  }

  String get displayName {
    switch (this) {
      case ConditionOperator.equals:
        return '=';
      case ConditionOperator.notEquals:
        return '≠';
      case ConditionOperator.greaterThan:
        return '>';
      case ConditionOperator.greaterThanOrEqual:
        return '≥';
      case ConditionOperator.lessThan:
        return '<';
      case ConditionOperator.lessThanOrEqual:
        return '≤';
      case ConditionOperator.contains:
        return 'contiene';
    }
  }
}

/// Acción condicional a ejecutar
class ConditionalAction {
  final ConditionalActionType type;
  final Map<String, dynamic>? parameters;

  ConditionalAction({
    required this.type,
    this.parameters,
  });

  factory ConditionalAction.fromMap(Map<String, dynamic> map) {
    return ConditionalAction(
      type: ConditionalActionType.fromString(map['type'] as String),
      parameters: map['parameters'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      if (parameters != null) 'parameters': parameters,
    };
  }

  ConditionalAction copyWith({
    ConditionalActionType? type,
    Map<String, dynamic>? parameters,
  }) {
    return ConditionalAction(
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
    );
  }

  String get description {
    switch (type) {
      case ConditionalActionType.requireApproval:
        final roles = parameters?['requiredRoles'] as List<String>?;
        return 'Requiere aprobación ${roles != null ? 'de: ${roles.join(", ")}' : 'adicional'}';
      case ConditionalActionType.showWarning:
        final message = parameters?['message'] as String?;
        return 'Mostrar advertencia${message != null ? ': $message' : ''}';
      case ConditionalActionType.blockTransition:
        final reason = parameters?['reason'] as String?;
        return 'Bloquear transición${reason != null ? ': $reason' : ''}';
      case ConditionalActionType.requireAdditionalField:
        final field = parameters?['fieldName'] as String?;
        return 'Requiere campo adicional${field != null ? ': $field' : ''}';
      case ConditionalActionType.notifyRoles:
        final roles = parameters?['requiredRoles'] as List<String>?;
        return 'Notificar a: ${roles != null ? roles.join(", ") : 'roles seleccionados'}';
    }
  }
}

/// Tipos de acciones condicionales
enum ConditionalActionType {
  requireApproval('require_approval'),
  showWarning('show_warning'),
  blockTransition('block_transition'),
  requireAdditionalField('require_additional_field'),
  notifyRoles('notify_roles');

  final String value;
  const ConditionalActionType(this.value);

  static ConditionalActionType fromString(String value) {
    return ConditionalActionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ConditionalActionType.showWarning,
    );
  }
}

/// Datos de validación completados por el usuario
class ValidationDataModel {
  final String? text;
  final int? quantity;
  final Map<String, bool>? checklistAnswers;
  final List<String>? photoUrls;
  final List<String>? approvedBy;
  final DateTime timestamp;

  // NUEVO: Para gestionar defectos individuales
  final DefectDetailsMode? defectMode;
  final String? singleDefectReason; // Motivo único para todos
  final Map<int, String>? individualDefects; // Map: índice producto → motivo

  ValidationDataModel({
    this.text,
    this.quantity,
    this.checklistAnswers,
    this.photoUrls,
    this.approvedBy,
    required this.timestamp,
    this.defectMode,
    this.singleDefectReason,
    this.individualDefects,
  });

  factory ValidationDataModel.fromMap(Map<String, dynamic> map) {
    return ValidationDataModel(
      text: map['text'] as String?,
      quantity: map['quantity'] as int?,
      checklistAnswers: map['checklistAnswers'] != null
          ? Map<String, bool>.from(map['checklistAnswers'] as Map)
          : null,
      photoUrls: map['photoUrls'] != null
          ? List<String>.from(map['photoUrls'] as List)
          : null,
      approvedBy: map['approvedBy'] != null
          ? List<String>.from(map['approvedBy'] as List)
          : null,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      defectMode: map['defectMode'] != null
          ? DefectDetailsMode.fromString(map['defectMode'] as String)
          : null,
      singleDefectReason: map['singleDefectReason'] as String?,
      individualDefects: map['individualDefects'] != null
          ? Map<int, String>.from(
              (map['individualDefects'] as Map).map(
                (key, value) => MapEntry(
                  int.parse(key.toString()),
                  value.toString(),
                ),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (text != null) 'text': text,
      if (quantity != null) 'quantity': quantity,
      if (checklistAnswers != null) 'checklistAnswers': checklistAnswers,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (approvedBy != null) 'approvedBy': approvedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      if (defectMode != null) 'defectMode': defectMode!.value,
      if (singleDefectReason != null) 'singleDefectReason': singleDefectReason,
      if (individualDefects != null)
        'individualDefects': individualDefects!.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
    };
  }

  ValidationDataModel copyWith({
    String? text,
    int? quantity,
    Map<String, bool>? checklistAnswers,
    List<String>? photoUrls,
    List<String>? approvedBy,
    DateTime? timestamp,
    DefectDetailsMode? defectMode,
    String? singleDefectReason,
    Map<int, String>? individualDefects,
  }) {
    return ValidationDataModel(
      text: text ?? this.text,
      quantity: quantity ?? this.quantity,
      checklistAnswers: checklistAnswers ?? this.checklistAnswers,
      photoUrls: photoUrls ?? this.photoUrls,
      approvedBy: approvedBy ?? this.approvedBy,
      timestamp: timestamp ?? this.timestamp,
      defectMode: defectMode ?? this.defectMode,
      singleDefectReason: singleDefectReason ?? this.singleDefectReason,
      individualDefects: individualDefects ?? this.individualDefects,
    );
  }

  /// Obtiene el motivo de defecto para un producto específico
  String? getDefectReasonForIndex(int index) {
    if (defectMode == DefectDetailsMode.single) {
      return singleDefectReason;
    } else if (defectMode == DefectDetailsMode.individual) {
      return individualDefects?[index];
    }
    return null;
  }
}

/// Modo de detalle de defectos
enum DefectDetailsMode {
  single('single'), // Mismo motivo para todos
  individual('individual'); // Motivo individual por producto

  final String value;
  const DefectDetailsMode(this.value);

  static DefectDetailsMode fromString(String value) {
    return DefectDetailsMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => DefectDetailsMode.single,
    );
  }

  String get displayName {
    switch (this) {
      case DefectDetailsMode.single:
        return 'Mismo motivo para todos';
      case DefectDetailsMode.individual:
        return 'Motivo individual por producto';
    }
  }
}