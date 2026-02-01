// lib/screens/management/management_folders_view.dart
// ✅ OPTIMIZADO: Recibe lista de clientes como parámetro en lugar de hacer query

import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/clients/client_form_screen.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/management_view_types.dart';
import '../../widgets/management/client_folder_card.dart';
import '../../widgets/common_refresh.dart';
import '../../providers/production_data_provider.dart';

class ManagementFoldersView extends StatelessWidget {
  final List<ClientModel> clients; // ✅ NUEVO: Lista pre-cargada del provider
  final ManagementFilters filters;
  final VoidCallback onAddClient;

  const ManagementFoldersView({
    Key? key,
    required this.clients, // ✅ NUEVO: Recibe datos del provider
    required this.filters,
    required this.onAddClient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final permissionService = Provider.of<PermissionService>(context);
    final canCreateClients = permissionService.canCreateClients;

    // ✅ OPTIMIZACIÓN: Filtrado local de la lista recibida
    var filteredClients = clients;

    // Aplicar filtros
    if (filters.clientId != null) {
      filteredClients =
          filteredClients.where((c) => c.id == filters.clientId).toList();
    }

    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      filteredClients = filteredClients.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.company.toLowerCase().contains(query) ||
            (c.email.toLowerCase().contains(query));
      }).toList();
    }

    if (filteredClients.isEmpty) {
      return CommonRefresh(
        onRefresh: () async {
          // ✅ OPTIMIZACIÓN: Refrescar desde el provider
          final provider = Provider.of<ProductionDataProvider>(
            context,
            listen: false,
          );
          await provider.refresh();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                filters.hasActiveFilters
                    ? l10n.noResultsFound
                    : l10n.noClientsFound,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CommonRefresh(
      onRefresh: () async {
        // ✅ OPTIMIZACIÓN: Refrescar desde el provider
        final provider =
            Provider.of<ProductionDataProvider>(context, listen: false);
        await provider.refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: (canCreateClients ? 1 : 0) + filteredClients.length,
        itemBuilder: (context, index) {
          // Botón de crear cliente al inicio (solo si tiene permisos)
          if (canCreateClients && index == 0) {
            return _buildCreateClientButton(context, l10n);
          }
          // Ajustar índice si hay botón de crear
          final clientIndex = canCreateClients ? index - 1 : index;

          final client = filteredClients[clientIndex];
          return ClientFolderCard(
            client: client,
          );
        },
      ),
    );
  }

  Widget _buildCreateClientButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientFormScreen(),
            ),
          );
        },
        icon: Icon(Icons.add, color: theme.colorScheme.primary),
        label: Text(
          l10n.createClient,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
