import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:gestion_produccion/widgets/common_refresh.dart';
import 'package:provider/provider.dart';
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
    
    final user = authService.currentUserData;
    final organizationId = authService.currentUserData?.organizationId;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canEdit = user.canManageProduction;
    final canDelete = user.hasAdminAccess;

      // Función para recargar los datos del perfil
    Future<void> handleRefresh() async {
      // Usamos listen: false porque estamos dentro de una función asíncrona
      if (user.organizationId != null) {
        await clientService.getOrganizationClients(user.organizationId!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Cliente'),
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
              tooltip: 'Editar',
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context, clientService, organizationId),
              tooltip: 'Eliminar',
            ),
        ],
      ),
      body: CommonRefresh(
        onRefresh: handleRefresh,
        child: SingleChildScrollView(
        // IMPORTANTE: Esto permite hacer scroll (y refresh) aunque el contenido sea corto
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
                  _buildSectionTitle(context, 'Información de Contacto'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    children: [
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Correo electrónico',
                        value: client.email,
                        onTap: () => _copyToClipboard(context, client.email),
                      ),
                      if (client.hasPhone) ...[
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: client.phone!,
                          onTap: () => _copyToClipboard(context, client.phone!),
                        ),
                      ],
                    ],
                  ),

                  if (client.hasAddress || client.hasCity || client.hasPostalCode || client.hasCountry) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Dirección'),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context,
                      children: [
                        if (client.address != null)
                          _buildInfoTile(
                            icon: Icons.location_on_outlined,
                            label: 'Dirección',
                            value: client.address!,
                          ),
                        if (client.city != null || client.postalCode != null) ...[
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.location_city,
                            label: 'Ciudad / C.P.',
                            value:
                                '${client.city ?? ', '} ${client.postalCode ?? ''}'
                                    .trim(),
                          ),
                        ],
                        if (client.country != null) ...[
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.public,
                            label: 'País',
                            value: client.country!,
                          ),
                        ],
                      ],
                    ),
                  ],

                  if (client.hasNotes) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Notas'),
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
                  _buildSectionTitle(context, 'Información del Registro'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    children: [
                      _buildInfoTile(
                        icon: Icons.calendar_today,
                        label: 'Fecha de creación',
                        value: _formatDate(client.createdAt),
                      ),
                      if (client.updatedAt != null) ...[
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.update,
                          label: 'Última actualización',
                          value: _formatDate(client.updatedAt!),
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

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ClientService clientService, String? organizationId) {
    if (organizationId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('No se puede eliminar el cliente. Organización no encontrada.'),
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
        title: const Text('Eliminar Cliente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${client.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await clientService.deleteClient(organizationId, client.id);
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        clientService.error ?? 'Error al eliminar cliente',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}