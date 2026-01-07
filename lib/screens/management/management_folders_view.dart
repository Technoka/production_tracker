// lib/screens/management/management_folders_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../models/product_catalog_model.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/product_catalog_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/management_view_types.dart';
import '../../widgets/management/client_folder_card.dart';
import '../../widgets/common_refresh.dart';

class ManagementFoldersView extends StatelessWidget {
  final ManagementFilters filters;
  final VoidCallback onAddClient;

  const ManagementFoldersView({
    Key? key,
    required this.filters,
    required this.onAddClient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    return StreamBuilder<List<ClientModel>>(
      stream: Provider.of<ClientService>(context, listen: false)
          .watchClients(user.organizationId!),
      builder: (context, clientSnapshot) {
        if (clientSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var clients = clientSnapshot.data ?? [];

        // Aplicar filtros
        if (filters.clientId != null) {
          clients = clients.where((c) => c.id == filters.clientId).toList();
        }

        if (filters.searchQuery.isNotEmpty) {
          final query = filters.searchQuery.toLowerCase();
          clients = clients.where((c) {
            return c.name.toLowerCase().contains(query) ||
                c.company.toLowerCase().contains(query) ||
                (c.email?.toLowerCase().contains(query) ?? false);
          }).toList();
        }

        if (clients.isEmpty) {
          return CommonRefresh(
            onRefresh: () async {
              await Provider.of<ClientService>(context, listen: false)
                  .getOrganizationClients(user.organizationId!);
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
                        : l10n.noClientsRegistered,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!filters.hasActiveFilters)
                    Text(
                      l10n.tapToAddClient,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return CommonRefresh(
          onRefresh: () async {
            await Provider.of<ClientService>(context, listen: false)
                .getOrganizationClients(user.organizationId!);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              return FutureBuilder<_ClientStats>(
                future: _getClientStats(
                  context,
                  user.organizationId!,
                  clients[index].id,
                  filters,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    );
                  }

                  final stats = snapshot.data ?? _ClientStats(0, 0);

                  return ClientFolderCard(
                    client: clients[index],
                    urgentProductsCount: stats.urgentCount,
                    totalProductsCount: stats.totalProducts,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<_ClientStats> _getClientStats(
    BuildContext context,
    String organizationId,
    String clientId,
    ManagementFilters filters,
  ) async {
    try {
      final clientService = Provider.of<ClientService>(context, listen: false);
      final productService = Provider.of<ProductCatalogService>(context, listen: false);

      // Obtener proyectos del cliente
      var projects = await clientService
          .getClientProjects(organizationId, clientId)
          .first;

      int totalProducts = 0;
      int urgentCount = 0;

      // Contar productos por proyecto
      for (final project in projects) {
        try {
          final products = await productService
              .getProjectProducts(organizationId, project.id)
              .first;

          totalProducts += products.length;
          
          // Si tienes lógica de urgencia, aplicarla aquí
          if (filters.onlyUrgent) {
            urgentCount = 0;
            // urgentCount += productos urgentes
          }
        } catch (e) {
          continue;
        }
      }

      return _ClientStats(
        totalProducts,
        urgentCount,
      );
    } catch (e) {
      return _ClientStats(
        0,
        0,
      );
    }
  }
}

class _ClientStats {
  final int totalProducts;
  final int urgentCount;

  _ClientStats(this.totalProducts, this.urgentCount);
}