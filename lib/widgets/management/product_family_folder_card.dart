// lib/widgets/management/family_folder_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_catalog_model.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/organization_member_service.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/catalog/product_catalog_detail_screen.dart';
import '../../screens/catalog/create_product_catalog_screen.dart';
import '../../models/user_model.dart';

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
  State<ProductFamilyFolderCard> createState() => _ProductFamilyFolderCardState();
}

class _ProductFamilyFolderCardState extends State<ProductFamilyFolderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;
    final accentColor = widget.accentColor ?? theme.colorScheme.secondary;

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
                    widget.familyName.isNotEmpty
                        ? widget.familyName[0].toUpperCase() + widget.familyName.substring(1)
                        : widget.familyName,
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
              FutureBuilder<bool>(
                future: _canManageProducts(context, user),
                builder: (context, permissionSnapshot) {
                  final canManageProducts = permissionSnapshot.data ?? false;
                  
                  return Column(
                    children: [
                      // Botón de crear producto (al inicio si tiene permisos)
                      if (canManageProducts)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200, width: 0.5),
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
                                      organizationId: user.organizationId!,
                                      currentUser: user,
                                      initialClientId: widget.client.id,
                                      initialProjectId: widget.project.id,
                                      initialFamily: widget.familyName != 'Sin categoría' 
                                          ? widget.familyName 
                                          : null,
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
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(color: accentColor.withOpacity(0.4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Lista de productos
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: canManageProducts 
                              ? null 
                              : Border(
                                  top: BorderSide(color: Colors.grey.shade200, width: 0.5),
                                ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.products.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 48,
                          ),
                          itemBuilder: (context, index) {
                            return _buildProductListTile(
                              context,
                              widget.products[index],
                              user,
                              l10n,
                              accentColor,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _canManageProducts(BuildContext context, UserModel user) async {
    try {
      final memberService = Provider.of<OrganizationMemberService>(context, listen: false);
      await memberService.getCurrentMember(user.organizationId!, user.uid);
      return await memberService.can('product_catalog', 'create');
    } catch (e) {
      return false;
    }
  }

  Widget _buildProductListTile(
    BuildContext context,
    ProductCatalogModel product,
    dynamic user,
    AppLocalizations l10n,
    Color accentColor,
  ) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
      leading: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: 16,
          color: accentColor,
        ),
      ),
      title: Text(
        '${l10n.skuLabel} ${product.reference}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.keyboard_arrow_right,
        size: 16,
        color: Colors.grey.shade400,
      ),
    );
  }
}