import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de catálogo de productos - Plantilla base reutilizable
class ProductCatalogModel {
  final String id;
  final String organizationId;
  final String name;
  final String reference; // SKU/Código único
  final String description;
  final String? category; 
  final String? family;
  final List<String> imageUrls; 
  final Map<String, dynamic> specifications; 
  final List<String> tags; 
  final MaterialInfo? materialInfo; 
  final DimensionsInfo? dimensions; 
  final double? estimatedWeight; 
  final double? basePrice; 
  final String? notes; 
  final bool isActive; 
  final String createdBy; 
  final DateTime createdAt;
  final String? updatedBy; 
  final DateTime updatedAt;
  final int usageCount; 
  final String approvalStatus; 
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? clientId; 
  final bool isPublic; 
  final int? estimatedProductionHours; 
  final List<Map<String, dynamic>>? clientPrices; 
  final List<String> projects;

  ProductCatalogModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.reference,
    required this.description,
    this.category,
    this.family, // ✅
    this.imageUrls = const [],
    this.specifications = const {},
    this.tags = const [],
    this.materialInfo,
    this.dimensions,
    this.estimatedWeight,
    this.basePrice,
    this.notes,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
    this.usageCount = 0,
    this.approvalStatus = 'approved',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.clientId,
    this.isPublic = true,
    this.estimatedProductionHours,
    this.clientPrices,
    required this.projects,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'reference': reference,
      'description': description,
      'category': category,
      'family': family, // ✅
      'imageUrls': imageUrls,
      'specifications': specifications,
      'tags': tags,
      'materialInfo': materialInfo?.toMap(),
      'dimensions': dimensions?.toMap(),
      'estimatedWeight': estimatedWeight,
      'basePrice': basePrice,
      'notes': notes,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'usageCount': usageCount,
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'clientId': clientId,
      'isPublic': isPublic,
      'estimatedProductionHours': estimatedProductionHours,
      'clientPrices': clientPrices,
      'projects': projects,
    };
  }

  factory ProductCatalogModel.fromMap(Map<String, dynamic> map) {
    return ProductCatalogModel(
      id: map['id'] as String,
      organizationId: map['organizationId'] as String,
      name: map['name'] as String,
      reference: map['reference'] as String,
      description: map['description'] as String,
      category: map['category'] as String?,
      family: map['family'] as String?, // ✅
      imageUrls: map['imageUrls'] != null 
          ? List<String>.from(map['imageUrls'] as List)
          : [],
      specifications: map['specifications'] != null
          ? Map<String, dynamic>.from(map['specifications'] as Map)
          : {},
      tags: map['tags'] != null 
          ? List<String>.from(map['tags'] as List)
          : [],
      materialInfo: map['materialInfo'] != null
          ? MaterialInfo.fromMap(map['materialInfo'] as Map<String, dynamic>)
          : null,
      dimensions: map['dimensions'] != null
          ? DimensionsInfo.fromMap(map['dimensions'] as Map<String, dynamic>)
          : null,
      estimatedWeight: map['estimatedWeight'] != null ? (map['estimatedWeight'] as num).toDouble() : null,
      basePrice: map['basePrice'] != null ? (map['basePrice'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      usageCount: map['usageCount'] as int? ?? 0,
      approvalStatus: map['approvalStatus'] ?? 'approved',
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null 
          ? (map['approvedAt'] as Timestamp).toDate() 
          : null,
      rejectionReason: map['rejectionReason'],
      clientId: map['clientId'],
      isPublic: map['isPublic'] ?? true,
      estimatedProductionHours: map['estimatedProductionHours'] != null ? (map['estimatedProductionHours'] as num).toInt() : null,
      clientPrices: map['clientPrices'] != null 
          ? List<Map<String, dynamic>>.from(map['clientPrices']) 
          : null,
      projects: List<String>.from(map['projects'] as List),
    );
  }

  ProductCatalogModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? reference,
    String? description,
    String? category,
    String? family, // ✅
    List<String>? imageUrls,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    MaterialInfo? materialInfo,
    DimensionsInfo? dimensions,
    double? estimatedWeight,
    double? basePrice,
    String? notes,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    int? usageCount,
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    String? clientId,
    bool? isPublic,
    int? estimatedProductionHours,
    List<Map<String, dynamic>>? clientPrices,
    List<String>? projects,
  }) {
    return ProductCatalogModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      category: category ?? this.category,
      family: family ?? this.family, // ✅
      imageUrls: imageUrls ?? this.imageUrls,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      materialInfo: materialInfo ?? this.materialInfo,
      dimensions: dimensions ?? this.dimensions,
      estimatedWeight: estimatedWeight ?? this.estimatedWeight,
      basePrice: basePrice ?? this.basePrice,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      clientId: clientId ?? this.clientId,
      isPublic: isPublic ?? this.isPublic,
      estimatedProductionHours: estimatedProductionHours ?? this.estimatedProductionHours,
      clientPrices: clientPrices ?? this.clientPrices,
      projects: projects ?? this.projects,
    );
  }
  
  // ... Resto de métodos (matchesSearch, etc) se mantienen igual
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           reference.toLowerCase().contains(lowerQuery) ||
           description.toLowerCase().contains(lowerQuery) ||
           (category?.toLowerCase().contains(lowerQuery) ?? false) ||
           (family?.toLowerCase().contains(lowerQuery) ?? false) || // ✅ Incluimos familia en búsqueda
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  bool matchesCategory(String? categoryFilter) {
    if (categoryFilter == null || categoryFilter.isEmpty) return true;
    return category?.toLowerCase() == categoryFilter.toLowerCase();
  }

  bool matchesTags(List<String> tagFilters) {
    if (tagFilters.isEmpty) return true;
    return tagFilters.any((filter) => 
      tags.any((tag) => tag.toLowerCase() == filter.toLowerCase())
    );
  }

  bool get hasProjects => projects.isNotEmpty;
  int get projectCount => projects.length;
}

/// Información de materiales del producto
class MaterialInfo {
  final String primaryMaterial; // Material principal
  final List<String> secondaryMaterials; // Materiales secundarios
  final String? finish; // Acabado (barnizado, lacado, etc)
  final String? color; // Color principal

  MaterialInfo({
    required this.primaryMaterial,
    this.secondaryMaterials = const [],
    this.finish,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'primaryMaterial': primaryMaterial,
      'secondaryMaterials': secondaryMaterials,
      'finish': finish,
      'color': color,
    };
  }

  factory MaterialInfo.fromMap(Map<String, dynamic> map) {
    return MaterialInfo(
      primaryMaterial: map['primaryMaterial'] as String,
      secondaryMaterials: map['secondaryMaterials'] != null
          ? List<String>.from(map['secondaryMaterials'] as List)
          : [],
      finish: map['finish'] as String?,
      color: map['color'] as String?,
    );
  }

  MaterialInfo copyWith({
    String? primaryMaterial,
    List<String>? secondaryMaterials,
    String? finish,
    String? color,
  }) {
    return MaterialInfo(
      primaryMaterial: primaryMaterial ?? this.primaryMaterial,
      secondaryMaterials: secondaryMaterials ?? this.secondaryMaterials,
      finish: finish ?? this.finish,
      color: color ?? this.color,
    );
  }
}

/// Información de dimensiones del producto
class DimensionsInfo {
  final double? width; // Ancho en cm
  final double? height; // Alto en cm
  final double? depth; // Profundidad en cm
  final String unit; // Unidad de medida

  DimensionsInfo({
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

  factory DimensionsInfo.fromMap(Map<String, dynamic> map) {
    return DimensionsInfo(
      width: map['width'] as double?,
      height: map['height'] as double?,
      depth: map['depth'] as double?,
      unit: map['unit'] as String? ?? 'cm',
    );
  }

  DimensionsInfo copyWith({
    double? width,
    double? height,
    double? depth,
    String? unit,
  }) {
    return DimensionsInfo(
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