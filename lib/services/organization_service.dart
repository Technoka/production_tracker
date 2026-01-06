import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../models/organization_model.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importar storage
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Importar compresor

class OrganizationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://production-tracker-top.firebasestorage.app'
  );
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

  /// Obtener solo el nombre de una organización por su ID
  Future<String?> getOrganizationName(String organizationId) async {
    try {
      // 1. Optimización: Verificar si es la organización actual cargada en memoria
      if (_currentOrganization != null && _currentOrganization!.id == organizationId) {
        return _currentOrganization!.name;
      }

      // 2. Si no, buscar en Firestore (lectura ligera solo del documento)
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] as String?;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al obtener nombre de organización: $e');
      return null;
    }
  }

// ==================== LOGO DE LA ORGANIZACIÓN (MODO PNG) ====================
  Future<String?> uploadOrganizationLogo(String orgId, XFile imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      // ✅ CAMBIO 1: Extensión del archivo a .png
      final ref = _storage.ref().child('organizations/$orgId/logo.png');

      final Uint8List imageBytes = await imageFile.readAsBytes();

      final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 256,
        minHeight: 256,
        quality: 90, // PNG ignora esto a veces porque es 'lossless', pero lo dejamos alto
        // ✅ CAMBIO 2: Formato PNG para mantener transparencia
        format: CompressFormat.png, 
      );

      final uploadTask = ref.putData(
        compressedBytes, 
        // ✅ CAMBIO 3: Content type correcto
        SettableMetadata(contentType: 'image/png') 
      );
      
      await uploadTask.whenComplete(() => null);
      final String downloadUrl = await ref.getDownloadURL();
      
      await updateOrganization(organizationId: orgId, logoUrl: downloadUrl);
      
      _isLoading = false;
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      print('Error uploading logo: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
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
// En organization_service.dart

Future<bool> acceptInvitation({
  required BuildContext context,
  required String invitationId,
  required String userId,
}) async {
  // Función rápida para mensajes en pantalla
  void msg(String text, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  try {
    final invRef = _firestore.collection('invitations').doc(invitationId);
    
    // PASO CRÍTICO: Intentamos leer con un catch específico
    final DocumentSnapshot invDoc;
    try {
      invDoc = await invRef.get().timeout(const Duration(seconds: 5));
    } catch (e) {
      return false;
    }

    if (!invDoc.exists) {
      msg("ERROR: El documento no existe en Firestore", isError: true);
      return false;
    }

    final data = invDoc.data() as Map<String, dynamic>?;
    final orgId = data?['organizationId'];

    if (orgId == null) {
      msg("ERROR: La invitación no tiene organizationId", isError: true);
      return false;
    }

    await _firestore.runTransaction((transaction) async {
      transaction.update(_firestore.collection('users').doc(userId), {
        'organizationId': orgId,
      });
      transaction.update(_firestore.collection('organizations').doc(orgId), {
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      transaction.update(invRef, {'status': 'accepted'});
    });
    
    await loadOrganization(orgId);
    return true;

  } catch (e) {
    msg("FALLO GENERAL: $e", isError: true);
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
    } on FirebaseException catch (e) {
      // Manejar errores específicos de Firebase
      if (e.code == 'permission-denied') {
        _error = 'Código de invitación inválido o sin permisos';
      } else if (e.code == 'not-found') {
        _error = 'Código de invitación no encontrado';
      } else {
        _error = 'Error al verificar el código: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al unirse a la organización: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== GESTIÓN DE MIEMBROS ====================

  Future<void> loadOrganizationMembers() async {
    if (_currentOrganization == null) return;

    try {
      final memberIds = _currentOrganization!.memberIds;
      if (memberIds.isEmpty) {
        _organizationMembers = [];
        return;
      }

      // Cargar miembros en lotes de 10 (límite de Firestore para 'in')
      _organizationMembers = [];
      for (var i = 0; i < memberIds.length; i += 10) {
        final batch = memberIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        _organizationMembers.addAll(
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar miembros: $e');
    }
  }

  // Stream de miembros
  Stream<List<UserModel>> watchOrganizationMembers(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .snapshots()
        .asyncMap((orgSnapshot) async {
      if (!orgSnapshot.exists) return [];

      final org = OrganizationModel.fromMap(orgSnapshot.data()!);
      final memberIds = org.memberIds;

      if (memberIds.isEmpty) return [];

      // Cargar miembros
      final members = <UserModel>[];
      for (var i = 0; i < memberIds.length; i += 10) {
        final batch = memberIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        members.addAll(
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())),
        );
      }

      return members;
    });
  }

  // Promover a administrador
  Future<bool> promoteToAdmin(String userId) async {
    if (_currentOrganization == null) return false;

    try {
      await _firestore
          .collection('organizations')
          .doc(_currentOrganization!.id)
          .update({
        'adminIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadOrganization(_currentOrganization!.id);
      return true;
    } catch (e) {
      _error = 'Error al promover usuario: $e';
      notifyListeners();
      return false;
    }
  }

  // Remover administrador
  Future<bool> demoteFromAdmin(String userId) async {
    if (_currentOrganization == null) return false;

    // No se puede remover al propietario
    if (_currentOrganization!.ownerId == userId) {
      _error = 'No puedes remover permisos al propietario';
      notifyListeners();
      return false;
    }

    try {
      await _firestore
          .collection('organizations')
          .doc(_currentOrganization!.id)
          .update({
        'adminIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadOrganization(_currentOrganization!.id);
      return true;
    } catch (e) {
      _error = 'Error al remover permisos: $e';
      notifyListeners();
      return false;
    }
  }

  // Eliminar miembro
  Future<bool> removeMember(String userId) async {
    if (_currentOrganization == null) return false;

    // No se puede eliminar al propietario
    if (_currentOrganization!.ownerId == userId) {
      _error = 'No puedes eliminar al propietario';
      notifyListeners();
      return false;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'organizationId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          _firestore.collection('organizations').doc(_currentOrganization!.id),
          {
            'memberIds': FieldValue.arrayRemove([userId]),
            'adminIds': FieldValue.arrayRemove([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      await loadOrganization(_currentOrganization!.id);
      return true;
    } catch (e) {
      _error = 'Error al eliminar miembro: $e';
      notifyListeners();
      return false;
    }
  }

  // Salir de la organización
  Future<bool> leaveOrganization(String userId) async {
    if (_currentOrganization == null) return false;

    // El propietario no puede salir
    if (_currentOrganization!.ownerId == userId) {
      _error = 'El propietario no puede salir de la organización';
      notifyListeners();
      return false;
    }

    return await removeMember(userId);
  }

  // ==================== ACTUALIZAR ORGANIZACIÓN ====================

  Future<bool> updateOrganization({
    required String organizationId,
    String? name,
    String? description,
    String? logoUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      
      // Solo actualizamos el logoUrl si se provee uno nuevo (o null para borrarlo si fuera necesario)
      if (logoUrl != null) {
        updates['settings.branding.logoUrl'] = logoUrl;
      }

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