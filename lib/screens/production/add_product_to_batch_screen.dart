import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product_catalog_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/production_batch_model.dart';
import '../../services/product_catalog_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/phase_service.dart';
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
  
  // Controladores
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _productNotesController = TextEditingController();

  // Estado del formulario
  ProductCatalogModel? _selectedProduct;
  bool _isLoading = false;
  String _productSearchQuery = '';
  String _productUrgencyLevel = 'medium';
  DateTime? _productExpectedDelivery;
  
  // Datos del lote
  String? _batchClientId;
  String? _batchProjectId;
  ProductionBatchModel? _batchData;
  late Stream<List<BatchProductModel>> _existingProductsStream;

  // NUEVO: Lista de productos pendientes de guardar
  final List<Map<String, dynamic>> _pendingProducts = [];

  @override
  void initState() {
    super.initState();
    _loadBatchInfo();
    
    // Inicializar fecha por defecto
    _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));

    // Inicializar Stream aquí para evitar recargas al hacer setState
    _existingProductsStream = Provider.of<ProductionBatchService>(context, listen: false)
        .watchBatchProducts(widget.organizationId, widget.batchId);

    _productSearchController.addListener(() {
      setState(() {
        _productSearchQuery = _productSearchController.text;
      });
    });
    // Fecha por defecto: 3 semanas
    _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));
  }

    void _removeProductFromList(int index) {
    setState(() {
      _pendingProducts.removeAt(index);
    });
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

  // --- LÓGICA DE LISTA PENDIENTE ---

  void _addProductToPendingList() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un producto')),
      );
      return;
    }

    // Validar límite total (Existentes + Pendientes)
    final currentTotal = (_batchData?.totalProducts ?? 0) + _pendingProducts.length;
    if (currentTotal >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El límite es de 10 productos por lote')),
      );
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final unitPrice = _unitPriceController.text.isNotEmpty
        ? double.tryParse(_unitPriceController.text)
        : _selectedProduct!.basePrice;

    setState(() {
      _pendingProducts.add({
        'product': _selectedProduct,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'expectedDeliveryDate': _productExpectedDelivery,
        'urgencyLevel': _productUrgencyLevel,
        'notes': _productNotesController.text.trim(),
      });

      // Resetear formulario
      _selectedProduct = null;
      _quantityController.text = '1';
      _unitPriceController.clear();
      _productNotesController.clear();
      _productUrgencyLevel = 'medium';
      _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));
      // No limpiamos el buscador para facilitar añadir productos similares si se desea
    });
  }

  void _removePendingProduct(int index) {
    setState(() {
      _pendingProducts.removeAt(index);
    });
  }

  Future<void> _saveAllProducts() async {
    if (_pendingProducts.isEmpty) return;

    setState(() => _isLoading = true);
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final phaseService = Provider.of<PhaseService>(context, listen: false);

    try {
      final phases = await phaseService.getOrganizationPhases(widget.organizationId);
      if (phases.isEmpty) throw Exception('No hay fases configuradas');
      phases.sort((a, b) => a.order.compareTo(b.order));

      // Guardar secuencialmente
      for (final item in _pendingProducts) {
        final product = item['product'] as ProductCatalogModel;
        
        await batchService.addProductToBatch(
          organizationId: widget.organizationId,
          batchId: widget.batchId,
          productCatalogId: product.id,
          productName: product.name,
          productReference: product.reference,
          description: product.description,
          quantity: item['quantity'],
          phases: phases,
          unitPrice: item['unitPrice'],
          expectedDeliveryDate: item['expectedDeliveryDate'],
          urgencyLevel: item['urgencyLevel'],
          notes: item['notes'].isNotEmpty ? item['notes'] : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pendingProducts.length} productos añadidos exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_batchData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Añadir Producto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalCount = (_batchData?.totalProducts ?? 0) + _pendingProducts.length;

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
          // 1. Productos Existentes
          _buildExistingProductsSection(),
          const SizedBox(height: 24),

          // 2. Formulario Nuevo Producto
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Añadir Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$totalCount/10', style: TextStyle(
                          color: totalCount >= 10 ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold
                        )),
                      ],
                    ),
                    const Divider(height: 24),

                    // Filtro de búsqueda
                    FilterUtils.buildSearchField(
                      hintText: 'Buscar por nombre o SKU...',
                      searchQuery: _productSearchQuery,
                      onChanged: (value) {
                        setState(() {
                          _productSearchQuery = value;
                        });
                      },
                      fontSize: 14,
                    ),
                    const SizedBox(height: 12),

                    // Selector
                    _buildProductSelector(),
                    const SizedBox(height: 12),

                    // Urgencia y Fecha
                    Row(
                      children: [
                        Expanded(
                          child: FilterUtils.buildUrgencySelector(
                            context: context,
                            urgencyLevel: _productUrgencyLevel,
                            onChanged: (v) => setState(() => _productUrgencyLevel = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fecha de entrega estimada del producto
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
                    
                    // Notas del producto (NUEVO)
                    TextFormField(
                      controller: _productNotesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Añade detalles específicos de este producto...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.notes),
                        alignLabelWithHint: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Cantidad y Precio
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(labelText: 'Cantidad *', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Inválido',
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

                    // Botón Añadir a Lista
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: totalCount >= 10 ? null : _addProductToPendingList,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Añadir a la lista'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    
          const SizedBox(height: 24),
                              // Lista de productos añadidos
                    if (_pendingProducts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'No hay productos seleccionados',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pendingProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _pendingProducts[index];
                          final product = item['product'] as ProductCatalogModel;
                          final quantity = item['quantity'] as int;
                          final deliveryDate = item['expectedDeliveryDate'] as DateTime?;
                          final urgency = item['urgencyLevel'] as String? ?? 'medium';
                          final notes = item['notes'] as String?;
                          final sequence = index + 1 + (_batchData?.totalProducts ?? 0);

                      // Determinar color y texto de urgencia
                          Color urgencyColor;
                          String urgencyLabel;
                          switch (urgency) {
                            case 'low': 
                              urgencyColor = Colors.green; 
                              urgencyLabel = 'Baja';
                              break;
                            case 'high': 
                              urgencyColor = Colors.red[500]!; 
                              urgencyLabel = 'Alta';
                              break;
                            case 'critical': 
                              urgencyColor = Colors.red[900]!; 
                              urgencyLabel = 'Crítica';
                              break;
                            default: 
                              urgencyColor = Colors.orange;
                              urgencyLabel = 'Media';
                          }

  return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 1. LEADING: Avatar con número
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: urgencyColor.withOpacity(0.2),
                                  child: Text(
                                    '#$sequence',
                                    style: TextStyle(
                                      color: urgencyColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 2. CENTRO: Información del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'SKU: ${product.reference}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (deliveryDate != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Entrega: ${_formatDate(deliveryDate)}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                      if (notes != null && notes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Notas: $notes',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue[800],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 3. DERECHA: Chip arriba, Acciones abajo
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // ARRIBA: Chip de urgencia
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: urgencyColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: urgencyColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        urgencyLabel,
                                        style: TextStyle(
                                          color: urgencyColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12), // Espacio en medio
                                    
                                    // ABAJO: Cantidad y Borrar
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Text(
                                            'x$quantity',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _removeProductFromList(index),
                                          borderRadius: BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

 
            const SizedBox(height: 24),
          
        ],
      ),
      bottomNavigationBar: _pendingProducts.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: FilledButton(
                onPressed: _isLoading ? null : _saveAllProducts,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Guardar ${_pendingProducts.length} Productos'),
              ),
            )
          : null,
    );
  }

  // Se usa el Stream inicializado en initState para evitar recargas
  Widget _buildExistingProductsSection() {
    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Productos en el Lote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_batchData!.totalProducts} guardados', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          
          StreamBuilder<List<BatchProductModel>>(
            stream: _existingProductsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay productos guardados.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero, // Padding eliminado para reducir espacio
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    dense: true, // Reduce altura
                    leading: Text('#${product.productNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    title: Text(product.productName),
                    subtitle: Text('SKU: ${product.productReference ?? "-"}'),
                    trailing: Text('x${product.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              );
            },
          ),
          // Pequeño espacio final opcional
          const SizedBox(height: 4), 
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    if (_batchClientId == null) return const LinearProgressIndicator();

    return StreamBuilder<List<ProductCatalogModel>>(
      stream: Provider.of<ProductCatalogService>(context, listen: false)
          .getOrganizationProductsStream(widget.organizationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: LinearProgressIndicator()));

        var allProducts = snapshot.data ?? [];
        
        // 1. Filtrar por cliente
        var products = allProducts.where((p) => p.isPublic || p.clientId == _batchClientId).toList();

        // 2. Filtrar por búsqueda
        if (_productSearchQuery.isNotEmpty) {
          final query = _productSearchQuery.toLowerCase();
          products = products.where((p) =>
            p.name.toLowerCase().contains(query) ||
            (p.reference?.toLowerCase().contains(query) ?? false)
          ).toList();
        }

        // --- SOLUCIÓN ERROR "BAD STATE" ---
        // Verificamos si la selección actual sigue siendo válida en la lista filtrada
        final isSelectionValid = _selectedProduct != null && products.any((p) => p.id == _selectedProduct!.id);
        
        // Si no es válida, pasamos null al dropdown (visual), pero mantenemos el estado si queremos
        // O según tu petición: "se elimine el producto seleccionado"
        final dropdownValue = isSelectionValid ? _selectedProduct!.id : null;

        return FilterUtils.buildFullWidthDropdown<String>(
          context: context,
          label: 'Producto',
          value: dropdownValue,
          icon: Icons.inventory,
          hintText: products.isEmpty ? 'Sin coincidencias' : 'Seleccionar...',
          items: products.map((product) {
            return DropdownMenuItem(
              value: product.id,
              child: Text(
                '${product.name} (SKU: ${product.reference ?? "-"})',
                overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}