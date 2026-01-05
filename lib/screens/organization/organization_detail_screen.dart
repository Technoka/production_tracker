import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/organization/organization_settings_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import '../../models/organization_model.dart';
import 'organization_members_screen.dart';
import 'invite_member_screen.dart';
import 'manage_phases_screen.dart';
import '../../l10n/app_localizations.dart';

class OrganizationDetailScreen extends StatelessWidget {

  const OrganizationDetailScreen({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final organizationService = Provider.of<OrganizationService>(context);
    final organization = organizationService.currentOrganization;
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    if (user == null || organization == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner = organization.isOwner(user.uid);
    final isAdmin = organization.isAdmin(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrganizationTitle),
      ),
      body: StreamBuilder<OrganizationModel?>(
        stream: organizationService.watchOrganization(organization.id),
        builder: (context, snapshot) {
          final org = snapshot.data ?? organization;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
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
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estadísticas
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.people,
                              label: l10n.members,
                              value: '${org.totalMembers}',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.admin_panel_settings,
                              label: l10n.adminsLabel,
                              value: '${org.totalAdmins}',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Código de invitación
                      Text(
                        l10n.inviteCodeTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.vpn_key),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.shareCodeLabel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          org.inviteCode,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: org.inviteCode),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.codeCopied),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    tooltip: l10n.copyCodeTooltip,
                                  ),
                                ],
                              ),
                              if (isAdmin) ...[
                                const Divider(height: 24),
                                TextButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(l10n.regenerateCodeAction),
                                        content: Text(
                                          l10n.regenerateCodeWarning,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(l10n.cancel),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(l10n.regenerateBtn),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true && context.mounted) {
                                      final newCode = await organizationService
                                          .regenerateInviteCode(org.id);
                                      if (newCode != null &&
                                          context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text(l10n.codeRegeneratedSuccess),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: Text(l10n.regenerateCodeAction),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Acciones rápidas
                      Text(
                        l10n.actionsTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            
                      // Añadir botón para gestionar fases
                          ListTile(
                            leading: const Icon(Icons.format_list_numbered),
                            title: Text(l10n.managePhasesTitle),
                            subtitle: Text(l10n.managePhasesSubtitle),
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

                              const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.people),
                              title: Text(l10n.viewMembersAction),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OrganizationMembersScreen(),
                                  ),
                                );
                              },
                            ),
                            if (isAdmin) ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.person_add),
                                title: Text(l10n.inviteMemberAction),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const InviteMemberScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
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
                            if (!isOwner) ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: Icon(Icons.exit_to_app,
                                    color: Colors.red[700]),
                                title: Text(
                                  l10n.leaveOrganizationAction,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                                onTap: () => _showLeaveDialog(
                                  context,
                                  organizationService,
                                  user.uid,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(
    BuildContext context,
    OrganizationService organizationService,
    String userId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveOrganizationAction),
        content: Text(l10n.leaveOrganizationWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await organizationService.leaveOrganization(userId);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.leaveOrganizationSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.exitButton),
          ),
        ],
      ),
    );
  }
}