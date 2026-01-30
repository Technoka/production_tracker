import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/permission_registry_model.dart';
import 'organization_member_service.dart';

class ClientService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final OrganizationMemberService _memberService;

  ClientService({required OrganizationMemberService memberService})
      : _memberService = memberService;

  List<ClientModel> _clients = [];
  List<ClientModel> get clients => _clients;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ==================== CREAR CLIENTE ====================

  Future<String?> createClient({
    required String organizationId,
    required String name,
    required String email,
    required String createdBy,
    required String company,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? notes,
    String? userId, // Para portal del cliente (Fase 12)
    String? color, // NUEVO
    Map<String, dynamic>? clientPermissions, // NUEVO
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canCreate = await _memberService.can('clients', 'create');
      if (!canCreate) {
        _error = 'No tienes permisos para crear clientes';
        notifyListeners();
        return null;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final clientId = _uuid.v4();
      final now = DateTime.now();

      final client = ClientModel(
        id: clientId,
        organizationId: organizationId,
        name: name,
        email: email,
        company: company,
        phone: phone,
        address: address,
        city: city,
        postalCode: postalCode,
        country: country,
        notes: notes,
        userId: userId,
        color: color,
        clientPermissions: clientPermissions,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .set(client.toMap());

      _isLoading = false;
      notifyListeners();

      return clientId;
    } on FirebaseException catch (e) {
      _error = 'Error al crear cliente: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error inesperado al crear cliente: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== OBTENER CLIENTES ====================

  /// Stream de clientes de una organización
  Stream<List<ClientModel>> watchClients(String organizationId) {
    // Si es cliente, solo puede ver SU cliente
    if (_memberService.isClient) {
      final clientId = _memberService.currentClientId;
      // if (clientId == null) return Stream.value([]);

      return _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .where(FieldPath.documentId, isEqualTo: clientId) // Solo SU cliente
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ClientModel.fromMap(doc.data()))
              .toList());
    }

    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('clients')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      _clients =
          snapshot.docs.map((doc) => ClientModel.fromMap(doc.data())).toList();
      return _clients;
    });
  }

/// Obtener clientes (one-time)
/// Si el usuario es cliente, solo devuelve SU cliente
Future<List<ClientModel>> getOrganizationClients(
  String organizationId,
  String userId,
) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Obtener datos del miembro actual
    final memberData = await _memberService.getCurrentMember(organizationId, userId);

    // Si es cliente, obtener SOLO su cliente
    if (memberData?.member.roleId == 'client') {
      final memberClientId = memberData!.member.clientId;
      
      if (memberClientId == null) {
        debugPrint('Cliente sin clientId asociado');
        _clients = [];
        _isLoading = false;
        notifyListeners();
        return [];
      }

      // Query específico para el cliente
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(memberClientId)
          .get();

      if (doc.exists) {
        _clients = [ClientModel.fromMap(doc.data()!)];
      } else {
        _clients = [];
      }

      _isLoading = false;
      notifyListeners();
      return _clients;
    }

    // Usuario normal: obtener todos los clientes
    final snapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('clients')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    _clients = snapshot.docs
        .map((doc) => ClientModel.fromMap(doc.data()))
        .toList();

    _isLoading = false;
    notifyListeners();
    return _clients;
  } catch (e) {
    _error = 'Error al cargar clientes: $e';
    _isLoading = false;
    notifyListeners();
    return [];
  }
}

  /// Obtener cliente por ID (stream)
  Stream<ClientModel?> getClientStream(
    String organizationId,
    String clientId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('clients')
        .doc(clientId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ClientModel.fromMap(doc.data()!);
    });
  }

  /// Obtener cliente por ID (one-time)
  Future<ClientModel?> getClient(
    String organizationId,
    String clientId,
  ) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .get();

      if (!doc.exists) return null;
      return ClientModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting client: $e');
      return null;
    }
  }

  /// Obtener cliente por userId (para portal cliente)
  Future<ClientModel?> getClientByUserId(
    String organizationId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ClientModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('Error getting client by userId: $e');
      return null;
    }
  }

  /// Obtener proyectos del cliente
  Stream<List<ProjectModel>> getClientProjects(
      String organizationId, String clientId) {
    return _firestore
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
  }

  Stream<List<ProjectModel>> watchClientProjectsWithScope(
      String organizationId, String clientId, String userId) async* {
    try {
      // Obtener scope del permiso
      print("before getCurrentMember watchClientProjectsWithScope");
      await _memberService.getCurrentMember(organizationId, userId);
      final scope = await _memberService.getScope('projects', 'view');

      // Verificar acceso
      if (scope == PermissionScope.none) {
        yield [];
        return;
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true);

      // Aplicar filtro según scope
      if (scope == PermissionScope.assigned) {
        // Solo proyectos asignados
        query = query.where('assignedMembers', arrayContains: userId);
      }
      // Si es 'all', no se añade filtro adicional

      // Ordenar (solo UNA vez)
      query = query.orderBy('createdAt', descending: true);

      yield* query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      debugPrint('Error en watchClientProjectsWithScope: $e');
      yield [];
    }
  }

/// Obtener proyectos de un cliente con scope (Future, no Stream)
/// Si el usuario es cliente, siempre obtiene SUS proyectos
Future<List<ProjectModel>> getClientProjectsWithScope(
    String organizationId, String clientId, String userId) async {
  try {
    // Obtener datos del miembro
    final memberData = await _memberService.getCurrentMember(organizationId, userId);
    
    // Si es cliente, obtener TODOS los proyectos de SU cliente
    if (memberData?.member.roleId == 'client') {
      // Usar el clientId del miembro (no el parámetro)
      final memberClientId = memberData!.member.clientId;
      
      if (memberClientId == null) {
        debugPrint('Cliente sin clientId asociado');
        return [];
      }
      
      final query = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('clientId', isEqualTo: memberClientId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();
    }

    // Usuario normal: aplicar scope
    final scope = await _memberService.getScope('projects', 'view');

    // Verificar acceso
    if (scope == PermissionScope.none) {
      return [];
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true);

    // Aplicar filtro según scope
    if (scope == PermissionScope.assigned) {
      query = query.where('assignedMembers', arrayContains: userId);
    }

    // Ordenar
    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ProjectModel.fromMap(doc.data()))
        .toList();
  } catch (e) {
    debugPrint('Error en getClientProjectsWithScope: $e');
    return [];
  }
}

  // ==================== ACTUALIZAR CLIENTE ====================

  Future<bool> updateClient({
    required String organizationId,
    required String clientId,
    String? name,
    String? company,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? notes,
    String? userId,
    String? color, // NUEVO
    Map<String, dynamic>? clientPermissions, // NUEVO
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canEdit = await _memberService.can('clients', 'edit');
      if (!canEdit) {
        _error = 'No tienes permisos para editar clientes';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (company != null) updates['company'] = company;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (postalCode != null) updates['postalCode'] = postalCode;
      if (country != null) updates['country'] = country;
      if (notes != null) updates['notes'] = notes;
      if (userId != null) updates['userId'] = userId;
      if (color != null) updates['color'] = color;
      if (clientPermissions != null)
        updates['clientPermissions'] = clientPermissions;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .update(updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _error = 'Error al actualizar cliente: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado al actualizar cliente: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClientColor({
    required String organizationId,
    required String clientId,
    required String color,
  }) async {
    try {
      final canEdit = await _memberService.can('clients', 'edit');
      if (!canEdit) {
        _error = 'No tienes permisos para editar clientes';
        notifyListeners();
        return false;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .update({
        'color': color,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _error = 'Error al actualizar color: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClientPermissions({
    required String organizationId,
    required String clientId,
    required Map<String, dynamic> clientPermissions,
  }) async {
    try {
      final canEdit = await _memberService.can('clients', 'edit');
      if (!canEdit) {
        _error = 'No tienes permisos para editar clientes';
        notifyListeners();
        return false;
      }

      // 1. Actualizar permisos en el documento del cliente
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .update({
        'clientPermissions': clientPermissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Obtener todos los miembros asociados a este cliente
      final membersSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .where('roleId', isEqualTo: 'client')
          .where('clientId', isEqualTo: clientId)
          .get();

      // 3. Actualizar permisos de cada miembro asociado
      if (membersSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final memberDoc in membersSnapshot.docs) {
          batch.update(memberDoc.reference, {
            'clientPermissions': clientPermissions,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar permisos: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== ELIMINAR CLIENTE ====================

  Future<bool> deleteClient(
    String organizationId,
    String clientId,
  ) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canDelete = await _memberService.can('clients', 'delete');
      if (!canDelete) {
        _error = 'No tienes permisos para eliminar clientes';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar si tiene proyectos asociados
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          .get();

      if (projectsSnapshot.docs.isNotEmpty) {
        _error = 'No se puede eliminar un cliente con proyectos asociados';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Soft delete
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _error = 'Error al eliminar cliente: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado al eliminar cliente: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminación física (permanente) - solo para casos especiales
  Future<bool> permanentlyDeleteClient(
      String organizationId, String clientId) async {
    try {
      // ✅ VALIDAR PERMISOS (solo admins con scope all)
      final canDelete = await _memberService.can('clients', 'delete');
      final scope = await _memberService.getScope('clients', 'delete');

      if (!canDelete || scope != PermissionScope.all) {
        _error =
            'Solo administradores pueden eliminar permanentemente clientes';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _error = 'Error al eliminar cliente permanentemente: ${e.message}';
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

  // ==================== BÚSQUEDA Y FILTRADO ====================

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<List<ClientModel>> searchClients(
    String? organizationId,
    String query,
  ) async {
    try {
      if (organizationId == null) return _clients;

      final lowerQuery = query.toLowerCase().trim();

      // Firestore no tiene búsqueda full-text, así que obtenemos todos y filtramos
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data()))
          .where((client) =>
              client.name.toLowerCase().contains(lowerQuery) ||
              client.email.toLowerCase().contains(lowerQuery) ||
              client.company.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      debugPrint('Error searching clients: $e');
      return [];
    }
  }

  Future<List<ClientModel>> searchClientsByName(
    String organizationId,
    String namePrefix,
  ) async {
    try {
      // Búsqueda por prefijo (más eficiente)
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([namePrefix]).endAt([namePrefix + '\uf8ff']).get();

      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error searching clients by name: $e');
      return [];
    }
  }

  // ==================== ESTADÍSTICAS ====================

  Future<Map<String, dynamic>> getClientStatistics(
    String organizationId,
    String clientId,
  ) async {
    try {
      // Obtener proyectos del cliente
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .where('clientId', isEqualTo: clientId)
          .get();

      final projects = projectsSnapshot.docs;
      final totalProjects = projects.length;

      int activeProjects = 0;
      int completedProjects = 0;
      int delayedProjects = 0;

      for (final projectDoc in projects) {
        final status = projectDoc.data()['status'] as String?;
        final isDelayed = projectDoc.data()['isDelayed'] as bool? ?? false;

        if (status == ProjectStatus.production.value ||
            status == ProjectStatus.preparation.value) {
          activeProjects++;
        }
        if (status == ProjectStatus.completed.value ||
            status == ProjectStatus.delivered.value) {
          completedProjects++;
        }
        if (isDelayed) {
          delayedProjects++;
        }
      }

      return {
        'totalProjects': totalProjects,
        'activeProjects': activeProjects,
        'completedProjects': completedProjects,
        'delayedProjects': delayedProjects,
      };
    } catch (e) {
      debugPrint('Error getting client statistics: $e');
      return {
        'totalProjects': 0,
        'activeProjects': 0,
        'completedProjects': 0,
        'delayedProjects': 0,
      };
    }
  }

  // ==================== VINCULAR USUARIO (PORTAL CLIENTE) ====================

  Future<bool> linkUserToClient(
    String organizationId,
    String clientId,
    String userId,
  ) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canEdit = await _memberService.can('clients', 'edit');
      if (!canEdit) {
        _error = 'No tienes permisos para vincular usuarios';
        notifyListeners();
        return false;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .update({
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error linking user to client: $e');
      return false;
    }
  }

  Future<bool> unlinkUserFromClient(
    String organizationId,
    String clientId,
  ) async {
    try {
      // ✅ VALIDAR PERMISOS
      final canEdit = await _memberService.can('clients', 'edit');
      if (!canEdit) {
        _error = 'No tienes permisos para desvincular usuarios';
        notifyListeners();
        return false;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .doc(clientId)
          .update({
        'userId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error unlinking user from client: $e');
      return false;
    }
  }

  // ==================== VALIDACIÓN ====================

  Future<bool> emailExists(
    String organizationId,
    String email, {
    String? excludeClientId,
  }) async {
    try {
      var query = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
          .where('email', isEqualTo: email)
          .limit(1);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) return false;

      // Si estamos editando, excluir el cliente actual
      if (excludeClientId != null) {
        return snapshot.docs.first.id != excludeClientId;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _clients = [];
    _searchQuery = '';
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
