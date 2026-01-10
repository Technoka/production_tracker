import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestion_produccion/models/organization_settings_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'services/auth_service.dart';
import 'services/organization_settings_service.dart';

import 'services/organization_service.dart';
import 'services/client_service.dart';
import 'services/project_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

import 'package:country_picker/country_picker.dart';
import 'services/production_batch_service.dart';
import 'services/product_catalog_service.dart';
import 'services/phase_service.dart';
import 'services/message_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicios de lógica de negocio
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => OrganizationService()),
        ChangeNotifierProvider(create: (_) => ClientService()),
        ChangeNotifierProvider(create: (_) => ProjectService()),
        ChangeNotifierProvider(create: (_) => ProductionBatchService()),
        Provider<ProductCatalogService>(create: (_) => ProductCatalogService()),
        Provider<PhaseService>(create: (_) => PhaseService()),
        Provider<MessageService>(create: (_) => MessageService()),
      ],
      // ✅ SOLO UN Consumer2 - No duplicado
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          // ✅ Asegurar que siempre haya branding
          if (themeProvider.branding == null) {
            // Solo log una vez, sin setState para evitar rebuild
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (themeProvider.branding == null) {
                // print('⚠️ Branding es null, aplicando defaults');
                themeProvider.updateBranding(OrganizationBranding.defaultBranding());
              }
            });
          }

          return MaterialApp(
            title: 'Production Tracker',
            debugShowCheckedModeBanner: false,

            // Configuración de Tema
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: ThemeMode.light,

            // Configuración de Idioma
            locale: localeProvider.locale,
            supportedLocales: localeProvider.supportedLocales,

            // Delegados de localización
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              CountryLocalizations.delegate,
            ],

            // Lógica para resolver el idioma inicial
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              return const Locale('es'); // Fallback
            },

            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Wrapper para manejar autenticación y cargar configuración
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Mostrando pantalla de carga mientras verifica autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay datos (usuario autenticado)
        if (snapshot.hasData) {
          // Cargar datos del usuario si no están en memoria
          if (authService.currentUserData == null) {
            authService.getUserData();
          }
          // Si hay usuario, cargar configuración de organización y mostrar home
          return const OrganizationSettingsWrapper();
        }

        // No hay usuario autenticado
        return const LoginScreen();
      },
    );
  }
}

/// Wrapper para cargar configuración de organización y preferencias de usuario
class OrganizationSettingsWrapper extends StatefulWidget {
  const OrganizationSettingsWrapper({Key? key}) : super(key: key);

  @override
  State<OrganizationSettingsWrapper> createState() =>
      _OrganizationSettingsWrapperState();
}

class _OrganizationSettingsWrapperState
    extends State<OrganizationSettingsWrapper> {
  final AuthService _authService = AuthService();
  final OrganizationSettingsService _orgSettingsService =
      OrganizationSettingsService();

  bool _isLoading = true;
  bool _hasLoaded = false; // ✅ GUARD para evitar carga duplicada
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserConfiguration();
  }

  Future<void> _loadUserConfiguration() async {
    // ✅ GUARD: Evitar ejecuciones múltiples
    if (_hasLoaded) {
      // print('⚠️ Configuración ya cargada, ignorando...');
      return;
    }
    _hasLoaded = true;

    try {
      // print('🚀 Iniciando carga de configuración...');

      final user = _authService.currentUser;
      if (user == null) {
        print('❌ Usuario no autenticado');
        if (mounted) {
          setState(() {
            _error = 'Usuario no autenticado';
            _isLoading = false;
          });
        }
        return;
      }

      // print('✅ Usuario autenticado: ${user.uid}');

      // Obtener datos del usuario
      final userData = await _authService.getUserData();
      if (userData == null) {
        // print('❌ No se pudieron cargar los datos del usuario');
        if (mounted) {
          setState(() {
            _error = 'No se pudieron cargar los datos del usuario';
            _isLoading = false;
          });
        }
        return;
      }

      // print('✅ Datos de usuario obtenidos: ${userData.name}');

      final organizationId = userData.organizationId;

      if (organizationId == null || organizationId.isEmpty) {
        // print('⚠️ Usuario sin organizationId, usando configuración por defecto');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // print('✅ OrganizationId encontrado: $organizationId');

      // Cargar configuración de organización
      final orgSettings =
          await _orgSettingsService.getOrganizationSettings(organizationId);

      // print('📦 Settings recibidos: ${orgSettings != null ? "✅ OK" : "❌ NULL"}');

      if (orgSettings != null && mounted) {
        // print('🎨 Aplicando branding...');

        // Aplicar branding al tema
        Provider.of<ThemeProvider>(context, listen: false)
            .updateBranding(orgSettings.branding);

        // print('🌍 Cargando locale del usuario...');

        // Cargar locale efectivo del usuario
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        await Provider.of<LocaleProvider>(context, listen: false)
            .loadUserLocale(
          userId: user.uid,
          organizationId: organizationId,
          systemLocale: systemLocale,
        );

        // print('✅ Configuración aplicada correctamente');
      } else if (!mounted) {
        // print('⚠️ Widget desmontado, cancelando aplicación de settings');
        return; // ✅ IMPORTANTE: Return para no ejecutar setState
      }

      // ✅ Solo setState si mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
    } catch (e, stackTrace) {
      print('❌ ERROR CRÍTICO al cargar configuración: $e');
      print('📍 Stack trace completo:');
      print(stackTrace);

      // ✅ Solo setState si mounted
      if (mounted) {
        setState(() {
          _error = null; // No mostrar error al usuario
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando configuración...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
                child: const Text('Volver al Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Todo cargado correctamente, mostrar home
    return const HomeScreen();
  }
}