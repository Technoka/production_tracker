import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/organization_settings_model.dart';

class OrganizationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Stream de configuración de organización en tiempo real
  Stream<OrganizationSettings?> getOrganizationSettingsStream(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data();
      if (data == null || !data.containsKey('settings')) {
        return OrganizationSettings.defaultSettings();
      }
      
      return OrganizationSettings.fromMap(
        data['settings'] as Map<String, dynamic>,
      );
    });
  }

  /// Obtener configuración actual (snapshot único)
  Future<OrganizationSettings?> getOrganizationSettings(String organizationId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || !data.containsKey('settings')) {
        return OrganizationSettings.defaultSettings();
      }

      return OrganizationSettings.fromMap(
        data['settings'] as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error al obtener configuración: $e');
      return null;
    }
  }

  /// Actualizar configuración completa
  Future<void> updateOrganizationSettings({
    required String organizationId,
    required OrganizationSettings settings,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings': settings.toMap(),
      });
    } catch (e) {
      print('Error al actualizar configuración: $e');
      rethrow;
    }
  }

  /// Actualizar solo branding
  Future<void> updateBranding({
    required String organizationId,
    required OrganizationBranding branding,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings.branding': branding.toMap(),
      });
    } catch (e) {
      print('Error al actualizar branding: $e');
      rethrow;
    }
  }

  /// Actualizar solo configuración de idioma
  Future<void> updateLanguageSettings({
    required String organizationId,
    required LanguageSettings languageSettings,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings.language': languageSettings.toMap(),
      });
    } catch (e) {
      print('Error al actualizar configuración de idioma: $e');
      rethrow;
    }
  }

  /// Subir logo de organización
  Future<String?> uploadOrganizationLogo({
    required String organizationId,
    required XFile imageFile,
  }) async {
    try {
      // Leer archivo
      final File file = File(imageFile.path);
      
      // Referencia en Storage
      final storageRef = _storage.ref().child(
        'organizations/$organizationId/branding/logo.${imageFile.path.split('.').last}',
      );

      // Subir archivo
      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${imageFile.path.split('.').last}',
        ),
      );

      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Actualizar en Firestore
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings.branding.logoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print('Error al subir logo: $e');
      return null;
    }
  }

  /// Eliminar logo de organización
  Future<void> deleteOrganizationLogo(String organizationId) async {
    try {
      // Obtener URL actual
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      final data = doc.data();
      final logoUrl = data?['settings']?['branding']?['logoUrl'] as String?;

      if (logoUrl == null) return;

      // Eliminar de Storage
      final storageRef = _storage.refFromURL(logoUrl);
      await storageRef.delete();

      // Actualizar en Firestore
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings.branding.logoUrl': FieldValue.delete(),
      });
    } catch (e) {
      print('Error al eliminar logo: $e');
      rethrow;
    }
  }

  /// Actualizar colores
  Future<void> updateColors({
    required String organizationId,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (primaryColor != null) {
        updates['settings.branding.primaryColor'] = primaryColor;
      }
      if (secondaryColor != null) {
        updates['settings.branding.secondaryColor'] = secondaryColor;
      }
      if (accentColor != null) {
        updates['settings.branding.accentColor'] = accentColor;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('organizations')
            .doc(organizationId)
            .update(updates);
      }
    } catch (e) {
      print('Error al actualizar colores: $e');
      rethrow;
    }
  }

  /// Actualizar tipografía
  Future<void> updateFontFamily({
    required String organizationId,
    required String fontFamily,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings.branding.fontFamily': fontFamily,
      });
    } catch (e) {
      print('Error al actualizar tipografía: $e');
      rethrow;
    }
  }

  /// Actualizar nombre de organización
  Future<void> updateOrganizationName({
    required String organizationId,
    required String name,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings.branding.organizationName': name,
      });
    } catch (e) {
      print('Error al actualizar nombre: $e');
      rethrow;
    }
  }

  /// Actualizar mensaje de bienvenida
  Future<void> updateWelcomeMessage({
    required String organizationId,
    required Map<String, String> welcomeMessage,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .update({
        'settings.branding.welcomeMessage': welcomeMessage,
      });
    } catch (e) {
      print('Error al actualizar mensaje de bienvenida: $e');
      rethrow;
    }
  }

  /// Verificar si el usuario tiene permisos de admin
  Future<bool> hasAdminPermissions({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final orgDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (!orgDoc.exists) return false;

      final ownerId = orgDoc.data()?['ownerId'] as String?;
      if (ownerId == userId) return true;

      final memberDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) return false;

      final role = memberDoc.data()?['role'] as String?;
      return role == 'admin';
    } catch (e) {
      print('Error al verificar permisos: $e');
      return false;
    }
  }

  /// Inicializar settings por defecto si no existen
  Future<void> initializeDefaultSettings(String organizationId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      final data = doc.data();
      if (data == null || !data.containsKey('settings')) {
        await _firestore
            .collection('organizations')
            .doc(organizationId)
            .update({
          'settings': OrganizationSettings.defaultSettings().toMap(),
        });
      }
    } catch (e) {
      print('Error al inicializar settings: $e');
      rethrow;
    }
  }
}