import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/permission_model.dart';
import '../../models/organization_member_model.dart';
import '../../services/permission_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_permissions_screen.dart';

class OrganizationMembersScreen extends StatefulWidget {
  const OrganizationMembersScreen({super.key});

  @override
  State<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState extends State<OrganizationMembersScreen> {
  List<OrganizationMemberWithUser> _members = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Carga los miembros y sus datos de usuario combinados
  Future<void> _loadData() async {
    final orgService = Provider.of<OrganizationService>(context, listen: false);
    final permissionService = Provider.of<PermissionService>(context, listen: false);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    
    final organizationId = orgService.currentOrganization?.id;

    if (organizationId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtener la lista base de miembros (roles, permisos, IDs)
      final rawMembers = await permissionService.getOrganizationMembers(organizationId);

      // 2. Obtener detalles de usuario (Nombre, Email, Foto) para cada miembro
      // Esto es necesario porque OrganizationMemberModel solo tiene el userId
      final membersWithUserFuture = rawMembers.map((member) async {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(member.userId)
              .get();
          
          final userData = userDoc.data() ?? {};

          return OrganizationMemberWithUser(
            member: member,
            userName: userData['name'] as String? ?? 'Usuario Desconocido',
            userEmail: userData['email'] as String? ?? 'Sin email',
            userPhotoUrl: userData['photoURL'] as String?,
          );
        } catch (e) {
          // Fallback si falla la carga de un usuario especÃ­fico
          return OrganizationMemberWithUser(
            member: member,
            userName: 'Error cargando usuario',
            userEmail: '---',
          );
        }
      });

      final loadedMembers = await Future.wait(membersWithUserFuture);

      if (mounted) {
        setState(() {
          _members = loadedMembers;
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

@override
  Widget build(BuildContext context) {
    final orgService = Provider.of<OrganizationService>(context);
    final authService = Provider.of<AuthService>(context);
    final l10n = AppLocalizations.of(context)!; // Descomenta si usas l10n

    final organization = orgService.currentOrganization;
    final currentUser = authService.currentUserData;

    if (organization == null || currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Clonar y ordenar lista
    final sortedMembers = List<OrganizationMemberWithUser>.from(_members);
    
    sortedMembers.sort((a, b) {
      // 1. El dueÃ±o va primero
      final aIsOwner = a.userId == organization.ownerId;
      final bIsOwner = b.userId == organization.ownerId;
      if (aIsOwner) return -1;
      if (bIsOwner) return 1;
      
      // 2. Los admins van segundo
      final aIsAdmin = a.isAdmin;
      final bIsAdmin = b.isAdmin;
      if (aIsAdmin && !bIsAdmin) return -1;
      if (!aIsAdmin && bIsAdmin) return 1;
      
      // 3. Orden alfabÃ©tico
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
                '${sortedMembers.length} ${l10n.peopleLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () {
               // Navegar a pantalla de invitar miembros
               // Navigator.pushNamed(context, '/invite_member');
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
                        child: const Text('Reintentar'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: sortedMembers.isEmpty
                      ? Center(child: Text(l10n.noMembersFound))
                      : ListView.separated(
                          itemCount: sortedMembers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final member = sortedMembers[index];
                            return _buildMemberTile(
                              context,
                              member,
                              currentUser.uid,
                              organization.ownerId,
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    OrganizationMemberWithUser member,
    String currentUserId,
    String ownerId,
  ) {
    // Determinar si es el usuario actual
    final isMe = member.userId == currentUserId;
    final isOwner = member.userId == ownerId;

    // SubtÃ­tulo con el rol
    String roleText = member.roleName;
    if (isOwner) roleText = 'Dueño $roleText';
    if (isMe) roleText += ' (Tú)';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(member.roleId),
        backgroundImage: member.userPhotoUrl != null 
            ? NetworkImage(member.userPhotoUrl!) 
            : null,
        child: member.userPhotoUrl == null
            ? Text(member.initials, style: const TextStyle(color: Colors.white))
            : null,
      ),
      title: Text(
        member.userName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(roleText),
      trailing: _buildActionsMenu(context, member, currentUserId, ownerId),
      onTap: () async {
        // Solo el owner y admin pueden gestionar permisos de otros usuarios
        final permissionService = Provider.of<PermissionService>(context, listen: false);
        final canManagePermissions = permissionService.hasPermission('organization', 'manageRoles');
        print("can manage permissions: ${canManagePermissions} =====================");
        
        // No se puede editar al propietario
        if (member.userId == ownerId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pueden modificar los permisos del propietario'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

// TODO: descomentar esto !!!!!!!!!! SUPER IMPORTANTE !!!!!!!!! quitado solo para pruebas
        // Verificar permisos
        // if (!canManagePermissions && member.userId != currentUserId) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Text('No tienes permisos para gestionar usuarios'),
        //       backgroundColor: Colors.red,
        //     ),
        //   );
        //   return;
        // }

        // Navegar a la pantalla de gestión de permisos
        final orgService = Provider.of<OrganizationService>(context, listen: false);
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
      },
    );
  }

Widget? _buildActionsMenu(
    BuildContext context,
    OrganizationMemberWithUser member,
    String currentUserId,
    String ownerId,
  ) {
    final permissionService = Provider.of<PermissionService>(context, listen: false);
    
    // Reglas bÃ¡sicas de visualizaciÃ³n de menÃº:
    // 1. No puedes editarte a ti mismo desde esta lista (usualmente)
    if (member.userId == currentUserId) return null;

    // 2. Solo Admin o Owner pueden gestionar (verificar permisos reales)
    final canManageMembers = permissionService.hasPermission('organization', 'manageRoles') ||
                             permissionService.hasPermission('organization', 'removeMembers');
    
    if (!canManageMembers) return null;

    // 3. No puedes editar al DueÃ±o
    if (member.userId == ownerId) return null;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit_role') {
           // Abrir diÃ¡logo de cambio de rol
        } else if (value == 'remove') {
           // Confirmar eliminaciÃ³n
        }
      },
      itemBuilder: (context) => [
        if (permissionService.hasPermission('organization', 'manageRoles'))
          const PopupMenuItem(
            value: 'edit_role',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 20),
                SizedBox(width: 8),
                Text('Cambiar Rol'),
              ],
            ),
          ),
        if (permissionService.hasPermission('organization', 'removeMembers'))
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  // Helper simple para colores de roles (puedes moverlo a utils)
  Color _getRoleColor(String roleId) {
    switch (roleId) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'production_manager':
        return Colors.orange;
      case 'operator':
        return Colors.green;
      case 'client':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}