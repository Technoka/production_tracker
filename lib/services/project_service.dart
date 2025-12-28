import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';

class ProjectService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<ProjectModel> _projects = [];
  List<ProjectModel> get projects => _projects;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _statusFilter;
  String? get statusFilter => _statusFilter;

  // ==================== CREAR PROYECTO ====================

  Future<String?> createProject({
    required String name,
    required String description,
    required String clientId,
    required String organizationId,
    required DateTime startDate,
    required DateTime estimatedEndDate,
    required List<String> assignedMembers,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validar fechas
      if (estimatedEndDate.isBefore(startDate)) {
        _error = 'La fecha de entrega debe ser posterior a la fecha de inicio';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final projectId = _uuid.v4();
      final project = ProjectModel(
        id: projectId,
        name: name,
        description: description,
        clientId: clientId,
        organizationId: organizationId,
        status: ProjectStatus.preparation.value,
        startDate: startDate,
        estimatedEndDate: estimatedEndDate,
        assignedMembers: assignedMembers,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('projects').doc(projectId).set(project.toMap());

      _isLoading = false;
      notifyListeners();
      return projectId;
    } on FirebaseException catch (e) {
      _error = 'Error al crear proyecto: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error inesperado al crear proyecto: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== OBTENER PROYECTOS ====================

  // Stream de proyectos de una organización
  Stream<List<ProjectModel>> watchProjects(String organizationId) {
    return _firestore
        .collection('projects')
        .where('organizationId', isEqualTo: organizationId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      _projects = snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();
      return _projects;
    });
  }

  // Stream de proyectos asignados a un usuario
  Stream<List<ProjectModel>> watchUserProjects(String userId, String organizationId) {
    return _firestore
        .collection('projects')
        .where('organizationId', isEqualTo: organizationId)
        .where('assignedMembers', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data()))
            .toList());
  }

  // Obtener un proyecto específico
  Future<ProjectModel?> getProject(String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (doc.exists) {
        return ProjectModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _error = 'Error al obtener proyecto: $e';
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTUALIZAR PROYECTO ====================

  Future<bool> updateProject({
    required String projectId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? estimatedEndDate,
    List<String>? assignedMembers,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
      if (estimatedEndDate != null) {
        updates['estimatedEndDate'] = Timestamp.fromDate(estimatedEndDate);
      }
      if (assignedMembers != null) updates['assignedMembers'] = assignedMembers;

      await _firestore.collection('projects').doc(projectId).update(updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _error = 'Error al actualizar proyecto: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar estado del proyecto
  Future<bool> updateProjectStatus(String projectId, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Si el estado es completado o entregado, guardar fecha real
      if (newStatus == ProjectStatus.completed.value ||
          newStatus == ProjectStatus.delivered.value) {
        updates['actualEndDate'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('projects').doc(projectId).update(updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Asignar miembro al proyecto
  Future<bool> assignMember(String projectId, String userId) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'assignedMembers': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Error al asignar miembro: $e';
      notifyListeners();
      return false;
    }
  }

  // Remover miembro del proyecto
  Future<bool> unassignMember(String projectId, String userId) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'assignedMembers': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Error al remover miembro: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== ELIMINAR PROYECTO ====================

  Future<bool> deleteProject(String projectId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('projects').doc(projectId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar proyecto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== BÚSQUEDA Y FILTRADO ====================

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    notifyListeners();
  }

  List<ProjectModel> get filteredProjects {
    var filtered = _projects;

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        final nameMatch = project.name.toLowerCase().contains(_searchQuery);
        final descMatch = project.description.toLowerCase().contains(_searchQuery);
        return nameMatch || descMatch;
      }).toList();
    }

    // Filtro por estado
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((project) => project.status == _statusFilter).toList();
    }

    return filtered;
  }

  // Proyectos por estado
  List<ProjectModel> getProjectsByStatus(String status) {
    return _projects.where((project) => project.status == status).toList();
  }

  // Proyectos atrasados
  List<ProjectModel> get overdueProjects {
    return _projects.where((project) => project.isOverdue).toList();
  }

  // ==================== ESTADÍSTICAS ====================

  int get totalProjects => _projects.length;

  int getProjectCountByStatus(String status) {
    return _projects.where((project) => project.status == status).length;
  }

  int get overdueCount => overdueProjects.length;

  // ==================== UTILIDADES ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _projects = [];
    _searchQuery = '';
    _statusFilter = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}