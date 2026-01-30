import 'package:flutter/material.dart';
import 'package:gestion_produccion/services/phase_service.dart';
import 'package:provider/provider.dart';
import '../../models/production_batch_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/client_service.dart';
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
  String _searchQuery = ''; // Búsqueda universal
  String? _clientFilter; // Filtro de cliente
  String? _batchFilter; // Filtro de lote
  String? _phaseFilter; // Filtro de fase
  String? _statusFilter; // Filtro de estado
  String? _projectFilter; // Filtro de proyecto (solo Kanban)
  bool _onlyUrgent = false; // Filtro de urgentes
  final TextEditingController _searchController = TextEditingController();

  late Future<List<ProductionPhase>> _phasesFuture;

  // Verificar si hay filtros activos (universal)
  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _clientFilter != null ||
        _batchFilter != null ||
        _phaseFilter != null ||
        _statusFilter != null ||
        _projectFilter != null ||
        _onlyUrgent;
  }

  // Limpiar TODOS los filtros de TODAS las vistas
  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear(); // ← AGREGAR ESTO
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final organizationId = authService.currentUserData?.organizationId;
    _phasesFuture = Provider.of<PhaseService>(context, listen: false)
        .getActivePhases(organizationId!);
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
          user.canManageProduction && _currentView == ProductionView.batches
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
        children: [
          // Búsqueda universal (visible en todas las vistas donde esté configurada)
          if (FilterConfig.shouldShowFilter('search', _currentView))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _getSearchHint(l10n),
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

          // Filtros en chips (solo los visibles para la vista actual)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Filtro de Cliente
              if (FilterConfig.shouldShowFilter('client', _currentView))
                _buildClientFilterChip(user, l10n),

              // Filtro de Lote
              if (FilterConfig.shouldShowFilter('batch', _currentView))
                _buildBatchFilterChip(user, l10n),

              // Filtro de Fase
              if (FilterConfig.shouldShowFilter('phase', _currentView))
                _buildPhaseFilterChip(user, l10n),

              // Filtro de Estado
              if (FilterConfig.shouldShowFilter('status', _currentView))
                _buildStatusFilterChip(l10n),

              // Filtro de Proyecto (solo Kanban)
              if (FilterConfig.shouldShowFilter('project', _currentView))
                _buildProjectFilterChip(user, l10n),

              // Filtro de Urgentes
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

  String _getSearchHint(AppLocalizations l10n) {
    switch (_currentView) {
      case ProductionView.batches:
        return l10n.searchBatches;
      case ProductionView.products:
        return l10n.searchProducts;
      case ProductionView.kanban:
        return l10n.searchInKanban;
      default:
        return l10n.search;
    }
  }

  Widget _buildClientFilterChip(UserModel user, AppLocalizations l10n) {
    return FutureBuilder<List<ClientModel>>(
      future: Provider.of<ClientService>(context, listen: false)
          .getOrganizationClients(user.organizationId!, user.uid),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];
        final selectedClient =
            clients.where((c) => c.id == _clientFilter).firstOrNull;

        return FilterUtils.buildFilterOption<String>(
          context: context,
          label: l10n.client,
          value: _clientFilter,
          icon: Icons.storefront_outlined,
          allLabel: l10n.allClients,
          items: clients
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _clientFilter = val;
            });
            // Forzar rebuild inmediato
            Future.microtask(() => setState(() {}));
          },
        );
      },
    );
  }

  Widget _buildBatchFilterChip(UserModel user, AppLocalizations l10n) {
    return StreamBuilder<List<ProductionBatchModel>>(
      stream: Provider.of<ProductionBatchService>(context, listen: false)
          .watchBatches(user.organizationId!, user.uid),
      builder: (context, snapshot) {
        final batches = snapshot.data ?? [];
        final selectedBatch =
            batches.where((b) => b.id == _batchFilter).firstOrNull;

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
          onChanged: (val) {
            setState(() {
              _batchFilter = val;
            });
            Future.microtask(() => setState(() {}));
          },
        );
      },
    );
  }

  Widget _buildPhaseFilterChip(UserModel user, AppLocalizations l10n) {
    return FutureBuilder<List<ProductionPhase>>(
      // 3. Usamos la variable, NO la llamada a la función
      future: _phasesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final phases = snapshot.data!;

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
          onChanged: (val) {
            setState(() {
              _phaseFilter = val;
            });
            Future.microtask(() => setState(() {}));
          },
        );
      },
    );
  }

  Widget _buildStatusFilterChip(AppLocalizations l10n) {
    return FilterUtils.buildFilterOption<String>(
      context: context,
      label: l10n.status,
      value: _statusFilter,
      icon: Icons.flag_outlined,
      allLabel: l10n.allPluralMasculine,
      items: ProductStatus.values
          .map((status) => DropdownMenuItem(
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
              ))
          .toList(),
      onChanged: (val) {
        setState(() {
          _statusFilter = val;
        });
        Future.microtask(() => setState(() {}));
      },
    );
  }

  Widget _buildProjectFilterChip(UserModel user, AppLocalizations l10n) {
    // Similar al filtro de batch, pero para proyectos
    return StreamBuilder<List<ProductionBatchModel>>(
        stream: Provider.of<ProductionBatchService>(context, listen: false)
            .watchBatches(user.organizationId!, user.uid),
        builder: (context, batchSnapshot) {
          final batches = batchSnapshot.data ?? [];

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
            onChanged: (val) {
              setState(() {
                _projectFilter = val;
              });
              Future.microtask(() => setState(() {}));
            },
          );
        });
  }

  // ========================================
  // VISTAS
  // ========================================

  Widget _buildBatchesView(UserModel user, AppLocalizations l10n) {
    // 1. Necesitamos el servicio de clientes
    final clientService = Provider.of<ClientService>(context, listen: false);

    // 2. Primer Stream: Escuchamos los clientes
    return FutureBuilder<List<ClientModel>>(
      future: clientService.getOrganizationClients(
          user.organizationId!, user.uid), // Asumo que tienes este método
      builder: (context, clientSnapshot) {
        if (clientSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Si los clientes están cargando, no bloqueamos la UI, asumimos lista vacía temporalmente
        // o mostramos loader si prefieres bloquear todo.
        final clients = clientSnapshot.data ?? [];
        print("Clients loaded for batch view: ${clients.length}");

        // 3. OPTIMIZACIÓN CRÍTICA: Convertimos la lista a un Mapa para búsqueda instantánea
        // Esto crea algo tipo: {'client_id_1': '#FF0000', 'client_id_2': '#00FF00'}
        final Map<String, String> clientColors = {
          for (var client in clients)
            client.id: client.color! // Asumiendo que client.color es String hex
        };

        // 4. Segundo Stream: Escuchamos los lotes (Tu código original)
        return StreamBuilder<List<ProductionBatchModel>>(
          stream: Provider.of<ProductionBatchService>(context, listen: false)
              .watchBatches(user.organizationId!, user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('${l10n.error}: ${snapshot.error}'));
            }

            var batches = snapshot.data ?? [];
        print("batches loaded for batch view: ${batches.length}");

            // ... (Tus filtros originales se mantienen igual) ...
            if (_searchQuery.isNotEmpty) {
              batches = batches.where((batch) {
                final searchLower = _searchQuery.toLowerCase();
                return batch.batchNumber.toLowerCase().contains(searchLower) ||
                    batch.projectName.toLowerCase().contains(searchLower) ||
                    batch.clientName.toLowerCase().contains(searchLower);
              }).toList();
            }

            if (_clientFilter != null) {
              batches =
                  batches.where((b) => b.clientId == _clientFilter).toList();
            }

            if (batches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _hasActiveFilters
                          ? l10n.noResultsFound
                          : l10n.noBatchesFound,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: batches.length,
                itemBuilder: (context, index) {
                  final batch = batches[index];

                  return _buildBatchCard(
                    batch,
                    user,
                    l10n,
                    parseColorValue(clientColors[
                        batch.clientId]), // <--- Aquí pasas el color
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsView(UserModel user, AppLocalizations l10n) {
    // 1. Obtenemos el servicio de clientes
    final clientService = Provider.of<ClientService>(context, listen: false);

    // 2. PRIMER NIVEL: Escuchamos los clientes para obtener sus colores
    return FutureBuilder<List<ClientModel>>(
      future:
          clientService.getOrganizationClients(user.organizationId!, user.uid),
      builder: (context, clientSnapshot) {
        final clients = clientSnapshot.data ?? [];

        // 3. MAPEO RÁPIDO: ID Cliente -> Color Hex
        final Map<String, String> clientColors = {
          for (var client in clients) client.id: client.color!
        };

        // 4. SEGUNDO NIVEL: Tu código original de productos
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAllProductsWithBatches(user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('${l10n.error}: ${snapshot.error}'));
            }

            var allProducts = snapshot.data ?? [];

            // --- TUS FILTROS (Sin cambios) ---
            if (_searchQuery.isNotEmpty) {
              allProducts = allProducts.where((item) {
                final product = item['product'] as BatchProductModel;
                final searchLower = _searchQuery.toLowerCase();
                return product.productName
                        .toLowerCase()
                        .contains(searchLower) ||
                    (product.productReference
                            ?.toLowerCase()
                            .contains(searchLower) ??
                        false);
              }).toList();
            }

            if (_statusFilter != null) {
              allProducts = allProducts
                  .where((item) =>
                      (item['product'] as BatchProductModel).statusName ==
                      _statusFilter)
                  .toList();
            }

            if (_phaseFilter != null) {
              allProducts = allProducts
                  .where((item) =>
                      (item['product'] as BatchProductModel).currentPhase ==
                      _phaseFilter)
                  .toList();
            }

            if (_clientFilter != null) {
              allProducts = allProducts
                  .where((item) =>
                      (item['batch'] as ProductionBatchModel).clientId ==
                      _clientFilter)
                  .toList();
            }

            if (_batchFilter != null) {
              allProducts = allProducts
                  .where((item) =>
                      (item['batch'] as ProductionBatchModel).id ==
                      _batchFilter)
                  .toList();
            }

            if (_onlyUrgent) {
              allProducts = allProducts
                  .where((item) =>
                      (item['product'] as BatchProductModel).urgencyLevel ==
                      'urgent')
                  .toList();
            }
            // -------------------------------

            if (allProducts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.widgets_outlined,
                        size: 64, color: Colors.grey[400]),
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

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  final item = allProducts[index];
                  final product = item['product'] as BatchProductModel;
                  final batch = item['batch'] as ProductionBatchModel;

                  return _buildProductCard(
                      product,
                      batch,
                      user,
                      l10n,
                      parseColorValue(clientColors[
                          batch.clientId]) // <--- Aquí pasas el nuevo parámetro
                      );
                },
              ),
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
      // Pasar filtros unificados al Kanban
      initialClientFilter: _clientFilter,
      initialBatchFilter: _batchFilter,
      initialProjectFilter: _projectFilter,
      initialUrgentFilter: _onlyUrgent,
    );
  }

  // Helper para obtener todos los productos con sus lotes
  Future<List<Map<String, dynamic>>> _getAllProductsWithBatches(
      UserModel user) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final batches = await batchService.watchBatches(user.organizationId!, user.uid).first;

    List<Map<String, dynamic>> allProducts = [];

    for (final batch in batches) {
      try {
        final products = await batchService
            .watchBatchProducts(
              user.organizationId!,
              batch.id,
              user.uid,
            )
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

  Widget _buildBatchCard(ProductionBatchModel batch, UserModel user,
      AppLocalizations l10n, Color clientColor) {
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
                ],
              ),
              const SizedBox(height: 8),
              Text('${l10n.project}: ${batch.projectName}',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text('${l10n.client}: ${batch.clientName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
    Color clientColor,
  ) {
    final urgencyLevel = UrgencyLevel.fromString(product.urgencyLevel);

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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.statusLegacyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: product.statusLegacyColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      product.statusDisplayName,
                      style: TextStyle(
                        color: product.statusLegacyColor,
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
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 13)),
                            ),
                          ],
                        ),
                        if (product.productReference != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.qr_code,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('SKU: ${product.productReference!}',
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 13)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product.quantity} ${l10n.unitsSuffix}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          product.currentPhaseName,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 11),
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

  Color parseColorValue(String? color) {
    if (color == null) return defaultColor;
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (e) {
      return defaultColor;
    }
  }
}
