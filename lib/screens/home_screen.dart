import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/management/management_screen.dart';
import 'package:gestion_produccion/services/client_service.dart';
import 'package:gestion_produccion/services/phase_service.dart';
import 'package:gestion_produccion/services/product_catalog_service.dart';
import 'package:gestion_produccion/services/product_status_service.dart';
import 'package:gestion_produccion/services/production_batch_service.dart';
import 'package:gestion_produccion/services/project_service.dart';
import 'package:gestion_produccion/widgets/notification_badge.dart';
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
import '../../screens/dashboard/metrics_dashboard_screen.dart';
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
  bool _permissionsLoaded = false; // ✅ NUEVO
  String? _memberRoleName; // ✅ NUEVO

  @override
  void initState() {
    super.initState();
    // Ejecutar después del renderizado inicial para poder mostrar Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdates();
      _loadUserPermissions(); // ✅ NUEVO: Carga permisos primero
    });
  }

  Future<void> _loadUserPermissions() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);

    final user = authService.currentUserData;

    if (user == null || user.organizationId == null) {
      setState(() => _permissionsLoaded = true);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final organizationService = Provider.of<OrganizationService>(context);
    final user = authService.currentUserData;

    final permissionService = Provider.of<PermissionService>(context);
    final memberService = Provider.of<OrganizationMemberService>(context);

    // Verificar permisos específicos
    final canViewKanban = permissionService.hasPermission('kanban', 'view');
    final canViewBatches = permissionService.hasPermission('batches', 'view');
    final canCreateBatches =
        permissionService.hasPermission('batches', 'create');
    final canAccessProduction = canViewKanban || canViewBatches;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: user.organizationId != null
            ? StreamBuilder(
                stream:
                    organizationService.watchOrganization(user.organizationId!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(snapshot.data!.name);
                  }
                  return Text(l10n.appTitle);
                },
              )
            : Text(l10n.appTitle),
        actions: const [
          NotificationBadge(),
        ],
      ),
      body: SingleChildScrollView(
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
                    backgroundImage:
                        (user.photoURL != null && user.photoURL!.isNotEmpty)
                            ? NetworkImage(user.photoURL!)
                            : null,
                    child: (user.photoURL == null || user.photoURL!.isEmpty)
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
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
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      // RoleUtils.buildRoleBadge(user.role, compact: true),
                      // ✅ NUEVO: Badge con el rol del usuario
                      if (_memberRoleName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _memberRoleName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
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
      drawer:
          _buildDrawer(context, user, authService, organizationService, l10n),
      bottomNavigationBar: BottomNavBarWidget(currentIndex: 0, user: user),
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
              currentUser: user,
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
        permissionService.hasPermission('kanban', 'view') ||
            permissionService.hasPermission('batches', 'view');
    final canAccessManagement =
        permissionService.hasPermission('projects', 'view') ||
            permissionService.hasPermission('clients', 'view') ||
            permissionService.hasPermission('catalog', 'view');
    final canViewReports = permissionService.hasPermission('reports', 'view');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            currentAccountPicture: IconButton(
              icon: CircleAvatar(
                radius: 30,
                // backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                backgroundImage:
                    (user.photoURL != null && user.photoURL!.isNotEmpty)
                        ? NetworkImage(user.photoURL!)
                        : null,
                child: (user.photoURL == null || user.photoURL!.isEmpty)
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
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
            accountName: Text(user.name),
            accountEmail: Text(user.email),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(l10n.home),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          if (canAccessProduction) ...[
            ListTile(
              leading: const Icon(Icons.precision_manufacturing),
              title: Text(l10n.production),
              onTap: () {
                Navigator.pop(context);
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
              leading: const Icon(Icons.manage_accounts),
              title: Text(l10n.management),
              onTap: () {
                Navigator.pop(context);
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
              leading: const Icon(Icons.align_vertical_bottom),
              title: Text(l10n.slaAlerts),
              onTap: () {
                Navigator.pop(context);
                if (user.organizationId == null) return;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetricsDashboardScreen(
                          organizationId: user.organizationId!,
                          currentUser: user),
                    ));
              },
            ),
          ListTile(
            leading: const Icon(Icons.business),
            title: Text(l10n.organization),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
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
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[700]),
            title: Text(
              l10n.logout,
              style: TextStyle(color: Colors.red[700]),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(authService, l10n);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Versión 0.10.0 - 30/1/25 - Invitaciones y Activación',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
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

  /// ✅ MEJORADO
  Widget _buildUserHeader(UserModel user, AppLocalizations l10n) {
    return Row(
      children: [
        // Avatar clickable
        IconButton(
          icon: CircleAvatar(
            radius: 30,
            child: Text(user.name[0].toUpperCase()), // ✅ Usa el nuevo getter
          ),
          onPressed: () {/* ir a perfil */},
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.welcome}, ${user.name}'),
              const SizedBox(height: 4),
              // ✅ NUEVO: Badge con el rol del usuario
              if (_memberRoleName != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _memberRoleName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(AuthService authService, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();

              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome', // ⚠️ Asegúrate de que esta ruta esté definida en tu main.dart
                  (route) => false, // Esto elimina todas las rutas anteriores
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.exitButton),
          ),
        ],
      ),
    );
  }
}
