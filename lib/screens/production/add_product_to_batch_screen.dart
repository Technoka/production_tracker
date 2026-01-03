import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_produccion/services/product_catalog_service.dart';
import 'package:provider/provider.dart';
import '../../models/product_catalog_model.dart';
import '../../services/production_batch_service.dart';
import '../../services/phase_service.dart';
import '../../services/client_service.dart';
import '../../models/client_model.dart';

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
  
  String? _batchClientId;
  String? _batchProjectId;

  @override
  void initState() {
    super.initState();
    _loadBatchInfo();
  }

  // AÑADIR método para cargar info del lote:
  Future<void> _loadBatchInfo() async {
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final batch = await batchService.getBatch(widget.organizationId, widget.batchId);
    
    if (batch != null && mounted) {
      setState(() {
        _batchClientId = batch.clientId;
        _batchProjectId = batch.projectId;
      });
    }
  }

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
                          final basePrice = double.tryParse(value);
                          if (basePrice == null || basePrice < 0) {
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
  if (_batchClientId == null) {
    return const Center(child: CircularProgressIndicator());
  }

  return StreamBuilder<List<ProductCatalogModel>>(
    stream: Provider.of<ProductCatalogService>(context, listen: false)
        .getClientProductsStream(widget.organizationId, _batchClientId!),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      final allProducts = snapshot.data ?? [];

      // FILTRAR: Solo productos del cliente del lote o públicos
      final products = allProducts.where((product) {
        // Si el producto es público, incluirlo
        if (product.isPublic) return true;
        // Si tiene clientId específico, solo incluir si coincide
        if (product.clientId != null) {
          return product.clientId == _batchClientId;
        }
        return true;
      }).toList();

      if (products.isEmpty) {
        return Column(
          children: [
            Text(
              'No hay productos disponibles para este cliente',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Volver'),
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
              // --- 1. CAMBIO: selectedItemBuilder para mostrar SOLO TEXTO al seleccionar ---
              selectedItemBuilder: (BuildContext context) {
                return products.map<Widget>((ProductCatalogModel product) {
                  return Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      overflow: TextOverflow.ellipsis
                    ),
                    maxLines: 1,
                  );
                }).toList();
              },
            items: products.map((product) {
              return DropdownMenuItem(
                value: product.id,
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
                if (product.clientId != null)
                          FutureBuilder<ClientModel?>(
                            future: Provider.of<ClientService>(context, listen: false)
                                .getClient(widget.organizationId, product.clientId!),
                            builder: (context, snapshot) {
                              String clientText = 'Cliente: Cargando...';
                              
                              if (snapshot.hasData && snapshot.data != null) {
                                clientText = 'Cliente: ${snapshot.data!.name}';
                              } else if (snapshot.hasError) {
                                clientText = 'Cliente: Error';
                              }
                              
                              return Text(
                                clientText,
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Colors.grey[600]
                                ),
                              );
                            },
                          )
                          else // SI NO TIENE CLIENTE
                          Text(
                            'Público',
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.green[700], // Color verde para destacar que es público
                              fontStyle: FontStyle.italic
                            ),
                          ),
        ]),
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
            validator: (value) {
              if (value == null) {
                return 'Debes seleccionar un producto';
              }
              return null;
            },
          ),

          // CAMBIAR el Container de detalles para evitar overflow:
          if (_selectedProduct != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity, // FIX OVERFLOW
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [// CLIENTE (Movido aquí)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        if (_selectedProduct!.clientId != null)
                          Expanded(
                            child: FutureBuilder<ClientModel?>(
                              future: Provider.of<ClientService>(context, listen: false)
                                  .getClient(widget.organizationId, _selectedProduct!.clientId!),
                              builder: (context, snapshot) {
                                String clientText = 'Cargando...';
                                if (snapshot.hasData && snapshot.data != null) {
                                  clientText = snapshot.data!.name;
                                } else if (snapshot.hasError) {
                                  clientText = 'Error';
                                }
                                return Text(
                                  'Cliente: ${clientText}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                );
                              },
                            ),
                          )
                        else
                          Text(
                            'Público',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                  if (_selectedProduct!.reference != null) ...[
                    Text(
                      'SKU: ${_selectedProduct!.reference}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_selectedProduct!.description != null) ...[
                    Text(
                      _selectedProduct!.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3, // FIX OVERFLOW
                      overflow: TextOverflow.ellipsis, // FIX OVERFLOW
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_selectedProduct!.basePrice != null)
                    Text(
                      'Precio catálogo: ${_selectedProduct!.basePrice!.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 13,
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