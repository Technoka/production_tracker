// lib/widgets/management/product_family_folder_card.dart
// ✅ OPTIMIZADO: Usa permisos cacheados del PermissionService

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_catalog_model.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/catalog/product_catalog_detail_screen.dart';
import '../../screens/catalog/create_product_catalog_screen.dart';

class ProductFamilyFolderCard extends StatefulWidget {
  final String familyName;
  final List<ProductCatalogModel> products;
  final Color? accentColor;
  final ClientModel client;
  final ProjectModel project;

  const ProductFamilyFolderCard({
    Key? key,
    required this.familyName,
    required this.products,
    this.accentColor,
    required this.client,
    required this.project,
  }) : super(key: key);

  @override
  State<ProductFamilyFolderCard> createState() =>
      _ProductFamilyFolderCardState();
}

class _ProductFamilyFolderCardState extends State<ProductFamilyFolderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accentColor = widget.accentColor ?? theme.colorScheme.secondary;

    // ✅ OPTIMIZACIÓN: Usar permisos cacheados
    final permissionService = Provider.of<PermissionService>(context);
    final canCreateCatalogProducts = permissionService.canCreateCatalogProducts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _isExpanded
                ? accentColor.withOpacity(0.3)
                : Colors.grey.shade300,
            width: _isExpanded ? 1.5 : 1,
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            childrenPadding: EdgeInsets.zero,
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.category_outlined,
                color: accentColor,
                size: 18,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.familyName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.products.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey.shade400,
              size: 20,
            ),
            children: [
              Column(
                children: [
                  // Botón de crear producto (al inicio si tiene permisos)
                  if (canCreateCatalogProducts)
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
                      padding: const EdgeInsets.all(10),
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
                                  initialFamily: widget.familyName,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.add, size: 14, color: accentColor),
                          label: Text(
                            l10n.createProduct,
                            style: TextStyle(fontSize: 12, color: accentColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(
                              color: accentColor.withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Lista de productos
                  if (widget.products.isEmpty && !canCreateCatalogProducts)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          l10n.noProductsInFamily,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else if (widget.products.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: accentColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: widget.products.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                          indent: 52,
                        ),
                        itemBuilder: (context, index) {
                          final product = widget.products[index];
                          return _buildProductItem(
                            product: product,
                            theme: theme,
                            accentColor: accentColor,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem({
    required ProductCatalogModel product,
    required ThemeData theme,
    required Color accentColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    return InkWell(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Icono del producto
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: accentColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),

            // Info del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.skuLabel} ${product.reference}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),    
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Flecha
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}