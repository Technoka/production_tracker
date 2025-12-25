import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/organization_service.dart';
import '../../services/auth_service.dart';
import '../../models/organization_model.dart';

class PendingInvitationsScreen extends StatelessWidget {
  const PendingInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final organizationService = Provider.of<OrganizationService>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitaciones Pendientes'),
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
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                          'No tienes invitaciones pendientes',
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
                                      Text('Invitado por: ${invitation.invitedByName}'),
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
                                    child: const Text('Rechazar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: organizationService.isLoading
                                        ? null
                                        : () => _handleAccept(context, organizationService, authService, invitation),
                                    child: const Text('Aceptar'),
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
  InvitationModel invitation, // <--- Asegúrate de que este nombre sea exacto
) async {
  // Debug: imprime para verificar que el objeto tiene el dato
  print('Aceptando invitacion para org: ${invitation.organizationId}');

  final success = await service.acceptInvitation(
    invitationId: invitation.id,
    userId: auth.currentUser!.uid,
  );

    if (success && context.mounted) {
      // Recargamos los datos del usuario para que el Home detecte la nueva organizationId
      await auth.getUserData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te has unido a ${invitation.organizationName}')),
        );
        Navigator.pop(context); // Volver al home
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    OrganizationService service,
    String invitationId,
  ) async {
    final success = await service.rejectInvitation(invitationId);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación rechazada')),
      );
    }
  }
}