// lib/widgets/management/project_folder_card.dart

import 'package:flutter/material.dart';
import 'package:gestion_produccion/models/user_model.dart';
import 'package:gestion_produccion/screens/projects/edit_project_screen.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../models/product_catalog_model.dart';
import '../../services/auth_service.dart';
import '../../services/product_catalog_service.dart';
import '../../services/organization_member_service.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/projects/project_detail_screen.dart';
import '../../screens/catalog/create_product_catalog_screen.dart';
import 'product_family_folder_card.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
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
                .getProjectProducts(user.organizationId!, widget.project.id),
            builder: (context, productSnapshot) {
              final allProducts = productSnapshot.data ?? [];

              // Agrupar productos por familia
              final Map<String, List<ProductCatalogModel>> productsByFamily =
                  {};
              for (final product in allProducts) {
                final family = product.family ?? 'Sin categoría';
                productsByFamily.putIfAbsent(family, () => []).add(product);
              }

              final productCount = allProducts.length;
              final familyCount = productsByFamily.keys.length;

              return ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                childrenPadding: EdgeInsets.zero,
                onExpansionChanged: (expanded) {
                  setState(() => _isExpanded = expanded);
                },
                trailing: const SizedBox.shrink(),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                    FutureBuilder<bool>(
                      future: _canEditProjects(context, user),
                      builder: (context, permissionSnapshot) {
                        final canEditProjects =
                            permissionSnapshot.data ?? false;
                        return Column(
                          children: [
                            // --- FILA 1: NOMBRE + ICONOS (A LA DERECHA DEL TODO) ---
                            Row(
                              children: [
                                // Expanded empuja los iconos al final
                                Expanded(
                                  child: Text(
                                    widget.project.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Iconos de acción
                                _buildActionButton(
                                  icon: Icons.visibility_outlined,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProjectDetailScreen(
                                          projectId: widget.project.id,
                                        ),
                                      ),
                                    );
                                  },
                                  theme: theme,
                                  tooltip: l10n.viewDetailsTooltip,
                                ),
                                if (canEditProjects)
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProjectScreen(
                                                  project: widget.project),
                                        ),
                                      );
                                    },
                                    theme: theme,
                                    tooltip: l10n.edit,
                                  ),
                                const SizedBox(width: 4),

                                // Tu flecha personalizada
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.7),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$familyCount ${familyCount == 1 ? l10n.family : l10n.families}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                        );
                      },
                    ),
                  ],
                ),
                children: [
                  FutureBuilder<bool>(
                    future: _canCreateCatalogProducts(context, user),
                    builder: (context, permissionSnapshot) {
                      final canManageProducts =
                          permissionSnapshot.data ?? false;

                      return Column(
                        children: [
                          // Botón de crear familia/producto (al inicio si tiene permisos)
                          if (canManageProducts)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Navegar a crear producto con cliente y proyecto pre-seleccionados
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateProductCatalogScreen(
                                          organizationId: user.organizationId!,
                                          currentUser: user,
                                          initialClientId: widget.client.id,
                                          initialProjectId: widget.project.id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: Text(
                                    l10n.createProductFamily,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.4)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Lista de familias
                          if (allProducts.isEmpty && !canManageProducts)
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
                          else if (allProducts.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: productsByFamily.keys.length,
                                itemBuilder: (context, index) {
                                  final family =
                                      productsByFamily.keys.elementAt(index);
                                  final products = productsByFamily[family]!;

                                  // Colores alternados para familias
                                  final colors = [
                                    theme.colorScheme.secondary,
                                    Colors.teal,
                                    Colors.purple,
                                    Colors.orange,
                                    Colors.indigo,
                                  ];
                                  final color = colors[index % colors.length];

                                  return ProductFamilyFolderCard(
                                    familyName: family,
                                    products: products,
                                    accentColor: color,
                                    client: widget.client,
                                    project: widget.project,
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _canCreateCatalogProducts(
      BuildContext context, UserModel user) async {
    try {
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);
      await memberService.getCurrentMember(user.organizationId!, user.uid);
      return await memberService.can('product_catalog', 'create');
    } catch (e) {
      return false;
    }
  }

  Future<bool> _canEditProjects(BuildContext context, UserModel user) async {
    try {
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);
      await memberService.getCurrentMember(user.organizationId!, user.uid);
      return await memberService.can('projects', 'edit');
    } catch (e) {
      return false;
    }
  }

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
        icon: Icon(icon,
            size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
        tooltip: tooltip,
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }
}
