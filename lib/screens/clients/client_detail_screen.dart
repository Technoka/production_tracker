import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Importante para las fechas
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../models/client_model.dart';
import 'edit_client_screen.dart';
import '../../widgets/common_refresh.dart';

class ClientDetailScreen extends StatelessWidget {
  final ClientModel client;

  const ClientDetailScreen({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final clientService = context.watch<ClientService>();
    final l10n = AppLocalizations.of(context)!;
    
    final user = authService.currentUserData;
    final organizationId = authService.currentUserData?.organizationId;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canEdit = user.canManageProduction;
    final canDelete = user.hasAdminAccess;

    Future<void> handleRefresh() async {
      if (user.organizationId != null) {
        await clientService.getOrganizationClients(user.organizationId!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientDetailTitle),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditClientScreen(client: client),
                  ),
                );
              },
              tooltip: l10n.edit,
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context, clientService, organizationId, l10n),
              tooltip: l10n.delete,
            ),
        ],
      ),
      body: CommonRefresh(
        onRefresh: handleRefresh,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header con avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      client.initials,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    client.company,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Información
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, l10n.contactInfoSection),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    children: [
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        label: l10n.email,
                        value: client.email,
                        onTap: () => _copyToClipboard(context, client.email, l10n),
                      ),
                      if (client.hasPhone) ...[
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: l10n.phoneLabel,
                          value: client.phone!,
                          onTap: () => _copyToClipboard(context, client.phone!, l10n),
                        ),
                      ],
                    ],
                  ),

                  if (client.hasAddress || client.hasCity || client.hasPostalCode || client.hasCountry) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, l10n.addressLabel),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context,
                      children: [
                        if (client.address != null)
                          _buildInfoTile(
                            icon: Icons.location_on_outlined,
                            label: l10n.addressLabel,
                            value: client.address!,
                          ),
                        if (client.city != null || client.postalCode != null) ...[
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.location_city,
                            label: l10n.cityZipLabel,
                            value:
                                '${client.city ?? ', '} ${client.postalCode ?? ''}'
                                    .trim(),
                          ),
                        ],
                        if (client.country != null) ...[
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.public,
                            label: l10n.countryLabel,
                            value: client.country!,
                          ),
                        ],
                      ],
                    ),
                  ],

                  if (client.hasNotes) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, l10n.notesSection),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          client.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, l10n.registrationInfoSection),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    children: [
                      _buildInfoTile(
                        icon: Icons.calendar_today,
                        label: l10n.creationDateLabel,
                        value: _formatDate(client.createdAt, l10n.localeName),
                      ),
                      if (client.updatedAt != null) ...[
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.update,
                          label: l10n.lastUpdateLabel,
                          value: _formatDate(client.updatedAt!, l10n.localeName),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.copy, size: 20, color: Colors.grey[400])
          : null,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date, String locale) {
    // Usa DateFormat.yMMMMd para obtener "5 de enero de 2024" o "January 5, 2024"
    return DateFormat.yMMMMd(locale).format(date);
  }

  void _copyToClipboard(BuildContext context, String text, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ClientService clientService, String? organizationId, AppLocalizations l10n) {
    if (organizationId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.error),
          content: Text(l10n.cantDeleteClientError),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteClientTitle),
        content: Text(l10n.deleteClientConfirm(client.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await clientService.deleteClient(organizationId, client.id);
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.clientDeleted),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        clientService.error ?? l10n.deleteClientError,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}