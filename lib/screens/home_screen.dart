import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/initialization_provider.dart';
import 'package:gestion_produccion/screens/management/management_screen.dart';
import 'package:gestion_produccion/services/client_service.dart';
import 'package:gestion_produccion/services/organization_settings_service.dart';
import 'package:gestion_produccion/services/phase_service.dart';
import 'package:gestion_produccion/services/product_catalog_service.dart';
import 'package:gestion_produccion/services/product_status_service.dart';
import 'package:gestion_produccion/services/production_batch_service.dart';
import 'package:gestion_produccion/services/project_service.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import 'package:gestion_produccion/widgets/notification_badge.dart';
import 'package:gestion_produccion/widgets/universal_loading_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';
import '../l10n/app_localizations.dart';
import 'profile/profile_screen.dart';
import 'organization/organization_home_screen.dart';
import 'production/production_screen.dart';
import 'production/create_production_batch_screen.dart';
import '../widgets/production_dashboard_widget.dart';
import '../widgets/kanban/kanban_board_widget.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import '../../models/user_model.dart';
import '../../services/update_service.dart';
import '../../widgets/whats_new_dialog.dart';
import '../../services/permission_service.dart';
import '../../services/organization_member_service.dart';
import '../providers/production_data_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsLoaded = false;
  String? _memberRoleName;
  String? _cachedOrgName;
  String? _cachedOrgLogoUrl;

  @override
  void initState() {
    super.initState();
    // Ejecutar después del renderizado inicial para poder mostrar Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdates();
      _loadUserPermissions();
    });
  }

  Future<void> _loadUserPermissions() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);
    final organizationService =
        Provider.of<OrganizationService>(context, listen: false);
    final settingsService =
        Provider.of<OrganizationSettingsService>(context, listen: false);

    final user = authService.currentUserData;

    if (user == null || user.organizationId == null) {
      setState(() => _permissionsLoaded = false);
      return;
    }

    try {
      // 1. Cargar permisos efectivos del usuario PRIMERO
      await permissionService.loadCurrentUserPermissions(
        userId: user.uid,
        organizationId: user.organizationId!,
      );

      // 2. Obtener datos del miembro para mostrar el rol
      final memberData = await memberService.getCurrentMember(
        user.organizationId!,
        user.uid,
      );

      // Cachear datos de la organización
      final orgData =
          await organizationService.getOrganization(user.organizationId!);
      final orgSettings =
          await settingsService.getOrganizationSettings(user.organizationId!);

      // 3. ✅ INICIALIZAR PRODUCTION DATA PROVIDER (DESPUÉS de permisos)
      final productionDataProvider =
          Provider.of<ProductionDataProvider>(context, listen: false);
      await productionDataProvider.initialize(
        organizationId: user.organizationId!,
        userId: user.uid,
        batchService:
            Provider.of<ProductionBatchService>(context, listen: false),
        phaseService: Provider.of<PhaseService>(context, listen: false),
        statusService:
            Provider.of<ProductStatusService>(context, listen: false),
        clientService: Provider.of<ClientService>(context, listen: false),
        catalogService:
            Provider.of<ProductCatalogService>(context, listen: false),
        projectService: Provider.of<ProjectService>(context, listen: false),
      );

      if (mounted) {
        setState(() {
          _memberRoleName = memberData?.member.roleName ?? 'Usuario?';
          _cachedOrgName = orgData!.name;
          _cachedOrgLogoUrl = orgSettings?.branding.logoUrl;
          _permissionsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error cargando permisos en HomeScreen: $e');
      if (mounted) {
        setState(() => _permissionsLoaded = true);
      }
    }
  }

  Future<void> _checkUpdates() async {
    final updateService = UpdateService();

    // 1. Aquí ocurre la espera asíncrona
    final releaseNote = await updateService.checkForUpdates();

    // ✅ SOLUCIÓN: Verificar si el widget sigue vivo.
    // Si el usuario cerró la pantalla mientras cargaba, paramos aquí.
    if (!mounted) return;

    // 2. Ahora ya es seguro usar 'context' porque sabemos que estamos 'mounted'
    if (releaseNote != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WhatsNewDialog(
          note: releaseNote,
          onClose: () async {
            await updateService.markVersionAsSeen();

            // ✅ También aplicamos la seguridad aquí dentro del callback
            // En versiones nuevas de Flutter usamos 'context.mounted' para contextos locales
            if (!context.mounted) return;

            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    final initProvider =
        Provider.of<InitializationProvider>(context, listen: false);
    await initProvider.refresh(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initProvider = Provider.of<InitializationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final organizationService = Provider.of<OrganizationService>(context);
    final user = authService.currentUserData;
    // print(
    //     '🏠 HomeScreen build - user: ${user?.uid}, orgId: ${user?.organizationId}');

    final permissionService = Provider.of<PermissionService>(context);
    final memberService = Provider.of<OrganizationMemberService>(context);

    if (!initProvider.isInitialized && !initProvider.isInitializing) {
      // Solo intentar inicializar si ya tenemos el UserModel cargado.
      // Si user es null pero hay currentUser de Firebase, esperamos al
      // próximo rebuild (que vendrá cuando AuthService cargue los datos).
      if (user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          initProvider.initialize(context);
        });
      }
      return const UniversalLoadingScreen();
    }

    // ✅ Mostrar loading mientras inicializa
    if (initProvider.isInitializing) {
      return const UniversalLoadingScreen();
    }

    // Verificar permisos específicos
    final canViewKanban = permissionService.canViewKanban;
    final canViewBatches = permissionService.canViewBatches;
    final canCreateBatches = permissionService.canCreateBatches;
    final canAccessProduction = canViewKanban || canViewBatches;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      currentIndex: AppNavIndex.home,
      title: l10n.appTitle,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El contenido principal
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saludo
                    Row(
                      children: [
                        IconButton(
                          padding: const EdgeInsets.all(8),
                          icon: CircleAvatar(
                            radius: 30, // Tamaño ajustado para AppBar
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            backgroundImage: (user.photoURL != null &&
                                    user.photoURL!.isNotEmpty)
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: (user.photoURL == null ||
                                    user.photoURL!.isEmpty)
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()),
                            );
                          },
                          tooltip: l10n.profile,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.welcome}, ${user.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              // Usar el cache del provider en lugar de variable local
                              if (initProvider.cachedRoleName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    initProvider.cachedRoleName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Dashboard de Producción (si aplica)
                    if (canViewBatches && user.organizationId != null) ...[
                      ProductionDashboardWidget(
                        organizationId: user.organizationId!,
                        clientId: memberService.getClientFilter(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Vista Kanban (si aplica)
                    if (canViewKanban && user.organizationId != null) ...[
                      _buildKanbanSection(user, l10n),
                    ],

                    // Nuevo: Mensaje cuando no tiene acceso
                    if (!canAccessProduction && user.organizationId != null)
                      _buildNoAccessCard(l10n),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canCreateBatches && user.organizationId != null
          ? _buildFloatingButtons(user, l10n)
          : null,
    );
  }

  Widget _buildKanbanSection(user, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.view_kanban,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.kanban,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductionScreen(
                      initialView: ProductionView.kanban,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_full, size: 16),
              label: Text(l10n.kanban),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 600,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: KanbanBoardWidget(
              organizationId: user.organizationId!,
              maxHeight: 600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButtons(UserModel user, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botón Clientes (Compacto)
        // Botón Crear Lote (Compacto)
        SizedBox(
          height: 40, // Altura reducida
          child: FloatingActionButton.extended(
            heroTag: 'fab_batch',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateProductionBatchScreen(
                    organizationId: user.organizationId!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label:
                Text(l10n.createBatchBtn, style: const TextStyle(fontSize: 13)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    UserModel user,
    AuthService authService,
    OrganizationService organizationService,
    AppLocalizations l10n,
  ) {
    // ✅ Verificar permisos para cada opción del menú

    final permissionService = Provider.of<PermissionService>(context);
    final canAccessProduction =
        permissionService.canViewKanban || permissionService.canViewBatches;
    final canAccessManagement = permissionService.canViewProjects ||
        permissionService.canViewClients ||
        permissionService.canViewCatalog;
    final canViewReports = permissionService.canViewReports;

    // Obtener el color primario del tema para aplicarlo a los iconos
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Función auxiliar para cerrar el drawer solo si está abierto en modo móvil
    void closeDrawer() {
      // Si la pantalla es pequeña, significa que es el Drawer flotante de móvil
      if (MediaQuery.of(context).size.width <
          UIConstants.DESKTOP_MIN_SCREEN_WIDTH) {
        Navigator.pop(context); // Esto cierra el Drawer flotante
      }
      // Si es pantalla grande, el Drawer es parte del body (fijo), así que no hacemos pop.
    }

    return Drawer(
      backgroundColor: Colors.white, // Fondo blanco
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Sin bordes redondeados
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 15),
                ListTile(
                  leading:
                      Icon(Icons.home, color: primaryColor, size: 20), // Color aplicado
                  title: Text(l10n.home, style: const TextStyle(fontSize: 14)),
                  selected: true,
                  onTap: () {
                    // No hace nada para evitar hacer pop del contexto y destruir la app
                    closeDrawer();
                  },
                ),
                if (canAccessProduction) ...[
                  ListTile(
                    leading: Icon(Icons.precision_manufacturing,
                        color: primaryColor, size: 20), // Color aplicado
                    title: Text(l10n.production, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      closeDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductionScreen(),
                        ),
                      );
                    },
                  ),
                ],
                if (canAccessManagement) ...[
                  ListTile(
                    leading: Icon(Icons.manage_accounts,
                        color: primaryColor, size: 20), // Color aplicado
                    title: Text(l10n.management, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      closeDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
                if (canViewReports && user.organizationId != null)
                  ListTile(
                    leading: Icon(Icons.business, color: primaryColor, size: 20),
                    title: Text(l10n.organization, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      closeDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrganizationHomeScreen(),
                        ),
                      );
                    },
                  ),
                const Divider(),
                ListTile(
                  leading:
                      Icon(Icons.person, color: primaryColor, size: 20), // Color aplicado
                  title: Text(l10n.profile, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Version movida abajo del todo, fuera del ListView
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 10),
            child: Center(
              child: Text(
                'Version 0.10.0 - 23/2/25 - Alpha Test',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO WIDGET
  Widget _buildNoAccessCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProductionAccess,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.contactAdminForPermissions,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
