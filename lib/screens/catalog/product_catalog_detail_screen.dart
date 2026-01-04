import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../utils/role_utils.dart';
import 'edit_product_catalog_screen.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import 'package:provider/provider.dart';

class ProductCatalogDetailScreen extends StatefulWidget {
  final String productId;
  final UserModel currentUser;
  final String organizationId;

  const ProductCatalogDetailScreen({
    super.key,
    required this.productId,
    required this.currentUser,
    required this.organizationId,
  });

  @override
  State<ProductCatalogDetailScreen> createState() =>
      _ProductCatalogDetailScreenState();
}

class _ProductCatalogDetailScreenState
    extends State<ProductCatalogDetailScreen> {
  final ProductCatalogService _catalogService = ProductCatalogService();
  ProductCatalogModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    final product = await _catalogService.getProductById(widget.organizationId, widget.productId);

    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  bool _canManageProducts() {
    return RoleUtils.canManageProducts(widget.currentUser.role);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.productDetailTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.productDetailTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.productNotFound),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productDetailTitle),
        actions: [
          if (_canManageProducts())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductCatalogScreen(
                      product: product,
                      currentUser: widget.currentUser,
                      organizationId: widget.organizationId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadProduct();
                }
              },
            ),
          if (_canManageProducts())
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.content_copy, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.duplicate),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        product.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(product.isActive ? l10n.deactivateProductTitle : l10n.reactivateProductTitle),
                    ],
                  ),
                ),
                if (!product.isActive)
                   PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) async {
                if (value == 'duplicate') {
                  await _duplicateProduct(l10n);
                } else if (value == 'toggle') {
                  await _toggleActive(l10n);
                } else if (value == 'delete') {
                  await _deleteProduct(l10n);
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProduct,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Estado del producto
            if (!product.isActive)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      l10n.productIsInactiveMessage,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Imágenes (placeholder)
            if (product.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(product.imageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Información básica
            _buildSectionTitle(context, l10n.basicInfo),
            _buildInfoCard(context, [
              _buildInfoRow(l10n.productNameLabel.replaceAll(' *', ''), product.name),
              _buildInfoRow(l10n.referenceLabel.replaceAll(' *', ''), product.reference, monospace: true),
              if (!product.isPublic) ...[
                FutureBuilder<ClientModel?>(
                  future: Provider.of<ClientService>(context, listen: false)
                      .getClient(widget.organizationId, product.clientId!),
                  builder: (context, snapshot) {
                    String displayValue = l10n.loading;
                    if (snapshot.hasData && snapshot.data != null) {
                      displayValue = snapshot.data!.name;
                    } else if (snapshot.hasError) {
                      displayValue = l10n.error;
                    }
                    return _buildInfoRow(l10n.client, displayValue);
                  },
                ),
              ],
              if (product.isPublic) _buildInfoRow(l10n.client, l10n.publicProduct),
               _buildInfoRow(l10n.descriptionLabel.replaceAll(' *', ''), product.description),
              if (product.category != null) _buildInfoRow(l10n.categoryLabel, product.category!),
            ]),
            const SizedBox(height: 16),

            // Dimensiones
            if (product.dimensions != null && product.dimensions!.hasAnyDimension) ...[
              _buildSectionTitle(context, l10n.dimensionsLabel('cm')),
              _buildInfoCard(context, [
                if (product.dimensions!.width != null)
                  _buildInfoRow(l10n.widthLabel, '${product.dimensions!.width} cm'),
                if (product.dimensions!.height != null)
                  _buildInfoRow(l10n.heightLabel, '${product.dimensions!.height} cm'),
                if (product.dimensions!.depth != null)
                  _buildInfoRow(l10n.depthLabel, '${product.dimensions!.depth} cm'),
              ]),
              const SizedBox(height: 16),
            ],

            // Material
            if (product.materialInfo != null) ...[
              _buildSectionTitle(context, l10n.materialTitle),
              _buildInfoCard(context, [
                _buildInfoRow(l10n.primaryMaterialLabel,
                    product.materialInfo!.primaryMaterial),
                if (product.materialInfo!.secondaryMaterials.isNotEmpty)
                  _buildInfoRow(l10n.secondaryMaterialsLabel,
                      product.materialInfo!.secondaryMaterials.join(', ')),
                if (product.materialInfo!.finish != null)
                  _buildInfoRow(l10n.finishLabel, product.materialInfo!.finish!),
                if (product.materialInfo!.color != null)
                  _buildInfoRow(l10n.colorLabel, product.materialInfo!.color!),
              ]),
              const SizedBox(height: 16),
            ],

            // Datos adicionales
            _buildSectionTitle(context, l10n.additionalDataTitle),
            _buildInfoCard(context, [
              if (product.estimatedWeight != null)
                _buildInfoRow(l10n.estimatedWeightLabel, '${product.estimatedWeight} kg'),
              if (product.basePrice != null)
                _buildInfoRow(l10n.basePriceLabel,
                    '€ ${product.basePrice!.toStringAsFixed(2)}'),
              _buildInfoRow(l10n.usedLabel, // "Actualizado" / "Used" (contextual, but using placeholder)
                  '${product.usageCount} ${product.usageCount == 1 ? l10n.timeUsageSingle : l10n.timeUsageMultiple}'),
            ]),
            const SizedBox(height: 16),

            // Etiquetas
            if (product.tags.isNotEmpty) ...[
              _buildSectionTitle(context, l10n.tagsLabel),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Notas
            if (product.notes != null && product.notes!.isNotEmpty) ...[
              _buildSectionTitle(context, l10n.notesLabel),
              _buildInfoCard(context, [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    product.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            // Especificaciones (si hay)
            if (product.specifications.isNotEmpty) ...[
              _buildSectionTitle(context, l10n.specifications),
              _buildInfoCard(context,
                  product.specifications.entries.map((entry) {
                return _buildInfoRow(entry.key, entry.value.toString());
              }).toList()),
              const SizedBox(height: 16),
            ],

            // Información de sistema
            _buildSectionTitle(context, l10n.systemInfoTitle),
            _buildInfoCard(context, [
              _buildInfoRow(l10n.createdLabel, dateFormat.format(product.createdAt)),
              _buildInfoRow(l10n.updatedLabel, dateFormat.format(product.updatedAt)),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool monospace = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: monospace ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateProduct(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.duplicateTitle),
        content: Text(l10n.duplicateConfirmMessage(_product!.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.duplicate),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final newId = await _catalogService.duplicateProduct(
      productId: _product!.id,
      createdBy: widget.currentUser.uid,
      organizationId: widget.organizationId,
    );

    if (mounted) {
      if (newId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productDuplicatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductCatalogDetailScreen(
              productId: newId,
              currentUser: widget.currentUser,
              organizationId: widget.organizationId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.duplicateError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            _product!.isActive ? l10n.deactivateProductTitle : l10n.reactivateProductTitle),
        content: Text(
          _product!.isActive
              ? l10n.deactivateProductMessage(_product!.name)
              : l10n.reactivateProductMessage(_product!.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_product!.isActive ? l10n.deactivateProductTitle : l10n.reactivateProductTitle),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = _product!.isActive
        ? await _catalogService.deactivateProduct(
          organizationId: widget.organizationId,
            productId: _product!.id,
            updatedBy: widget.currentUser.uid,
          )
        : await _catalogService.reactivateProduct(
            organizationId: widget.organizationId,
            productId: _product!.id,
            updatedBy: widget.currentUser.uid,
          );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _product!.isActive
                  ? l10n.productDeactivatedSuccess
                  : l10n.productReactivatedSuccess,
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadProduct();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productUpdateError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteConfirmMessage(_product!.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _catalogService.deleteProduct(widget.organizationId, _product!.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}