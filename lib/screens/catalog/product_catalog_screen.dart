import 'package:flutter/material.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../utils/role_utils.dart';
import 'create_product_catalog_screen.dart';
import 'edit_product_catalog_screen.dart';
import 'product_catalog_detail_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  final String organizationId;
  final UserModel currentUser;

  const ProductCatalogScreen({
    super.key,
    required this.organizationId,
    required this.currentUser,
  });

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final ProductCatalogService _catalogService = ProductCatalogService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _availableCategories = [];
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _catalogService.getOrganizationCategories(widget.organizationId);
    if (mounted) {
      setState(() {
        _availableCategories = categories;
      });
    }
  }

  bool _canManageProducts() {
    return RoleUtils.canManageProducts(widget.currentUser.role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        actions: [
          // Filtro de categorías
          if (_availableCategories.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por categoría',
              onSelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text('Todas las categorías'),
                ),
                const PopupMenuDivider(),
                ..._availableCategories.map(
                  (category) => PopupMenuItem<String?>(
                    value: category,
                    child: Text(category),
                  ),
                ),
              ],
            ),
          // Mostrar inactivos
          if (_canManageProducts())
            IconButton(
              icon: Icon(
                _showInactive ? Icons.visibility : Icons.visibility_off,
              ),
              tooltip: _showInactive ? 'Ocultar inactivos' : 'Mostrar inactivos',
              onPressed: () {
                setState(() {
                  _showInactive = !_showInactive;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, referencia o descripción...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Chips de filtros activos
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(_selectedCategory!),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Lista de productos
          Expanded(
            child: StreamBuilder<List<ProductCatalogModel>>(
              stream: _catalogService.getOrganizationCatalog(
                widget.organizationId,
                includeInactive: _showInactive,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                var products = snapshot.data ?? [];

                // Aplicar filtros
                if (_searchQuery.isNotEmpty) {
                  products = products
                      .where((p) => p.matchesSearch(_searchQuery))
                      .toList();
                }

                if (_selectedCategory != null) {
                  products = products
                      .where((p) => p.category == _selectedCategory)
                      .toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty || _selectedCategory != null
                              ? Icons.search_off
                              : Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != null
                              ? 'No se encontraron productos'
                              : 'No hay productos en el catálogo',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != null
                              ? 'Intenta con otros términos de búsqueda'
                              : 'Crea tu primer producto',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        currentUser: widget.currentUser,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductCatalogDetailScreen(
                                productId: product.id,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        },
                        onEdit: _canManageProducts()
                            ? () async {
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
                                  setState(() {});
                                  _loadCategories();
                                }
                              }
                            : null,
                        onToggleActive: _canManageProducts()
                            ? () async {
                                await _toggleProductActive(product);
                              }
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _canManageProducts()
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateProductCatalogScreen(
                      organizationId: widget.organizationId,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
                if (result == true) {
                  setState(() {});
                  _loadCategories();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Producto'),
            )
          : null,
    );
  }

  Future<void> _toggleProductActive(ProductCatalogModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          product.isActive ? 'Desactivar producto' : 'Reactivar producto',
        ),
        content: Text(
          product.isActive
              ? '¿Deseas desactivar "${product.name}"? No se eliminará, solo quedará oculto.'
              : '¿Deseas reactivar "${product.name}"?',
        ),
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
            child: Text(
              product.isActive ? 'Desactivar' : 'Reactivar',
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = product.isActive
        ? await _catalogService.deactivateProduct(
            productId: product.id,
            updatedBy: widget.currentUser.uid,
          )
        : await _catalogService.reactivateProduct(
            productId: product.id,
            updatedBy: widget.currentUser.uid,
          );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? product.isActive
                    ? 'Producto desactivado correctamente'
                    : 'Producto reactivado correctamente'
                : 'Error al actualizar el producto',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        setState(() {});
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  final ProductCatalogModel product;
  final UserModel currentUser;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  const _ProductCard({
    required this.product,
    required this.currentUser,
    required this.onTap,
    this.onEdit,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isActive ? 1.0 : 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Imagen del producto
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      image: product.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrls.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrls.isEmpty
                        ? Icon(
                            Icons.inventory_2,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!product.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Inactivo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${product.reference}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (product.category != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Menú de opciones
                  if (onEdit != null || onToggleActive != null)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                        if (onToggleActive != null)
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
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'toggle') {
                          onToggleActive?.call();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.dimensions != null && product.dimensions!.hasAnyDimension) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      product.dimensions!.toDisplayString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              if (product.usageCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.history, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Usado ${product.usageCount} ${product.usageCount == 1 ? "vez" : "veces"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    )
    );
  }
}