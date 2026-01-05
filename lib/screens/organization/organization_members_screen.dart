import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import '../../l10n/app_localizations.dart';

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
    await Provider.of<OrganizationService>(context, listen: false).loadOrganizationMembers();
  }

  @override
  Widget build(BuildContext context) {
    final orgService = Provider.of<OrganizationService>(context);
    final authService = Provider.of<AuthService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Obtener datos actuales
    final organization = orgService.currentOrganization;
    final currentUser = authService.currentUserData;
    final members = orgService.organizationMembers;

    // Validaciones de seguridad
    if (organization == null || currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Clonamos la lista para ordenarla
    final sortedMembers = List<UserModel>.from(members);
    
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
            Text(l10n.members),
            Text(
              '${sortedMembers.length} ${l10n.peopleLabel}',
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
                ? Center(child: Text(l10n.noMembersFound))
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
    final l10n = AppLocalizations.of(context)!;
    final isOwner = member.uid == ownerId;
    final isAdmin = adminIds.contains(member.uid);
    final isMe = member.uid == currentUser.uid;

    final iAmOwner = currentUser.uid == ownerId;
    final iAmAdmin = adminIds.contains(currentUser.uid);
    
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
            _buildRoleBadge(context, isOwner, isAdmin),
          ]
        ],
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              onSelected: (value) => _handleAction(value, member, service, isAdmin),
              itemBuilder: (context) => [
                // Opción Promover/Degradar
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
                        Text(isAdmin ? l10n.removeAdminAction : l10n.makeAdminAction),
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
                      Text(l10n.removeMemberAction, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildRoleBadge(BuildContext context, bool isOwner, bool isAdmin) {
    final l10n = AppLocalizations.of(context)!;
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
        isOwner ? l10n.ownerRole : l10n.adminRole,
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
    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    
    if (action == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.removeMemberTitle),
          content: Text('${l10n.removeMemberConfirmPart1} ${member.name} ${l10n.removeMemberConfirmPart2}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.removeMemberAction),
            ),
          ],
        ),
      );

      if (confirm == true) {
        success = await service.removeMember(member.uid);
      } else {
        return;
      }
    } 
    else if (action == 'promote') {
      success = await service.promoteToAdmin(member.uid);
    } 
    else if (action == 'demote') {
      success = await service.demoteFromAdmin(member.uid);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.updateMemberError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}