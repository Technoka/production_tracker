import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';

class OrganizationMembersScreen extends StatefulWidget {
  const OrganizationMembersScreen({super.key});

  @override
  State<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState extends State<OrganizationMembersScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Usamos la función pública que definimos en el servicio
    await Provider.of<OrganizationService>(context, listen: false).loadOrganizationMembers();
  }

  @override
  Widget build(BuildContext context) {
    final orgService = Provider.of<OrganizationService>(context);
    final authService = Provider.of<AuthService>(context);
    
    // Obtener datos actuales
    final organization = orgService.currentOrganization;
    final currentUser = authService.currentUserData;
    final members = orgService.organizationMembers; // Getter del servicio

    // Validaciones de seguridad
    if (organization == null || currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Clonamos la lista para ordenarla sin afectar la original del provider
    final sortedMembers = List<UserModel>.from(members);
    
    // Lógica de ordenamiento: Dueño > Admins > Alfabético
    sortedMembers.sort((a, b) {
      if (organization.ownerId == a.uid) return -1;
      if (organization.ownerId == b.uid) return 1;
      
      final aIsAdmin = organization.adminIds.contains(a.uid);
      final bIsAdmin = organization.adminIds.contains(b.uid);
      
      if (aIsAdmin && !bIsAdmin) return -1;
      if (!aIsAdmin && bIsAdmin) return 1;
      
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Miembros'),
            Text(
              '${sortedMembers.length} personas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: orgService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: sortedMembers.isEmpty 
                ? const Center(child: Text('No se encontraron miembros'))
                : ListView.builder(
                    itemCount: sortedMembers.length,
                    itemBuilder: (context, index) {
                      final member = sortedMembers[index];
                      return _buildMemberTile(
                        context,
                        member,
                        currentUser,
                        organization.ownerId,
                        organization.adminIds,
                        orgService,
                      );
                    },
                  ),
            ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    UserModel member,
    UserModel currentUser,
    String ownerId,
    List<String> adminIds,
    OrganizationService service,
  ) {
    final isOwner = member.uid == ownerId;
    final isAdmin = adminIds.contains(member.uid);
    final isMe = member.uid == currentUser.uid;

    // Determinar si el usuario actual tiene permisos sobre este miembro
    final iAmOwner = currentUser.uid == ownerId;
    final iAmAdmin = adminIds.contains(currentUser.uid);
    
    // Reglas: 
    // 1. Nadie se gestiona a sí mismo aquí (para eso está Salir).
    // 2. El dueño gestiona a todos.
    // 3. Los admins gestionan a miembros normales (no a otros admins ni al dueño).
    final canManage = !isMe && (iAmOwner || (iAmAdmin && !isOwner && !isAdmin));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOwner
            ? Colors.purple[100]
            : (isAdmin ? Colors.blue[100] : Colors.grey[200]),
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: isOwner
                ? Colors.purple[900]
                : (isAdmin ? Colors.blue[900] : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        member.name,
        style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.email),
          if (isOwner || isAdmin) ...[
            const SizedBox(height: 4),
            _buildRoleBadge(isOwner, isAdmin),
          ]
        ],
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              onSelected: (value) => _handleAction(value, member, service, isAdmin),
              itemBuilder: (context) => [
                // Opción Promover/Degradar (Solo Dueño)
                if (iAmOwner)
                  PopupMenuItem(
                    value: isAdmin ? 'demote' : 'promote',
                    child: Row(
                      children: [
                        Icon(
                          isAdmin ? Icons.remove_moderator : Icons.add_moderator,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(isAdmin ? 'Quitar Admin' : 'Hacer Admin'),
                      ],
                    ),
                  ),
                // Opción Expulsar
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.person_remove, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Text('Expulsar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildRoleBadge(bool isOwner, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOwner ? Colors.purple[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isOwner ? Colors.purple[200]! : Colors.blue[200]!,
        ),
      ),
      child: Text(
        isOwner ? 'Propietario' : 'Admin',
        style: TextStyle(
          fontSize: 10, 
          color: isOwner ? Colors.purple[900] : Colors.blue[900],
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Future<void> _handleAction(
    String action,
    UserModel member,
    OrganizationService service,
    bool isCurrentlyAdmin,
  ) async {
    bool success = false;
    
    if (action == 'remove') {
      // Diálogo de confirmación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Expulsar miembro?'),
          content: Text('¿Estás seguro de eliminar a ${member.name} de la organización?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Expulsar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Llamada a tu función: removeMember(userId)
        success = await service.removeMember(member.uid);
      } else {
        return;
      }
    } 
    else if (action == 'promote') {
      // Llamada a tu función: promoteToAdmin(userId)
      success = await service.promoteToAdmin(member.uid);
    } 
    else if (action == 'demote') {
      // Llamada a tu función: demoteFromAdmin(userId)
      success = await service.demoteFromAdmin(member.uid);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el miembro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}