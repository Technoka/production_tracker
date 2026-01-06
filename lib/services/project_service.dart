import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';
import '../models/product_model.dart';

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
    // Nuevos campos opcionales para inicialización
    int priority = 3,
    String urgencyLevel = 'medium',
    List<String>? tags,
    int? totalSlaHours,
    double totalAmount = 0,
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
        // Inicialización de nuevos campos
        priority: priority,
        urgencyLevel: urgencyLevel,
        tags: tags,
        totalSlaHours: totalSlaHours,
        totalAmount: totalAmount,
        invoiceStatus: 'pending',
        isDelayed: false,
        paidAmount: 0,
        delayHours: 0,
      );

      // ✅ NUEVA RUTA: dentro de organizations
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .set(project.toMap());

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

  /// Stream de proyectos de una organización
  Stream<List<ProjectModel>> watchProjects(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
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

  /// Stream de proyectos asignados a un usuario
  Stream<List<ProjectModel>> watchUserProjects(String userId, String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
        .where('assignedMembers', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data()))
            .toList());
  }

    /// Estadísticas por cliente
  Future<List<ProjectModel>?> getClientProjects(
    String organizationId,
    String clientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true)
          .get();

      final projects = snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();

      return projects;
    } catch (e) {
      _error = 'Error al obtener productos del cliente: $e';
      notifyListeners();
      return null;
    }
  }

  /// Stream de proyectos por cliente
  Stream<List<ProjectModel>> watchClientProjects(String clientId, String organizationId) {

    final clientProjects = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data()))
            .toList());

    // print('clientId: ${clientId}, organizationId: ${organizationId} -> projects: ${clientProjects.length}');

    return clientProjects;
  }

  /// Stream de un proyecto específico
  Stream<ProjectModel?> watchProject(String organizationId, String projectId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProjectModel.fromMap(doc.data()!);
    });
  }

  /// Obtener un proyecto específico (one-time)
  Future<ProjectModel?> getProject(String organizationId, String projectId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return ProjectModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _error = 'Error al obtener proyecto: $e';
      notifyListeners();
      return null;
    }
  }

  /// Obtener todos los proyectos (one-time)
  Future<List<ProjectModel>> getProjects(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _error = 'Error al obtener proyectos: $e';
      notifyListeners();
      return [];
    }
  }

  // ==================== ACTUALIZAR PROYECTO ====================

  Future<bool> updateProject({
    required String organizationId,
    required String projectId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? estimatedEndDate,
    List<String>? assignedMembers,
    // Nuevos campos actualizables
    int? priority,
    String? urgencyLevel,
    List<String>? tags,
    int? totalSlaHours,
    DateTime? expectedCompletionDate,
    String? invoiceStatus,
    String? invoiceId,
    double? totalAmount,
    double? paidAmount,
    DateTime? paymentDueDate,
    bool? isDelayed,
    double? delayHours,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Campos básicos
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
      if (estimatedEndDate != null) {
        updates['estimatedEndDate'] = Timestamp.fromDate(estimatedEndDate);
      }
      if (assignedMembers != null) updates['assignedMembers'] = assignedMembers;

      // Campos de Kanban y Prioridad
      if (priority != null) updates['priority'] = priority;
      if (urgencyLevel != null) updates['urgencyLevel'] = urgencyLevel;
      if (tags != null) updates['tags'] = tags;

      // Campos de SLA
      if (totalSlaHours != null) updates['totalSlaHours'] = totalSlaHours;
      if (expectedCompletionDate != null) {
        updates['expectedCompletionDate'] = Timestamp.fromDate(expectedCompletionDate);
      }
      if (isDelayed != null) updates['isDelayed'] = isDelayed;
      if (delayHours != null) updates['delayHours'] = delayHours;

      // Campos Financieros
      if (invoiceStatus != null) updates['invoiceStatus'] = invoiceStatus;
      if (invoiceId != null) updates['invoiceId'] = invoiceId;
      if (totalAmount != null) updates['totalAmount'] = totalAmount;
      if (paidAmount != null) updates['paidAmount'] = paidAmount;
      if (paymentDueDate != null) {
        updates['paymentDueDate'] = Timestamp.fromDate(paymentDueDate);
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .update(updates);

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

  /// Actualizar estado del proyecto
  Future<bool> updateProjectStatus(
    String organizationId,
    String projectId,
    String newStatus,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Si el estado es completado o entregado, guardar fechas reales
      if (newStatus == ProjectStatus.completed.value ||
          newStatus == ProjectStatus.delivered.value) {
        final now = FieldValue.serverTimestamp();
        updates['actualEndDate'] = now;
        updates['actualCompletionDate'] = now;
      } 
      // Si se vuelve a un estado anterior (reabrir), limpiamos las fechas de finalización
      else if (newStatus == ProjectStatus.preparation.value || 
               newStatus == ProjectStatus.production.value) {
        updates['actualEndDate'] = null;
        updates['actualCompletionDate'] = null;
      }
      
      // Registrar fecha de inicio real si pasa a producción por primera vez
      if (newStatus == ProjectStatus.production.value) {
        // Verificar si ya tiene startedAt
        final project = await getProject(organizationId, projectId);
        if (project?.startedAt == null) {
          updates['startedAt'] = FieldValue.serverTimestamp();
        }
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .update(updates);

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

  /// Asignar miembro al proyecto
  Future<bool> assignMember(
    String organizationId,
    String projectId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .update({
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

  /// Remover miembro del proyecto
  Future<bool> unassignMember(
    String organizationId,
    String projectId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .update({
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

  Future<bool> deleteProject(String organizationId, String projectId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Soft delete
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .update({
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

  /// Hard delete (eliminar permanentemente)
  Future<bool> permanentlyDeleteProject(
    String organizationId,
    String projectId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Nota: Esto NO elimina subcolecciones (products, messages, etc.)
      // Para eliminación completa, considera Cloud Functions
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar proyecto permanentemente: $e';
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
        final tagMatch = project.tags?.any(
          (tag) => tag.toLowerCase().contains(_searchQuery)
        ) ?? false;
        return nameMatch || descMatch || tagMatch;
      }).toList();
    }

    // Filtro por estado
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((project) => project.status == _statusFilter).toList();
    }

    return filtered;
  }

  /// Proyectos por estado
  List<ProjectModel> getProjectsByStatus(String status) {
    return _projects.where((project) => project.status == status).toList();
  }

  /// Proyectos atrasados
  List<ProjectModel> get overdueProjects {
    return _projects.where((project) => project.isOverdue).toList();
  }

  /// Proyectos con flag isDelayed
  List<ProjectModel> get delayedProjects {
    return _projects.where((project) => project.isDelayed).toList();
  }

  /// Proyectos por prioridad
  List<ProjectModel> getProjectsByPriority(int priority) {
    return _projects.where((project) => project.priority == priority).toList();
  }

  /// Proyectos urgentes (prioridad alta)
  List<ProjectModel> get urgentProjects {
    return _projects.where((project) => 
      project.priority <= 2 || project.urgencyLevel == 'high' || project.urgencyLevel == 'critical'
    ).toList();
  }

  // ==================== BÚSQUEDA AVANZADA ====================

  /// Buscar proyectos en Firebase (más eficiente para grandes datasets)
  Future<List<ProjectModel>> searchProjects(
    String organizationId,
    String query,
  ) async {
    try {
      final lowerQuery = query.toLowerCase();
      
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .where((project) =>
              project.name.toLowerCase().contains(lowerQuery) ||
              project.description.toLowerCase().contains(lowerQuery) ||
              (project.tags?.any((tag) => tag.toLowerCase().contains(lowerQuery)) ?? false))
          .toList();
    } catch (e) {
      _error = 'Error al buscar proyectos: $e';
      notifyListeners();
      return [];
    }
  }

  /// Filtrar proyectos por múltiples criterios
  Future<List<ProjectModel>> filterProjects(
    String organizationId, {
    String? status,
    String? clientId,
    int? minPriority,
    int? maxPriority,
    bool? isDelayed,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    List<String>? tags,
  }) async {
    try {
      Query query = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('isActive', isEqualTo: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }

      if (isDelayed != null) {
        query = query.where('isDelayed', isEqualTo: isDelayed);
      }

      final snapshot = await query.get();
      var projects = snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filtros que no se pueden hacer en Firestore
      if (minPriority != null) {
        projects = projects.where((p) => p.priority >= minPriority).toList();
      }

      if (maxPriority != null) {
        projects = projects.where((p) => p.priority <= maxPriority).toList();
      }

      if (startDateFrom != null) {
        projects = projects.where((p) => p.startDate.isAfter(startDateFrom)).toList();
      }

      if (startDateTo != null) {
        projects = projects.where((p) => p.startDate.isBefore(startDateTo)).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        projects = projects.where((p) =>
            p.tags?.any((tag) => tags.contains(tag)) ?? false).toList();
      }

      return projects;
    } catch (e) {
      _error = 'Error al filtrar proyectos: $e';
      notifyListeners();
      return [];
    }
  }

  /// Stream de productos de un proyecto
  Stream<List<ProductModel>> watchProjectProducts(
    String organizationId,
    String projectId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList());
  }

  // ==================== ESTADÍSTICAS ====================

  int get totalProjects => _projects.length;

  int getProjectCountByStatus(String status) {
    return _projects.where((project) => project.status == status).length;
  }

  int get overdueCount => overdueProjects.length;
  
  int get delayedCount => delayedProjects.length;
  
  /// Total facturado (suma de totalAmount de todos los proyectos)
  double get totalRevenue {
    return _projects.fold(0, (sum, project) => sum + project.totalAmount);
  }

  /// Total cobrado (suma de paidAmount)
  double get totalPaid {
    return _projects.fold(0, (sum, project) => sum + project.paidAmount);
  }

  /// Total pendiente de cobro
  double get totalPending {
    return totalRevenue - totalPaid;
  }

  /// Obtener estadísticas completas
  Future<Map<String, dynamic>> getProjectStatistics(String organizationId) async {
    try {
      final projects = await getProjects(organizationId);

      final stats = {
        'total': projects.length,
        'preparation': projects.where((p) => p.status == ProjectStatus.preparation.value).length,
        'production': projects.where((p) => p.status == ProjectStatus.production.value).length,
        'completed': projects.where((p) => p.status == ProjectStatus.completed.value).length,
        'delivered': projects.where((p) => p.status == ProjectStatus.delivered.value).length,
        'overdue': projects.where((p) => p.isOverdue).length,
        'delayed': projects.where((p) => p.isDelayed).length,
        'urgent': projects.where((p) => p.priority <= 2).length,
        'totalRevenue': projects.fold<double>(0, (sum, p) => sum + p.totalAmount),
        'totalPaid': projects.fold<double>(0, (sum, p) => sum + p.paidAmount),
        'pendingPayment': projects.fold<double>(0, (sum, p) => sum + (p.totalAmount - p.paidAmount)),
      };

      return stats;
    } catch (e) {
      _error = 'Error al obtener estadísticas: $e';
      notifyListeners();
      return {};
    }
  }

  /// Estadísticas por cliente
  Future<Map<String, dynamic>> getClientStatistics(
    String organizationId,
    String clientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true)
          .get();

      final projects = snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();

      return {
        'total': projects.length,
        'active': projects.where((p) => 
          p.status == ProjectStatus.production.value || 
          p.status == ProjectStatus.preparation.value).length,
        'completed': projects.where((p) => p.status == ProjectStatus.completed.value).length,
        'totalRevenue': projects.fold<double>(0, (sum, p) => sum + p.totalAmount),
        'totalPaid': projects.fold<double>(0, (sum, p) => sum + p.paidAmount),
      };
    } catch (e) {
      _error = 'Error al obtener estadísticas del cliente: $e';
      notifyListeners();
      return {};
    }
  }

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