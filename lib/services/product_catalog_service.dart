import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_catalog_model.dart';

class ProductCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CREAR PRODUCTO EN CATÁLOGO ====================
  
  Future<String?> createProductCatalog({
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
  }) async {
    try {
      // Verificar que la referencia sea única en la organización
      final existingRef = await _firestore
          .collection('product_catalog')
          .where('organizationId', isEqualTo: organizationId)
          .where('reference', isEqualTo: reference)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingRef.docs.isNotEmpty) {
        throw Exception('Ya existe un producto con la referencia "$reference"');
      }

      final productId = _firestore.collection('product_catalog').doc().id;
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
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        usageCount: 0,
      );

      await _firestore
          .collection('product_catalog')
          .doc(productId)
          .set(product.toMap());

      return productId;
    } catch (e) {
      print('Error al crear producto en catálogo: $e');
      rethrow;
    }
  }

  // ==================== OBTENER CATÁLOGO DE ORGANIZACIÓN ====================
  
  Stream<List<ProductCatalogModel>> getOrganizationCatalog(
    String organizationId, {
    bool includeInactive = false,
  }) {
    Query query = _firestore
        .collection('product_catalog')
        .where('organizationId', isEqualTo: organizationId);

    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCatalogModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ==================== OBTENER PRODUCTO POR ID ====================
  
  Future<ProductCatalogModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection('product_catalog')
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      return ProductCatalogModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error al obtener producto: $e');
      return null;
    }
  }

  // ==================== ACTUALIZAR PRODUCTO ====================
  
  Future<bool> updateProductCatalog({
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
        final product = await getProductById(productId);
        if (product != null && product.reference != reference) {
          final existingRef = await _firestore
              .collection('product_catalog')
              .where('organizationId', isEqualTo: product.organizationId)
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

      await _firestore
          .collection('product_catalog')
          .doc(productId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error al actualizar producto: $e');
      rethrow;
    }
  }

  // ==================== DESACTIVAR PRODUCTO ====================
  
  Future<bool> deactivateProduct({
    required String productId,
    required String updatedBy,
  }) async {
    try {
      await _firestore.collection('product_catalog').doc(productId).update({
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
    required String productId,
    required String updatedBy,
  }) async {
    try {
      await _firestore.collection('product_catalog').doc(productId).update({
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

  // ==================== ELIMINAR PRODUCTO (PERMANENTE) ====================
  
  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('product_catalog').doc(productId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar producto: $e');
      return false;
    }
  }

  // ==================== INCREMENTAR CONTADOR DE USO ====================
  
  Future<void> incrementUsageCount(String productId) async {
    try {
      await _firestore.collection('product_catalog').doc(productId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al incrementar contador de uso: $e');
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
          .collection('product_catalog')
          .where('organizationId', isEqualTo: organizationId);

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
          .collection('product_catalog')
          .where('organizationId', isEqualTo: organizationId)
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
          .collection('product_catalog')
          .where('organizationId', isEqualTo: organizationId)
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

  // ==================== OBTENER PRODUCTOS MÁS USADOS ====================
  
  Future<List<ProductCatalogModel>> getMostUsedProducts({
    required String organizationId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('product_catalog')
          .where('organizationId', isEqualTo: organizationId)
          .where('isActive', isEqualTo: true)
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
    String? newReference,
  }) async {
    try {
      final original = await getProductById(productId);
      if (original == null) {
        throw Exception('Producto original no encontrado');
      }

      // Generar nueva referencia si no se proporciona
      String reference = newReference ?? '${original.reference}_COPIA';
      
      // Verificar que la referencia sea única
      int copyNumber = 1;
      while (true) {
        final existingRef = await _firestore
            .collection('product_catalog')
            .where('organizationId', isEqualTo: original.organizationId)
            .where('reference', isEqualTo: reference)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (existingRef.docs.isEmpty) break;
        
        copyNumber++;
        reference = '${original.reference}_COPIA_$copyNumber';
      }

      return await createProductCatalog(
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
}