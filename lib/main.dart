import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestion_produccion/models/organization_settings_model.dart';
import 'package:gestion_produccion/models/user_model.dart';
import 'package:gestion_produccion/providers/initialization_provider.dart';
import 'package:gestion_produccion/screens/auth/welcome_screen.dart';
import 'package:gestion_produccion/services/notification_service.dart';
import 'package:gestion_produccion/services/pending_object_service.dart';
import 'package:gestion_produccion/widgets/universal_loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'firebase_options.dart';

import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/production_data_provider.dart';

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
import 'services/status_transition_service.dart';
import 'services/product_status_service.dart';
import 'services/organization_member_service.dart';
import 'services/kanban_service.dart';
import 'services/permission_service.dart';
import 'services/role_service.dart';
import 'services/activation_code_service.dart';
import 'services/invitation_service.dart';

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
        // ==================== SERVICIOS BASE (Sin dependencias) ====================

        ChangeNotifierProvider(create: (_) => AuthService()),

        // OrganizationMemberService - SERVICIO CENTRAL RBAC
        ChangeNotifierProvider(create: (_) => OrganizationMemberService()),
        ChangeNotifierProvider(create: (_) => PermissionService()),
        ChangeNotifierProvider(create: (_) => RoleService()),

        // OrganizationSettings - Branding y configuración de la organización
        ChangeNotifierProvider(create: (_) => OrganizationSettingsService()),

        // Servicios sin dependencias RBAC
        Provider<PhaseService>(create: (_) => PhaseService()),
        Provider<MessageService>(create: (_) => MessageService()),

        // Notificaciones y objetos pendientes
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => PendingObjectService()),

        // Invitaciones y activaciones
        ChangeNotifierProvider(create: (_) => ActivationCodeService()),
        ChangeNotifierProvider(create: (_) => InvitationService()),

        // Providers de datos de producción
        ChangeNotifierProvider(create: (_) => InitializationProvider()),
        ChangeNotifierProvider(create: (_) => ProductionDataProvider()),

        // ==================== SERVICIOS CON DEPENDENCIA DE OrganizationMemberService ====================

        // ClientService
        ChangeNotifierProxyProvider<OrganizationMemberService, ClientService>(
          create: (context) => ClientService(
            memberService: context.read<OrganizationMemberService>(),
          ),
          update: (context, memberService, previous) =>
              previous ?? ClientService(memberService: memberService),
        ),

        // ProjectService
        ChangeNotifierProxyProvider<OrganizationMemberService, ProjectService>(
          create: (context) => ProjectService(
            memberService: context.read<OrganizationMemberService>(),
          ),
          update: (context, memberService, previous) =>
              previous ?? ProjectService(memberService: memberService),
        ),

        // ProductCatalogService
        ChangeNotifierProxyProvider<OrganizationMemberService,
            ProductCatalogService>(
          create: (context) => ProductCatalogService(
            memberService: context.read<OrganizationMemberService>(),
          ),
          update: (context, memberService, previous) =>
              previous ?? ProductCatalogService(memberService: memberService),
        ),

        // KanbanService (Provider normal, no ChangeNotifier)
        ProxyProvider<OrganizationMemberService, KanbanService>(
          create: (context) => KanbanService(
            memberService: context.read<OrganizationMemberService>(),
          ),
          update: (context, memberService, previous) =>
              previous ?? KanbanService(memberService: memberService),
        ),

        // ProductStatusService
        ChangeNotifierProxyProvider<OrganizationMemberService,
            ProductStatusService>(
          create: (context) => ProductStatusService(
            memberService: context.read<OrganizationMemberService>(),
          ),
          update: (context, memberService, previous) =>
              previous ?? ProductStatusService(memberService: memberService),
        ),

        // StatusTransitionService (sin dependencias RBAC por ahora)
        ChangeNotifierProvider(create: (_) => StatusTransitionService()),

        // ==================== SERVICIOS COMPLEJOS CON MÚLTIPLES DEPENDENCIAS ====================

        // OrganizationService depende de: OrganizationMemberService y NotificationService
        ChangeNotifierProxyProvider2<OrganizationMemberService,
            NotificationService, OrganizationService>(
          create: (context) => OrganizationService(
            memberService: context.read<OrganizationMemberService>(),
            notificationService: context.read<NotificationService>(),
          ),
          update: (context, memberService, notificationService, previous) =>
              previous ??
              OrganizationService(
                memberService: memberService,
                notificationService: notificationService,
              ),
        ),

        // ProductionBatchService depende de:
        // - ProductStatusService
        // - StatusTransitionService
        // - OrganizationMemberService
        ChangeNotifierProxyProvider3<
            ProductStatusService,
            StatusTransitionService,
            OrganizationMemberService,
            ProductionBatchService>(
          create: (context) => ProductionBatchService(
            statusService: context.read<ProductStatusService>(),
            transitionService: context.read<StatusTransitionService>(),
            memberService: context.read<OrganizationMemberService>(),
          ),
          update:
              (_, statusService, transitionService, memberService, previous) =>
                  previous ??
                  ProductionBatchService(
                    statusService: statusService,
                    transitionService: transitionService,
                    memberService: memberService,
                  ),
        ),
      ],

      // ✅ SOLO UN Consumer2 - No duplicado
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          // ✅ Asegurar que siempre haya branding
          if (themeProvider.branding == null) {
            // Solo log una vez, sin setState para evitar rebuild
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (themeProvider.branding == null) {
                themeProvider
                    .updateBranding(OrganizationBranding.defaultBranding());
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

            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                return StreamBuilder<User?>(
                  stream: authService.authStateChanges,
                  builder: (context, snapshot) {
                    // Esperando autenticación
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const UniversalLoadingScreen();
                    }

                    // No hay usuario - mostrar Welcome
                    if (!snapshot.hasData) {
                      return const WelcomeScreen();
                    }

                    // Hay usuario - verificar si tiene organización
                    return FutureBuilder<UserModel?>(
                      future: authService.getUserData(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const UniversalLoadingScreen();
                        }

                        final user = userSnapshot.data!;

                        // Si no tiene organización, mostrar opciones
                        if (user.organizationId == null ||
                            user.organizationId!.isEmpty) {
                          return const WelcomeScreen();
                        }

                        // Tiene organización, ir al home
                        return const HomeScreen();
                      },
                    );
                  },
                );
              },
            ),

            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/welcome': (context) => const WelcomeScreen(),
            },
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
        return const WelcomeScreen();
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
    final authService = Provider.of<AuthService>(context, listen: false);
    // ✅ GUARD: Evitar ejecuciones múltiples
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;

    try {
      final user = authService.currentUser;
      if (user == null) {
        debugPrint('❌ Usuario no autenticado');
        if (mounted) {
          setState(() {
            _error = 'Usuario no autenticado';
            _isLoading = false;
          });
        }
        return;
      }

      // Obtener datos del usuario
      final userData = await authService.getUserData();
      if (userData == null) {
        if (mounted) {
          setState(() {
            _error = 'No se pudieron cargar los datos del usuario';
            _isLoading = false;
          });
        }
        return;
      }

      final organizationId = userData.organizationId;

      if (organizationId == null || organizationId.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Cargar configuración de organización
      final orgSettings =
          await _orgSettingsService.getOrganizationSettings(organizationId);

      if (orgSettings != null && mounted) {
        // Aplicar branding al tema
        Provider.of<ThemeProvider>(context, listen: false)
            .updateBranding(orgSettings.branding);

        // Cargar locale efectivo del usuario
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        await Provider.of<LocaleProvider>(context, listen: false)
            .loadUserLocale(
          userId: user.uid,
          organizationId: organizationId,
          systemLocale: systemLocale,
        );
      } else if (!mounted) {
        return; // ✅ IMPORTANTE: Return para no ejecutar setState
      }

      // ✅ Solo setState si mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR CRÍTICO al cargar configuración: $e');
      debugPrint('📋 Stack trace completo:');
      debugPrint(stackTrace.toString());

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
    final authService = Provider.of<AuthService>(context, listen: false);
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
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
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
