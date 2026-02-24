import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/screens/catalog/product_catalog_form_screen.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';

import '../../services/product_catalog_service.dart';

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
  ProductCatalogModel? _product;
  bool _isLoading = true;

  // Variables de estado para permisos pre-calculados
  bool _canEdit = false;
  bool _canDelete = false;
  bool _canDuplicate = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Cargar producto
      final product = dataProvider.getCatalogProductById(widget.productId);

      final canEditCatalogProducts = permissionService.canEditCatalogProducts;
      final canDeleteCatalogProducts =
          permissionService.canDeleteCatalogProducts;
      final canCreateCatalogProducts =
          permissionService.canCreateCatalogProducts;

      if (mounted) {
        setState(() {
          _product = product;
          _canEdit = canEditCatalogProducts;
          _canDelete = canDeleteCatalogProducts;
          _canDuplicate = canCreateCatalogProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return AppScaffold(
        title: l10n.productDetailTitle,
        currentIndex: AppNavIndex.management,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return AppScaffold(
        title: l10n.productDetailTitle,
        currentIndex: AppNavIndex.management,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(l10n.productNotFound),
              const SizedBox(height: 24),
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

    // Verificar si tiene algún permiso para mostrar el menú
    final hasAnyAction = _canEdit || _canDelete || _canDuplicate;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productDetailTitle),
        actions: [
          if (hasAnyAction)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductCatalogFormScreen(
                        product: product,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                } else if (value == 'duplicate') {
                  await _duplicateProduct(l10n);
                } else if (value == 'toggle') {
                  await _toggleActive(l10n);
                } else if (value == 'delete') {
                  await _deleteProduct(l10n);
                }
              },
              itemBuilder: (context) => [
                if (_canEdit)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                if (_canDuplicate)
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
                if (_canEdit)
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
                        Text(product.isActive
                            ? l10n.deactivateProductTitle
                            : l10n.reactivateProductTitle),
                      ],
                    ),
                  ),
                if (_canDelete && !product.isActive)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever,
                            size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.delete,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Estado inactivo
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

            // Carrusel de Imágenes
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

            // Tarjeta de Información Básica
            _buildSectionTitle(context, l10n.basicInfo),
            const SizedBox(height: 8),
            _buildInfoCard(
              context,
              icon: Icons.info_outline,
              iconColor: Colors.blue,
              children: [
                _buildCardRow(
                  label: l10n.productNameLabel.replaceAll(' *', ''),
                  value: product.name,
                ),
                _buildCardRow(
                  label: l10n.referenceLabel.replaceAll(' *', ''),
                  value: product.reference,
                  valueStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.description.isNotEmpty)
                  _buildCardRow(
                    label: l10n.descriptionLabel.replaceAll(' *', ''),
                    value: product.description,
                  ),
                _buildCardRow(
                  label: l10n.timesUsed,
                  value: product.usageCount != 1
                      ? '${product.usageCount} ${l10n.timeUsageMultiple}'
                      : '${product.usageCount} ${l10n.timeUsageSingle}',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tarjeta de Cliente (solo si no es público)
            if (!product.isPublic && product.clientId != null) ...[
              _buildSectionTitle(context, l10n.client),
              const SizedBox(height: 8),
              Consumer<ProductionDataProvider>(
                builder: (context, dataProvider, _) {
                  final client = dataProvider.getClientById(product.clientId!);

                  if (client == null) {
                    return _buildErrorCard(context, l10n.clientNotFound);
                  }

                  return _buildInfoCard(
                    context,
                    icon: Icons.person_outline,
                    iconColor: Colors.green,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(
                                    client.initials,
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (client.company.isNotEmpty)
                                        Text(
                                          client.company,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Tarjeta de Proyecto (Nueva funcionalidad)
            // Asumimos que product.projectId existe en el modelo (si no, añadir al modelo)
            if (!product.isPublic && product.projects.isNotEmpty) ...[
              _buildSectionTitle(context, l10n.project),
              const SizedBox(height: 8),
              Consumer<ProductionDataProvider>(
                builder: (context, dataProvider, _) {
                  final project =
                      dataProvider.getProjectById(product.projects.first);

                  if (project == null) {
                    return _buildErrorCard(context, l10n.projectNotFound);
                  }

                  return _buildInfoCard(
                    context,
                    icon: Icons.folder_outlined,
                    iconColor: Colors.indigo,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.folder,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    project.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Familia de producto
            if (product.family != null && product.family!.isNotEmpty) ...[
              _buildSectionTitle(context, l10n.productFamilyLabel),
              const SizedBox(height: 8),
              _buildInfoCard(
                context,
                icon: Icons.category_outlined,
                iconColor: Colors.purple,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            product.family!.capitalize,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Especificaciones
            if (product.specifications.isNotEmpty) ...[
              _buildSectionTitle(context, l10n.specifications),
              const SizedBox(height: 8),
              _buildInfoCard(
                context,
                icon: Icons.list_alt,
                iconColor: Colors.orange,
                children: product.specifications.entries.map((entry) {
                  return _buildCardRow(
                    label: entry.key,
                    value: entry.value.toString(),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Información del sistema
            _buildSectionTitle(context, l10n.systemInfoTitle),
            const SizedBox(height: 8),
            _buildInfoCard(
              context,
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              children: [
                _buildCardRow(
                  label: l10n.createdLabel,
                  value: dateFormat.format(product.createdAt),
                ),
                FutureBuilder<String>(
                  future: _getUserName(product.createdBy),
                  builder: (context, snapshot) {
                    return _buildCardRow(
                      label: l10n.createdBy,
                      value: snapshot.data ?? l10n.loading,
                    );
                  },
                ),
                _buildCardRow(
                  label: l10n.updatedLabel,
                  value: dateFormat.format(product.updatedAt),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildErrorCard(BuildContext context, String message) {
    return _buildInfoCard(
      context,
      icon: Icons.error_outline,
      iconColor: Colors.grey,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCardRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data()?['name'] ?? 'Usuario desconocido';
    } catch (e) {
      return 'Usuario desconocido';
    }
  }

  // --- Acciones ---

  Future<void> _duplicateProduct(AppLocalizations l10n) async {
    final catalogService =
        Provider.of<ProductCatalogService>(context, listen: false);
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

    final newId = await catalogService.duplicateProduct(
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
    final catalogService =
        Provider.of<ProductCatalogService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_product!.isActive
            ? l10n.deactivateProductTitle
            : l10n.reactivateProductTitle),
        content: Text(_product!.isActive
            ? l10n.deactivateProductMessage(_product!.name)
            : l10n.reactivateProductMessage(_product!.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_product!.isActive
                ? l10n.deactivateProductTitle
                : l10n.reactivateProductTitle),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = _product!.isActive
        ? await catalogService.deactivateProduct(
            organizationId: widget.organizationId,
            productId: _product!.id,
            updatedBy: widget.currentUser.uid,
          )
        : await catalogService.reactivateProduct(
            organizationId: widget.organizationId,
            productId: _product!.id,
            updatedBy: widget.currentUser.uid,
          );

    if (mounted) {
      if (success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_product!.isActive
                ? l10n.productDeactivatedSuccess
                : l10n.productReactivatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(AppLocalizations l10n) async {
    final catalogService =
        Provider.of<ProductCatalogService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteConfirmMessage(_product!.name)),
        actions: [
          TextButton(
            onPressed: () => {
              Navigator.pop(context, false), // cerrar pop up
            },
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success =
        await catalogService.deleteProduct(widget.organizationId, _product!.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, false); // volver atras al eliminar el producto
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
