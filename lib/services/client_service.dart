import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';

class ClientService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

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
  }) async {
    try {
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
        notes: notes,
        userId: userId,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
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

  // Stream de clientes de una organización
  Stream<List<ClientModel>> watchClients(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('clients')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      _clients = snapshot.docs
            .map((doc) => ClientModel.fromMap(doc.data()))
          .toList();
      return _clients;
    });
  }

  /// Obtener clientes (one-time)
  Future<List<ClientModel>> getOrganizationClients(String organizationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('clients')
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
      print('Error getting client: $e');
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
      print('Error getting client by userId: $e');
      return null;
    }
  }

  
  // Obtener proyectos del cliente
Stream<List<ProjectModel>> getClientProjects(String organizationId, String clientId) {
  return _firestore
      .collection('organizations')
      .doc(organizationId)
      .collection('projects')
      .where('clientId', isEqualTo: clientId)
      .where('isActive', isEqualTo: true) // Recomendado: filtrar solo activos
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList());
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
  }) async {
    try {
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

  // ==================== ELIMINAR CLIENTE ====================

  Future<bool> deleteClient(
    String organizationId,
    String clientId,
  ) async {
    try {
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
        _error = 'Cannot delete client with associated projects';
        
        _isLoading = false;
        notifyListeners();
        return false;
      }

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

  // Eliminación física (permanente) - solo para casos especiales
  Future<bool> permanentlyDeleteClient(String organizationId, String clientId) async {
    try {
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
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data()))
          .where((client) =>
              client.name.toLowerCase().contains(lowerQuery) ||
              (client.email?.toLowerCase().contains(lowerQuery) ?? false) ||
              (client.company?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    } catch (e) {
      print('Error searching clients: $e');
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
          .orderBy('name')
          .startAt([namePrefix])
          .endAt([namePrefix + '\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error searching clients by name: $e');
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

        if (status == 'in_production' || status == 'in_preparation') {
          activeProjects++;
        }
        if (status == 'completed' || status == 'delivered') {
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
      print('Error getting client statistics: $e');
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
      print('Error linking user to client: $e');
      return false;
    }
  }

  Future<bool> unlinkUserFromClient(
    String organizationId,
    String clientId,
  ) async {
    try {
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
      print('Error unlinking user from client: $e');
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
      print('Error checking email: $e');
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