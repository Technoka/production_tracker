import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

import 'package:flutter_localizations/flutter_localizations.dart';
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
      // 1. Aquí inyectamos TODOS los servicios (Antiguos + Nuevos)
      providers: [
        // Servicios de lógica de negocio (Del código antiguo)
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => OrganizationService()),
        ChangeNotifierProvider(create: (_) => ClientService()),
        ChangeNotifierProvider(create: (_) => ProjectService()),
        ChangeNotifierProvider(create: (_) => ProductionBatchService()),
        Provider<ProductCatalogService>(create: (_) => ProductCatalogService()),
        Provider<PhaseService>(create: (_) => PhaseService()),
        Provider<MessageService>(create: (_) => MessageService()),

        // Servicios de UI (Nuevos - Asegúrate de tener estas clases creadas)
        ChangeNotifierProvider(create: (_) => ThemeProvider()), 
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      // 2. Usamos Consumer para escuchar cambios de Tema e Idioma
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Production Tracker',
            debugShowCheckedModeBanner: false,

            // Configuración de Tema
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: ThemeMode.light, // O themeProvider.themeMode si lo tienes implementado

            // Configuración de Idioma
            locale: localeProvider.locale,
            supportedLocales: localeProvider.supportedLocales,
            
            // Delegados de localización (Fusionados: App + Flutter + Country)
            localizationsDelegates: const [
              AppLocalizations.delegate, // Tus traducciones
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              CountryLocalizations.delegate, // Importante para la librería de países
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
  State<OrganizationSettingsWrapper> createState() => _OrganizationSettingsWrapperState();
}

class _OrganizationSettingsWrapperState extends State<OrganizationSettingsWrapper> {
  final AuthService _authService = AuthService();
  final OrganizationSettingsService _orgSettingsService = OrganizationSettingsService();
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserConfiguration();
  }

  Future<void> _loadUserConfiguration() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      // Obtener datos del usuario
      final userData = await _authService.getUserData();
      if (userData == null) {
        setState(() {
          _error = 'No se pudieron cargar los datos del usuario';
          _isLoading = false;
        });
        return;
      }

      final organizationId = userData.organizationId;

      // Cargar configuración de organización
      final orgSettings = await _orgSettingsService.getOrganizationSettings(organizationId!);
      
      if (orgSettings != null && mounted) {
        // Aplicar branding al tema
        Provider.of<ThemeProvider>(context, listen: false)
            .updateBranding(orgSettings.branding);

        // Cargar locale efectivo del usuario
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        await Provider.of<LocaleProvider>(context, listen: false).loadUserLocale(
          userId: user.uid,
          organizationId: organizationId,
          systemLocale: systemLocale,
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error al cargar configuración: $e');
      setState(() {
        _error = 'Error al cargar configuración: $e';
        _isLoading = false;
      });
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
                  Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
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