// lib/widgets/management/project_folder_card.dart
// ✅ OPTIMIZADO: Usa ProductionDataProvider para estadísticas Y productos de catálogo

import 'package:flutter/material.dart';
import 'package:gestion_produccion/models/product_catalog_model.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import '../../providers/production_data_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/projects/project_detail_screen.dart';
import '../../screens/catalog/create_product_catalog_screen.dart';
import '../../screens/projects/edit_project_screen.dart';
import 'product_family_folder_card.dart';
import '../../models/permission_registry_model.dart';

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

  // Colores alternados para familias
  final familyColors = [
    Colors.green,
    Colors.teal,
    Colors.purple,
    Colors.orange,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;
    final permissionService = Provider.of<PermissionService>(context);

    // ✅ OPTIMIZACIÓN: Obtener estadísticas del provider
    final productionProvider = Provider.of<ProductionDataProvider>(context);
    final stats = productionProvider.getProjectStats(widget.project.id);
    final familyCount = stats['familiesCount'] ?? 0;
    final catalogProductCount = stats['catalogProductsCount'] ?? 0;

    // ✅ OPTIMIZACIÓN: Obtener productos del provider (sin StreamBuilder)
    final allProducts = productionProvider.filterCatalogProducts(
      projectId: widget.project.id,
    );

    // Agrupar productos por familia
    final Map<String, List<ProductCatalogModel>> productsByFamily = {};
    for (final product in allProducts) {
      final family = product.family ?? 'Sin categoría';
      productsByFamily.putIfAbsent(family, () => []).add(product);
    }

    // ✅ OPTIMIZACIÓN: Verificar permisos usando el servicio
    final canEditProject = _checkProjectPermission(
      permissionService,
      user.uid,
      'projects',
      'edit',
    );

    bool canViewProject = _checkProjectPermission(
      permissionService,
      user.uid,
      'projects',
      'view',
    );

    // Si es cliente y este proyecto le pertenece, puede verlo
    if (permissionService.currentMember?.roleId == 'client' &&
        widget.project.clientId == permissionService.currentMember?.clientId) {
      canViewProject = true;
    }

    final canCreateProducts = permissionService.canCreateCatalogProducts;

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
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
            trailing: const SizedBox.shrink(),
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
                // --- FILA 1: NOMBRE + ICONOS ---
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

                    // Icono VER (Solo si tiene permiso projects.view)
                    if (canViewProject)
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

                    // Icono EDITAR (Solo si tiene permiso projects.edit)
                    if (canEditProject)
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProjectScreen(
                                project: widget.project,
                              ),
                            ),
                          );
                        },
                        theme: theme,
                        tooltip: l10n.edit,
                      ),

                    const SizedBox(width: 4),

                    // Flecha de expansión
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.primary.withOpacity(0.7),
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
                      '$catalogProductCount ${l10n.products}',
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
              // Botón crear producto
              if (canCreateProducts)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateProductCatalogScreen(
                              initialClientId: widget.client.id,
                              initialProjectId: widget.project.id,
                              createNewFamily: true,
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),

              // Lista de familias
              if (productsByFamily.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      l10n.noProductsInProject,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else ...[
                // Usamos spread operator (...) con una lista generada
                ...productsByFamily.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((mapEntry) {
                  // 1. Extraemos el índice y los datos reales
                  final index = mapEntry.key;
                  final entry = mapEntry.value;

                  // 3. Calculamos el color basado en el índice
                  final color = familyColors[index % familyColors.length];

                  return ProductFamilyFolderCard(
                    familyName: entry.key,
                    products: entry.value,
                    // Aquí usamos el color calculado en vez del fijo del cliente
                    accentColor: color,
                    client: widget.client,
                    project: widget.project,
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Helper sincrónico para verificar permisos de proyecto
  bool _checkProjectPermission(
    PermissionService service,
    String userId,
    String module,
    String action,
  ) {
    final permissions = service.effectivePermissions;
    if (permissions == null) return false;

    // Verificar si tiene permiso booleano base
    if (!permissions.dynamicHelper.can(module, action)) return false;

    final scope = permissions.getScope(module, action);

    // Si tiene scope "all", puede acceder a cualquier proyecto
    if (scope == PermissionScope.all) {
      return true;
    }

    // Si tiene scope "assigned", verificar si está asignado a este proyecto
    if (scope == PermissionScope.assigned) {
      return widget.project.assignedMembers.contains(userId);
    }

    // Scope "none"
    return false;
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required String tooltip,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        tooltip: tooltip,
        onPressed: onTap,
        splashRadius: 16,
      ),
    );
  }
}
