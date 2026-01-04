import 'package:cloud_firestore/cloud_firestore.dart';

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
      primaryColor: map['primaryColor'] as String? ?? '#2196F3',
      secondaryColor: map['secondaryColor'] as String? ?? '#FF9800',
      accentColor: map['accentColor'] as String? ?? '#4CAF50',
      logoUrl: map['logoUrl'] as String?,
      fontFamily: map['fontFamily'] as String? ?? 'Roboto',
      organizationName: map['organizationName'] as String? ?? '',
      welcomeMessage: Map<String, String>.from(
        map['welcomeMessage'] as Map<String, dynamic>? ?? 
        {'es': 'Bienvenido', 'en': 'Welcome'},
      ),
    );
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

  LanguageSettings({
    required this.defaultLanguage,
    required this.supportedLanguages,
  });

  factory LanguageSettings.fromMap(Map<String, dynamic> map) {
    return LanguageSettings(
      defaultLanguage: map['defaultLanguage'] as String? ?? 'es',
      supportedLanguages: List<String>.from(
        map['supportedLanguages'] as List<dynamic>? ?? ['es', 'en'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultLanguage': defaultLanguage,
      'supportedLanguages': supportedLanguages,
    };
  }

  LanguageSettings copyWith({
    String? defaultLanguage,
    List<String>? supportedLanguages,
  }) {
    return LanguageSettings(
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
    );
  }

  factory LanguageSettings.defaultSettings() {
    return LanguageSettings(
      defaultLanguage: 'es',
      supportedLanguages: ['es', 'en'],
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
    return OrganizationSettings(
      branding: OrganizationBranding.fromMap(
        map['branding'] as Map<String, dynamic>? ?? {},
      ),
      language: LanguageSettings.fromMap(
        map['language'] as Map<String, dynamic>? ?? {},
      ),
    );
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