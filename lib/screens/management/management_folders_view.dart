// lib/screens/management/management_folders_view.dart

import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/clients/client_form_screen.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/product_catalog_service.dart';
import '../../services/organization_member_service.dart';
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
                (c.email.toLowerCase().contains(query));
          }).toList();
        }

        if (clients.isEmpty) {
          return CommonRefresh(
            onRefresh: () async {
              await Provider.of<ClientService>(context, listen: false)
                  .getOrganizationClients(user.organizationId!, user.uid);
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
            await Provider.of<ClientService>(context, listen: false)
                .getOrganizationClients(user.organizationId!, user.uid);
          },
          child: FutureBuilder<bool>(
            future: _canCreateClients(context, user.organizationId!, user.uid),
            builder: (context, permissionSnapshot) {
              final canCreateClients = permissionSnapshot.data ?? false;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (canCreateClients ? 1 : 0) +
                    clients.length +
                    (filters.hasActiveFilters && clients.isEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  // Botón de crear cliente al inicio (solo si tiene permisos)
                  if (canCreateClients && index == 0) {
                    return _buildCreateClientButton(context, l10n);
                  }

                  // Ajustar índice si hay botón de crear
                  final clientIndex = canCreateClients ? index - 1 : index;

                  // Mensaje de "no resultados" si se aplican filtros
                  if (clients.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          l10n.noResultsFound,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }

                  return FutureBuilder<_ClientStats>(
                    future: _getClientStats(
                      context,
                      user.organizationId!,
                      clients[clientIndex].id,
                      user.uid,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        );
                      }

                      final stats = snapshot.data ?? _ClientStats(0, 0, 0);

                      return ClientFolderCard(
                        client: clients[clientIndex],
                        urgentProductsCount: stats.urgentCount,
                        totalProductsCount: stats.totalProducts,
                        projectsCount: stats.projectsCount,
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
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

  Future<bool> _canCreateClients(
      BuildContext context, String organizationId, String userId) async {
    try {
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);
      await memberService.getCurrentMember(organizationId, userId);
      return await memberService.can('clients', 'create');
    } catch (e) {
      return false;
    }
  }

  Future<_ClientStats> _getClientStats(
    BuildContext context,
    String organizationId,
    String clientId,
    String userId,
    ManagementFilters filters,
  ) async {
    try {
      final clientService = Provider.of<ClientService>(context, listen: false);
      final productService = Provider.of<ProductCatalogService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUserData!;

      // Obtener proyectos del cliente
      var projects =
          await clientService.getClientProjectsWithScope(organizationId, clientId, userId);

      int totalProducts = 0;
      int urgentCount = 0;
      int projectsCount = projects.length;
      print("Projects count: $projectsCount");

      // Contar productos por proyecto
      for (final project in projects) {
        try {
          final products = await productService
              .getProjectProductsStream(organizationId, project.id, user.clientId)
              .first;

          totalProducts += products.length;

        } catch (e) {
          continue;
        }
      }

      return _ClientStats(
        totalProducts,
        urgentCount,
        projectsCount,
      );
    } catch (e) {
      return _ClientStats(0, 0, 0);
    }
  }
}

class _ClientStats {
  final int totalProducts;
  final int urgentCount;
  final int projectsCount;

  _ClientStats(this.totalProducts, this.urgentCount, this.projectsCount);
}
