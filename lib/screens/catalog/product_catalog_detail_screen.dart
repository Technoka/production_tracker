import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../utils/role_utils.dart';
import 'edit_product_catalog_screen.dart';

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
  late String organizationId;

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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del Producto'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del Producto'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Producto no encontrado'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
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
        title: const Text('Detalle del Producto'),
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
                      const Text('Duplicar'),
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
                      Text(product.isActive ? 'Desactivar' : 'Reactivar'),
                    ],
                  ),
                ),
                if (!product.isActive)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) async {
                if (value == 'duplicate') {
                  await _duplicateProduct();
                } else if (value == 'toggle') {
                  await _toggleActive();
                } else if (value == 'delete') {
                  await _deleteProduct();
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
                      'Este producto está desactivado',
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
            _buildSectionTitle(context, 'Información Básica'),
            _buildInfoCard(context, [
              _buildInfoRow('Nombre', product.name),
              _buildInfoRow('Referencia', product.reference, monospace: true),
              _buildInfoRow('Descripción', product.description),
              if (product.category != null)
                _buildInfoRow('Categoría', product.category!),
            ]),
            const SizedBox(height: 16),

            // Dimensiones
            if (product.dimensions != null && product.dimensions!.hasAnyDimension) ...[
              _buildSectionTitle(context, 'Dimensiones'),
              _buildInfoCard(context, [
                if (product.dimensions!.width != null)
                  _buildInfoRow('Ancho', '${product.dimensions!.width} cm'),
                if (product.dimensions!.height != null)
                  _buildInfoRow('Alto', '${product.dimensions!.height} cm'),
                if (product.dimensions!.depth != null)
                  _buildInfoRow('Fondo', '${product.dimensions!.depth} cm'),
              ]),
              const SizedBox(height: 16),
            ],

            // Material
            if (product.materialInfo != null) ...[
              _buildSectionTitle(context, 'Material'),
              _buildInfoCard(context, [
                _buildInfoRow('Material principal',
                    product.materialInfo!.primaryMaterial),
                if (product.materialInfo!.secondaryMaterials.isNotEmpty)
                  _buildInfoRow('Materiales secundarios',
                      product.materialInfo!.secondaryMaterials.join(', ')),
                if (product.materialInfo!.finish != null)
                  _buildInfoRow('Acabado', product.materialInfo!.finish!),
                if (product.materialInfo!.color != null)
                  _buildInfoRow('Color', product.materialInfo!.color!),
              ]),
              const SizedBox(height: 16),
            ],

            // Datos adicionales
            _buildSectionTitle(context, 'Datos Adicionales'),
            _buildInfoCard(context, [
              if (product.estimatedWeight != null)
                _buildInfoRow('Peso estimado', '${product.estimatedWeight} kg'),
              if (product.basePrice != null)
                _buildInfoRow('Precio base',
                    '€ ${product.basePrice!.toStringAsFixed(2)}'),
              _buildInfoRow('Veces usado',
                  '${product.usageCount} ${product.usageCount == 1 ? "vez" : "veces"}'),
            ]),
            const SizedBox(height: 16),

            // Etiquetas
            if (product.tags.isNotEmpty) ...[
              _buildSectionTitle(context, 'Etiquetas'),
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
              _buildSectionTitle(context, 'Notas'),
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
              _buildSectionTitle(context, 'Especificaciones'),
              _buildInfoCard(context,
                  product.specifications.entries.map((entry) {
                return _buildInfoRow(entry.key, entry.value.toString());
              }).toList()),
              const SizedBox(height: 16),
            ],

            // Información de sistema
            _buildSectionTitle(context, 'Información del Sistema'),
            _buildInfoCard(context, [
              _buildInfoRow('Creado', dateFormat.format(product.createdAt)),
              _buildInfoRow(
                  'Última actualización', dateFormat.format(product.updatedAt)),
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

  Future<void> _duplicateProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar producto'),
        content: Text(
            '¿Deseas crear una copia de "${_product!.name}"? Se generará automáticamente una nueva referencia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duplicar'),
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
          const SnackBar(
            content: Text('Producto duplicado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Navegar al nuevo producto
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
          const SnackBar(
            content: Text('Error al duplicar el producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleActive() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            _product!.isActive ? 'Desactivar producto' : 'Reactivar producto'),
        content: Text(
          _product!.isActive
              ? '¿Deseas desactivar "${_product!.name}"? No se eliminará, solo quedará oculto.'
              : '¿Deseas reactivar "${_product!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_product!.isActive ? 'Desactivar' : 'Reactivar'),
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
                  ? 'Producto desactivado correctamente'
                  : 'Producto reactivado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadProduct();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
            '¿Estás seguro de que deseas eliminar permanentemente "${_product!.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _catalogService.deleteProduct(widget.organizationId, _product!.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}