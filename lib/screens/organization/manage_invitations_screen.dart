import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/invitation_service.dart';
import '../../services/role_service.dart';
import '../../models/invitation_model.dart';
import 'create_invitation_screen.dart';

/// Pantalla para gestionar invitaciones activas y expiradas
class ManageInvitationsScreen extends StatelessWidget {
  final String organizationId;
  final String organizationName;

  const ManageInvitationsScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  Future<void> _handleRevoke(
    BuildContext context,
    InvitationModel invitation,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revokeInvitationAction),
        content: Text(l10n.revokeInvitationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.revokeInvitationAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final invitationService =
        Provider.of<InvitationService>(context, listen: false);

    final success = await invitationService.revokeInvitation(
      invitationId: invitation.id,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invitationRevokedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(invitationService.error ?? l10n.error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    InvitationModel invitation,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteInvitationAction),
        content: Text(l10n.deleteInvitationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final invitationService =
        Provider.of<InvitationService>(context, listen: false);

    final success = await invitationService.deleteInvitation(
      invitationId: invitation.id,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invitationDeletedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(invitationService.error ?? l10n.error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invitationService = Provider.of<InvitationService>(context);
    final roleService = Provider.of<RoleService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageInvitationsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateInvitationScreen(
                    organizationId: organizationId,
                    organizationName: organizationName,
                  ),
                ),
              );
            },
            tooltip: l10n.createInvitationTitle,
          ),
        ],
      ),
      body: StreamBuilder<List<InvitationModel>>(
        stream: invitationService.watchActiveInvitations(organizationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noActiveInvitations,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateInvitationScreen(
                            organizationId: organizationId,
                            organizationName: organizationName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createInvitationButton),
                  ),
                ],
              ),
            );
          }

          final invitations = snapshot.data!;

          // Separar activas y expiradas
          final activeInvitations =
              invitations.where((inv) => inv.canBeUsed).toList();
          final expiredInvitations =
              invitations.where((inv) => !inv.canBeUsed).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Invitaciones activas
              if (activeInvitations.isNotEmpty) ...[
                Text(
                  l10n.activeInvitationsSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...activeInvitations.map((invitation) => _buildInvitationCard(
                      context,
                      invitation,
                      roleService,
                      l10n,
                      isActive: true,
                    )),
                const SizedBox(height: 24),
              ],

              // Invitaciones expiradas
              if (expiredInvitations.isNotEmpty) ...[
                Text(
                  l10n.expiredInvitationsSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 12),
                ...expiredInvitations.map((invitation) => _buildInvitationCard(
                      context,
                      invitation,
                      roleService,
                      l10n,
                      isActive: false,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildInvitationCard(
    BuildContext context,
    InvitationModel invitation,
    RoleService roleService,
    AppLocalizations l10n, {
    required bool isActive,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Código e icono de estado
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue[50] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? Colors.blue[200]!
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: Text(
                          invitation.code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                            color:
                                isActive ? Colors.blue[900] : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: invitation.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.invitationCodeCopied)),
                          );
                        },
                        tooltip: l10n.copyInvitationCode,
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      invitation.isExpired ? l10n.expired : l10n.revoked,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Rol
            FutureBuilder(
              future:
                  roleService.getRoleById(organizationId, invitation.roleId),
              builder: (context, snapshot) {
                final roleName = snapshot.data?.name ?? invitation.roleId;
                return Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.invitationRole}: ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      roleName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (invitation.clientName != null) ...[
                      Text(
                        ' (${invitation.clientName})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 4),

            // Descripción (si existe)
            if (invitation.description != null &&
                invitation.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                invitation.description!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Info: usos y expiración
            Row(
              children: [
                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${l10n.invitationUses}: ${invitation.usedCount}/${invitation.maxUses}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${l10n.invitationExpires}: ${dateFormat.format(invitation.expiresAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            // Acciones
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleRevoke(context, invitation),
                    icon: const Icon(Icons.block, size: 18),
                    label: Text(l10n.revokeInvitationAction),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _handleDelete(context, invitation),
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(l10n.deleteInvitationAction),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _handleDelete(context, invitation),
                  icon: const Icon(Icons.delete, size: 18),
                  label: Text(l10n.deleteInvitationAction),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
