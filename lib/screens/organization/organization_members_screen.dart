import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import '../../services/role_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/permission_model.dart';
import '../../models/organization_member_model.dart';
import '../../models/role_model.dart';
import '../../services/permission_service.dart';
import '../../utils/filter_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_permissions_screen.dart';
import 'invite_member_screen.dart';
import '../../widgets/client_permissions_selector.dart';
import '../../services/client_service.dart';

class OrganizationMembersScreen extends StatefulWidget {
  final String? initialRoleFilter; // Filtro de rol preseleccionado

  const OrganizationMembersScreen({
    super.key,
    this.initialRoleFilter,
  });

  @override
  State<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState extends State<OrganizationMembersScreen> {
  List<OrganizationMemberWithUser> _members = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtros
  String? _selectedRoleId;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRoleId =
        widget.initialRoleFilter; // Aplicar filtro inicial si existe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Carga los miembros, sus datos de usuario y los roles
  Future<void> _loadData() async {
    final orgService = Provider.of<OrganizationService>(context, listen: false);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final roleService = Provider.of<RoleService>(context, listen: false);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final organizationId = orgService.currentOrganization?.id;
    final l10n = AppLocalizations.of(context)!;

    if (organizationId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Cargar roles de la organización
      final roles = await roleService.getAllRoles(organizationId);

      // 2. Obtener la lista base de miembros
      final rawMembers =
          await permissionService.getOrganizationMembers(organizationId);

      // 3. Obtener detalles de usuario para cada miembro
      final membersWithUserFuture = rawMembers.map((member) async {
        try {
          final userDoc =
              await firestore.collection('users').doc(member.userId).get();

          final userData = userDoc.data() ?? {};

          return OrganizationMemberWithUser(
            member: member,
            userName: userData['name'] as String? ?? l10n.unknownUser,
            userEmail: userData['email'] as String? ?? l10n.withoutEmail,
            userPhotoUrl: userData['photoURL'] as String?,
          );
        } catch (e) {
          return OrganizationMemberWithUser(
            member: member,
            userName: l10n.errorLoadingUser,
            userEmail: '---',
          );
        }
      });

      final loadedMembers = await Future.wait(membersWithUserFuture);

      if (mounted) {
        setState(() {
          _members = loadedMembers;
          _roles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando miembros: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar los miembros.';
          _isLoading = false;
        });
      }
    }
  }

  /// Filtrar miembros según los criterios seleccionados
  List<OrganizationMemberWithUser> _getFilteredMembers() {
    var filtered = List<OrganizationMemberWithUser>.from(_members);

    // Filtro por rol
    if (_selectedRoleId != null) {
      filtered = filtered.where((m) => m.roleId == _selectedRoleId).toList();
    }

    // Filtro por texto (nombre o rol)
    if (_searchText.isNotEmpty) {
      final searchLower = _searchText.toLowerCase();
      filtered = filtered.where((m) {
        return m.userName.toLowerCase().contains(searchLower) ||
            m.roleName.toLowerCase().contains(searchLower);
      }).toList();
    }

    return filtered;
  }

  /// Limpiar todos los filtros
  void _clearFilters() {
    setState(() {
      _selectedRoleId = null;
      _searchText = '';
      _searchController.clear();
    });
  }

  /// Verificar si hay filtros activos
  bool get _hasActiveFilters =>
      _selectedRoleId != null || _searchText.isNotEmpty;

  Future<void> _showClientPermissionsDialog(
    BuildContext context,
    OrganizationMemberWithUser member,
  ) async {
    if (member.member.clientId == null) return;

    final clientService = Provider.of<ClientService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Obtener cliente
    final client = await clientService.getClient(
      member.organizationId,
      member.member.clientId!,
    );

    if (client == null || !context.mounted) return;

    final initialPermissions =
        Map<String, dynamic>.from(client.clientPermissions);

    await showDialog(
      context: context,
      builder: (context) {
        Map<String, dynamic> updatedPermissions = Map.from(initialPermissions);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.editClientPermissions),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.client}: ${client.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.clientPermissionsApplyToAllMembers,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClientPermissionsSelector(
                        initialPermissions: updatedPermissions,
                        onPermissionsChanged: (newPerms) {
                          setState(() {
                            updatedPermissions = newPerms;
                          });
                        },
                        enabled: true,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    // Actualizar permisos del cliente

                    final success = await clientService.updateClientPermissions(
                      organizationId: member.organizationId,
                      clientId: member.member.clientId!,
                      clientPermissions: updatedPermissions,
                    );

                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.clientPermissionsUpdated),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(clientService.error ??
                                l10n.errorUpdatingPermissions),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgService = Provider.of<OrganizationService>(context);
    final authService = Provider.of<AuthService>(context);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!; // Descomenta si usas l10n

    final organization = orgService.currentOrganization;
    final currentUser = authService.currentUserData;

    if (organization == null || currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Filtrar y ordenar lista
    final filteredMembers = _getFilteredMembers();

    filteredMembers.sort((a, b) {
      // 1. El dueño va primero
      final aIsOwner = a.userId == organization.ownerId;
      final bIsOwner = b.userId == organization.ownerId;
      if (aIsOwner) return -1;
      if (bIsOwner) return 1;

      // 2. Los admins van segundo
      final aIsAdmin = a.isAdmin;
      final bIsAdmin = b.isAdmin;
      if (aIsAdmin && !bIsAdmin) return -1;
      if (!aIsAdmin && bIsAdmin) return 1;

      // 3. Orden alfabético
      return a.userName.compareTo(b.userName);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.members),
            if (!_isLoading)
              Text(
                '${filteredMembers.length} ${l10n.peopleLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (permissionService.hasPermission('organization', 'inviteMembers'))
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InviteMemberScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text(l10n.retry),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      // Barra de filtros
                      _buildFilterBar(context, l10n),

                      // Lista de miembros
                      Expanded(
                        child: filteredMembers.isEmpty
                            ? Center(child: Text(l10n.noMembersFound))
                            : ListView.separated(
                                itemCount: filteredMembers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final member = filteredMembers[index];
                                  return _buildMemberTile(
                                      context,
                                      member,
                                      currentUser.uid,
                                      organization.ownerId,
                                      l10n);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Barra de filtros
  Widget _buildFilterBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.filterByName,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchText = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),

          const SizedBox(height: 8),

          // Fila de filtros y botón limpiar
          Row(
            children: [
              // Filtro de roles
              if (_roles.isNotEmpty)
                FilterUtils.buildFilterOption<String>(
                  context: context,
                  label: l10n.filterByRole,
                  value: _selectedRoleId,
                  items: _roles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role.id,
                      child: Row(
                        children: [
                          Icon(
                            UIConstants.getIcon(role.icon),
                            color: role.colorValue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(role.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoleId = value;
                    });
                  },
                  icon: Icons.admin_panel_settings_outlined,
                  allLabel: l10n.allRoles,
                ),

              // Botón limpiar filtros
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                FilterUtils.buildClearFiltersButton(
                  context: context,
                  onPressed: _clearFilters,
                  hasActiveFilters: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
      BuildContext context,
      OrganizationMemberWithUser member,
      String currentUserId,
      String ownerId,
      AppLocalizations l10n) {
        
    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);

    // Determinar si es el usuario actual
    final isMe = member.userId == currentUserId;

    String roleText = member.roleName;
    // if (isOwner) roleText = '$roleText';
    if (isMe) roleText += ' (${l10n.you})';
    if (member.isClient) {
      final clientName = dataProvider.getClientById(member.member.clientId!)!.name;
      roleText += " ($clientName)";
    }

    return ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(member.roleId),
          backgroundImage: member.userPhotoUrl != null
              ? NetworkImage(member.userPhotoUrl!)
              : null,
          child: member.userPhotoUrl == null
              ? Text(member.initials,
                  style: const TextStyle(color: Colors.white))
              : null,
        ),
        title: Text(
          member.userName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(roleText),
        trailing:
            _buildActionsMenu(context, member, currentUserId, ownerId, l10n),
        onTap: () async {
          if (member.isClient) {
            // Para clientes, mostrar dialog de permisos
            _showClientPermissionsDialog(context, member);
          } else {
            // Navegar a la pantalla de gestión de permisos
            final orgService =
                Provider.of<OrganizationService>(context, listen: false);
            final organizationId = orgService.currentOrganization?.id;

            if (organizationId == null) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemberPermissionsScreen(
                  memberData: member,
                  organizationId: organizationId,
                ),
              ),
            );

            // Recargar datos después de volver
            _loadData();
          }
        });
  }

  Widget? _buildActionsMenu(
      BuildContext context,
      OrganizationMemberWithUser member,
      String currentUserId,
      String ownerId,
      AppLocalizations l10n) {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);

    // Si es el usuario actual, no mostrar menú (puede verse a sí mismo con tap)
    if (member.userId == currentUserId) return null;

    // Solo Admin o Owner pueden gestionar
    final canManageMembers =
        permissionService.hasPermission('organization', 'manageRoles') ||
            permissionService.hasPermission('organization', 'removeMembers');

    if (!canManageMembers) return null;

    // No puedes editar al Dueño
    if (member.userId == ownerId) return null;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit_role') {
          // Abrir diálogo de cambio de rol
        } else if (value == 'remove') {
          // Confirmar eliminación
        }
      },
      itemBuilder: (context) => [
        if (permissionService.hasPermission('organization', 'manageRoles'))
          PopupMenuItem(
            value: 'edit_role',
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 20),
                const SizedBox(width: 8),
                Text(l10n.changeRole),
              ],
            ),
          ),
        if (permissionService.hasPermission('organization', 'removeMembers'))
          PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                const Icon(Icons.person_remove_outlined,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(l10n.removeMemberAction,
                    style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  Color _getRoleColor(String roleId) {
    final role = _roles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => RoleModel(
        id: roleId,
        name: roleId,
        description: '',
        color: '#9E9E9E',
        icon: 'person',
        isDefault: false,
        isCustom: false,
        permissions: PermissionsModel.empty(),
        organizationId: '',
        createdBy: '',
        createdAt: DateTime.now(),
      ),
    );
    return role.colorValue;
  }
}
