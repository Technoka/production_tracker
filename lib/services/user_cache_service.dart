import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de caché de usuarios para obtener datos actualizados de forma eficiente
/// Evita múltiples consultas a Firebase para el mismo usuario
class UserCacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache en memoria con tiempo de expiración
  final Map<String, _CachedUser> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  /// Singleton
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();
  
  /// Obtener datos básicos del usuario (nombre y foto de perfil) con caché
  Future<UserBasicData?> getUserBasicData(String userId) async {
    // Verificar si existe en caché y no ha expirado
    if (_cache.containsKey(userId)) {
      final cached = _cache[userId]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        return cached.data;
      }
    }
    
    // Si no está en caché o expiró, obtener de Firebase
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      final userData = UserBasicData(
        userId: userId,
        name: data['name'] as String? ?? 'Usuario',
        photoURL: data['photoURL'] as String?,
      );
      
      // Guardar en caché
      _cache[userId] = _CachedUser(
        data: userData,
        timestamp: DateTime.now(),
      );
      
      return userData;
    } catch (e) {
      print('Error obteniendo datos de usuario $userId: $e');
      return null;
    }
  }
  
  /// Obtener Stream de datos básicos del usuario (actualización en tiempo real)
  /// Útil para widgets que necesitan actualizarse cuando cambia la foto de perfil
  Stream<UserBasicData?> getUserBasicDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data()!;
      final userData = UserBasicData(
        userId: userId,
        name: data['name'] as String? ?? 'Usuario',
        photoURL: data['photoURL'] as String?,
      );
      
      // Actualizar caché
      _cache[userId] = _CachedUser(
        data: userData,
        timestamp: DateTime.now(),
      );
      
      return userData;
    });
  }
  
  /// Obtener múltiples usuarios de forma eficiente (batch)
  /// Útil para cargar datos de varios autores de mensajes a la vez
  Future<Map<String, UserBasicData>> getUsersBasicData(List<String> userIds) async {
    final result = <String, UserBasicData>{};
    final idsToFetch = <String>[];
    
    // Verificar caché primero
    for (final userId in userIds) {
      if (_cache.containsKey(userId)) {
        final cached = _cache[userId]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          result[userId] = cached.data;
          continue;
        }
      }
      idsToFetch.add(userId);
    }
    
    // Obtener los que no están en caché
    if (idsToFetch.isNotEmpty) {
      try {
        // Firebase Firestore permite máximo 10 documentos en whereIn
        // Dividir en chunks de 10
        for (int i = 0; i < idsToFetch.length; i += 10) {
          final chunk = idsToFetch.skip(i).take(10).toList();
          
          final snapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userData = UserBasicData(
              userId: doc.id,
              name: data['name'] as String? ?? 'Usuario',
              photoURL: data['photoURL'] as String?,
            );
            
            result[doc.id] = userData;
            
            // Actualizar caché
            _cache[doc.id] = _CachedUser(
              data: userData,
              timestamp: DateTime.now(),
            );
          }
        }
      } catch (e) {
        print('Error obteniendo datos de usuarios en batch: $e');
      }
    }
    
    return result;
  }
  
  /// Invalidar caché de un usuario específico
  void invalidateUser(String userId) {
    _cache.remove(userId);
  }
  
  /// Limpiar toda la caché
  void clearCache() {
    _cache.clear();
  }
  
  /// Limpiar caché expirada
  void cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) {
      return now.difference(value.timestamp) >= _cacheDuration;
    });
  }
}

/// Datos básicos del usuario (solo lo necesario para chat)
class UserBasicData {
  final String userId;
  final String name;
  final String? photoURL;
  
  UserBasicData({
    required this.userId,
    required this.name,
    this.photoURL,
  });
  
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }
}

/// Entrada de caché interna
class _CachedUser {
  final UserBasicData data;
  final DateTime timestamp;
  
  _CachedUser({
    required this.data,
    required this.timestamp,
  });
}