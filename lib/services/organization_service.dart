import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../models/organization_model.dart';
import '../models/user_model.dart';

class OrganizationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  OrganizationModel? _currentOrganization;
  OrganizationModel? get currentOrganization => _currentOrganization;

  List<UserModel> _organizationMembers = [];
  List<UserModel> get organizationMembers => _organizationMembers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ==================== CREAR ORGANIZACIÓN ====================

  Future<String?> createOrganization({
    required String name,
    required String description,
    required String ownerId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final organizationId = _uuid.v4();
      final inviteCode = _generateInviteCode();

      final organization = OrganizationModel(
        id: organizationId,
        name: name,
        description: description,
        ownerId: ownerId,
        inviteCode: inviteCode,
        adminIds: [ownerId],
        memberIds: [ownerId],
        createdAt: DateTime.now(),
      );

      // Crear organización en Firestore
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .set(organization.toMap());

      // Actualizar usuario con organizationId
      await _firestore.collection('users').doc(ownerId).update({
        'organizationId': organizationId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _currentOrganization = organization;
      _isLoading = false;
      notifyListeners();

      return organizationId;
    } catch (e) {
      _error = 'Error al crear organización: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== CARGAR ORGANIZACIÓN ====================

  Future<OrganizationModel?> loadOrganization(String organizationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (doc.exists) {
        _currentOrganization = OrganizationModel.fromMap(doc.data()!);
        await loadOrganizationMembers();
        
        _isLoading = false;
        notifyListeners();
        return _currentOrganization;
      }

      _error = 'Organización no encontrada';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error al cargar organización: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Stream para observar cambios en la organización
  Stream<OrganizationModel?> watchOrganization(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        _currentOrganization = OrganizationModel.fromMap(snapshot.data()!);
        return _currentOrganization;
      }
      return null;
    });
  }

  // ==================== INVITACIONES POR EMAIL ====================

  Future<bool> inviteUserByEmail({
    required String email,
    required String organizationId,
    required String invitedBy,
    required String invitedByName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar que la organización existe
      final orgDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (!orgDoc.exists) {
        throw Exception('Organización no encontrada');
      }

      final org = OrganizationModel.fromMap(orgDoc.data()!);

      // Verificar si el usuario ya está en la organización
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final user = UserModel.fromMap(userQuery.docs.first.data());
        if (user.organizationId == organizationId) {
          _error = 'Este usuario ya pertenece a la organización';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (user.organizationId != null) {
          _error = 'Este usuario ya pertenece a otra organización';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Verificar si ya hay una invitación pendiente
      final existingInvite = await _firestore
          .collection('invitations')
          .where('email', isEqualTo: email)
          .where('organizationId', isEqualTo: organizationId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingInvite.docs.isNotEmpty) {
        _error = 'Ya existe una invitación pendiente para este email';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Crear invitación
      final invitationId = _uuid.v4();
      final invitation = InvitationModel(
        id: invitationId,
        organizationId: organizationId,
        organizationName: org.name,
        email: email,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await _firestore
          .collection('invitations')
          .doc(invitationId)
          .set(invitation.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al enviar invitación: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener invitaciones pendientes para un email
  Stream<List<InvitationModel>> getPendingInvitations(String email) {
    return _firestore
        .collection('invitations')
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvitationModel.fromMap(doc.data()))
            .where((inv) => !inv.isExpired)
            .toList());
  }

  // Aceptar invitación
  Future<bool> acceptInvitation({
    required String invitationId,
    required String organizationId,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final invDoc = await _firestore
          .collection('invitations')
          .doc(invitationId)
          .get();

      if (!invDoc.exists) {
        throw Exception('Invitación no encontrada');
      }

      final invitation = InvitationModel.fromMap(invDoc.data()!);

      if (!invitation.isPending) {
        throw Exception('Esta invitación ya no es válida');
      }

      // Verificar que el usuario no pertenece a otra organización
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromMap(userDoc.data()!);

      if (user.organizationId != null) {
        _error = 'Ya perteneces a una organización';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Usar transacción para asegurar consistencia
      await _firestore.runTransaction((transaction) async {
        // Actualizar usuario
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'organizationId': invitation.organizationId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Actualizar organización
        transaction.update(
          _firestore.collection('organizations').doc(invitation.organizationId),
          {
            'memberIds': FieldValue.arrayUnion([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Actualizar invitación
        transaction.update(
          _firestore.collection('invitations').doc(invitationId),
          {'status': 'accepted'},
        );
      });

      await loadOrganization(invitation.organizationId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al aceptar invitación: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Rechazar invitación
  Future<bool> rejectInvitation(String invitationId) async {
    try {
      await _firestore
          .collection('invitations')
          .doc(invitationId)
          .update({'status': 'rejected'});
      return true;
    } catch (e) {
      _error = 'Error al rechazar invitación: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== UNIRSE POR CÓDIGO ====================

  Future<bool> joinByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Buscar organización por código
      final orgQuery = await _firestore
          .collection('organizations')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (orgQuery.docs.isEmpty) {
        _error = 'Código de invitación inválido';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final org = OrganizationModel.fromMap(orgQuery.docs.first.data());

      // Verificar que el usuario no está en la organización
      if (org.memberIds.contains(userId)) {
        _error = 'Ya perteneces a esta organización';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verificar que el usuario no pertenece a otra organización
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromMap(userDoc.data()!);

      if (user.organizationId != null) {
        _error = 'Ya perteneces a una organización';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Unir usuario a la organización
      await _firestore.runTransaction((transaction) async {
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'organizationId': org.id,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          _firestore.collection('organizations').doc(org.id),
          {
            'memberIds': FieldValue.arrayUnion([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      await loadOrganization(org.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al unirse a la organización: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== GESTIÓN DE MIEMBROS ====================

  // Cargar miembros (Hecha pública y robusta)
  Future<void> loadOrganizationMembers() async {
    if (_currentOrganization == null) return;

    try {
      _isLoading = true;
      // No notificamos aquí para evitar parpadeos innecesarios si ya había datos
      
      final memberIds = _currentOrganization!.memberIds;
      if (memberIds.isEmpty) {
        _organizationMembers = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cargar miembros en lotes de 10 (límite de Firestore para 'in')
      List<UserModel> tempMembers = [];
      for (var i = 0; i < memberIds.length; i += 10) {
        // Safe range slicing
        final end = (i + 10 < memberIds.length) ? i + 10 : memberIds.length;
        final batch = memberIds.sublist(i, end);
        
        if (batch.isEmpty) continue;

        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        tempMembers.addAll(
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())),
        );
      }

      _organizationMembers = tempMembers;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar miembros: $e');
      _error = 'Error cargando miembros: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Promover a administrador (Tu versión es correcta)
  Future<bool> promoteToAdmin(String userId) async {
    if (_currentOrganization == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('organizations')
          .doc(_currentOrganization!.id)
          .update({
        'adminIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recargamos la organización para actualizar los adminIds locales
      await loadOrganization(_currentOrganization!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al promover usuario: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remover administrador (Tu versión es correcta)
  Future<bool> demoteFromAdmin(String userId) async {
    if (_currentOrganization == null) return false;

    if (_currentOrganization!.ownerId == userId) {
      _error = 'No puedes remover permisos al propietario';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('organizations')
          .doc(_currentOrganization!.id)
          .update({
        'adminIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadOrganization(_currentOrganization!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al remover permisos: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar miembro (Tu versión con TRANSACCIÓN es perfecta)
  Future<bool> removeMember(String userId) async {
    if (_currentOrganization == null) return false;

    if (_currentOrganization!.ownerId == userId) {
      _error = 'No puedes eliminar al propietario';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.runTransaction((transaction) async {
        // Referencias
        final userRef = _firestore.collection('users').doc(userId);
        final orgRef = _firestore.collection('organizations').doc(_currentOrganization!.id);

        transaction.update(userRef, {
          'organizationId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(orgRef, {
          'memberIds': FieldValue.arrayRemove([userId]),
          'adminIds': FieldValue.arrayRemove([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Recargar datos locales tras la transacción exitosa
      await loadOrganization(_currentOrganization!.id);
      await loadOrganizationMembers(); // Recargamos la lista para quitar al usuario visualmente
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar miembro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Salir de la organización
  Future<bool> leaveOrganization(String userId) async {
     // Reutilizamos la lógica segura de removeMember
     return await removeMember(userId);
  }

  // ==================== ACTUALIZAR ORGANIZACIÓN ====================

  Future<bool> updateOrganization({
    required String organizationId,
    String? name,
    String? description,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update(updates);

      await loadOrganization(organizationId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar organización: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Regenerar código de invitación
  Future<String?> regenerateInviteCode(String organizationId) async {
    try {
      final newCode = _generateInviteCode();

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'inviteCode': newCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadOrganization(organizationId);
      return newCode;
    } catch (e) {
      _error = 'Error al regenerar código: $e';
      notifyListeners();
      return null;
    }
  }

  // ==================== UTILIDADES ====================

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _currentOrganization = null;
    _organizationMembers = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}