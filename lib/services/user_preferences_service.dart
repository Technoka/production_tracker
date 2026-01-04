import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/organization_settings_model.dart';
import 'organization_settings_service.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrganizationSettingsService _orgSettingsService = OrganizationSettingsService();

  /// Stream de preferencias de usuario en tiempo real
  Stream<UserPreferences?> getUserPreferencesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data();
      if (data == null || !data.containsKey('preferences')) {
        return UserPreferences.defaultPreferences();
      }
      
      return UserPreferences.fromMap(
        data['preferences'] as Map<String, dynamic>,
      );
    });
  }

  /// Obtener preferencias actuales
  Future<UserPreferences?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || !data.containsKey('preferences')) {
        return UserPreferences.defaultPreferences();
      }

      return UserPreferences.fromMap(
        data['preferences'] as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error al obtener preferencias: $e');
      return null;
    }
  }

  /// Actualizar preferencias completas
  Future<void> updateUserPreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'preferences': preferences.toMap(),
      });
    } catch (e) {
      print('Error al actualizar preferencias: $e');
      rethrow;
    }
  }

  /// Actualizar idioma del usuario
  Future<void> updateUserLanguage({
    required String userId,
    required String language,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'preferences.language': language,
        'preferences.useSystemLanguage': false,
      });
    } catch (e) {
      print('Error al actualizar idioma: $e');
      rethrow;
    }
  }

  /// Activar/desactivar uso de idioma del sistema
  Future<void> toggleSystemLanguage({
    required String userId,
    required bool useSystemLanguage,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'preferences.useSystemLanguage': useSystemLanguage,
      });
    } catch (e) {
      print('Error al cambiar configuración de idioma del sistema: $e');
      rethrow;
    }
  }

  /// Actualizar preferencias de notificaciones
  Future<void> updateNotificationPreferences({
    required String userId,
    required Map<String, bool> notifications,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'preferences.notifications': notifications,
      });
    } catch (e) {
      print('Error al actualizar preferencias de notificaciones: $e');
      rethrow;
    }
  }

  /// Determinar idioma efectivo del usuario
  /// Prioridad: Idioma usuario > Idioma sistema > Idioma org > Español
  Future<Locale> getEffectiveUserLocale({
    required String userId,
    required String organizationId,
    Locale? systemLocale,
  }) async {
    try {
      // 1. Obtener preferencias del usuario
      final userPrefs = await getUserPreferences(userId);
      
      // 2. Si el usuario tiene idioma configurado y no usa sistema
      if (userPrefs != null && 
          userPrefs.language != null && 
          !userPrefs.useSystemLanguage) {
        return Locale(userPrefs.language!);
      }

      // 3. Si usa idioma del sistema y está disponible
      if (userPrefs?.useSystemLanguage == true && systemLocale != null) {
        final orgSettings = await _orgSettingsService.getOrganizationSettings(organizationId);
        final supportedLanguages = orgSettings?.language.supportedLanguages ?? ['es', 'en'];
        
        if (supportedLanguages.contains(systemLocale.languageCode)) {
          return systemLocale;
        }
      }

      // 4. Idioma por defecto de la organización
      final orgSettings = await _orgSettingsService.getOrganizationSettings(organizationId);
      if (orgSettings != null) {
        return Locale(orgSettings.language.defaultLanguage);
      }

      // 5. Fallback a español
      return const Locale('es');
    } catch (e) {
      print('Error al determinar idioma efectivo: $e');
      return const Locale('es');
    }
  }

  /// Inicializar preferencias por defecto
  Future<void> initializeDefaultPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      final data = doc.data();
      if (data == null || !data.containsKey('preferences')) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({
          'preferences': UserPreferences.defaultPreferences().toMap(),
        });
      }
    } catch (e) {
      print('Error al inicializar preferencias: $e');
      // No lanzar error si falla, usar defaults
    }
  }

  /// Obtener idiomas soportados de la organización
  Future<List<String>> getSupportedLanguages(String organizationId) async {
    try {
      final settings = await _orgSettingsService.getOrganizationSettings(organizationId);
      return settings?.language.supportedLanguages ?? ['es', 'en'];
    } catch (e) {
      print('Error al obtener idiomas soportados: $e');
      return ['es', 'en'];
    }
  }
}