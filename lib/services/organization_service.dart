import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/organization_model.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/organization_member_model.dart';
import '../models/product_status_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'organization_member_service.dart';

class OrganizationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://production-tracker-top.firebasestorage.app');
  final _uuid = const Uuid();
  final OrganizationMemberService _memberService;

  OrganizationService({required OrganizationMemberService memberService})
      : _memberService = memberService;

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
        statusesInitialized: false,
        defaultStatuses: [],
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

      // Inicializar roles predeterminados
      await _initializeDefaultRoles(organizationId, ownerId);

      // Inicializar estados predeterminados
      await _initializeDefaultStatuses(organizationId, ownerId);

      // Crear miembro owner con rol
      await _createOrganizationMember(
        organizationId: organizationId,
        userId: ownerId,
        roleId: 'owner',
      );

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

  // ==================== INICIALIZAR ROLES PREDETERMINADOS ====================

  Future<void> _initializeDefaultRoles(
      String organizationId, String createdBy) async {
    try {
      final defaultRoles = RoleModel.getDefaultRoles(
        organizationId: organizationId,
        createdBy: createdBy,
      );

      final batch = _firestore.batch();

      for (final role in defaultRoles) {
        final roleRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('roles')
            .doc(role.id);

        batch.set(roleRef, role.toMap());
      }

      await batch.commit();
      debugPrint('✅ Roles predeterminados inicializados: ${defaultRoles.length}');
    } catch (e) {
      debugPrint('❌ Error inicializando roles: $e');
      rethrow;
    }
  }

  /// Obtener nombre de organización (sin requerir permisos - es dato público)
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




Future<String?> uploadOrganizationLogo(
  String orgId,
  XFile imageFile, {
  String? currentUserId, // Para validar permisos
}) async {
  try {
    // ✅ VALIDAR PERMISOS
    if (currentUserId != null) {
      final canEdit = await _memberService.can('organization', 'edit');
      if (!canEdit) {
        _error = 'No tienes permisos para cambiar el logo';
        notifyListeners();
        return null;
      }
    }

    _isLoading = true;
    notifyListeners();

    final ref = _storage.ref().child('organizations/$orgId/logo.png');
    final Uint8List imageBytes = await imageFile.readAsBytes();

    // Comprimir imagen
    final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 256,
      minHeight: 256,
      quality: 90,
      format: CompressFormat.png, 
    );

    final uploadTask = ref.putData(
      compressedBytes, 
      SettableMetadata(contentType: 'image/png') 
    );
    
    await uploadTask.whenComplete(() => null);
    final String downloadUrl = await ref.getDownloadURL();
    
    // Actualizar organización con nuevo logo
    await updateOrganization(
      organizationId: orgId,
      logoUrl: downloadUrl,
      currentUserId: currentUserId,
    );
    
    _isLoading = false;
    notifyListeners();
    return downloadUrl;
  } catch (e) {
    debugPrint('Error subiendo logo: $e');
    _error = 'Error al subir logo: $e';
    _isLoading = false;
    notifyListeners();
    return null;
  }
}

Future<bool> inviteUserByEmail({
  required String email,
  required String organizationId,
  required String invitedBy,
  required String invitedByName,
  String roleId = 'operator', // Rol que se asignará al aceptar
}) async {
  try {
    // ✅ VALIDAR PERMISOS
    final canInvite = await _memberService.can('organization', 'manageMembers');
    if (!canInvite) {
      _error = 'No tienes permisos para invitar usuarios';
      notifyListeners();
      return false;
    }

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

    // Verificar si ya existe invitación pendiente
    final existingInvite = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('invitations')
        .where('email', isEqualTo: email)
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
      roleId: roleId, // Guardar el rol que se asignará
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    await _firestore
        .collection('organizations')
        .doc(organizationId)
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

Stream<List<InvitationModel>> getPendingInvitations(String email) async* {
  try {
    // Obtener todas las organizaciones
    final orgsSnapshot = await _firestore.collection('organizations').get();
    
    final allInvitations = <InvitationModel>[];
    
    for (final orgDoc in orgsSnapshot.docs) {
      final orgId = orgDoc.id;
      
      // Buscar invitaciones para este email en esta organización
      final invitationsSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('invitations')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();
      
      for (final invDoc in invitationsSnapshot.docs) {
        final invitation = InvitationModel.fromMap(invDoc.data());
        if (!invitation.isExpired) {
          allInvitations.add(invitation);
        }
      }
    }
    
    yield allInvitations;
  } catch (e) {
    debugPrint('Error obteniendo invitaciones: $e');
    yield [];
  }
}

Future<bool> acceptInvitation({
  required BuildContext context,
  required String invitationId,
  required String userId,
  required String organizationId,
}) async {
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
    final invRef = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('invitations')
        .doc(invitationId);
    
    final DocumentSnapshot invDoc;
    try {
      invDoc = await invRef.get().timeout(const Duration(seconds: 5));
    } catch (e) {
      msg("Timeout al obtener invitación", isError: true);
      return false;
    }

    if (!invDoc.exists) {
      msg("ERROR: La invitación no existe", isError: true);
      return false;
    }

    final invitation = InvitationModel.fromMap(invDoc.data()! as Map<String, dynamic>);

    // Verificar si está expirada
    if (invitation.isExpired) {
      msg("Esta invitación ha expirado", isError: true);
      return false;
    }

    await _firestore.runTransaction((transaction) async {
      transaction.update(_firestore.collection('users').doc(userId), {
        'organizationId': organizationId,
      });
      transaction.update(_firestore.collection('organizations').doc(organizationId), {
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      transaction.update(invRef, {'status': 'accepted'});
    });
    
    // Crear miembro con rol especificado en la invitación
    await _createOrganizationMember(
      organizationId: organizationId,
      userId: userId,
      roleId: invitation.roleId ?? 'operator', // Usar rol de la invitación
    );
    
    await loadOrganization(organizationId);
    return true;

  } catch (e) {
    msg("Error al aceptar invitación: $e", isError: true);
    return false;
  }
}

Future<bool> rejectInvitation(String invitationId, String organizationId) async {
  try {
    await _firestore
        .collection('organizations')
        .doc(organizationId)
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

  // ==================== INICIALIZAR ESTADOS PREDETERMINADOS ====================

  Future<void> _initializeDefaultStatuses(
      String organizationId, String createdBy) async {
    try {
      final defaultStatuses = ProductStatusModel.getDefaultStatuses(
        organizationId: organizationId,
        createdBy: createdBy,
      );

      final batch = _firestore.batch();
      final statusIds = <String>[];

      for (final status in defaultStatuses) {
        final statusRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('product_statuses')
            .doc(status.id);

        batch.set(statusRef, status.toMap());
        statusIds.add(status.id);
      }

      // Actualizar organización con flag y lista de estados
      batch.update(
        _firestore.collection('organizations').doc(organizationId),
        {
          'statusesInitialized': true,
          'defaultStatuses': statusIds,
        },
      );

      await batch.commit();
      debugPrint('✅ Estados predeterminados inicializados: ${defaultStatuses.length}');
    } catch (e) {
      debugPrint('❌ Error inicializando estados: $e');
      rethrow;
    }
  }

  // ==================== GESTIÓN DE MIEMBROS ====================

  // Stream de miembros
  Stream<List<UserModel>> watchOrganizationMembers(String organizationId) {
  return _firestore
      .collection('users')
      .where('organizationId', isEqualTo: organizationId)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
}

  /// Actualizar rol de un miembro (requiere permisos de admin)
  Future<bool> updateMemberRole({
    required String organizationId,
    required String userId,
    required String newRoleId,
    String? currentUserId, // Para validar permisos
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      if (currentUserId != null) {
        final canManage =
            await _memberService.can('organization', 'manageMembers');
        if (!canManage) {
          _error = 'No tienes permisos para gestionar miembros';
          notifyListeners();
          return false;
        }
      }

      // Obtener el rol para actualizar información desnormalizada
      final roleDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc(newRoleId)
          .get();

      if (!roleDoc.exists) {
        _error = 'Rol no encontrado';
        notifyListeners();
        return false;
      }

      final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .update({
        'roleId': newRoleId,
        'roleName': role.name,
        'roleColor': role.color,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidar cache del miembro
      _memberService.invalidateCache(userId);

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar rol: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remover miembro de la organización (requiere permisos de admin)
  Future<bool> removeMember(
    String userId, {
    String? currentUserId, // Para validar permisos
  }) async {
    if (_currentOrganization == null) return false;

    try {
      // ✅ VALIDAR PERMISOS
      if (currentUserId != null) {
        final canManage =
            await _memberService.can('organization', 'manageMembers');
        if (!canManage) {
          _error = 'No tienes permisos para remover miembros';
          notifyListeners();
          return false;
        }

        // No permitir remover al owner
        if (_currentOrganization!.ownerId == userId) {
          _error = 'No se puede remover al propietario de la organización';
          notifyListeners();
          return false;
        }
      }

      // Remover de la organización (arrays legacy - deprecar gradualmente)
      await _firestore
          .collection('organizations')
          .doc(_currentOrganization!.id)
          .update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
      });

      // Actualizar usuario
      await _firestore.collection('users').doc(userId).update({
        'organizationId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Eliminar miembro de la colección members
      await _firestore
          .collection('organizations')
          .doc(_currentOrganization!.id)
          .collection('members')
          .doc(userId)
          .delete();

      // Invalidar cache
      _memberService.invalidateCache(userId);

      await loadOrganization(_currentOrganization!.id);
      return true;
    } catch (e) {
      _error = 'Error al remover miembro: $e';
      notifyListeners();
      return false;
    }
  }

  /// Abandonar organización (usuario sale voluntariamente)
  Future<bool> leaveOrganization(String userId) async {
    if (_currentOrganization == null) return false;

    if (_currentOrganization!.ownerId == userId) {
      _error = 'El propietario no puede abandonar la organización';
      notifyListeners();
      return false;
    }

    return await removeMember(userId);
  }

  /// @deprecated Usar updateMemberRole en su lugar
  @Deprecated('Usar updateMemberRole para gestionar roles con RBAC')
  Future<bool> toggleAdminRole(String userId, bool makeAdmin) async {
    if (_currentOrganization == null) return false;

    try {
      if (makeAdmin) {
        await _firestore
            .collection('organizations')
            .doc(_currentOrganization!.id)
            .update({
          'adminIds': FieldValue.arrayUnion([userId]),
        });
      } else {
        await _firestore
            .collection('organizations')
            .doc(_currentOrganization!.id)
            .update({
          'adminIds': FieldValue.arrayRemove([userId]),
        });
      }

      await loadOrganization(_currentOrganization!.id);
      return true;
    } catch (e) {
      _error = 'Error al cambiar rol: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== OBTENER MIEMBROS ====================

  /// Obtener miembro de organización
  Future<OrganizationMemberModel?> getOrganizationMember({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        return OrganizationMemberModel.fromMap(doc.data()!, docId: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo miembro: $e');
      return null;
    }
  }

  /// Stream de miembro de organización
  Stream<OrganizationMemberModel?> watchOrganizationMember({
    required String organizationId,
    required String userId,
  }) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return OrganizationMemberModel.fromMap(snapshot.data()!,
            docId: snapshot.id);
      }
      return null;
    });
  }

  // ==================== CREAR MIEMBRO DE ORGANIZACIÓN ====================

  Future<void> _createOrganizationMember({
    required String organizationId,
    required String userId,
    required String roleId,
  }) async {
    try {
      // Obtener información del rol
      final roleDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc(roleId)
          .get();

      if (!roleDoc.exists) {
        throw Exception('Rol no encontrado');
      }

      final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);

      // Obtener información del usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final user = UserModel.fromMap(userDoc.data()!);

      // Crear miembro
      final member = OrganizationMemberModel(
        userId: userId,
        organizationId: organizationId,
        roleId: role.id,
        roleName: role.name,
        roleColor: role.color,
        joinedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .set(member.toMap());

      debugPrint('✅ Miembro creado: ${user.email} como ${role.name}');
    } catch (e) {
      debugPrint('❌ Error creando miembro: $e');
      rethrow;
    }
  }

  // ==================== ACTUALIZAR ORGANIZACIÓN ====================

  Future<bool> updateOrganization({
    required String organizationId,
    String? name,
    String? description,
    String? logoUrl,
    String? currentUserId, // Para validar permisos
  }) async {
    try {
      // ✅ VALIDAR PERMISOS
      if (currentUserId != null) {
        final canEdit = await _memberService.can('organization', 'edit');
        if (!canEdit) {
          _error = 'No tienes permisos para editar la organización';
          notifyListeners();
          return false;
        }
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (logoUrl != null) updates['logoUrl'] = logoUrl;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update(updates);

      // Recargar organización
      await loadOrganization(organizationId);

      return true;
    } catch (e) {
      _error = 'Error al actualizar organización: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== CARGAR ORGANIZACIÓN ====================

  Future<OrganizationModel?> loadOrganization(String organizationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (doc.exists && doc.data() != null) {
        _currentOrganization = OrganizationModel.fromMap(doc.data()!);
        _isLoading = false;
        notifyListeners();
        return _currentOrganization;
      }

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

  /// Stream de organización
  Stream<OrganizationModel?> watchOrganization(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _currentOrganization = OrganizationModel.fromMap(snapshot.data()!);
        return _currentOrganization;
      }
      return null;
    });
  }

  // ==================== GESTIÓN DE INVITACIONES ====================

  Future<OrganizationModel?> getOrganizationByInviteCode(
      String inviteCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizations')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return OrganizationModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      _error = 'Error al buscar organización: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinOrganizationWithCode({
    required String inviteCode,
    required String userId,
    String defaultRoleId = 'operator', // Rol por defecto al unirse
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final organization = await getOrganizationByInviteCode(inviteCode);

      if (organization == null) {
        _error = 'Código de invitación inválido';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Añadir usuario a la organización
      await _firestore
          .collection('organizations')
          .doc(organization.id)
          .update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Actualizar usuario con organizationId
      await _firestore.collection('users').doc(userId).update({
        'organizationId': organization.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Crear miembro con rol por defecto
      await _createOrganizationMember(
        organizationId: organization.id,
        userId: userId,
        roleId: defaultRoleId,
      );

      _currentOrganization = organization;
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

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ==================== CARGAR MIEMBROS ====================

  Future<void> loadOrganizationMembers(String organizationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final org = await loadOrganization(organizationId);
      if (org == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final membersDocs = await Future.wait(
        org.memberIds.map((id) => _firestore.collection('users').doc(id).get()),
      );

      _organizationMembers = membersDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar miembros: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UTILIDADES ====================

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