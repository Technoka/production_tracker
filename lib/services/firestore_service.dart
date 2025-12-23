import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';
import '../models/product_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ==================== PROYECTOS ====================

  // Crear proyecto
  Future<String?> createProject({
    required String name,
    required String description,
    required String manufacturerId,
    required String clientId,
  }) async {
    try {
      final projectId = _uuid.v4();
      final project = ProjectModel(
        id: projectId,
        name: name,
        description: description,
        manufacturerId: manufacturerId,
        clientId: clientId,
        status: 'En planificación',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('projects')
          .doc(projectId)
          .set(project.toMap());

      return projectId;
    } catch (e) {
      print('Error al crear proyecto: $e');
      return null;
    }
  }

  // Obtener proyectos del fabricante
  Stream<List<ProjectModel>> getManufacturerProjects(String manufacturerId) {
    return _firestore
        .collection('projects')
        .where('manufacturerId', isEqualTo: manufacturerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data()))
            .toList());
  }

  // Obtener proyectos del cliente
  Stream<List<ProjectModel>> getClientProjects(String clientId) {
    return _firestore
        .collection('projects')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data()))
            .toList());
  }

  // Actualizar estado del proyecto
  Future<bool> updateProjectStatus(String projectId, String status) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al actualizar proyecto: $e');
      return false;
    }
  }

  // ==================== PRODUCTOS ====================

  // Crear producto
  Future<String?> createProduct({
    required String projectId,
    required String name,
    required String description,
    required int quantity,
    required String stage,
  }) async {
    try {
      final productId = _uuid.v4();
      final product = ProductModel(
        id: productId,
        projectId: projectId,
        name: name,
        description: description,
        quantity: quantity,
        currentStage: stage,
        batchNumber: _generateBatchNumber(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        stages: [
          StageModel(
            name: stage,
            status: 'En proceso',
            startedAt: DateTime.now(),
          ),
        ],
      );

      await _firestore
          .collection('products')
          .doc(productId)
          .set(product.toMap());

      return productId;
    } catch (e) {
      print('Error al crear producto: $e');
      return null;
    }
  }

  // Obtener productos de un proyecto
  Stream<List<ProductModel>> getProjectProducts(String projectId) {
    return _firestore
        .collection('products')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList());
  }

  // Actualizar etapa del producto
  Future<bool> updateProductStage({
    required String productId,
    required String newStage,
  }) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) return false;

      final product = ProductModel.fromMap(doc.data()!);
      final updatedStages = List<StageModel>.from(product.stages);

      // Completar la etapa actual
      final currentStageIndex = updatedStages.indexWhere(
        (s) => s.name == product.currentStage,
      );
      if (currentStageIndex >= 0) {
        updatedStages[currentStageIndex] = updatedStages[currentStageIndex].copyWith(
          status: 'Completado',
          completedAt: DateTime.now(),
        );
      }

      // Agregar nueva etapa
      updatedStages.add(
        StageModel(
          name: newStage,
          status: 'En proceso',
          startedAt: DateTime.now(),
        ),
      );

      await _firestore.collection('products').doc(productId).update({
        'currentStage': newStage,
        'stages': updatedStages.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error al actualizar etapa: $e');
      return false;
    }
  }

  // Actualizar cantidad del producto
  Future<bool> updateProductQuantity(String productId, int quantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al actualizar cantidad: $e');
      return false;
    }
  }

  // Generar número de lote
  String _generateBatchNumber() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomStr = _uuid.v4().substring(0, 4).toUpperCase();
    return 'LOTE-$dateStr-$randomStr';
  }

  // ==================== BÚSQUEDA DE USUARIOS ====================

  // Buscar clientes (para que el fabricante los asigne a proyectos)
  Future<List<Map<String, dynamic>>> searchClients(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'client')
          .get();

      return snapshot.docs
          .map((doc) => {
                'uid': doc.id,
                'name': doc.data()['name'] as String,
                'email': doc.data()['email'] as String,
              })
          .where((user) =>
              user['name']!.toLowerCase().contains(query.toLowerCase()) ||
              user['email']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error al buscar clientes: $e');
      return [];
    }
  }
}