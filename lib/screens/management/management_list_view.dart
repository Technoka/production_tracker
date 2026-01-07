// lib/screens/management/management_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/project_service.dart';
import '../../services/product_catalog_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/management_view_types.dart';
import '../../widgets/common_refresh.dart';
import '../clients/client_detail_screen.dart';
import '../clients/edit_client_screen.dart';
import '../projects/project_detail_screen.dart';
import '../projects/edit_project_screen.dart';
import '../catalog/product_catalog_detail_screen.dart';

class ManagementListView extends StatelessWidget {
  final ManagementTab currentTab;
  final ManagementFilters filters;
  final void Function(ClientModel) onOpenClientTab;
  final void Function(ProjectModel, String) onOpenProjectTab;
  final void Function(String familyName, String projectId, String clientId) onOpenFamilyTab;

  const ManagementListView({
    Key? key,
    required this.currentTab,
    required this.filters,
    required this.onOpenClientTab,
    required this.onOpenProjectTab,
    required this.onOpenFamilyTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (currentTab.type) {
      case ManagementTabType.general:
        return _GeneralTabView(
          filters: filters,
          onOpenClientTab: onOpenClientTab,
        );
      case ManagementTabType.client:
        return _ClientTabView(
          clientId: currentTab.clientId!,
          filters: filters,
          onOpenProjectTab: (project) =>
              onOpenProjectTab(project, currentTab.clientId!),
        );
      case ManagementTabType.project:
        return _ProjectTabView(
          projectId: currentTab.projectId!,
          clientId: currentTab.clientId!,
          filters: filters,
          onOpenFamilyTab: (familyName) =>
              onOpenFamilyTab(familyName, currentTab.projectId!, currentTab.clientId!),
        );
      case ManagementTabType.family:
        return _FamilyTabView(
          familyName: currentTab.familyName!,
          projectId: currentTab.projectId!,
          clientId: currentTab.clientId!,
          filters: filters,
        );
    }
  }
}

// ==================== GENERAL TAB ====================

class _GeneralTabView extends StatelessWidget {
  final ManagementFilters filters;
  final void Function(ClientModel) onOpenClientTab;

  const _GeneralTabView({
    required this.filters,
    required this.onOpenClientTab,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    return StreamBuilder<List<ClientModel>>(
      stream: Provider.of<ClientService>(context, listen: false)
          .watchClients(user.organizationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var clients = snapshot.data ?? [];

        // Aplicar filtros
        if (filters.clientId != null) {
          clients = clients.where((c) => c.id == filters.clientId).toList();
        }

        if (filters.searchQuery.isNotEmpty) {
          final query = filters.searchQuery.toLowerCase();
          clients = clients.where((c) {
            return c.name.toLowerCase().contains(query) ||
                c.company.toLowerCase().contains(query);
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
              return _buildClientCard(context, clients[index], user);
            },
          ),
        );
      },
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    ClientModel client,
    UserModel user,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpenClientTab(client),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  client.initials,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.company,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (client.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              client.email!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== FAMILY TAB ====================

class _FamilyTabView extends StatelessWidget {
  final String familyName;
  final String projectId;
  final String clientId;
  final ManagementFilters filters;

  const _FamilyTabView({
    required this.familyName,
    required this.projectId,
    required this.clientId,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    return StreamBuilder<List<ProductCatalogModel>>(
      stream: Provider.of<ProductCatalogService>(context, listen: false)
          .getProjectFamilyProducts(user.organizationId!, projectId, familyName),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = productSnapshot.data ?? [];

        // Aplicar filtros
        if (filters.searchQuery.isNotEmpty) {
          final query = filters.searchQuery.toLowerCase();
          products = products.where((p) {
            return p.name.toLowerCase().contains(query) ||
                p.reference.toLowerCase().contains(query);
          }).toList();
        }

        return Column(
          children: [
            _buildFamilyHeader(context, familyName, products.length, l10n),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noProductsInFamily,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(
                          context,
                          products[index],
                          user,
                          l10n,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFamilyHeader(
    BuildContext context,
    String familyName,
    int productCount,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.category,
              color: theme.colorScheme.secondary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  familyName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.widgets_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$productCount ${l10n.products}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductCatalogModel product,
    UserModel user,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductCatalogDetailScreen(
                productId: product.id,
                currentUser: user,
                organizationId: user.organizationId!,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.tag,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.reference,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CLIENT TAB ====================

class _ClientTabView extends StatelessWidget {
  final String clientId;
  final ManagementFilters filters;
  final void Function(ProjectModel) onOpenProjectTab;

  const _ClientTabView({
    required this.clientId,
    required this.filters,
    required this.onOpenProjectTab,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    return StreamBuilder<ClientModel?>(
      stream: Provider.of<ClientService>(context, listen: false)
          .getClientStream(user.organizationId!, clientId),
      builder: (context, clientSnapshot) {
        if (clientSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final client = clientSnapshot.data;
        if (client == null) {
          return Center(child: Text(l10n.clientNotFound));
        }

        return Column(
          children: [
            _buildClientHeader(context, client, user, l10n),
            Expanded(
              child: StreamBuilder<List<ProjectModel>>(
                stream: Provider.of<ProjectService>(context, listen: false)
                    .watchClientProjects(clientId, user.organizationId!),
                builder: (context, projectSnapshot) {
                  if (projectSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var projects = projectSnapshot.data ?? [];

                  // Aplicar filtros
                  if (filters.searchQuery.isNotEmpty) {
                    final query = filters.searchQuery.toLowerCase();
                    projects = projects.where((p) {
                      return p.name.toLowerCase().contains(query) ||
                          (p.description?.toLowerCase().contains(query) ??
                              false);
                    }).toList();
                  }

                  if (projects.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_off_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noProjectsForClient,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(
                        context,
                        projects[index],
                        user,
                        l10n,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClientHeader(
    BuildContext context,
    ClientModel client,
    UserModel user,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              client.initials,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  client.company,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientDetailScreen(client: client),
                ),
              );
            },
            tooltip: l10n.viewDetailsTooltip,
          ),
          if (user.canManageProduction)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
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
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    ProjectModel project,
    UserModel user,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpenProjectTab(project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (project.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PROJECT TAB ====================

class _ProjectTabView extends StatelessWidget {
  final String projectId;
  final String clientId;
  final ManagementFilters filters;
  final void Function(String) onOpenFamilyTab;

  const _ProjectTabView({
    required this.projectId,
    required this.clientId,
    required this.filters,
    required this.onOpenFamilyTab,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    return StreamBuilder<ProjectModel?>(
      stream: Provider.of<ProjectService>(context, listen: false)
          .watchProject(user.organizationId!, projectId),
      builder: (context, projectSnapshot) {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final project = projectSnapshot.data;
        if (project == null) {
          return Center(child: Text(l10n.projectNotFound));
        }

        return Column(
          children: [
            _buildProjectHeader(context, project, user, l10n),
            Expanded(
              child: StreamBuilder<List<ProductCatalogModel>>(
                stream: Provider.of<ProductCatalogService>(
                  context,
                  listen: false,
                ).getProjectProducts(user.organizationId!, projectId),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var products = productSnapshot.data ?? [];

                  // Aplicar filtros
                  if (filters.searchQuery.isNotEmpty) {
                    final query = filters.searchQuery.toLowerCase();
                    products = products.where((p) {
                      return p.name.toLowerCase().contains(query) ||
                          p.reference.toLowerCase().contains(query);
                    }).toList();
                  }

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noProductsInProject,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(
                        context,
                        products[index],
                        user,
                        l10n,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectHeader(
    BuildContext context,
    ProjectModel project,
    UserModel user,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.folder,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (project.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    project.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailScreen(projectId: project.id),
                ),
              );
            },
            tooltip: l10n.viewDetailsTooltip,
          ),
          if (user.canManageProduction)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProjectScreen(
                      project: project,
                    ),
                  ),
                );
              },
              tooltip: l10n.edit,
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductCatalogModel product,
    UserModel user,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductCatalogDetailScreen(
                productId: product.id,
                currentUser: user,
                organizationId: user.organizationId!,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.tag,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.reference,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}