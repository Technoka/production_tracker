import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_produccion/services/product_catalog_service.dart';
import 'package:provider/provider.dart';
import '../../models/product_catalog_model.dart';
import '../../models/phase_model.dart';
import '../../services/production_batch_service.dart';
import '../../services/phase_service.dart';

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
  final _colorController = TextEditingController();
  final _materialController = TextEditingController();
  final _specialDetailsController = TextEditingController();
  final _unitPriceController = TextEditingController();

  ProductCatalogModel? _selectedProduct;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _specialDetailsController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Producto al Lote'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Seleccionar producto del catálogo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Seleccionar Producto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProductSelector(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cantidad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cantidad *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de unidades',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La cantidad es obligatoria';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Debe ser un número mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personalización (opcional)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalización (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.palette),
                        hintText: 'Ej: Negro, Marrón, Rojo...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _materialController,
                      decoration: const InputDecoration(
                        labelText: 'Material',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.texture),
                        hintText: 'Ej: Cuero, Sintético...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _specialDetailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detalles especiales',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                        hintText: 'Especificaciones adicionales...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Precio (opcional, solo para roles autorizados)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Precio Unitario (opcional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El precio del catálogo se usa por defecto',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio por unidad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                        suffixText: '€',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Precio inválido';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón añadir
            FilledButton.icon(
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
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelector() {
    return StreamBuilder<List<ProductCatalogModel>>(
      stream: Provider.of<ProductCatalogService>(context, listen: false)
          .getOrganizationProductsStream(widget.organizationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Column(
            children: [
              Text(
                'No hay productos en el catálogo',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ir al catálogo'),
              ),
            ],
          );
        }

return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CAMBIO AQUÍ: El tipo ahora es String, no ProductCatalogModel
            DropdownButtonFormField<String>( 
              decoration: const InputDecoration(
                labelText: 'Producto del catálogo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              // USAMOS EL ID COMO VALOR
              value: _selectedProduct?.id, 
              isExpanded: true,
              itemHeight: null,
              items: products.map((product) {
                return DropdownMenuItem(
                  value: product.id, // AQUÍ TAMBIÉN USAMOS EL ID
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis // Corta con "..." si es muy largo
                      ), 
                      maxLines: 1,
                      ),
                      if (product.reference != null)
                        Text(
                          'Ref: ${product.reference}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                );
              }).toList(),
              // AL CAMBIAR, BUSCAMOS EL OBJETO REAL USANDO EL ID
              onChanged: (productId) {
                if (productId == null) return;
                // Buscamos el objeto completo en la lista usando el ID
                final product = products.firstWhere((p) => p.id == productId);
                
                setState(() {
                  _selectedProduct = product;
                  if (product.basePrice != null) {
                    _unitPriceController.text = product.basePrice!.toStringAsFixed(2);
                  }
                });
              },
              validator: (value) => value == null ? 'Debes seleccionar un producto' : null,
            ),

            // Mostrar detalles del producto seleccionado
            if (_selectedProduct != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedProduct!.description != null) ...[
                      Text(
                        _selectedProduct!.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_selectedProduct!.basePrice != null)
                      Text(
                        'Precio catálogo: ${_selectedProduct!.basePrice!.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
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
      // Obtener las fases de producción
      final phases = await phaseService.getOrganizationPhases(widget.organizationId);
      
      if (phases.isEmpty) {
        throw Exception('No hay fases de producción configuradas');
      }

      // Ordenar fases por orden
      phases.sort((a, b) => a.order.compareTo(b.order));

      // Parsear valores
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
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        material: _materialController.text.trim().isEmpty
            ? null
            : _materialController.text.trim(),
        specialDetails: _specialDetailsController.text.trim().isEmpty
            ? null
            : _specialDetailsController.text.trim(),
        unitPrice: unitPrice,
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
            content: Text('Error al añadir producto: $e'),
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
}