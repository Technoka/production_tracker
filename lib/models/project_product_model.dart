import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de producto dentro de un proyecto (vinculado al catálogo)
class ProjectProductModel {
  final String id;
  final String projectId;
  final String catalogProductId; // Referencia al producto del catálogo
  final String catalogProductName; // Nombre del producto (cacheado)
  final String catalogProductReference; // Referencia del producto (cacheado)
  final int quantity; // Cantidad de unidades
  final ProductCustomization customization; // Personalizaciones
  final double unitPrice; // Precio unitario
  final double totalPrice; // Precio total (quantity * unitPrice)
  final String status; // pendiente, en_produccion, completado
  final String? notes; // Notas adicionales
  final String createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime updatedAt;

  ProjectProductModel({
    required this.id,
    required this.projectId,
    required this.catalogProductId,
    required this.catalogProductName,
    required this.catalogProductReference,
    required this.quantity,
    required this.customization,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'catalogProductId': catalogProductId,
      'catalogProductName': catalogProductName,
      'catalogProductReference': catalogProductReference,
      'quantity': quantity,
      'customization': customization.toMap(),
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProjectProductModel.fromMap(Map<String, dynamic> map) {
    return ProjectProductModel(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      catalogProductId: map['catalogProductId'] as String,
      catalogProductName: map['catalogProductName'] as String,
      catalogProductReference: map['catalogProductReference'] as String,
      quantity: map['quantity'] as int,
      customization: ProductCustomization.fromMap(
        map['customization'] as Map<String, dynamic>,
      ),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ProjectProductModel copyWith({
    String? id,
    String? projectId,
    String? catalogProductId,
    String? catalogProductName,
    String? catalogProductReference,
    int? quantity,
    ProductCustomization? customization,
    double? unitPrice,
    double? totalPrice,
    String? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return ProjectProductModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      catalogProductId: catalogProductId ?? this.catalogProductId,
      catalogProductName: catalogProductName ?? this.catalogProductName,
      catalogProductReference: catalogProductReference ?? this.catalogProductReference,
      quantity: quantity ?? this.quantity,
      customization: customization ?? this.customization,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helpers
  bool get isPending => status == 'pendiente';
  bool get isInProduction => status == 'en_produccion';
  bool get isCompleted => status == 'completado';

  String get statusDisplayName {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_produccion':
        return 'En Producción';
      case 'completado':
        return 'Completado';
      default:
        return status;
    }
  }
}

/// Personalizaciones de un producto en un proyecto
class ProductCustomization {
  final String? color;
  final String? material;
  final String? finish;
  final String? specialDetails;
  final CustomDimensions? dimensions;
  final Map<String, dynamic> additionalSpecs; // Especificaciones adicionales

  ProductCustomization({
    this.color,
    this.material,
    this.finish,
    this.specialDetails,
    this.dimensions,
    this.additionalSpecs = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'material': material,
      'finish': finish,
      'specialDetails': specialDetails,
      'dimensions': dimensions?.toMap(),
      'additionalSpecs': additionalSpecs,
    };
  }

  factory ProductCustomization.fromMap(Map<String, dynamic> map) {
    return ProductCustomization(
      color: map['color'] as String?,
      material: map['material'] as String?,
      finish: map['finish'] as String?,
      specialDetails: map['specialDetails'] as String?,
      dimensions: map['dimensions'] != null
          ? CustomDimensions.fromMap(map['dimensions'] as Map<String, dynamic>)
          : null,
      additionalSpecs: map['additionalSpecs'] != null
          ? Map<String, dynamic>.from(map['additionalSpecs'] as Map)
          : {},
    );
  }

  ProductCustomization copyWith({
    String? color,
    String? material,
    String? finish,
    String? specialDetails,
    CustomDimensions? dimensions,
    Map<String, dynamic>? additionalSpecs,
  }) {
    return ProductCustomization(
      color: color ?? this.color,
      material: material ?? this.material,
      finish: finish ?? this.finish,
      specialDetails: specialDetails ?? this.specialDetails,
      dimensions: dimensions ?? this.dimensions,
      additionalSpecs: additionalSpecs ?? this.additionalSpecs,
    );
  }

  bool get hasCustomizations {
    return color != null ||
        material != null ||
        finish != null ||
        specialDetails != null ||
        (dimensions?.hasAnyDimension ?? false) ||
        additionalSpecs.isNotEmpty;
  }

  List<String> getCustomizationSummary() {
    final summary = <String>[];
    if (color != null) summary.add('Color: $color');
    if (material != null) summary.add('Material: $material');
    if (finish != null) summary.add('Acabado: $finish');
    if (dimensions?.hasAnyDimension ?? false) {
      summary.add('Dimensiones: ${dimensions!.toDisplayString()}');
    }
    if (specialDetails != null && specialDetails!.isNotEmpty) {
      summary.add('Detalles: $specialDetails');
    }
    return summary;
  }
}

/// Dimensiones personalizadas del producto
class CustomDimensions {
  final double? width;
  final double? height;
  final double? depth;
  final String unit;

  CustomDimensions({
    this.width,
    this.height,
    this.depth,
    this.unit = 'cm',
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'depth': depth,
      'unit': unit,
    };
  }

  factory CustomDimensions.fromMap(Map<String, dynamic> map) {
    return CustomDimensions(
      width: map['width'] as double?,
      height: map['height'] as double?,
      depth: map['depth'] as double?,
      unit: map['unit'] as String? ?? 'cm',
    );
  }

  CustomDimensions copyWith({
    double? width,
    double? height,
    double? depth,
    String? unit,
  }) {
    return CustomDimensions(
      width: width ?? this.width,
      height: height ?? this.height,
      depth: depth ?? this.depth,
      unit: unit ?? this.unit,
    );
  }

  String toDisplayString() {
    final parts = <String>[];
    if (width != null) parts.add('${width}$unit');
    if (height != null) parts.add('${height}$unit');
    if (depth != null) parts.add('${depth}$unit');
    return parts.join(' × ');
  }

  bool get hasAnyDimension => width != null || height != null || depth != null;
}

/// Estados posibles de un producto en proyecto
enum ProjectProductStatus {
  pending('pendiente', 'Pendiente'),
  inProduction('en_produccion', 'En Producción'),
  completed('completado', 'Completado');

  final String value;
  final String displayName;
  const ProjectProductStatus(this.value, this.displayName);

  static ProjectProductStatus fromString(String value) {
    return ProjectProductStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectProductStatus.pending,
    );
  }
}