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
import '../../widgets/kanban_board_widget.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../l10n/app_localizations.dart';

enum ProductionView { batches, products, kanban }

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
  String _batchSearchQuery = '';

  // Filtros para Vista de Productos
  String? _productPhaseFilter;
  String? _productClientFilter;
  String? _productBatchFilter;
  String? _productStatusFilter; 
  String _productSearchQuery = '';
  bool? _onlyUrgentFilter;

  // Filtros para Vista Kanban
  String? _kanbanBatchFilter;
  String? _kanbanClientFilter;
  String? _kanbanProjectFilter;
  bool _kanbanOnlyUrgent = false;

  // Verificar si hay filtros activos
  bool get _hasActiveFilters {
    if (_currentView == ProductionView.batches) {
      return _batchSearchQuery.isNotEmpty || 
             _batchClientFilter != null;
    } else if (_currentView == ProductionView.products) {
      return _productSearchQuery.isNotEmpty ||
             _productStatusFilter != null ||
             _productPhaseFilter != null ||
             _productClientFilter != null ||
             _productBatchFilter != null || 
             _onlyUrgentFilter == true;
    } else {
      return _kanbanBatchFilter != null ||
             _kanbanClientFilter != null ||
             _kanbanProjectFilter != null ||
             _kanbanOnlyUrgent;
    }
  }
  
  // Limpiar filtros según vista actual
  void _clearAllFilters() {
    setState(() {
      if (_currentView == ProductionView.batches) {
        _batchSearchQuery = '';
        _batchClientFilter = null;
      } else if (_currentView == ProductionView.products) {
        _productSearchQuery = '';
        _productStatusFilter = null;
        _productPhaseFilter = null;
        _productClientFilter = null;
        _productBatchFilter = null;
        _onlyUrgentFilter = false;
      } else {
        _kanbanBatchFilter = null;
        _kanbanClientFilter = null;
        _kanbanProjectFilter = null;
        _kanbanOnlyUrgent = false;
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
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.production)),
        body: Center(child: Text(l10n.noOrganizationAssigned)),
        bottomNavigationBar: BottomNavBarWidget(currentIndex: 1, user: user!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productionTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildViewToggle(l10n),
        ),
      ),
      body: Column(
        children: [
          if (_currentView != ProductionView.kanban) _buildFilters(user!, l10n),
          Expanded(
            child: _currentView == ProductionView.batches
                ? _buildBatchesView(user!, l10n)
                : _currentView == ProductionView.products
                    ? _buildProductsView(user!, l10n)
                    : _buildKanbanView(user!, l10n),
          ),
        ],
      ),
      floatingActionButton:
          user!.canManageProduction && _currentView == ProductionView.batches
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateProductionBatchScreen(
                          organizationId: user!.organizationId!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createBatchBtn),
                )
              : null,
      bottomNavigationBar: BottomNavBarWidget(currentIndex: 1, user: user!),
    );
  }

  Widget _buildViewToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<ProductionView>(
              segments: [
                ButtonSegment(
                  value: ProductionView.batches,
                  label: Text(l10n.batchesViewTitleLabel),
                  icon: const Icon(Icons.inventory_2),
                ),
                ButtonSegment(
                  value: ProductionView.products,
                  label: Text(l10n.productsViewTitleLabel),
                  icon: const Icon(Icons.widgets),
                ),
                ButtonSegment(
                  value: ProductionView.kanban,
                  label: Text(l10n.kanban),
                  icon: const Icon(Icons.view_kanban),
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

  Widget _buildFilters(UserModel user, AppLocalizations l10n) {
    return Container(
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
          FilterUtils.buildSearchField(
            hintText: _currentView == ProductionView.batches 
                ? '${l10n.search} ${l10n.batchLabel.toLowerCase()}...' 
                : '${l10n.search} ${l10n.product.toLowerCase()}...',
            searchQuery: _currentView == ProductionView.batches ? _batchSearchQuery : _productSearchQuery,
            onChanged: (value) => setState(() => _currentView == ProductionView.batches 
                ? _batchSearchQuery = value 
                : _productSearchQuery = value),
          ),
          
          const SizedBox(height: 10),
          
          SizedBox(
            width: double.infinity,
            child: _currentView == ProductionView.batches
                ? _buildBatchFilterChips(user, l10n)
                : _buildProductFilterChips(user, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchFilterChips(UserModel user, AppLocalizations l10n) {
    return StreamBuilder<List<ClientModel>>(
      stream: Provider.of<ClientService>(context, listen: false)
          .watchClients(user.organizationId!),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];
        
        final List<Widget> filterWidgets = [
          FilterUtils.buildFilterOption<String>(
            context: context,
            label: l10n.client,
            value: _batchClientFilter,
            icon: Icons.storefront_outlined,
            allLabel: l10n.allClients,
            items: clients.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (val) => setState(() => _batchClientFilter = val),
          ),
        ];
          
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
      },
    );
  }

  Widget _buildProductFilterChips(UserModel user, AppLocalizations l10n) {
    return StreamBuilder<List<ClientModel>>(
      stream: Provider.of<ClientService>(context, listen: false).watchClients(user.organizationId!),
      builder: (context, clientSnapshot) {
        final clients = clientSnapshot.data ?? [];

        return StreamBuilder<List<ProductionBatchModel>>(
          stream: Provider.of<ProductionBatchService>(context, listen: false).watchBatches(user.organizationId!),
          builder: (context, batchSnapshot) {
            final batches = batchSnapshot.data ?? [];
            final phases = ProductionPhase.getDefaultPhases();

            final List<Widget> filterWidgets = [
              FilterUtils.buildFilterOption<String>(
                context: context,
                label: l10n.status,
                value: _productStatusFilter,
                icon: Icons.flag_outlined,
                allLabel: l10n.allPluralMasculine,
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

              FilterUtils.buildFilterOption<String>(
                context: context,
                label: l10n.phase,
                value: _productPhaseFilter,
                icon: Icons.layers_outlined,
                allLabel: l10n.allPluralFeminine,
                items: phases.map((phase) => DropdownMenuItem(
                  value: phase.id,
                  child: Text(phase.name),
                )).toList(),
                onChanged: (val) => setState(() => _productPhaseFilter = val),
              ),

              FilterUtils.buildFilterOption<String>(
                context: context,
                label: l10n.client,
                value: _productClientFilter,
                icon: Icons.storefront_outlined,
                allLabel: l10n.allClients,
                items: clients.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) => setState(() => _productClientFilter = val),
              ),

              FilterUtils.buildFilterOption<String>(
                context: context,
                label: l10n.batchLabel,
                value: _productBatchFilter,
                icon: Icons.inventory_2_outlined,
                allLabel: l10n.allPluralMasculine,
                items: batches.map((b) => DropdownMenuItem(
                  value: b.id,
                  child: Text(b.batchNumber, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) => setState(() => _productBatchFilter = val),
              ),
              
              FilterUtils.buildUrgencyFilterChip(
                context: context,
                isUrgentOnly: _onlyUrgentFilter ?? false,
                onToggle: () {
                  setState(() {
                    _onlyUrgentFilter = !(_onlyUrgentFilter ?? false);
                  });
                }
              ),
            ];

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

  Widget _buildBatchesView(UserModel user, AppLocalizations l10n) {
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
        
        if (_batchSearchQuery.isNotEmpty) {
          batches = batches.where((b) =>
              b.batchNumber.toLowerCase().contains(_batchSearchQuery.toLowerCase()) ||
              b.projectName.toLowerCase().contains(_batchSearchQuery.toLowerCase())).toList();
        }

        if (batches.isEmpty) {
          return Center(child: Text(l10n.noBatchesFound));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: batches.length,
          itemBuilder: (context, index) => _buildBatchCard(batches[index], user, l10n),
        );
      },
    );
  }

  Widget _buildProductsView(UserModel user, AppLocalizations l10n) {
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
            
            if (_productStatusFilter != null) {
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
            
            if (_onlyUrgentFilter == true) {
              products = products.where((p) {
                final product = p['product'] as BatchProductModel;
                return product.urgencyLevel == UrgencyLevel.urgent.value;
              }).toList();
            }

            if (products.isEmpty) {
              return Center(child: Text(l10n.noProductsFound));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index]['product'] as BatchProductModel;
                final batch = products[index]['batch'] as ProductionBatchModel;
                return _buildProductCard(product, batch, user, l10n);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKanbanView(UserModel user, AppLocalizations l10n) {
    return KanbanBoardWidget(
      organizationId: user.organizationId!,
      currentUser: user,
      initialBatchFilter: _kanbanBatchFilter,
      initialClientFilter: _kanbanClientFilter,
      initialProjectFilter: _kanbanProjectFilter,
      initialUrgentFilter: _kanbanOnlyUrgent,
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

  Widget _buildBatchCard(ProductionBatchModel batch, UserModel user, AppLocalizations l10n) {
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
                ],
              ),
              const SizedBox(height: 8),
              Text('${l10n.project}: ${batch.projectName}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text('${l10n.client}: ${batch.clientName}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text(
                '${batch.totalProducts} ${l10n.products}',
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
    AppLocalizations l10n,
  ) {
    final urgencyLevel = UrgencyLevel.fromString(product.urgencyLevel);

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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            product.productName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        if (urgencyLevel == UrgencyLevel.urgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: urgencyLevel.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: urgencyLevel.color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              urgencyLevel.displayName,
                              style: TextStyle(
                                color: urgencyLevel.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
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
                                '${l10n.batchLabel} ${batch.batchNumber} (#${product.productNumber})', 
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
                          '${product.quantity} ${l10n.unitsSuffix}',
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
}