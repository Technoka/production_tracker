import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/production_batch_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/client_service.dart';
import 'create_production_batch_screen.dart';
import 'production_batch_detail_screen.dart';
import 'batch_product_detail_screen.dart';

enum ProductionView { batches, products }

class ProductionScreen extends StatefulWidget {
  final ProductionView? initialView;
  final String? initialBatchFilter;
  final String? initialPhaseFilter;
  final String? initialStatusFilter;

  const ProductionScreen({
    Key? key,
    this.initialView,
    this.initialBatchFilter,
    this.initialPhaseFilter,
    this.initialStatusFilter,
  }) : super(key: key);

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  late ProductionView _currentView;
  
  // Filtros para Vista de Lotes
  String? _batchClientFilter;
  String? _batchUrgencyFilter;
  String _batchSearchQuery = '';
  
  // Filtros para Vista de Productos
  String? _productPhaseFilter;
  String? _productClientFilter;
  String? _productBatchFilter;
  String _productSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView ?? ProductionView.batches;
    
    // Aplicar filtros iniciales
    if (widget.initialBatchFilter != null) {
      _productBatchFilter = widget.initialBatchFilter;
    }
    if (widget.initialPhaseFilter != null) {
      _productPhaseFilter = widget.initialPhaseFilter;
      _currentView = ProductionView.products;
    }
    if (widget.initialStatusFilter != null) {
      // Para estado de lote
      _currentView = ProductionView.batches;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producción')),
        body: const Center(child: Text('No tienes una organización asignada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Producción'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildViewToggle(),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(user!),
          Expanded(
            child: _currentView == ProductionView.batches
                ? _buildBatchesView(user)
                : _buildProductsView(user),
          ),
        ],
      ),
      floatingActionButton: user.canManageProduction && _currentView == ProductionView.batches
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateProductionBatchScreen(
                      organizationId: user.organizationId!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Lote'),
            )
          : null,
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<ProductionView>(
              segments: const [
                ButtonSegment(
                  value: ProductionView.batches,
                  label: Text('Vista por Lotes'),
                  icon: Icon(Icons.inventory_2),
                ),
                ButtonSegment(
                  value: ProductionView.products,
                  label: Text('Vista por Productos'),
                  icon: Icon(Icons.widgets),
                ),
              ],
              selected: {_currentView},
              onSelectionChanged: (Set<ProductionView> newSelection) {
                setState(() {
                  _currentView = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(UserModel user) {
    if (_currentView == ProductionView.batches) {
      return _buildBatchFilters(user);
    } else {
      return _buildProductFilters(user);
    }
  }

  Widget _buildBatchFilters(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Cliente
              Expanded(
                child: StreamBuilder<List<ClientModel>>(
                  stream: Provider.of<ClientService>(context, listen: false)
                      .watchClients(user.organizationId!),
                  builder: (context, snapshot) {
                    final clients = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _batchClientFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...clients.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (value) => setState(() => _batchClientFilter = value),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              // Urgencia
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Urgencia',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _batchUrgencyFilter,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'low', child: Text('Baja')),
                    DropdownMenuItem(value: 'medium', child: Text('Media')),
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                    DropdownMenuItem(value: 'critical', child: Text('Crítica')),
                  ],
                  onChanged: (value) => setState(() => _batchUrgencyFilter = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Búsqueda
          TextField(
            decoration: InputDecoration(
              labelText: 'Buscar por nombre de lote',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _batchSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _batchSearchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _batchSearchQuery = value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductFilters(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Fase
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Fase',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _productPhaseFilter,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'planned', child: Text('Planned')),
                    DropdownMenuItem(value: 'cutting', child: Text('Cutting')),
                    DropdownMenuItem(value: 'skiving', child: Text('Skiving')),
                    DropdownMenuItem(value: 'assembly', child: Text('Assembly')),
                    DropdownMenuItem(value: 'studio', child: Text('Studio')),
                  ],
                  onChanged: (value) => setState(() => _productPhaseFilter = value),
                ),
              ),
              const SizedBox(width: 8),
              
              // Cliente
              Expanded(
                child: StreamBuilder<List<ClientModel>>(
                  stream: Provider.of<ClientService>(context, listen: false)
                      .watchClients(user.organizationId!),
                  builder: (context, snapshot) {
                    final clients = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _productClientFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...clients.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (value) => setState(() => _productClientFilter = value),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              // Lote (con búsqueda)
              Expanded(
                child: StreamBuilder<List<ProductionBatchModel>>(
                  stream: Provider.of<ProductionBatchService>(context, listen: false)
                      .watchBatches(user.organizationId!),
                  builder: (context, snapshot) {
                    final batches = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Lote',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _productBatchFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...batches.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.batchNumber, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (value) => setState(() => _productBatchFilter = value),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Búsqueda
          TextField(
            decoration: InputDecoration(
              labelText: 'Buscar por nombre o SKU',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _productSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _productSearchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _productSearchQuery = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesView(UserModel user) {
    return StreamBuilder<List<ProductionBatchModel>>(
      stream: Provider.of<ProductionBatchService>(context, listen: false)
          .watchBatches(user.organizationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var batches = snapshot.data ?? [];

        // Aplicar filtros
        if (_batchClientFilter != null) {
          batches = batches.where((b) => b.clientId == _batchClientFilter).toList();
        }
        if (_batchUrgencyFilter != null) {
          batches = batches.where((b) => b.urgencyLevel == _batchUrgencyFilter).toList();
        }
        if (_batchSearchQuery.isNotEmpty) {
          batches = batches.where((b) => 
            b.batchNumber.toLowerCase().contains(_batchSearchQuery.toLowerCase()) ||
            b.projectName.toLowerCase().contains(_batchSearchQuery.toLowerCase())
          ).toList();
        }

        if (batches.isEmpty) {
          return const Center(child: Text('No hay lotes que coincidan con los filtros'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: batches.length,
          itemBuilder: (context, index) => _buildBatchCard(batches[index], user),
        );
      },
    );
  }

  Widget _buildProductsView(UserModel user) {
    return StreamBuilder<List<ProductionBatchModel>>(
      stream: Provider.of<ProductionBatchService>(context, listen: false)
          .watchBatches(user.organizationId!),
      builder: (context, batchSnapshot) {
        if (batchSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final batches = batchSnapshot.data ?? [];
            print('Total batches: ${batches.length} =========================================');

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAllProducts(user.organizationId!, batches),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var products = productsSnapshot.data ?? [];
            print('Total products before filtering: ${products.length} =========================================');

            // Aplicar filtros
            if (_productPhaseFilter != null) {
              products = products.where((p) => 
                (p['product'] as BatchProductModel).currentPhase == _productPhaseFilter
              ).toList();
            }
            if (_productClientFilter != null) {
              products = products.where((p) => 
                (p['batch'] as ProductionBatchModel).clientId == _productClientFilter
              ).toList();
            }
            if (_productBatchFilter != null) {
              products = products.where((p) => 
                (p['product'] as BatchProductModel).batchId == _productBatchFilter
              ).toList();
            }
            if (_productSearchQuery.isNotEmpty) {
              final query = _productSearchQuery.toLowerCase();
              products = products.where((p) {
                final product = p['product'] as BatchProductModel;
                return product.productName.toLowerCase().contains(query) ||
                       (product.productReference?.toLowerCase().contains(query) ?? false);
              }).toList();
            }

            if (products.isEmpty) {
              return const Center(child: Text('No hay productos que coincidan con los filtros'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index]['product'] as BatchProductModel;
                final batch = products[index]['batch'] as ProductionBatchModel;
                return _buildProductCard(product, batch, user);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAllProducts(
    String organizationId,
    List<ProductionBatchModel> batches,
  ) async {
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final allProducts = <Map<String, dynamic>>[];

    for (final batch in batches) {
      try {
        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;
print('Batch ${batch.batchNumber} has ${products.length} products =========================================');
        for (final product in products) {
          allProducts.add({
            'product': product,
            'batch': batch,
          });
        }
      } catch (e) {
        // Continuar con el siguiente lote
      }
    }

    return allProducts;
  }

  Widget _buildBatchCard(ProductionBatchModel batch, UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductionBatchDetailScreen(
                organizationId: user.organizationId!,
                batchId: batch.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batch.batchNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildUrgencyChip(batch.urgencyLevel),
                ],
              ),
              const SizedBox(height: 8),
              Text('Proyecto: ${batch.projectName}'),
              Text('Cliente: ${batch.clientName}'),
              const SizedBox(height: 8),
              Text(
                '${batch.totalProducts} productos',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BatchProductModel product,
    ProductionBatchModel batch,
    UserModel user,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BatchProductDetailScreen(
                organizationId: user.organizationId!,
                batchId: batch.id,
                productId: product.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.statusDisplayName,
                      style: TextStyle(
                        color: product.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Cantidad: ${product.quantity}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.tag, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Lote: ${batch.batchNumber}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.precision_manufacturing, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Fase: ${product.currentPhaseName}'),
                ],
              ),
              if (product.productReference != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.qr_code, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('SKU: ${product.productReference}'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    final urgencyEnum = UrgencyLevel.fromString(urgency);
    Color color;
    
    switch (urgencyEnum) {
      case UrgencyLevel.low:
        color = Colors.green;
        break;
      case UrgencyLevel.medium:
        color = Colors.orange;
        break;
      case UrgencyLevel.high:
        color = Colors.red;
        break;
      case UrgencyLevel.critical:
        color = Colors.red.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        urgencyEnum.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}