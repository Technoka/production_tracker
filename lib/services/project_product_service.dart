import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_product_model.dart';
import 'product_catalog_service.dart';
import 'phase_service.dart'; // 1. Importar PhaseService

@Deprecated("NO se usa. Sera eliminada pronto.")
class ProjectProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductCatalogService _catalogService = ProductCatalogService();
  final PhaseService _phaseService = PhaseService(); // 2. Instanciar PhaseService

  // ==================== CREAR PRODUCTO EN PROYECTO ====================

  Future<String?> addProductToProject({
    required String projectId,
    required String organizationId, // 3. Requerido para inicializar fases
    required String catalogProductId,
    required int quantity,
    required double unitPrice,
    required String createdBy,
    ProductCustomization? customization,
    String? notes,
  }) async {
    try {
      // Obtener información del producto del catálogo
      final catalogProduct = await _catalogService.getProductById(organizationId, catalogProductId);
      if (catalogProduct == null) {
        throw Exception('Producto del catálogo no encontrado');
      }

      final productId = _firestore
          .collection('organizations')  
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc()
          .id;

      final totalPrice = quantity * unitPrice;
      final now = DateTime.now();

      final projectProduct = ProjectProductModel(
        id: productId,
        projectId: projectId,
        catalogProductId: catalogProductId,
        catalogProductName: catalogProduct.name,
        catalogProductReference: catalogProduct.reference,
        quantity: quantity,
        customization: customization ?? ProductCustomization(),
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        status: ProjectProductStatus.pending.value,
        notes: notes,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      // Guardar el producto
      await _firestore
          .collection('organizations')  
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .set(projectProduct.toMap());

      // 4. Inicializar automáticamente las fases de producción
      await _phaseService.initializeProductPhases(
        organizationId,
        projectId,
        productId,
      );

      // Incrementar contador de uso del producto del catálogo
      await _catalogService.incrementUsageCount(organizationId, catalogProductId);

      return productId;
    } catch (e) {
      print('Error al añadir producto al proyecto: $e');
      rethrow;
    }
  }

  // ==================== OBTENER PRODUCTOS DEL PROYECTO ====================

  Stream<List<ProjectProductModel>> watchProjectProducts(String organizationId, String projectId) {
    return _firestore
          .collection('organizations')  
          .doc(organizationId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectProductModel.fromMap(doc.data()))
            .toList());
  }

  Future<List<ProjectProductModel>> getProjectProductsStream(String organizationId, String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')  
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ProjectProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener productos del proyecto: $e');
      return [];
    }
  }

  Future<ProjectProductModel?> getProductById({
    required String organizationId,
    required String projectId,
    required String productId,
  }) async {
    try {
      final doc = await _firestore
          .collection('organizations')  
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      return ProjectProductModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error al obtener producto: $e');
      return null;
    }
  }

  // ==================== ACTUALIZAR PRODUCTO ====================

  Future<bool> updateProjectProduct({
    required String organizationId,
    required String projectId,
    required String productId,
    required String updatedBy,
    int? quantity,
    double? unitPrice,
    ProductCustomization? customization,
    String? notes,
  }) async {
    try {
      // Obtener producto actual para calcular nuevo total
      final currentProduct = await getProductById(
        organizationId: organizationId,
        projectId: projectId,
        productId: productId,
      );

      if (currentProduct == null) {
        throw Exception('Producto no encontrado');
      }

      final updateData = <String, dynamic>{
        'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Actualizar cantidad
      final finalQuantity = quantity ?? currentProduct.quantity;
      if (quantity != null) {
        updateData['quantity'] = quantity;
      }

      // Actualizar precio unitario
      final finalUnitPrice = unitPrice ?? currentProduct.unitPrice;
      if (unitPrice != null) {
        updateData['unitPrice'] = unitPrice;
      }

      // Recalcular precio total
      final newTotalPrice = finalQuantity * finalUnitPrice;
      updateData['totalPrice'] = newTotalPrice;

      // Actualizar personalización
      if (customization != null) {
        updateData['customization'] = customization.toMap();
      }

      // Actualizar notas
      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore
          .collection('organizations')  
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error al actualizar producto: $e');
      rethrow;
    }
  }

  // ==================== ACTUALIZAR ESTADO DEL PRODUCTO ====================

  Future<bool> updateProductStatus({
    required String organizationId,
    required String projectId,
    required String productId,
    required String status,
    required String updatedBy,
  }) async {
    try {
      await _firestore
          .collection('organizations')  
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .update({
        'status': status,
        'updatedBy': updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error al actualizar estado del producto: $e');
      return false;
    }
  }

  // ==================== ELIMINAR PRODUCTO ====================

  Future<bool> removeProductFromProject({
    required String organizationId,
    required String projectId,
    required String productId,
  }) async {
    try {
      // Nota: Idealmente deberíamos eliminar también la subcolección 'phaseProgress'
      // pero Firestore no elimina subcolecciones automáticamente.
      // Se puede dejar así o implementar una eliminación recursiva con Cloud Functions.
      
      await _firestore
          .collection('organizations')  
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .delete();

      return true;
    } catch (e) {
      print('Error al eliminar producto del proyecto: $e');
      return false;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  Future<Map<String, dynamic>> getProjectProductsStreamtats(String organizationId, String projectId) async {
    try {
      final products = await getProjectProductsStream(organizationId, projectId);

      final totalProducts = products.length;
      final totalUnits = products.fold<int>(0, (sum, p) => sum + p.quantity);
      final totalValue = products.fold<double>(0, (sum, p) => sum + p.totalPrice);

      final pendingCount = products.where((p) => p.isPending).length;
      final inProgressCount = products.where((p) => p.isCao).length + products.where((p) => p.isHold).length + products.where((p) => p.isControl).length;
      final okCount = products.where((p) => p.isOk).length;

      return {
        'totalProducts': totalProducts,
        'totalUnits': totalUnits,
        'totalValue': totalValue,
        'pendingCount': pendingCount,
        'inProductionCount': inProgressCount,
        'completedCount': okCount,
        'completionPercentage': totalProducts > 0
            ? (okCount / totalProducts * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {};
    }
  }

  // ==================== PRODUCTOS AGRUPADOS POR ESTADO ====================

  Future<Map<String, List<ProjectProductModel>>> getProductsByStatus(String organizationId,
    String projectId,
  ) async {
    try {
      final products = await getProjectProductsStream(organizationId, projectId);

      return {
        'pendiente': products.where((p) => p.isPending).toList(),
        'cao': products.where((p) => p.isCao).toList(),
        'hold': products.where((p) => p.isHold).toList(),
        'control': products.where((p) => p.isControl).toList(),
        'ok': products.where((p) => p.isOk).toList(),
      };
    } catch (e) {
      print('Error al agrupar productos por estado: $e');
      return {};
    }
  }

  // ==================== DUPLICAR PRODUCTO ====================

  Future<String?> duplicateProduct({
    required String projectId,
    required String productId,
    required String organizationId, // 5. Agregado organizationId
    required String createdBy,
  }) async {
    try {
      final original = await getProductById(
        organizationId: organizationId,
        projectId: projectId,
        productId: productId,
      );

      if (original == null) {
        throw Exception('Producto original no encontrado');
      }

      return await addProductToProject(
        projectId: projectId,
        organizationId: organizationId, // 6. Pasar organizationId
        catalogProductId: original.catalogProductId,
        quantity: original.quantity,
        unitPrice: original.unitPrice,
        createdBy: createdBy,
        customization: original.customization,
        notes: original.notes != null ? '${original.notes} (Copia)' : null,
      );
    } catch (e) {
      print('Error al duplicar producto: $e');
      return null;
    }
  }

  // ==================== ACTUALIZAR PRECIOS EN LOTE ====================

  Future<bool> updateAllProductsPrices({
    required String organizationId,
    required String projectId,
    required double priceMultiplier,
    required String updatedBy,
  }) async {
    try {
      final products = await getProjectProductsStream(organizationId, projectId);

      final batch = _firestore.batch();

      for (final product in products) {
        final newUnitPrice = product.unitPrice * priceMultiplier;
        final newTotalPrice = newUnitPrice * product.quantity;

        final docRef = _firestore
          .collection('organizations')  
          .doc(organizationId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .doc(product.id);

        batch.update(docRef, {
          'unitPrice': newUnitPrice,
          'totalPrice': newTotalPrice,
          'updatedBy': updatedBy,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error al actualizar precios: $e');
      return false;
    }
  }
}