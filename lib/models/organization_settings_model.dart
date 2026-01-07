import 'package:flutter/material.dart';

/// Modelo para la configuración de branding de una organización
class OrganizationBranding {
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String? logoUrl;
  final String fontFamily;
  final String organizationName;
  final Map<String, String> welcomeMessage;

  OrganizationBranding({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.logoUrl,
    required this.fontFamily,
    required this.organizationName,
    required this.welcomeMessage,
  });

  
  /// Constructor desde Firestore
  factory OrganizationBranding.fromMap(Map<String, dynamic> map) {
    return OrganizationBranding(
      primaryColor: _parseColorToHex(map['primaryColor']) ?? '#2196F3',
      secondaryColor: _parseColorToHex(map['secondaryColor']) ?? '#FF9800',
      accentColor: _parseColorToHex(map['accentColor']) ?? '#4CAF50',
      logoUrl: map['logoUrl'] as String?,
      fontFamily: map['fontFamily'] as String? ?? 'Roboto',
      organizationName: map['organizationName'] as String? ?? '',
        welcomeMessage: _parseWelcomeMessage(map['welcomeMessage']),
    );
  }

    static Map<String, String> _parseWelcomeMessage(dynamic value) {
    if (value == null) {
      return {'es': 'Bienvenido', 'en': 'Welcome'};
    }

    // Si es un String directo (legacy)
    if (value is String) {
      return {'es': value, 'en': value};
    }

    // Si es un Map (formato actual)
    if (value is Map) {
      try {
        final result = <String, String>{};
        value.forEach((key, val) {
          if (key is String && val is String) {
            result[key] = val;
          }
        });
        
        // Asegurar que tenga al menos 'es' y 'en'
        result.putIfAbsent('es', () => 'Bienvenido');
        result.putIfAbsent('en', () => 'Welcome');
        
        return result;
      } catch (e) {
        print('⚠️ Error parseando welcomeMessage Map: $e');
      }
    }

    // Fallback
    return {'es': 'Bienvenido', 'en': 'Welcome'};
  }

    /// Helper seguro para parsear colores
    static String? _parseColorToHex(dynamic value) {
    if (value == null) return null;
    
    try {
      // Si ya es un String hex, devolverlo normalizado
      if (value is String) {
        final hex = value.trim().toUpperCase();
        
        // Si empieza con #, validar formato
        if (hex.startsWith('#')) {
          final cleanHex = hex.substring(1);
          
          if (cleanHex.length == 6) {
            // Formato válido #RRGGBB
            return '#$cleanHex';
          } else if (cleanHex.length == 8) {
            // Formato #AARRGGBB -> convertir a #RRGGBB
            return '#${cleanHex.substring(2)}';
          } else if (cleanHex.length == 3) {
            // Formato corto #RGB -> #RRGGBB
            final r = cleanHex[0];
            final g = cleanHex[1];
            final b = cleanHex[2];
            return '#$r$r$g$g$b$b';
          }
        }
        
        // Si no tiene #, asumir que es hex y añadirlo
        if (hex.length == 6 && _isValidHex(hex)) {
          return '#$hex';
        }
        
        // Devolver tal cual si no podemos parsearlo
        return value;
      }
      
      // Si es un int, convertir a hex
      if (value is int) {
        // Formato 0xAARRGGBB o 0xRRGGBB
        final hexString = value.toRadixString(16).toUpperCase();
        
        if (hexString.length >= 6) {
          // Tomar solo los últimos 6 dígitos (RGB)
          final rgb = hexString.substring(hexString.length - 6);
          return '#$rgb';
        }
        
        // Si es muy corto, pad con ceros
        return '#${hexString.padLeft(6, '0')}';
      }
    } catch (e) {
      print('⚠️ Error parseando color a hex: $value ($e)');
    }
    
    return null;
  }

  /// Validar si un string es hexadecimal válido
  static bool _isValidHex(String hex) {
    return RegExp(r'^[0-9A-Fa-f]+$').hasMatch(hex);
  }

  /// Convertir hex string a Color para uso en UI
  static Color _hexToColor(String hexString) {
    try {
      final hex = hexString.replaceAll('#', '').toUpperCase();
      
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      print('⚠️ Error convirtiendo hex a Color: $hexString ($e)');
    }
    
    // Fallback a azul
    return const Color(0xFF2196F3);
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'logoUrl': logoUrl,
      'fontFamily': fontFamily,
      'organizationName': organizationName,
      'welcomeMessage': welcomeMessage,
    };
  }

  /// Crear copia con modificaciones
  OrganizationBranding copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? logoUrl,
    String? fontFamily,
    String? organizationName,
    Map<String, String>? welcomeMessage,
  }) {
    return OrganizationBranding(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      logoUrl: logoUrl ?? this.logoUrl,
      fontFamily: fontFamily ?? this.fontFamily,
      organizationName: organizationName ?? this.organizationName,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
    );
  }

  /// Branding por defecto
  factory OrganizationBranding.defaultBranding() {
    return OrganizationBranding(
      primaryColor: '#2196F3',
      secondaryColor: '#FF9800',
      accentColor: '#4CAF50',
      fontFamily: 'Roboto',
      organizationName: 'Mi Organización',
      welcomeMessage: {
        'es': 'Bienvenido a nuestra organización',
        'en': 'Welcome to our organization',
      },
    );
  }
}

/// Modelo para configuración de idioma
class LanguageSettings {
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final bool useSystemLanguage;

  LanguageSettings({
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.useSystemLanguage,
  });

    factory LanguageSettings.fromMap(Map<String, dynamic> map) {
    try {
      return LanguageSettings(
        defaultLanguage: map['defaultLanguage'] as String? ?? 'es',
        supportedLanguages: map['supportedLanguages'] != null
            ? List<String>.from(map['supportedLanguages'] as List)
            : ['es', 'en'],
        useSystemLanguage: map['useSystemLanguage'] as bool? ?? true,
      );
    } catch (e) {
      print('❌ Error en LanguageSettings.fromMap: $e');
      return LanguageSettings.defaultSettings();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultLanguage': defaultLanguage,
      'supportedLanguages': supportedLanguages,
      'useSystemLanguage': useSystemLanguage,
    };
  }

  LanguageSettings copyWith({
    String? defaultLanguage,
    List<String>? supportedLanguages,
    bool? useSystemLanguage,
  }) {
    return LanguageSettings(
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      useSystemLanguage: useSystemLanguage ?? this.useSystemLanguage,
    );
  }

  factory LanguageSettings.defaultSettings() {
    return LanguageSettings(
      defaultLanguage: 'es',
      supportedLanguages: ['es', 'en'],
      useSystemLanguage: true,
    );
  }
}

/// Modelo completo de configuración de organización
class OrganizationSettings {
  final OrganizationBranding branding;
  final LanguageSettings language;

  OrganizationSettings({
    required this.branding,
    required this.language,
  });

   factory OrganizationSettings.fromMap(Map<String, dynamic> map) {
    try {
      return OrganizationSettings(
        branding: map.containsKey('branding') && map['branding'] != null
            ? OrganizationBranding.fromMap(map['branding'] as Map<String, dynamic>)
            : OrganizationBranding.defaultBranding(),
        language: map.containsKey('language') && map['language'] != null
            ? LanguageSettings.fromMap(map['language'] as Map<String, dynamic>)
            : LanguageSettings.defaultSettings(),
      );
    } catch (e) {
      print('❌ Error en OrganizationSettings.fromMap: $e');
      print('Map problemático: $map');
      return OrganizationSettings.defaultSettings();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'branding': branding.toMap(),
      'language': language.toMap(),
    };
  }

  OrganizationSettings copyWith({
    OrganizationBranding? branding,
    LanguageSettings? language,
  }) {
    return OrganizationSettings(
      branding: branding ?? this.branding,
      language: language ?? this.language,
    );
  }

  factory OrganizationSettings.defaultSettings() {
    return OrganizationSettings(
      branding: OrganizationBranding.defaultBranding(),
      language: LanguageSettings.defaultSettings(),
    );
  }
}

/// Modelo para preferencias de usuario
class UserPreferences {
  final String? language;
  final bool useSystemLanguage;
  final Map<String, bool> notifications;

  UserPreferences({
    this.language,
    this.useSystemLanguage = true,
    required this.notifications,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      language: map['language'] as String?,
      useSystemLanguage: map['useSystemLanguage'] as bool? ?? true,
      notifications: Map<String, bool>.from(
        map['notifications'] as Map<String, dynamic>? ?? 
        {'email': true, 'push': true},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'useSystemLanguage': useSystemLanguage,
      'notifications': notifications,
    };
  }

  UserPreferences copyWith({
    String? language,
    bool? useSystemLanguage,
    Map<String, bool>? notifications,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      useSystemLanguage: useSystemLanguage ?? this.useSystemLanguage,
      notifications: notifications ?? this.notifications,
    );
  }

  factory UserPreferences.defaultPreferences() {
    return UserPreferences(
      useSystemLanguage: true,
      notifications: {
        'email': true,
        'push': true,
      },
    );
  }
}