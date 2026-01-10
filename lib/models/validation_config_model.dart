
/// Tipo de validación para transiciones de estado
enum ValidationType {
  simpleApproval('simple_approval'),
  textRequired('text_required'),
  textOptional('text_optional'),
  quantityAndText('quantity_and_text'),
  checklist('checklist'),
  photoRequired('photo_required'),
  multiApproval('multi_approval');

  final String value;
  const ValidationType(this.value);

  static ValidationType fromString(String value) {
    return ValidationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ValidationType.simpleApproval,
    );
  }

  String get displayName {
    switch (this) {
      case ValidationType.simpleApproval:
        return 'Aprobación simple';
      case ValidationType.textRequired:
        return 'Texto obligatorio';
      case ValidationType.textOptional:
        return 'Texto opcional';
      case ValidationType.quantityAndText:
        return 'Cantidad y texto';
      case ValidationType.checklist:
        return 'Lista de verificación';
      case ValidationType.photoRequired:
        return 'Foto obligatoria';
      case ValidationType.multiApproval:
        return 'Aprobación múltiple';
    }
  }

  String get description {
    switch (this) {
      case ValidationType.simpleApproval:
        return 'Solo requiere confirmar con un botón';
      case ValidationType.textRequired:
        return 'Requiere ingresar un texto descriptivo';
      case ValidationType.textOptional:
        return 'Permite ingresar texto opcional';
      case ValidationType.quantityAndText:
        return 'Requiere cantidad numérica y descripción';
      case ValidationType.checklist:
        return 'Requiere completar una lista de verificación';
      case ValidationType.photoRequired:
        return 'Requiere adjuntar una o más fotos';
      case ValidationType.multiApproval:
        return 'Requiere aprobación de múltiples usuarios';
    }
  }
}

/// Configuración de validación para una transición
class ValidationConfigModel {
  // ==================== CONFIGURACIÓN GENERAL ====================
  
  /// Label del campo de texto (si aplica)
  final String? textLabel;
  
  /// Longitud mínima del texto
  final int? textMinLength;
  
  /// Longitud máxima del texto
  final int? textMaxLength;
  
  /// Placeholder del campo de texto
  final String? textPlaceholder;

  // ==================== QUANTITY AND TEXT ====================
  
  /// Label del campo de cantidad
  final String? quantityLabel;
  
  /// Cantidad mínima permitida
  final int? quantityMin;
  
  /// Cantidad máxima permitida
  final int? quantityMax;
  
  /// Placeholder del campo de cantidad
  final String? quantityPlaceholder;

  // ==================== CHECKLIST ====================
  
  /// Items de la checklist
  final List<ChecklistItem>? checklistItems;
  
  /// ¿Todos los items son obligatorios?
  final bool? checklistAllRequired;

  // ==================== PHOTO REQUIRED ====================
  
  /// Número mínimo de fotos requeridas
  final int? minPhotos;
  
  /// Número máximo de fotos permitidas
  final int? maxPhotos;

  // ==================== MULTI APPROVAL ====================
  
  /// IDs de roles que deben aprobar
  final List<String>? requiredApproverRoles;
  
  /// Número mínimo de aprobaciones necesarias
  final int? minApprovals;

  ValidationConfigModel({
    this.textLabel,
    this.textMinLength,
    this.textMaxLength,
    this.textPlaceholder,
    this.quantityLabel,
    this.quantityMin,
    this.quantityMax,
    this.quantityPlaceholder,
    this.checklistItems,
    this.checklistAllRequired,
    this.minPhotos,
    this.maxPhotos,
    this.requiredApproverRoles,
    this.minApprovals,
  });

  factory ValidationConfigModel.fromMap(Map<String, dynamic> map) {
    return ValidationConfigModel(
      textLabel: map['textLabel'] as String?,
      textMinLength: map['textMinLength'] as int?,
      textMaxLength: map['textMaxLength'] as int?,
      textPlaceholder: map['textPlaceholder'] as String?,
      quantityLabel: map['quantityLabel'] as String?,
      quantityMin: map['quantityMin'] as int?,
      quantityMax: map['quantityMax'] as int?,
      quantityPlaceholder: map['quantityPlaceholder'] as String?,
      checklistItems: map['checklistItems'] != null
          ? (map['checklistItems'] as List)
              .map((item) => ChecklistItem.fromMap(item as Map<String, dynamic>))
              .toList()
          : null,
      checklistAllRequired: map['checklistAllRequired'] as bool?,
      minPhotos: map['minPhotos'] as int?,
      maxPhotos: map['maxPhotos'] as int?,
      requiredApproverRoles: map['requiredApproverRoles'] != null
          ? List<String>.from(map['requiredApproverRoles'] as List)
          : null,
      minApprovals: map['minApprovals'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (textLabel != null) 'textLabel': textLabel,
      if (textMinLength != null) 'textMinLength': textMinLength,
      if (textMaxLength != null) 'textMaxLength': textMaxLength,
      if (textPlaceholder != null) 'textPlaceholder': textPlaceholder,
      if (quantityLabel != null) 'quantityLabel': quantityLabel,
      if (quantityMin != null) 'quantityMin': quantityMin,
      if (quantityMax != null) 'quantityMax': quantityMax,
      if (quantityPlaceholder != null) 'quantityPlaceholder': quantityPlaceholder,
      if (checklistItems != null)
        'checklistItems': checklistItems!.map((item) => item.toMap()).toList(),
      if (checklistAllRequired != null) 'checklistAllRequired': checklistAllRequired,
      if (minPhotos != null) 'minPhotos': minPhotos,
      if (maxPhotos != null) 'maxPhotos': maxPhotos,
      if (requiredApproverRoles != null) 'requiredApproverRoles': requiredApproverRoles,
      if (minApprovals != null) 'minApprovals': minApprovals,
    };
  }

  ValidationConfigModel copyWith({
    String? textLabel,
    int? textMinLength,
    int? textMaxLength,
    String? textPlaceholder,
    String? quantityLabel,
    int? quantityMin,
    int? quantityMax,
    String? quantityPlaceholder,
    List<ChecklistItem>? checklistItems,
    bool? checklistAllRequired,
    int? minPhotos,
    int? maxPhotos,
    List<String>? requiredApproverRoles,
    int? minApprovals,
  }) {
    return ValidationConfigModel(
      textLabel: textLabel ?? this.textLabel,
      textMinLength: textMinLength ?? this.textMinLength,
      textMaxLength: textMaxLength ?? this.textMaxLength,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      quantityMin: quantityMin ?? this.quantityMin,
      quantityMax: quantityMax ?? this.quantityMax,
      quantityPlaceholder: quantityPlaceholder ?? this.quantityPlaceholder,
      checklistItems: checklistItems ?? this.checklistItems,
      checklistAllRequired: checklistAllRequired ?? this.checklistAllRequired,
      minPhotos: minPhotos ?? this.minPhotos,
      maxPhotos: maxPhotos ?? this.maxPhotos,
      requiredApproverRoles: requiredApproverRoles ?? this.requiredApproverRoles,
      minApprovals: minApprovals ?? this.minApprovals,
    );
  }

  // ==================== VALIDACIONES ====================
  
  /// Valida si el texto cumple con los requisitos
  String? validateText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'El texto es obligatorio';
    }
    
    if (textMinLength != null && text.length < textMinLength!) {
      return 'Debe tener al menos $textMinLength caracteres';
    }
    
    if (textMaxLength != null && text.length > textMaxLength!) {
      return 'No puede exceder $textMaxLength caracteres';
    }
    
    return null;
  }

  /// Valida si la cantidad cumple con los requisitos
  String? validateQuantity(int? quantity) {
    if (quantity == null) {
      return 'La cantidad es obligatoria';
    }
    
    if (quantityMin != null && quantity < quantityMin!) {
      return 'La cantidad mínima es $quantityMin';
    }
    
    if (quantityMax != null && quantity > quantityMax!) {
      return 'La cantidad máxima es $quantityMax';
    }
    
    return null;
  }

  /// Valida si la checklist está completa
  String? validateChecklist(Map<String, bool> checkedItems) {
    if (checklistItems == null) return null;
    
    if (checklistAllRequired == true) {
      final unchecked = checklistItems!.where((item) => 
        item.required && !(checkedItems[item.id] ?? false)
      ).toList();
      
      if (unchecked.isNotEmpty) {
        return 'Faltan ${unchecked.length} items obligatorios';
      }
    }
    
    return null;
  }

  /// Valida si las fotos cumplen con los requisitos
  String? validatePhotos(int photoCount) {
    if (minPhotos != null && photoCount < minPhotos!) {
      return 'Se requieren al menos $minPhotos fotos';
    }
    
    if (maxPhotos != null && photoCount > maxPhotos!) {
      return 'No se permiten más de $maxPhotos fotos';
    }
    
    return null;
  }
}

/// Item de checklist
class ChecklistItem {
  final String id;
  final String label;
  final bool required;
  final String? description;

  ChecklistItem({
    required this.id,
    required this.label,
    this.required = true,
    this.description,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      label: map['label'] as String,
      required: map['required'] as bool? ?? true,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'required': required,
      if (description != null) 'description': description,
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? label,
    bool? required,
    String? description,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      label: label ?? this.label,
      required: required ?? this.required,
      description: description ?? this.description,
    );
  }
}

/// Templates predefinidos para configuraciones comunes
class ValidationConfigTemplates {
  /// Template: Rechazo de calidad (cantidad + texto + foto)
  static ValidationConfigModel qualityRejection() {
    return ValidationConfigModel(
      quantityLabel: 'Cantidad defectuosa',
      quantityMin: 1,
      quantityPlaceholder: 'Ej: 3',
      textLabel: 'Descripción del defecto',
      textMinLength: 10,
      textMaxLength: 500,
      textPlaceholder: 'Describe el problema encontrado...',
      minPhotos: 0,
      maxPhotos: 5,
    );
  }

  /// Template: Aprobación simple
  static ValidationConfigModel simpleApproval() {
    return ValidationConfigModel();
  }

  /// Template: Checklist de inspección
  static ValidationConfigModel inspectionChecklist(List<String> items) {
    return ValidationConfigModel(
      checklistItems: items
          .asMap()
          .entries
          .map((entry) => ChecklistItem(
                id: 'item_${entry.key}',
                label: entry.value,
                required: true,
              ))
          .toList(),
      checklistAllRequired: true,
    );
  }

  /// Template: Texto obligatorio con límites
  static ValidationConfigModel requiredText({
    String label = 'Comentario',
    int minLength = 10,
    int maxLength = 500,
  }) {
    return ValidationConfigModel(
      textLabel: label,
      textMinLength: minLength,
      textMaxLength: maxLength,
    );
  }
}