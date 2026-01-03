import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_catalog_model.dart';
import '../../models/project_product_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../services/project_product_service.dart';
import '../../utils/role_utils.dart';

class AddProductToProjectScreen extends StatefulWidget {
  final String projectId;
  final String organizationId;
  final UserModel currentUser;

  const AddProductToProjectScreen({
    super.key,
    required this.projectId,
    required this.organizationId,
    required this.currentUser,
  });

  @override
  State<AddProductToProjectScreen> createState() =>
      _AddProductToProjectScreenState();
}

class _AddProductToProjectScreenState extends State<AddProductToProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductCatalogService _catalogService = ProductCatalogService();
  final ProjectProductService _productService = ProjectProductService();

  ProductCatalogModel? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _colorController = TextEditingController();
  final _materialController = TextEditingController();
  final _finishController = TextEditingController();
  final _specialDetailsController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _depthController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _showPriceFields = false;

  @override
  void initState() {
    super.initState();
    _showPriceFields = RoleUtils.canViewFinancials(widget.currentUser.role);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _finishController.dispose();
    _specialDetailsController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Construir personalización
      final customization = ProductCustomization(
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        material: _materialController.text.trim().isNotEmpty
            ? _materialController.text.trim()
            : null,
        finish: _finishController.text.trim().isNotEmpty
            ? _finishController.text.trim()
            : null,
        specialDetails: _specialDetailsController.text.trim().isNotEmpty
            ? _specialDetailsController.text.trim()
            : null,
        dimensions: _buildCustomDimensions(),
      );

      final quantity = int.parse(_quantityController.text);
      final unitPrice = _showPriceFields && _unitPriceController.text.isNotEmpty
          ? double.parse(_unitPriceController.text)
          : (_selectedProduct!.basePrice ?? 0.0);

      final productId = await _productService.addProductToProject(
        projectId: widget.projectId,
        organizationId: widget.organizationId,
        catalogProductId: _selectedProduct!.id,
        quantity: quantity,
        unitPrice: unitPrice,
        createdBy: widget.currentUser.uid,
        customization: customization,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        if (productId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto añadido al proyecto'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al añadir producto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  CustomDimensions? _buildCustomDimensions() {
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);
    final depth = double.tryParse(_depthController.text);

    if (width == null && height == null && depth == null) return null;

    return CustomDimensions(
      width: width,
      height: height,
      depth: depth,
      unit: 'cm',
    );
  }

  void _onProductSelected(ProductCatalogModel product) {
    setState(() {
      _selectedProduct = product;
      // Pre-rellenar con datos del catálogo
      if (product.basePrice != null && _showPriceFields) {
        _unitPriceController.text = product.basePrice!.toStringAsFixed(2);
      }
      if (product.materialInfo != null) {
        _materialController.text = product.materialInfo!.primaryMaterial;
        if (product.materialInfo!.finish != null) {
          _finishController.text = product.materialInfo!.finish!;
        }
        if (product.materialInfo!.color != null) {
          _colorController.text = product.materialInfo!.color!;
        }
      }
      if (product.dimensions != null) {
        if (product.dimensions!.width != null) {
          _widthController.text = product.dimensions!.width!.toString();
        }
        if (product.dimensions!.height != null) {
          _heightController.text = product.dimensions!.height!.toString();
        }
        if (product.dimensions!.depth != null) {
          _depthController.text = product.dimensions!.depth!.toString();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de producto del catálogo
            _buildSectionTitle('Seleccionar del Catálogo'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(
                  _selectedProduct?.name ?? 'Ningún producto seleccionado',
                  style: TextStyle(
                    fontWeight: _selectedProduct != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: _selectedProduct != null
                    ? Text('SKU: ${_selectedProduct!.reference}')
                    : const Text('Toca para seleccionar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showModalBottomSheet<ProductCatalogModel>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => _ProductSelectorSheet(
                      organizationId: widget.organizationId,
                    ),
                  );
                  if (selected != null) {
                    _onProductSelected(selected);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Cantidad y precio
            _buildSectionTitle('Cantidad y Precio'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad *',
                      border: OutlineInputBorder(),
                      suffixText: 'uds',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                ),
                if (_showPriceFields) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio unitario',
                        border: OutlineInputBorder(),
                        prefixText: '€ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Personalización
            _buildSectionTitle('Personalización'),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
                hintText: 'Ej: Azul marino',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _materialController,
              decoration: const InputDecoration(
                labelText: 'Material',
                border: OutlineInputBorder(),
                hintText: 'Ej: Cuero genuino',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _finishController,
              decoration: const InputDecoration(
                labelText: 'Acabado',
                border: OutlineInputBorder(),
                hintText: 'Ej: Mate',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Dimensiones personalizadas
            _buildSectionTitle('Dimensiones Personalizadas (cm)'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Ancho',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Alto',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _depthController,
                    decoration: const InputDecoration(
                      labelText: 'Fondo',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Detalles especiales
            _buildSectionTitle('Detalles Especiales'),
            TextFormField(
              controller: _specialDetailsController,
              decoration: const InputDecoration(
                labelText: 'Detalles',
                border: OutlineInputBorder(),
                hintText: 'Especificaciones adicionales...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
                hintText: 'Notas internas...',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Botón añadir
            FilledButton(
              onPressed: _isLoading ? null : _addProduct,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Añadir al Proyecto'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Sheet para seleccionar producto del catálogo
class _ProductSelectorSheet extends StatefulWidget {
  final String organizationId;

  const _ProductSelectorSheet({required this.organizationId});

  @override
  State<_ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<_ProductSelectorSheet> {
  final ProductCatalogService _catalogService = ProductCatalogService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seleccionar Producto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Lista de productos
            Expanded(
              child: StreamBuilder<List<ProductCatalogModel>>(
                stream: _catalogService.getOrganizationProductsStream(
                  widget.organizationId,
                  includeInactive: false,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var products = snapshot.data ?? [];

                  if (_searchQuery.isNotEmpty) {
                    products = products
                        .where((p) => p.matchesSearch(_searchQuery))
                        .toList();
                  }

                  if (products.isEmpty) {
                    return const Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('No hay productos disponibles.'),
                          SizedBox(height: 8),
                          Text('Debes añadir primero productos al catálogo.'),
                        ],
                        ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: product.imageUrls.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrls.first,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.inventory_2),
                                ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('SKU: ${product.reference}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, product),
                        ),
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
}