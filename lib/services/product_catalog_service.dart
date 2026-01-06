import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_catalog_model.dart';
import 'package:rxdart/rxdart.dart';

class ProductCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CREAR PRODUCTO EN CATÁLOGO ====================

  Future<String?> createProduct({
    required String organizationId,
    required String name,
    required String reference,
    required String description,
    required String createdBy,
    String? category,
    List<String>? imageUrls,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    MaterialInfo? materialInfo,
    DimensionsInfo? dimensions,
    double? estimatedWeight,
    double? basePrice,
    String? notes,
    int? estimatedProductionHours,
    String? clientId, // Para productos específicos de cliente
    bool isPublic = true,
    String? family,
  }) async {
    try {
      // Verificar que la referencia sea única en la organización
      final existingRef = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .where('reference', isEqualTo: reference)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
          
      if (existingRef.docs.isNotEmpty) {
        throw Exception('Ya existe un producto con la referencia "$reference"');
      }

      final productId = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc().id;
      print('Creating product with doc ID: $productId');
      final now = DateTime.now();

      final product = ProductCatalogModel(
        id: productId,
        organizationId: organizationId,
        name: name,
        reference: reference,
        description: description,
        category: category,
        imageUrls: imageUrls ?? [],
        specifications: specifications ?? {},
        tags: tags ?? [],
        materialInfo: materialInfo,
        dimensions: dimensions,
        estimatedWeight: estimatedWeight,
        basePrice: basePrice,
        notes: notes,
        isActive: true,
        usageCount: 0,
        estimatedProductionHours: estimatedProductionHours,
        clientId: clientId,
        isPublic: isPublic,
        approvalStatus: 'approved', // Por defecto aprobado (cambiar si necesitas workflow)
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        family: family,
      );

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc(productId)
          .set(product.toMap());

      return productId;
    } catch (e) {
      print('Error al crear producto en catálogo: $e');
      return null;
    }
  }

  // ==================== OBTENER PRODUCTOS ====================

  /// Stream de todos los productos de la organización
  Stream<List<ProductCatalogModel>> getOrganizationProductsStream(
    String organizationId, {
    bool includeInactive = false,
    }) {
    Query query = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('product_catalog')
        as Query<Map<String, dynamic>>;

    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCatalogModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Obtener productos (one-time)
  Future<List<ProductCatalogModel>> getOrganizationProducts(
    String organizationId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  /// Obtener solo productos aprobados
  Stream<List<ProductCatalogModel>> getApprovedProductsStream(
    String organizationId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('product_catalog')
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCatalogModel.fromMap(doc.data()))
            .toList());
  }

  /// Obtener productos públicos (disponibles para todos los clientes)
  Future<List<ProductCatalogModel>> getPublicProducts(
    String organizationId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .where('isPublic', isEqualTo: true)
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting public products: $e');
      return [];
    }
  }

  /// Obtener productos de un cliente específico
  Future<List<ProductCatalogModel>> getClientProducts(
    String organizationId,
    String clientId,
  ) async {
    try {
      // Obtener productos públicos + productos específicos del cliente
      final publicSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .where('isPublic', isEqualTo: true)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final clientSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .where('clientId', isEqualTo: clientId)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final publicProducts = publicSnapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data()))
          .toList();

      final clientProducts = clientSnapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data()))
          .toList();

      // Combinar y eliminar duplicados
      final allProducts = [...publicProducts, ...clientProducts];
      final uniqueProducts = <String, ProductCatalogModel>{};
      
      for (final product in allProducts) {
        uniqueProducts[product.id] = product;
      }

      return uniqueProducts.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      print('Error getting client products: $e');
      return [];
    }
  }

/// Obtener productos de un cliente específico (Versión Stream en tiempo real)
  Stream<List<ProductCatalogModel>> getClientProductsStream(
    String organizationId,
    String clientId,
  ) {
    // 1. Stream de productos públicos
    final publicStream = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('product_catalog')
        .where('isPublic', isEqualTo: true)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCatalogModel.fromMap(doc.data()))
            .toList());

    // 2. Stream de productos específicos del cliente
    final clientStream = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('product_catalog')
        .where('clientId', isEqualTo: clientId)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCatalogModel.fromMap(doc.data()))
            .toList());

    // 3. Combinar ambos streams usando Rx.combineLatest2
    // Esto se ejecutará cada vez que CUALQUIERA de las dos listas cambie en Firebase
    return Rx.combineLatest2<List<ProductCatalogModel>,
        List<ProductCatalogModel>, List<ProductCatalogModel>>(
      publicStream,
      clientStream,
      (publicProducts, clientProducts) {
        // Combinar ambas listas
        final allProducts = [...publicProducts, ...clientProducts];
        
        // Eliminar duplicados usando un Map por ID
        final uniqueProducts = <String, ProductCatalogModel>{};
        for (final product in allProducts) {
          uniqueProducts[product.id] = product;
        }

        // Convertir a lista y ordenar por nombre
        final sortedList = uniqueProducts.values.toList();
        sortedList.sort((a, b) => a.name.compareTo(b.name));

        return sortedList;
      },
    );
  }

  /// Obtener producto por ID (stream)
  Stream<ProductCatalogModel?> getProductStream(
    String organizationId,
    String productId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('product_catalog')
        .doc(productId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ProductCatalogModel.fromMap(doc.data()!);
    });
  }

  /// Obtener producto por ID (one-time)
  Future<ProductCatalogModel?> getProductById(
    String organizationId,
    String productId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc(productId)
          .get();

      if (!doc.exists) return null;
        return ProductCatalogModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // ==================== ACTUALIZAR PRODUCTO ====================

  Future<bool> updateProduct({
    required String organizationId,
    required String productId,
    required String updatedBy,
    String? name,
    String? reference,
    String? description,
    String? category,
    List<String>? imageUrls,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    MaterialInfo? materialInfo,
    DimensionsInfo? dimensions,
    double? estimatedWeight,
    double? basePrice,
    String? notes,
    int? estimatedProductionHours,
    String? clientId,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Solo agregar campos que no sean null
      if (name != null) updateData['name'] = name;
      if (reference != null) {
        // Verificar que la nueva referencia sea única
        final product = await getProductById(organizationId, productId);
        if (product != null && product.reference != reference) {
          final existingRef = await _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('product_catalog')
              .where('reference', isEqualTo: reference)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

          if (existingRef.docs.isNotEmpty && 
              existingRef.docs.first.id != productId) {
            throw Exception('Ya existe un producto con la referencia "$reference"');
          }
        }
        updateData['reference'] = reference;
      }
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (imageUrls != null) updateData['imageUrls'] = imageUrls;
      if (specifications != null) updateData['specifications'] = specifications;
      if (tags != null) updateData['tags'] = tags;
      if (materialInfo != null) updateData['materialInfo'] = materialInfo.toMap();
      if (dimensions != null) updateData['dimensions'] = dimensions.toMap();
      if (estimatedWeight != null) updateData['estimatedWeight'] = estimatedWeight;
      if (basePrice != null) updateData['basePrice'] = basePrice;
      if (notes != null) updateData['notes'] = notes;
      if (estimatedProductionHours != null) {
        updateData['estimatedProductionHours'] = estimatedProductionHours;
      }
      if (clientId != null) updateData['clientId'] = clientId;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc(productId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error al actualizar producto: $e');
      rethrow;
    }
  }

  // Obtener stream de productos asociados a un proyecto
  Stream<List<ProductCatalogModel>> watchProjectProducts(String organizationId, String projectId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data()))
          .toList();
    });
  }

  // ==================== DESACTIVAR PRODUCTO ====================
  
  Future<bool> deactivateProduct({
    required String organizationId,
    required String productId,
    required String updatedBy,
  }) async {
    try {
      await _firestore
      .collection('organizations')
      .doc(organizationId)
      .collection('product_catalog')
      .doc(productId).update({
        'isActive': false,
        'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al desactivar producto: $e');
      return false;
    }
  }

  // ==================== REACTIVAR PRODUCTO ====================
  
  Future<bool> reactivateProduct({
    required String organizationId,
    required String productId,
    required String updatedBy,
  }) async {
    try {
      await _firestore
      .collection('organizations')
      .doc(organizationId)
      .collection('product_catalog')
      .doc(productId).update({
        'isActive': true,
        'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al reactivar producto: $e');
      return false;
    }
  }
  // ==================== APROBACIÓN DE PRODUCTOS ====================

  Future<bool> updateApprovalStatus({
    required String organizationId,
    required String productId,
    required String status,
    String? approvedBy,
    String? rejectionReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'approvalStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (approvedBy != null) {
        updates['approvedBy'] = approvedBy;
        updates['approvedAt'] = FieldValue.serverTimestamp();
      }

      if (rejectionReason != null) {
        updates['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc(productId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating approval status: $e');
      return false;
    }
  }

  // ==================== INCREMENTAR CONTADOR DE USO ====================

  Future<void> incrementUsageCount(
    String organizationId,
    String productId,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc(productId)
          .update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing usage count: $e');
    }
  }

  // ==================== ELIMINAR PRODUCTO ====================

  Future<bool> deleteProduct(
    String organizationId,
    String productId,
  ) async {
    try {
      // Verificar si está siendo usado en proyectos
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .get();

      for (final projectDoc in projectsSnapshot.docs) {
        final productsSnapshot = await projectDoc.reference
          .collection('organizations')
          .doc(organizationId)
            .collection('products')
            .where('catalogProductId', isEqualTo: productId)
            .limit(1)
            .get();

        if (productsSnapshot.docs.isNotEmpty) {
          print('Cannot delete product in use');
          return false;
        }
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc(productId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // ==================== BÚSQUEDA Y FILTRADO ====================

  Future<List<ProductCatalogModel>> searchProducts({
    required String organizationId,
    String? searchQuery,
    String? category,
    List<String>? tags,
    bool includeInactive = false,
  }) async {
    try {
      Query query = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog');

      if (!includeInactive) {
        query = query.where('isActive', isEqualTo: true);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      var products = snapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filtrado local para búsqueda de texto y tags
      if (searchQuery != null && searchQuery.isNotEmpty) {
        products = products
            .where((product) => product.matchesSearch(searchQuery))
            .toList();
      }

      if (tags != null && tags.isNotEmpty) {
        products = products
            .where((product) => product.matchesTags(tags))
            .toList();
      }

      return products;
    } catch (e) {
      print('Error al buscar productos: $e');
      return [];
    }
  }

  // ==================== OBTENER CATEGORÍAS DE LA ORGANIZACIÓN ====================
  
  Future<List<String>> getOrganizationCategories(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      final sortedCategories = categories.toList()..sort();
      return sortedCategories;
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }
  
  // ==================== OBTENER TODOS LOS TAGS DE LA ORGANIZACIÓN ====================
  
  Future<List<String>> getOrganizationTags(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .where('isActive', isEqualTo: true)
          .get();

      final allTags = <String>{};
      for (var doc in snapshot.docs) {
        final tags = doc.data()['tags'] as List?;
        if (tags != null) {
          allTags.addAll(tags.cast<String>());
        }
      }

      final sortedTags = allTags.toList()..sort();
      return sortedTags;
    } catch (e) {
      print('Error al obtener tags: $e');
      return [];
    }
  }
  Future<List<ProductCatalogModel>> searchProductsByReference(
    String organizationId,
    String referencePrefix,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .orderBy('reference')
          .startAt([referencePrefix])
          .endAt([referencePrefix + '\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error searching products by reference: $e');
      return [];
    }
  }

  // ==================== ESTADÍSTICAS ====================

  Future<Map<String, dynamic>> getProductStatistics(
    String organizationId,
    String productId,
  ) async {
    try {
      final product = await getProductById(organizationId, productId);
      
      if (product == null) {
        return {'usageCount': 0, 'activeProjects': 0};
      }

      // Contar proyectos activos que usan este producto
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .get();

      int activeProjects = 0;

      for (final projectDoc in projectsSnapshot.docs) {
        final projectStatus = projectDoc.data()['status'] as String?;
        
        if (projectStatus == 'in_production' || projectStatus == 'in_preparation') {
          final productsSnapshot = await projectDoc.reference
              .collection('products')
              .where('catalogProductId', isEqualTo: productId)
              .limit(1)
              .get();

          if (productsSnapshot.docs.isNotEmpty) {
            activeProjects++;
          }
        }
      }

      return {
        'usageCount': product.usageCount,
        'activeProjects': activeProjects,
      };
    } catch (e) {
      print('Error getting product statistics: $e');
      return {'usageCount': 0, 'activeProjects': 0};
    }
  }

  /// Obtener productos más usados
  Future<List<ProductCatalogModel>> getMostUsedProducts(
    String organizationId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .orderBy('usageCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductCatalogModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener productos más usados: $e');
      return [];
    }
  }

  // ==================== DUPLICAR PRODUCTO ====================
  
  Future<String?> duplicateProduct({
    required String productId,
    required String createdBy,
    required String organizationId,
    String? newReference,
  }) async {
    try {
      final original = await getProductById(organizationId, productId);
      if (original == null) {
        throw Exception('Producto original no encontrado');
      }

      // Generar nueva referencia si no se proporciona
      String reference = newReference ?? '${original.reference}_COPIA';
      
      // Verificar que la referencia sea única
      int copyNumber = 1;
      while (true) {
        final existingRef = await _firestore
          .collection('organizations')
          .doc(organizationId)
            .collection('product_catalog')
            .where('reference', isEqualTo: reference)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (existingRef.docs.isEmpty) break;
        
        copyNumber++;
        reference = '${original.reference}_COPIA_$copyNumber';
      }

      return await createProduct(
        organizationId: original.organizationId,
        name: '${original.name} (Copia)',
        reference: reference,
        description: original.description,
        createdBy: createdBy,
        category: original.category,
        imageUrls: original.imageUrls,
        specifications: original.specifications,
        tags: original.tags,
        materialInfo: original.materialInfo,
        dimensions: original.dimensions,
        estimatedWeight: original.estimatedWeight,
        basePrice: original.basePrice,
        notes: original.notes,
      );
    } catch (e) {
      print('Error al duplicar producto: $e');
      return null;
    }
  }
  // ==================== VALIDACIÓN ====================

  Future<bool> referenceExists(
    String organizationId,
    String reference, {
    String? excludeProductId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .where('reference', isEqualTo: reference)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      if (excludeProductId != null) {
        return snapshot.docs.first.id != excludeProductId;
      }

      return true;
    } catch (e) {
      print('Error checking reference: $e');
      return false;
    }
  }

  // ==================== PRECIOS POR CLIENTE ====================

  Future<bool> setClientPrice({
    required String organizationId,
    required String productId,
    required String clientId,
    required double unitPrice,
    int minQuantity = 1,
  }) async {
    try {
      final product = await getProductById(organizationId, productId);
      if (product == null) return false;

      final clientPrices = product.clientPrices ?? [];
      
      // Eliminar precio anterior si existe
      clientPrices.removeWhere((p) => p['clientId'] == clientId);
      
      // Añadir nuevo precio
      clientPrices.add({
        'clientId': clientId,
        'unitPrice': unitPrice,
        'minQuantity': minQuantity,
      });

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('product_catalog')
          .doc(productId)
          .update({
        'clientPrices': clientPrices,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error setting client price: $e');
      return false;
    }
  }

  Future<double?> getClientPrice(
    String organizationId,
    String productId,
    String clientId,
  ) async {
    try {
      final product = await getProductById(organizationId, productId);
      if (product == null) return null;

      final clientPrices = product.clientPrices ?? [];
      final clientPrice = clientPrices.firstWhere(
        (p) => p['clientId'] == clientId,
        orElse: () => {},
      );

      if (clientPrice.isEmpty) {
        return product.basePrice; // Usar precio base si no hay precio específico
      }

      return clientPrice['unitPrice'] as double?;
    } catch (e) {
      print('Error getting client price: $e');
      return null;
    }
  }
}