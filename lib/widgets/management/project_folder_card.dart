// lib/widgets/management/project_folder_card.dart

import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/projects/edit_project_screen.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../models/product_catalog_model.dart';
import '../../services/auth_service.dart';
import '../../services/product_catalog_service.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/projects/project_detail_screen.dart';
import '../../screens/catalog/product_catalog_detail_screen.dart';

class ProjectFolderCard extends StatefulWidget {
  final ProjectModel project;
  final ClientModel client;

  const ProjectFolderCard({
    Key? key,
    required this.project,
    required this.client,
  }) : super(key: key);

  @override
  State<ProjectFolderCard> createState() => _ProjectFolderCardState();
}

class _ProjectFolderCardState extends State<ProjectFolderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: _isExpanded
                ? theme.colorScheme.primary.withOpacity(0.2)
                : Colors.grey.shade300,
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: StreamBuilder<List<ProductCatalogModel>>(
            stream: Provider.of<ProductCatalogService>(context, listen: false)
                .getClientProductsStream(user.organizationId!, widget.client.id),
            builder: (context, productSnapshot) {
              final products = productSnapshot.data ?? [];
              final productCount = products.length;
              
              // Calcular progreso (simulado, ajustar según tu lógica)
              final progress = productCount > 0 ? 65.0 : 0.0;

              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                childrenPadding: EdgeInsets.zero,
                onExpansionChanged: (expanded) {
                  setState(() => _isExpanded = expanded);
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                          children: [
                    Text(
                      widget.project.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                            _buildActionButton(
                              icon: Icons.visibility_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProjectDetailScreen(
                              projectId: widget.project.id,
                            ),
                                  ),
                                );
                              },
                              theme: theme,
                              tooltip: l10n.viewDetailsTooltip,
                            ),
                            _buildActionButton(
                              icon: Icons.edit_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProjectScreen(project: widget.project),
                                  ),
                                );
                              },
                              theme: theme,
                              tooltip: l10n.edit,
                            ),

                            // Flecha de expansión
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.grey.shade400,
                              size: 18,
                            ),
                          ]
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.widgets_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$productCount ${l10n.products}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                children: [
                  if (products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noProductsInProject,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          return _buildProductListTile(
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
          ),
        ),
      ),
    );
  }

  Widget _buildProductListTile(
    BuildContext context,
    ProductCatalogModel product,
    dynamic user,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.tag,
            size: 11,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(
            product.reference,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 14),
        onPressed: () {
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
        tooltip: l10n.viewDetailsTooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

    // Widget auxiliar para botones de acción compactos
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required String tooltip,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: theme.primaryColor.withOpacity(0.7)),
        tooltip: tooltip,
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }
}