import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/production_batch_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/phase_model.dart'; 
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/client_service.dart';
import 'create_production_batch_screen.dart';
import 'production_batch_detail_screen.dart';
import 'batch_product_detail_screen.dart';
import '../../utils/filter_utils.dart';

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
  String? _productStatusFilter; 
  String _productSearchQuery = '';

  // Verificar si hay filtros activos
  bool get _hasActiveFilters {
    if (_currentView == ProductionView.batches) {
      return _batchSearchQuery.isNotEmpty || 
             _batchClientFilter != null || 
             _batchUrgencyFilter != null;
    } else {
      return _productSearchQuery.isNotEmpty ||
             _productStatusFilter != null ||
             _productPhaseFilter != null ||
             _productClientFilter != null ||
             _productBatchFilter != null;
    }
  }
  
  // Limpiar filtros según vista actual
  void _clearAllFilters() {
    setState(() {
      if (_currentView == ProductionView.batches) {
        _batchSearchQuery = '';
        _batchClientFilter = null;
        _batchUrgencyFilter = null;
      } else {
        _productSearchQuery = '';
        _productStatusFilter = null;
        _productPhaseFilter = null;
        _productClientFilter = null;
        _productBatchFilter = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView ?? ProductionView.batches;

    if (widget.initialBatchFilter != null) {
      _productBatchFilter = widget.initialBatchFilter;
    }
    if (widget.initialPhaseFilter != null) {
      _productPhaseFilter = widget.initialPhaseFilter;
      _currentView = ProductionView.products;
    }
    if (widget.initialStatusFilter != null) {
      _productStatusFilter = widget.initialStatusFilter;
      _currentView = ProductionView.products;
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
      floatingActionButton:
          user.canManageProduction && _currentView == ProductionView.batches
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

  // --- WIDGET DE FILTRADO REDUCIDO ---

Widget _buildFilterOption<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required Function(T?) onChanged,
  IconData? icon,
  String allLabel = 'Todos',
}) {
  final isSelected = value != null;
  
  String displayValue = label;
  if (isSelected) {
    try {
      final selectedItem = items.firstWhere((item) => item.value == value);
      if (selectedItem.child is Text) {
        displayValue = (selectedItem.child as Text).data ?? label;
      } else if (selectedItem.child is Row) {
        final children = (selectedItem.child as Row).children;
        for (var child in children) {
          if (child is Text) {
            displayValue = child.data ?? label;
            break;
          }
        }
      }
    } catch (e) {
      displayValue = label;
    }
  }

  return Theme(
    data: Theme.of(context).copyWith(
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
    ),
    child: PopupMenuButton<T?>(  // CAMBIO: Añadir ? al tipo genérico
      initialValue: value,
      tooltip: 'Filtrar por $label',
      offset: const Offset(0, 35),
      onSelected: (T? newValue) {
        onChanged(newValue);
      },
      itemBuilder: (BuildContext context) {
        return [
          // Opción "Todos" - el valor null se pasa correctamente ahora
          PopupMenuItem<T?>(
            value: null,
            // CORRECCIÓN: Usamos un valor especial para detectar cuando se selecciona "Todos"
            onTap: () {
              // Esto se ejecuta DESPUÉS de que se cierra el popup
              Future.delayed(Duration.zero, () => onChanged(null));
            },
            height: 36,
            child: Row(
              children: [
                Icon(
                  Icons.restart_alt,
                  color: isSelected ? Colors.grey : Theme.of(context).primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  allLabel,
                  style: TextStyle(
                    fontWeight: !isSelected ? FontWeight.bold : FontWeight.normal,
                    color: !isSelected ? Theme.of(context).primaryColor : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          ...items.map((item) {
            final isItemActive = item.value == value;
            return PopupMenuItem<T?>(
              value: item.value,
              height: 36,
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isItemActive ? Theme.of(context).primaryColor : Colors.black87,
                  fontWeight: isItemActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                child: item.child,
              ),
            );
          }).toList(),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              isSelected ? displayValue : label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildFilters(UserModel user) {
    return Container(
      // Padding del contenedor reducido
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: _currentView == ProductionView.batches 
                  ? 'Buscar lote o proyecto...' 
                  : 'Buscar producto o SKU...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              // Input más compacto
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              isDense: true,
              suffixIcon: (_currentView == ProductionView.batches ? _batchSearchQuery : _productSearchQuery).isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _currentView == ProductionView.batches 
                          ? _batchSearchQuery = '' 
                          : _productSearchQuery = ''),
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (value) => setState(() => _currentView == ProductionView.batches 
                ? _batchSearchQuery = value 
                : _productSearchQuery = value),
          ),
          
          const SizedBox(height: 10),
          
          SizedBox(
            width: double.infinity,
            child: _currentView == ProductionView.batches
                ? _buildBatchFilterChips(user)
                : _buildProductFilterChips(user),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchFilterChips(UserModel user) {
    return StreamBuilder<List<ClientModel>>(
      stream: Provider.of<ClientService>(context, listen: false)
          .watchClients(user.organizationId!),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];
        
        // Creamos la lista de widgets (chips)
        final List<Widget> filterWidgets = [
            _buildFilterOption<String>(
              label: 'Cliente',
              value: _batchClientFilter,
              icon: Icons.storefront_outlined,
              allLabel: 'Todos',
              items: clients.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (val) => setState(() => _batchClientFilter = val),
            ),

            _buildFilterOption<String>(
              label: 'Urgencia',
              value: _batchUrgencyFilter,
              icon: Icons.priority_high_rounded,
              allLabel: 'Todas',
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Baja')),
                DropdownMenuItem(value: 'medium', child: Text('Media')),
                DropdownMenuItem(value: 'high', child: Text('Alta')),
                DropdownMenuItem(value: 'critical', child: Text('Urgente')),
              ],
              onChanged: (val) => setState(() => _batchUrgencyFilter = val),
            ),
          ];
          
// CAMBIO: Añadimos el botón de borrar filtros AL FINAL de la lista
        if (_hasActiveFilters) {
          filterWidgets.add(
             FilterUtils.buildClearFiltersButton(
                context: context,
                onPressed: _clearAllFilters,
                hasActiveFilters: true,
             ),
          );
        }

        // Retornamos el Wrap con todos los hijos juntos
        return Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center, // Alinea verticalmente el botón con los chips
          children: filterWidgets,
        );
      },
    );
  }

  Widget _buildProductFilterChips(UserModel user) {
    return StreamBuilder<List<ClientModel>>(
      stream: Provider.of<ClientService>(context, listen: false).watchClients(user.organizationId!),
      builder: (context, clientSnapshot) {
        final clients = clientSnapshot.data ?? [];

        return StreamBuilder<List<ProductionBatchModel>>(
          stream: Provider.of<ProductionBatchService>(context, listen: false).watchBatches(user.organizationId!),
          builder: (context, batchSnapshot) {
            final batches = batchSnapshot.data ?? [];
            final phases = ProductionPhase.getDefaultPhases();

            // Creamos la lista de widgets
            final List<Widget> filterWidgets = [
                // Filtro de Estado
                _buildFilterOption<String>(
                  label: 'Estado',
                  value: _productStatusFilter,
                  icon: Icons.flag_outlined,
                  allLabel: 'Todos',
                  items: ProductStatus.values.map((status) => DropdownMenuItem(
                    value: status.value,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(status.displayName),
                      ],
                    ),
                  )).toList(),
                  onChanged: (val) => setState(() => _productStatusFilter = val),
                ),

                // Filtro de Fase
                _buildFilterOption<String>(
                  label: 'Fase',
                  value: _productPhaseFilter,
                  icon: Icons.layers_outlined,
                  allLabel: 'Todas',
                  items: phases.map((phase) => DropdownMenuItem(
                    value: phase.id,
                    child: Text(phase.name),
                  )).toList(),
                  onChanged: (val) => setState(() => _productPhaseFilter = val),
                ),

                // Filtro de Cliente
                _buildFilterOption<String>(
                  label: 'Cliente',
                  value: _productClientFilter,
                  icon: Icons.storefront_outlined,
                  allLabel: 'Todos',
                  items: clients.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) => setState(() => _productClientFilter = val),
                ),

                // Filtro de Lote
                _buildFilterOption<String>(
                  label: 'Lote',
                  value: _productBatchFilter,
                  icon: Icons.inventory_2_outlined,
                  allLabel: 'Todos',
                  items: batches.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.batchNumber, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) => setState(() => _productBatchFilter = val),
                ),
              ];

// CAMBIO: Añadimos el botón al final si hay filtros
            if (_hasActiveFilters) {
              filterWidgets.add(
                 FilterUtils.buildClearFiltersButton(
                    context: context,
                    onPressed: _clearAllFilters,
                    hasActiveFilters: true,
                 ),
              );
            }

            return Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: filterWidgets,
            );
          }
        );
      },
    );
  }

  // --- LOGICA DE VISTA Y FILTRADO ---

  Widget _buildBatchesView(UserModel user) {
    return StreamBuilder<List<ProductionBatchModel>>(
      stream: Provider.of<ProductionBatchService>(context, listen: false)
          .watchBatches(user.organizationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var batches = snapshot.data ?? [];

        if (_batchClientFilter != null) {
          batches = batches.where((b) => b.clientId == _batchClientFilter).toList();
        }
        if (_batchUrgencyFilter != null) {
          batches = batches.where((b) => b.urgencyLevel == _batchUrgencyFilter).toList();
        }
        
        if (_batchSearchQuery.isNotEmpty) {
          batches = batches.where((b) =>
              b.batchNumber.toLowerCase().contains(_batchSearchQuery.toLowerCase()) ||
              b.projectName.toLowerCase().contains(_batchSearchQuery.toLowerCase())).toList();
        }

        if (batches.isEmpty) {
          return const Center(child: Text('No hay lotes para los filtros seleccionados'));
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
        
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAllProducts(user.organizationId!, batches),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var products = productsSnapshot.data ?? [];
            
            // --- CORRECCIÓN DE FILTRO DE ESTADO ---
            if (_productStatusFilter != null) {
              // El enum tiene un campo 'id' (el primer string en tu ejemplo: 'pending', 'cao', etc)
              // Comparamos el string del modelo (status) con el id del enum seleccionado.
              products = products.where((p) {
                final prod = p['product'] as BatchProductModel;
                return prod.productStatus == _productStatusFilter!; 
              }).toList();
            }

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

  // --- MÉTODOS AUXILIARES ---

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
        for (final product in products) {
          allProducts.add({
            'product': product,
            'batch': batch,
          });
        }
      } catch (e) {
        continue;
      }
    }

    return allProducts;
  }

  Widget _buildBatchCard(ProductionBatchModel batch, UserModel user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildUrgencyChip(batch.urgencyLevel),
                ],
              ),
              const SizedBox(height: 8),
              Text('Proyecto: ${batch.projectName}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text('Cliente: ${batch.clientName}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text(
                '${batch.totalProducts} productos',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: product.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      product.statusDisplayName,
                      style: TextStyle(
                        color: product.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Lote: ${batch.batchNumber} (#${product.productNumber})', 
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13)
                              ),
                            ),
                          ],
                        ),
                        if (product.productReference != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.qr_code, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'SKU: ${product.productReference!}', 
                                style: TextStyle(color: Colors.grey[700], fontSize: 13)
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product.quantity} uds',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          product.currentPhaseName,
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  )
                ],
              ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        urgencyEnum.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}