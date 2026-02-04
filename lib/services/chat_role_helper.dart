import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organization_member_model.dart';

/// Helper para verificar el rol de un usuario en una organización
class ChatRoleHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Singleton
  static final ChatRoleHelper _instance = ChatRoleHelper._internal();
  factory ChatRoleHelper() => _instance;
  ChatRoleHelper._internal();
  
  /// Cache de roles de usuario por organización
  final Map<String, _CachedRole> _roleCache = {};
  static const Duration _cacheDuration = Duration(minutes: 15);
  
  /// Verificar si un usuario es cliente en una organización
  Future<bool> isUserClient(String organizationId, String userId) async {
    final cacheKey = '$organizationId:$userId';
    
    // Verificar caché
    if (_roleCache.containsKey(cacheKey)) {
      final cached = _roleCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        return cached.isClient;
      }
    }
    
    // Obtener de Firebase
    try {
      final memberDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();
      
      if (!memberDoc.exists) {
        // No es miembro, por defecto no es cliente
        _cacheRole(cacheKey, false, null);
        return false;
      }
      
      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );
      
      // Es cliente si roleId es 'client'
      final isClient = member.roleId == 'client';
      
      // Guardar en caché
      _cacheRole(cacheKey, isClient, member.roleId);
      
      return isClient;
    } catch (e) {
      print('Error verificando si usuario es cliente: $e');
      return false;
    }
  }
  
  /// Obtener el roleId del usuario en una organización
  Future<String?> getUserRole(String organizationId, String userId) async {
    final cacheKey = '$organizationId:$userId';
    
    // Verificar caché
    if (_roleCache.containsKey(cacheKey)) {
      final cached = _roleCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        return cached.roleId;
      }
    }
    
    // Obtener de Firebase
    try {
      final memberDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();
      
      if (!memberDoc.exists) {
        _cacheRole(cacheKey, false, null);
        return null;
      }
      
      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );
      
      // Guardar en caché
      _cacheRole(cacheKey, member.roleId == 'client', member.roleId);
      
      return member.roleId;
    } catch (e) {
      print('Error obteniendo rol de usuario: $e');
      return null;
    }
  }
  
  /// Stream para escuchar cambios en el rol del usuario
  Stream<bool> isUserClientStream(String organizationId, String userId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      
      final member = OrganizationMemberModel.fromMap(
        snapshot.data()!,
        docId: snapshot.id,
      );
      
      final isClient = member.roleId == 'client';
      
      // Actualizar caché
      final cacheKey = '$organizationId:$userId';
      _cacheRole(cacheKey, isClient, member.roleId);
      
      return isClient;
    });
  }
  
  /// Guardar en caché
  void _cacheRole(String key, bool isClient, String? roleId) {
    _roleCache[key] = _CachedRole(
      isClient: isClient,
      roleId: roleId,
      timestamp: DateTime.now(),
    );
  }
  
  /// Invalidar caché de un usuario específico
  void invalidateUser(String organizationId, String userId) {
    final cacheKey = '$organizationId:$userId';
    _roleCache.remove(cacheKey);
  }
  
  /// Limpiar toda la caché
  void clearCache() {
    _roleCache.clear();
  }
  
  /// Limpiar caché expirada
  void cleanExpiredCache() {
    final now = DateTime.now();
    _roleCache.removeWhere((key, value) {
      return now.difference(value.timestamp) >= _cacheDuration;
    });
  }
}

/// Entrada de caché de rol
class _CachedRole {
  final bool isClient;
  final String? roleId;
  final DateTime timestamp;
  
  _CachedRole({
    required this.isClient,
    required this.roleId,
    required this.timestamp,
  });
}