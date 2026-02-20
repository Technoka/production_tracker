// lib/screens/production/production_screen.dart
// ✅ OPTIMIZADO: Usa ProductionDataProvider para eliminar queries redundantes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/production_batch_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import '../../providers/production_data_provider.dart';
import 'create_production_batch_screen.dart';
import 'production_batch_detail_screen.dart';
import 'batch_product_detail_screen.dart';
import '../../utils/filter_utils.dart';
import '../../widgets/kanban/kanban_board_widget.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../l10n/app_localizations.dart';

enum ProductionView { batches, products, kanban }

// Configuración de qué filtros aparecen en cada vista
class FilterConfig {
  static const Map<String, List<ProductionView>> filterVisibility = {
    'search': [
      ProductionView.batches,
      ProductionView.products,
      ProductionView.kanban
    ],
    'client': [
      ProductionView.batches,
      ProductionView.products,
      ProductionView.kanban
    ],
    'batch': [ProductionView.products, ProductionView.kanban],
    'phase': [ProductionView.products],
    'status': [ProductionView.products],
    'project': [ProductionView.kanban],
    'urgent': [ProductionView.products, ProductionView.kanban],
  };

  static bool shouldShowFilter(String filterKey, ProductionView view) {
    return filterVisibility[filterKey]?.contains(view) ?? false;
  }
}

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

  // ========================================
  // FILTROS UNIFICADOS (persisten entre vistas)
  // ========================================
  String _searchQuery = '';
  String? _clientFilter;
  String? _batchFilter;
  String? _phaseFilter;
  String? _statusFilter;
  String? _projectFilter;
  bool _onlyUrgent = false;
  final TextEditingController _searchController = TextEditingController();

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _clientFilter != null ||
        _batchFilter != null ||
        _phaseFilter != null ||
        _statusFilter != null ||
        _projectFilter != null ||
        _onlyUrgent;
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _clientFilter = null;
      _batchFilter = null;
      _phaseFilter = null;
      _statusFilter = null;
      _projectFilter = null;
      _onlyUrgent = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView ?? ProductionView.batches;

    // Inicializar filtros si vienen de navegación
    if (widget.initialBatchFilter != null) {
      _batchFilter = widget.initialBatchFilter;
    }
    if (widget.initialPhaseFilter != null) {
      _phaseFilter = widget.initialPhaseFilter;
      _currentView = ProductionView.products;
    }
    if (widget.initialStatusFilter != null) {
      _statusFilter = widget.initialStatusFilter;
      _currentView = ProductionView.products;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final permissionService = Provider.of<PermissionService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.production)),
        body: Center(child: Text(l10n.noOrganizationAssigned)),
        bottomNavigationBar: BottomNavBarWidget(currentIndex: 1, user: user!),
      );
    }

    // ✅ OPTIMIZACIÓN: Usar permisos cacheados
    final canCreateBatches = permissionService.canCreateBatches;

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
          _buildFilters(user!, l10n),
          Expanded(
            child: _currentView == ProductionView.batches
                ? _buildBatchesView(user, l10n)
                : _currentView == ProductionView.products
                    ? _buildProductsView(user, l10n)
                    : _buildKanbanView(user, l10n),
          ),
        ],
      ),
      floatingActionButton:
          canCreateBatches && _currentView == ProductionView.batches
              ? SizedBox(
                  height: 40,
                  child: FloatingActionButton.extended(
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
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(l10n.createBatchBtn,
                        style: const TextStyle(fontSize: 13)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                )
              : null,
      bottomNavigationBar: BottomNavBarWidget(currentIndex: 1, user: user),
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
                  label: Text(l10n.batches),
                  icon: const Icon(Icons.inventory_2),
                ),
                ButtonSegment(
                  value: ProductionView.products,
                  label: Text(l10n.orders),
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
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Búsqueda
          if (FilterConfig.shouldShowFilter('search', _currentView))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.search,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

          // Chips de filtros
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (FilterConfig.shouldShowFilter('client', _currentView))
                _buildClientFilterChip(user, l10n),
              if (FilterConfig.shouldShowFilter('batch', _currentView))
                _buildBatchFilterChip(user, l10n),
              if (FilterConfig.shouldShowFilter('phase', _currentView))
                _buildPhaseFilterChip(user, l10n),
              if (FilterConfig.shouldShowFilter('status', _currentView))
                _buildStatusFilterChip(user, l10n),
              if (FilterConfig.shouldShowFilter('project', _currentView))
                _buildProjectFilterChip(user, l10n),
              if (FilterConfig.shouldShowFilter('urgent', _currentView))
                FilterUtils.buildUrgencyFilterChip(
                    context: context,
                    isUrgentOnly: _onlyUrgent,
                    onToggle: () {
                      setState(() {
                        _onlyUrgent = !_onlyUrgent;
                      });
                    }),

              // Botón de limpiar filtros (universal)
              if (_hasActiveFilters)
                FilterUtils.buildClearFiltersButton(
                  context: context,
                  onPressed: _clearAllFilters,
                  hasActiveFilters: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ OPTIMIZACIÓN: Usar ProductionDataProvider en lugar de queries individuales
  Widget _buildClientFilterChip(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        final clients = provider.clients;

        return FilterUtils.buildFilterOption<String>(
          context: context,
          label: l10n.client,
          value: _clientFilter,
          icon: Icons.person_outline,
          allLabel: l10n.allPluralMasculine,
          items: clients
              .map((client) => DropdownMenuItem(
                    value: client.id,
                    child: Text(client.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _clientFilter = val),
        );
      },
    );
  }

  Widget _buildBatchFilterChip(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        final batches = provider.batches;

        return FilterUtils.buildFilterOption<String>(
          context: context,
          label: l10n.batchLabel,
          value: _batchFilter,
          icon: Icons.inventory_2_outlined,
          allLabel: l10n.allPluralMasculine,
          items: batches
              .map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.batchNumber, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _batchFilter = val),
        );
      },
    );
  }

  Widget _buildPhaseFilterChip(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        final phases = provider.phases;

        return FilterUtils.buildFilterOption<String>(
          context: context,
          label: l10n.phase,
          value: _phaseFilter,
          icon: Icons.layers_outlined,
          allLabel: l10n.allPluralFeminine,
          items: phases
              .map((phase) => DropdownMenuItem(
                    value: phase.id,
                    child: Text(phase.name),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _phaseFilter = val),
        );
      },
    );
  }

  Widget _buildStatusFilterChip(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        final statuses = provider.statuses;

        return FilterUtils.buildFilterOption<String>(
          context: context,
          label: l10n.status,
          value: _statusFilter,
          icon: Icons.flag_outlined,
          allLabel: l10n.allPluralMasculine,
          items: statuses
              .map((status) => DropdownMenuItem(
                    value: status.id,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(int.parse(status.color.substring(1),
                                    radix: 16) +
                                0xFF000000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(status.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _statusFilter = val),
        );
      },
    );
  }

  Widget _buildProjectFilterChip(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        final batches = provider.batches;

        // Extraer proyectos únicos
        final Map<String, String> projects = {};
        for (var batch in batches) {
          projects[batch.projectId] = batch.projectName;
        }

        return FilterUtils.buildFilterOption<String>(
          context: context,
          label: l10n.project,
          value: _projectFilter,
          icon: Icons.folder_outlined,
          allLabel: l10n.allPluralMasculine,
          items: projects.entries
              .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _projectFilter = val),
        );
      },
    );
  }

  // ========================================
  // VISTAS OPTIMIZADAS
  // ========================================

  // ✅ OPTIMIZACIÓN: Sin StreamBuilders, usa datos del provider
  Widget _buildBatchesView(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrar lotes usando el provider
        var batches = provider.filterBatches(
          clientId: _clientFilter,
          searchQuery: _searchQuery,
        );

        if (batches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _hasActiveFilters ? l10n.noResultsFound : l10n.noBatchesFound,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            final client = provider.getClientById(batch.clientId);
            final clientColor = client != null && client.color != null
                ? Color(int.parse(client.color!.substring(1), radix: 16) +
                    0xFF000000)
                : Colors.grey;

            return _buildBatchCard(batch, user, l10n, clientColor);
          },
        );
      },
    );
  }

  // ✅ OPTIMIZACIÓN: Sin FutureBuilder anidados, usa datos del provider
  Widget _buildProductsView(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrar productos usando el provider
        var allProducts = provider.filterProducts(
          clientId: _clientFilter,
          batchId: _batchFilter,
          phaseId: _phaseFilter,
          statusId: _statusFilter,
          searchQuery: _searchQuery,
          onlyUrgent: _onlyUrgent,
        );

        if (allProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.widgets_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _hasActiveFilters
                      ? l10n.noResultsFound
                      : l10n.noProductsFound,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allProducts.length,
          itemBuilder: (context, index) {
            final item = allProducts[index];
            final product = item['product'] as BatchProductModel;
            final batch = item['batch'] as ProductionBatchModel;
            final client = provider.getClientById(batch.clientId);
            final clientColor = client != null && client.color != null
                ? Color(int.parse(client.color!.substring(1), radix: 16) +
                    0xFF000000)
                : Colors.grey;

            return _buildProductCard(product, batch, user, l10n, clientColor);
          },
        );
      },
    );
  }

  Widget _buildKanbanView(UserModel user, AppLocalizations l10n) {
    return Consumer<ProductionDataProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return KanbanBoardWidget(
          organizationId: user.organizationId!,
          initialClientFilter: _clientFilter,
          initialBatchFilter: _batchFilter,
          initialProjectFilter: _projectFilter,
          initialUrgentFilter: _onlyUrgent,
        );
      },
    );
  }

  Widget _buildBatchCard(
    ProductionBatchModel batch,
    UserModel user,
    AppLocalizations l10n,
    Color clientColor,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      color: clientColor.withAlpha(20),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: clientColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: clientColor),
                    ),
                    child: Text(
                      batch.clientName,
                      style: TextStyle(
                        fontSize: 11,
                        color: clientColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.project}: ${batch.projectName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.widgets, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${batch.totalProducts} ${l10n.products}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (batch.completedProducts > 0)
                    Text(
                      ' (${batch.completedProducts} / ${batch.totalProducts} ${l10n.complete})',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
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
    Color clientColor,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      color: clientColor.withAlpha(20),
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
                  if (product.urgencyLevel == UrgencyLevel.urgent.value)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: UrgencyLevel.urgent.color.withOpacity(0.3)),
                      ),
                      child: Text(
                        UrgencyLevel.fromString(product.urgencyLevel)
                            .displayName
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: UrgencyLevel.urgent.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                        '${l10n.batchLabel} ${batch.batchNumber} (# ${product.productNumber}/${batch.totalProducts})',
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.qr_code, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${l10n.skuLabel} ${product.productReference!}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.layers, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.phase}: ${product.currentPhaseName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (product.statusName != null) ...[
                    Icon(Icons.flag, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.status}: ${product.statusName!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
