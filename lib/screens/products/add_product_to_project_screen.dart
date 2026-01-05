import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_catalog_model.dart';
import '../../models/project_product_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../services/project_product_service.dart';
import '../../utils/role_utils.dart';
// IMPORTAR IDIOMA
import '../../l10n/app_localizations.dart';

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

  Future<void> _addProduct(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectProduct),
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
            SnackBar(
              content: Text(l10n.productAddedToProject),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorAddingProduct),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addProduct),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de producto del catálogo
            _buildSectionTitle(l10n.selectFromCatalog),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(
                  _selectedProduct?.name ?? l10n.noProductSelected,
                  style: TextStyle(
                    fontWeight: _selectedProduct != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: _selectedProduct != null
                    ? Text('${l10n.skuLabel}: ${_selectedProduct!.reference}')
                    : Text(l10n.tapToSelect),
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
            _buildSectionTitle(l10n.quantityAndPrice),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: '${l10n.quantity} *',
                      border: const OutlineInputBorder(),
                      suffixText: l10n.unitsSuffix,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.fieldRequired;
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return l10n.quantityInvalid;
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
                        labelText: 'Precio unitario', // Usar clave si existe
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
            _buildSectionTitle(l10n.customization),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color', // Usar clave existente
                border: OutlineInputBorder(),
                hintText: 'Ej: Azul marino',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _materialController,
              decoration: const InputDecoration(
                labelText: 'Material', // Usar clave existente
                border: OutlineInputBorder(),
                hintText: 'Ej: Cuero genuino',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _finishController,
              decoration: const InputDecoration(
                labelText: 'Acabado', // Usar clave existente
                border: OutlineInputBorder(),
                hintText: 'Ej: Mate',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Dimensiones personalizadas
            _buildSectionTitle(l10n.customDimensions),
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
            _buildSectionTitle(l10n.specialDetails),
            TextFormField(
              controller: _specialDetailsController,
              decoration: InputDecoration(
                labelText: l10n.detailsLabel,
                border: const OutlineInputBorder(),
                hintText: l10n.additionalSpecsHint,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
                hintText: l10n.internalNotesHint,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Botón añadir
            FilledButton(
              onPressed: _isLoading ? null : () => _addProduct(l10n),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.addToProject),
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
    final l10n = AppLocalizations.of(context)!;

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
                  Text(
                    l10n.selectProductTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchProductHint,
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
                    return Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.noProductsAvailable),
                          const SizedBox(height: 8),
                          Text(l10n.addProductsToCatalogFirst),
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
                          subtitle: Text('${l10n.skuLabel}: ${product.reference}'),
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