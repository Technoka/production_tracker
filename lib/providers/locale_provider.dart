import 'package:flutter/material.dart';
import '../services/user_preferences_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  final UserPreferencesService _preferencesService = UserPreferencesService();

  Locale get locale => _locale;

  /// Actualizar locale
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  /// Cargar locale efectivo del usuario
  Future<void> loadUserLocale({
    required String userId,
    required String organizationId,
    Locale? systemLocale,
  }) async {
    try {
      final effectiveLocale = await _preferencesService.getEffectiveUserLocale(
        userId: userId,
        organizationId: organizationId,
        systemLocale: systemLocale,
      );
      setLocale(effectiveLocale);
    } catch (e) {
      print('Error al cargar locale: $e');
      setLocale(const Locale('es')); // Fallback
    }
  }

  /// Cambiar idioma y guardar preferencia
  Future<void> changeLanguage({
    required String userId,
    required String languageCode,
  }) async {
    try {
      await _preferencesService.updateUserLanguage(
        userId: userId,
        language: languageCode,
      );
      setLocale(Locale(languageCode));
    } catch (e) {
      print('Error al cambiar idioma: $e');
      rethrow;
    }
  }

  /// Activar/desactivar idioma del sistema
  Future<void> toggleSystemLanguage({
    required String userId,
    required bool useSystemLanguage,
    required String organizationId,
    Locale? systemLocale,
  }) async {
    try {
      await _preferencesService.toggleSystemLanguage(
        userId: userId,
        useSystemLanguage: useSystemLanguage,
      );
      
      // Recargar locale efectivo
      await loadUserLocale(
        userId: userId,
        organizationId: organizationId,
        systemLocale: systemLocale,
      );
    } catch (e) {
      print('Error al cambiar configuración de idioma del sistema: $e');
      rethrow;
    }
  }

  /// Obtener lista de idiomas soportados
  List<Locale> get supportedLocales => const [
    Locale('es'),
    Locale('en'),
  ];

  /// Verificar si un locale está soportado
  bool isLocaleSupported(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  /// Obtener nombre del idioma actual
  String getLanguageName(BuildContext context) {
    switch (_locale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }

  /// Obtener bandera del idioma actual (emoji)
  String getLanguageFlag() {
    switch (_locale.languageCode) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇬🇧';
      default:
        return '🌐';
    }
  }
}