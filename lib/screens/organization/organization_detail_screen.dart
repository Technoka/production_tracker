import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/organization/manage_invitations_screen.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
import '../../screens/organization/manage_status_transitions_screen.dart';
import '../../screens/organization/organization_settings_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import '../../services/role_service.dart';
import '../../services/permission_service.dart';
import '../../models/organization_model.dart';
import '../../models/role_model.dart';
import 'organization_members_screen.dart';
import '../phases/manage_phases_screen.dart';
import '../../l10n/app_localizations.dart';
import 'manage_product_statuses_screen.dart';

class OrganizationDetailScreen extends StatefulWidget {
  const OrganizationDetailScreen({super.key});

  @override
  State<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  List<RoleModel> _roles = [];
  Map<String, int> _roleCounts = {};
  bool _isLoadingRoles = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRolesAndCounts();
    });
  }

  /// Cargar roles y conteo de miembros por rol
  Future<void> _loadRolesAndCounts() async {
    final orgService = Provider.of<OrganizationService>(context, listen: false);
    final roleService = Provider.of<RoleService>(context, listen: false);

    final organizationId = orgService.currentOrganization?.id;
    if (organizationId == null) return;

    setState(() => _isLoadingRoles = true);

    try {
      // Cargar roles y conteos en paralelo para eficiencia
      final results = await Future.wait([
        roleService.getAllRoles(organizationId),
        roleService.getMemberCountByRole(organizationId),
      ]);

      if (mounted) {
        setState(() {
          _roles = results[0] as List<RoleModel>;
          _roleCounts = results[1] as Map<String, int>;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando roles: $e');
      if (mounted) {
        setState(() => _isLoadingRoles = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final organizationService = Provider.of<OrganizationService>(context);
    final permissionService = Provider.of<PermissionService>(context);
    final organization = organizationService.currentOrganization;
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    if (user == null || organization == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Verificar permisos
    final canManagePhases =
        permissionService.hasPermission('phases', 'create') ||
            permissionService.hasPermission('phases', 'edit');
    final canManageMembers =
        permissionService.hasPermission('organization', 'manageRoles');
    final canManageSettings =
        permissionService.hasPermission('organization', 'manageSettings');
    final canManageProductStatuses = permissionService.hasPermission(
        'organization', 'manageProductStatuses');
    final canManageStatusTransitions = permissionService.hasPermission(
        'organization', 'manageStatusTransitions');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrganizationTitle),
      ),
      body: StreamBuilder<OrganizationModel?>(
        stream: organizationService.watchOrganization(organization.id),
        builder: (context, snapshot) {
          final org = snapshot.data ?? organization;

          return RefreshIndicator(
            onRefresh: () async {
              await _loadRolesAndCounts();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con logo
                  _buildHeader(context, org, l10n),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjetas de estadísticas
                        Row(
                          children: [
                            // Tarjeta de Miembros
                            Expanded(
                              child: _buildMembersCard(
                                context,
                                org,
                                l10n,
                              ),
                            ),
                            const SizedBox(width: 1),
                            // Tarjeta de Clientes
                            Expanded(
                              child: _buildClientsCard(
                                context,
                                org,
                                l10n,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Acciones rápidas
                        if (canManagePhases ||
                            canManageMembers ||
                            canManageSettings ||
                            canManageProductStatuses ||
                            canManageStatusTransitions) ...[
                          Text(
                            l10n.actionsTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildActionsCard(
                              context,
                              org,
                              user,
                              l10n,
                              canManagePhases,
                              canManageMembers,
                              canManageSettings,
                              canManageProductStatuses,
                              canManageStatusTransitions),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header con logo o icono de la organización
  Widget _buildHeader(
    BuildContext context,
    OrganizationModel org,
    AppLocalizations l10n,
  ) {
    final isOwner = org.isOwner(
        Provider.of<AuthService>(context, listen: false).currentUserData!.uid);
    final isAdmin = org.isAdmin(
        Provider.of<AuthService>(context, listen: false).currentUserData!.uid);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Logo o icono
          if (org.logoUrl != null && org.logoUrl!.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  org.logoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.business,
                      size: 48,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            )
          else
            const Icon(
              Icons.business,
              size: 64,
              color: Colors.white,
            ),

          const SizedBox(height: 16),
          Text(
            org.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            org.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    l10n.ownerRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isAdmin) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    l10n.adminRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tarjeta de Miembros mejorada
  Widget _buildMembersCard(
    BuildContext context,
    OrganizationModel org,
    AppLocalizations l10n,
  ) {
    // Calcular total de miembros reales (suma de todos los roles)
    final totalMembers =
        _roleCounts.values.fold(0, (sum, count) => sum + count);

    // Obtener roles no-clientes que tienen al menos 1 miembro
    final nonClientRolesWithMembers = _roles
        .where((role) => role.id != 'client' && (_roleCounts[role.id] ?? 0) > 0)
        .toList();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrganizationMembersScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          constraints: const BoxConstraints(
            minHeight: 160, // Altura mínima igual para ambas tarjetas
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título con icono y total
              Row(
                children: [
                  const Icon(Icons.people, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '$totalMembers',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.totalMembers,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Distribución por rol
              if (_isLoadingRoles)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (nonClientRolesWithMembers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Sin roles asignados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                )
              else
                ...nonClientRolesWithMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final role = entry.value;
                  final count = _roleCounts[role.id] ?? 0;
                  final isLast = index == nonClientRolesWithMembers.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrganizationMembersScreen(
                                initialRoleFilter: role.id,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              // Número a la izquierda
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Icono del rol
                              Icon(
                                UIConstants.getIcon(role.icon),
                                color: role.colorValue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              // Nombre del rol
                              Expanded(
                                child: Text(
                                  role.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Divider entre roles (excepto el último)
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey[300],
                        ),
                    ],
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de Clientes
  Widget _buildClientsCard(
    BuildContext context,
    OrganizationModel org,
    AppLocalizations l10n,
  ) {
    final clientCount = _roleCounts['client'] ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrganizationMembersScreen(
              initialRoleFilter: 'client',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          // ✅ SOLUCIÓN: Usamos una altura fija para que 'Expanded' funcione
          height: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Icono y Número)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business_center,
                        color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$clientCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        l10n.clientsCard,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // 2. Contenido Central (Usando Expanded de forma segura)
              if (clientCount == 0) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 32, color: Colors.grey[300]),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noClientsMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.groups_outlined,
                        size: 40,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.listView, // Usa l10n.viewList si existe
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        size: 16, color: Colors.teal),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de acciones
  Widget _buildActionsCard(
    BuildContext context,
    OrganizationModel org,
    dynamic user,
    AppLocalizations l10n,
    bool canManagePhases,
    bool canManageMembers,
    bool canManageSettings,
    bool canManageProductStatuses,
    bool canManageStatusTransitions,
  ) {
    final isOwner = org.isOwner(user.uid);

    return Card(
      child: Column(
        children: [
          // Manage Phases - solo si tiene permiso
          if (canManagePhases)
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: Text(l10n.managePhasesTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManagePhasesScreen(
                      organizationId: org.id,
                      currentUser: user,
                    ),
                  ),
                );
              },
            ),

          if (canManagePhases && canManageProductStatuses)
            const Divider(height: 1),

          // Manage Phases - solo si tiene permiso
          if (canManageProductStatuses)
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: Text(l10n.manageProductStatuses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageProductStatusesScreen(
                      organizationId: org.id,
                    ),
                  ),
                );
              },
            ),

          if (canManageProductStatuses && canManageStatusTransitions)
            const Divider(height: 1),

          if (canManageStatusTransitions)
            ListTile(
              leading: const Icon(Icons.published_with_changes_sharp),
              title: Text(l10n.manageStatusTransitions),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageStatusTransitionsScreen(
                      organizationId: org.id,
                    ),
                  ),
                );
              },
            ),

          if (canManageStatusTransitions && canManageMembers)
            const Divider(height: 1),

          // Manage Members - solo si tiene permiso
          if (canManageMembers) ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(l10n.manageMembers),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrganizationMembersScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: Text(l10n.manageInvitationsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageInvitationsScreen(
                      organizationId: org.id,
                      organizationName: org.name,
                    ),
                  ),
                );
              },
            ),
          ],

          if (canManageMembers && canManageSettings) const Divider(height: 1),

          // Organization Settings - solo si tiene permiso
          if (canManageSettings || isOwner || org.isAdmin(user.uid))
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.organizationSettings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OrganizationSettingsScreen(organizationId: org.id),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
