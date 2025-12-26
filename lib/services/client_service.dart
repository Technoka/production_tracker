import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../models/client_model.dart';

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
    required String name,
    required String company,
    required String email,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? notes,
    required String organizationId,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final clientId = _uuid.v4();
      final client = ClientModel(
        id: clientId,
        name: name,
        company: company,
        email: email,
        phone: phone,
        address: address,
        city: city,
        postalCode: postalCode,
        country: country,
        notes: notes,
        organizationId: organizationId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('clients').doc(clientId).set(client.toMap());

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
        .collection('clients')
        .where('organizationId', isEqualTo: organizationId)
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

  // Cargar clientes una vez
  Future<List<ClientModel>> loadClients(String organizationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('clients')
          .where('organizationId', isEqualTo: organizationId)
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

  // Obtener un cliente específico
  Future<ClientModel?> getClient(String clientId) async {
    try {
      final doc = await _firestore.collection('clients').doc(clientId).get();
      if (doc.exists) {
        return ClientModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _error = 'Error al obtener cliente: $e';
      notifyListeners();
      return null;
    }
  }

  // ==================== ACTUALIZAR CLIENTE ====================

  Future<bool> updateClient({
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
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'name': name,
        'company': company,
        'enail': email,
        'phone': phone,
        'address': address,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'notes': notes
      };

      await _firestore.collection('clients').doc(clientId).update(updates);

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

  // Eliminación lógica (soft delete)
  Future<bool> deleteClient(String clientId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('clients').doc(clientId).update({
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

  // Eliminación física (permanente) - solo para casos especiales
  Future<bool> permanentlyDeleteClient(String clientId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('clients').doc(clientId).delete();

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

  List<ClientModel> get filteredClients {
    if (_searchQuery.isEmpty) {
      return _clients;
    }

    return _clients.where((client) {
      final nameMatch = client.name.toLowerCase().contains(_searchQuery);
      final companyMatch = client.company.toLowerCase().contains(_searchQuery);
      final emailMatch = client.email.toLowerCase().contains(_searchQuery);
      final phoneMatch =
          client.phone?.toLowerCase().contains(_searchQuery) ?? false;
      final cityMatch = client.city?.toLowerCase().contains(_searchQuery) ?? false;

      return nameMatch || companyMatch || emailMatch || phoneMatch || cityMatch;
    }).toList();
  }

  // Filtrar por ciudad
  List<ClientModel> getClientsByCity(String city) {
    return _clients
        .where((client) =>
            client.city?.toLowerCase() == city.toLowerCase())
        .toList();
  }

  // Filtrar por país
  List<ClientModel> getClientsByCountry(String country) {
    return _clients
        .where((client) =>
            client.country?.toLowerCase() == country.toLowerCase())
        .toList();
  }

  // Obtener todas las ciudades únicas
  List<String> get uniqueCities {
    final cities = _clients
        .where((client) => client.city != null && client.city!.isNotEmpty)
        .map((client) => client.city!)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  // Obtener todos los países únicos
  List<String> get uniqueCountries {
    final countries = _clients
        .where((client) => client.country != null && client.country!.isNotEmpty)
        .map((client) => client.country!)
        .toSet()
        .toList();
    countries.sort();
    return countries;
  }

  // ==================== ESTADÍSTICAS ====================

  int get totalClients => _clients.length;

  int get clientsWithAddress =>
      _clients.where((client) => client.hasAddress).length;

  int get clientsWithPhone => _clients.where((client) => client.hasPhone).length;

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