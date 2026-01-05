import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/organization_service.dart';
import '../../services/auth_service.dart';
import '../../models/organization_model.dart';
import '../../l10n/app_localizations.dart';

class PendingInvitationsScreen extends StatelessWidget {
  const PendingInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final organizationService = Provider.of<OrganizationService>(context);
    final authService = Provider.of<AuthService>(context);
    final l10n = AppLocalizations.of(context)!;
    final user = authService.currentUserData;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pendingInvitationsTitle),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<InvitationModel>>(
              stream: organizationService.getPendingInvitations(user.email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('${l10n.error}: ${snapshot.error}'));
                }

                final invitations = snapshot.data ?? [];

                if (invitations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noPendingInvitations,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: invitations.length,
                  itemBuilder: (context, index) {
                    final invitation = invitations[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.business, color: Colors.blue[700]),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invitation.organizationName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text('${l10n.invitedByLabel} ${invitation.invitedByName}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: organizationService.isLoading
                                        ? null
                                        : () => _handleReject(context, organizationService, invitation.id),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    child: Text(l10n.rejectAction),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: organizationService.isLoading
                                        ? null
                                        : () => _handleAccept(context, organizationService, authService, invitation),
                                    child: Text(l10n.acceptAction),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    OrganizationService service,
    AuthService auth,
    InvitationModel invitation,
  ) async {
    final success = await service.acceptInvitation(
      context: context,
      invitationId: invitation.id,
      userId: auth.currentUser!.uid,
    );

    if (success && context.mounted) {
      await auth.loadUserData();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/organization_home',
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    OrganizationService service,
    String invitationId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await service.rejectInvitation(invitationId);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invitationRejectedMsg)),
      );
    }
  }
}