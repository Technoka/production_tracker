import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_produccion/services/product_catalog_service.dart';
import 'package:provider/provider.dart';
import '../../models/product_catalog_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/production_batch_model.dart';
import '../../services/production_batch_service.dart';
import '../../services/phase_service.dart';
import '../../services/client_service.dart';
import '../../models/client_model.dart';
import '../../utils/filter_utils.dart';

class AddProductToBatchScreen extends StatefulWidget {
  final String organizationId;
  final String batchId;

  const AddProductToBatchScreen({
    super.key,
    required this.organizationId,
    required this.batchId,
  });

  @override
  State<AddProductToBatchScreen> createState() => _AddProductToBatchScreenState();
}

class _AddProductToBatchScreenState extends State<AddProductToBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _productNotesController = TextEditingController();

  ProductCatalogModel? _selectedProduct;
  bool _isLoading = false;
  String _productSearchQuery = '';
  String _productUrgencyLevel = 'medium';
  DateTime? _productExpectedDelivery;
  
  String? _batchClientId;
  String? _batchProjectId;
  ProductionBatchModel? _batchData;

  @override
  void initState() {
    super.initState();
    _loadBatchInfo();
    _productSearchController.addListener(() {
      setState(() {
        _productSearchQuery = _productSearchController.text;
      });
    });
    // Fecha por defecto: 3 semanas
    _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));
  }

  Future<void> _loadBatchInfo() async {
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final batch = await batchService.getBatch(widget.organizationId, widget.batchId);
    
    if (batch != null && mounted) {
      setState(() {
        _batchData = batch;
        _batchClientId = batch.clientId;
        _batchProjectId = batch.projectId;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _productSearchController.dispose();
    _productNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectProductDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _productExpectedDelivery ?? DateTime.now().add(const Duration(days: 21)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha de entrega del producto',
    );

    if (picked != null) {
      setState(() {
        _productExpectedDelivery = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_batchData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Añadir Producto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Añadir Producto al Lote'),
            Text(
              _batchData!.batchNumber,
              style: const TextStyle(fontSize: 14), // Tamaño más pequeño para el subtítulo
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECCIÓN 1: Productos existentes en el lote
          _buildExistingProductsSection(),
          const SizedBox(height: 24),

          // SECCIÓN 2: Añadir nuevo producto
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Añadir Nuevo Producto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Filtro de búsqueda
                    FilterUtils.buildSearchField(
                      hintText: 'Buscar producto por nombre o SKU...',
                      searchQuery: _productSearchQuery,
                      onChanged: (value) {
                        setState(() {
                          _productSearchQuery = value;
                        });
                      },
                      fontSize: 14,
                    ),
                    const SizedBox(height: 12),

                    // Selector de producto
                    _buildProductSelector(),
                    const SizedBox(height: 12),

                    // Urgencia
                    FilterUtils.buildUrgencySelector(
                      context: context,
                      urgencyLevel: _productUrgencyLevel,
                      onChanged: (newUrgency) {
                        setState(() {
                          _productUrgencyLevel = newUrgency;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Notas
                    TextFormField(
                      controller: _productNotesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Añade detalles específicos...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                        alignLabelWithHint: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Fecha de entrega
                    InkWell(
                      onTap: _selectProductDeliveryDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Fecha de entrega estimada',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(_productExpectedDelivery!),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cantidad y Precio
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Requerido';
                              final quantity = int.tryParse(value);
                              if (quantity == null || quantity <= 0) return 'Mayor a 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _unitPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Precio (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.euro),
                              suffixText: '€',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón añadir
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _addProduct,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(_isLoading ? 'Añadiendo...' : 'Añadir Producto'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingProductsSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Productos ya en el Lote',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${_batchData!.totalProducts}/10',
                  style: TextStyle(
                    color: _batchData!.canAddMoreProducts ? Colors.grey : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            StreamBuilder<List<BatchProductModel>>(
              stream: Provider.of<ProductionBatchService>(context, listen: false)
                  .watchBatchProducts(widget.organizationId, widget.batchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No hay productos en el lote todavía',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: product.urgencyColor.withOpacity(0.2),
                        child: Text(
                          '#${product.productNumber}',
                          style: TextStyle(
                            color: product.urgencyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        product.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.productReference != null)
                            Text('SKU: ${product.productReference}', style: const TextStyle(fontSize: 12)),
                          Text('Cantidad: ${product.quantity} uds', style: const TextStyle(fontSize: 12)),
                          Text('Fase: ${product.currentPhaseName}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: product.urgencyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: product.urgencyColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          product.urgencyDisplayName,
                          style: TextStyle(
                            color: product.urgencyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelector() {
    if (_batchClientId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<ProductCatalogModel>>(
      stream: Provider.of<ProductCatalogService>(context, listen: false)
          .getOrganizationProductsStream(widget.organizationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        var allProducts = snapshot.data ?? [];

        // FILTRAR: Solo productos del cliente del lote o públicos
        var products = allProducts.where((product) {
          if (product.isPublic) return true;
          if (product.clientId != null) {
            return product.clientId == _batchClientId;
          }
          return true;
        }).toList();

        // FILTRAR por búsqueda
        if (_productSearchQuery.isNotEmpty) {
          final query = _productSearchQuery.toLowerCase();
          products = products.where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.reference.toLowerCase().contains(query)
          ).toList();
        }

        return FilterUtils.buildFullWidthDropdown<String>(
          context: context,
          label: 'Producto del catálogo',
          value: _selectedProduct?.id,
          icon: Icons.inventory,
          hintText: products.isEmpty ? 'No hay productos disponibles' : 'Seleccionar producto...',
          isRequired: true,
          items: products.map((product) {
            return DropdownMenuItem(
              value: product.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.reference}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (productId) {
            if (productId == null) return;
            setState(() {
              _selectedProduct = products.firstWhere((p) => p.id == productId);
              if (_selectedProduct!.basePrice != null) {
                _unitPriceController.text = _selectedProduct!.basePrice!.toStringAsFixed(2);
              }
            });
          },
          validator: (value) {
            if (value == null) return 'Debes seleccionar un producto';
            return null;
          },
        );
      },
    );
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un producto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final phaseService = Provider.of<PhaseService>(context, listen: false);

    try {
      final phases = await phaseService.getOrganizationPhases(widget.organizationId);
      
      if (phases.isEmpty) {
        throw Exception('No hay fases de producción configuradas');
      }

      phases.sort((a, b) => a.order.compareTo(b.order));

      final quantity = int.parse(_quantityController.text);
      final unitPrice = _unitPriceController.text.isNotEmpty
          ? double.tryParse(_unitPriceController.text)
          : _selectedProduct!.basePrice;

      final productId = await batchService.addProductToBatch(
        organizationId: widget.organizationId,
        batchId: widget.batchId,
        productCatalogId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        productReference: _selectedProduct!.reference,
        description: _selectedProduct!.description,
        quantity: quantity,
        phases: phases,
        unitPrice: unitPrice,
        expectedDeliveryDate: _productExpectedDelivery,
        urgencyLevel: _productUrgencyLevel,
        notes: _productNotesController.text.trim().isEmpty 
            ? null 
            : _productNotesController.text.trim(),
      );

      if (productId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto añadido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        throw Exception(batchService.error ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}