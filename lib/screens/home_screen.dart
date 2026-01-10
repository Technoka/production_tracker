import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/management/management_screen.dart';
import 'package:gestion_produccion/screens/profile/user_preferences_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';
import '../utils/role_utils.dart';
import '../l10n/app_localizations.dart';
import 'profile/profile_screen.dart';
import 'organization/organization_home_screen.dart';
import 'production/production_screen.dart';
import 'production/create_production_batch_screen.dart';
import '../widgets/production_dashboard_widget.dart';
import '../widgets/kanban/kanban_board_widget.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import '../widgets/sla/sla_alert_badge.dart';
import '../../screens/dashboard/metrics_dashboard_screen.dart';
import '../../models/user_model.dart';
import '../../services/update_service.dart';
import '../../widgets/whats_new_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

    @override
  void initState() {
    super.initState();
    // Ejecutar después del renderizado inicial para poder mostrar Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdates();
    });
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
        actions: [],
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
                      RoleUtils.buildRoleBadge(user.role, compact: true),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dashboard de Producción (si aplica)
            if (user.canManageProduction && user.organizationId != null) ...[
              ProductionDashboardWidget(
                organizationId: user.organizationId!,
              ),
              const SizedBox(height: 24),
            ],

            // Vista Kanban (si aplica)
            if (user.canManageProduction && user.organizationId != null) ...[
              _buildKanbanSection(user, l10n),
            ],
          ],
        ),
      ),
      drawer:
          _buildDrawer(context, user, authService, organizationService, l10n),
      bottomNavigationBar: BottomNavBarWidget(currentIndex: 0, user: user),
      floatingActionButton:
          user.canManageProduction && user.organizationId != null
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

  Widget _buildFloatingButtons(user, AppLocalizations l10n) {
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
          if (user.canManageProduction) ...[
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
          ],
          ListTile(
            leading: const Icon(Icons.business),
            title: Text(l10n.organization),
            trailing: StreamBuilder<List<dynamic>>(
              stream: organizationService.getPendingInvitations(user.email),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                if (count == 0) return const Icon(Icons.chevron_right);

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
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
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserPreferencesScreen(),
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
                'Versión 0.7.0 - 7/1/25',
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
