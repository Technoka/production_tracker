import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/production_batch_model.dart';
import '../../models/user_model.dart';
import '../../services/kanban_service.dart';
import '../../services/phase_service.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../widgets/draggable_product_card.dart';
import '../../utils/filter_utils.dart';
import '../production/batch_product_detail_screen.dart';
// IMPORTAR IDIOMA
import '../../l10n/app_localizations.dart';

class GlobalKanbanBoardScreen extends StatefulWidget {
  const GlobalKanbanBoardScreen({Key? key}) : super(key: key);

  @override
  State<GlobalKanbanBoardScreen> createState() => _GlobalKanbanBoardScreenState();
}

class _GlobalKanbanBoardScreenState extends State<GlobalKanbanBoardScreen> {
  final KanbanService _kanbanService = KanbanService();
  final PhaseService _phaseService = PhaseService();
  final AuthService _authService = AuthService();
  
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  double _scrollSpeed = 0;

  String _searchQuery = '';
  String? _batchFilter;
  UserModel? _currentUser;

  Map<String, List<Map<String, dynamic>>> _cachedProductsByPhase = {};
  List<ProductionPhase> _cachedPhases = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final user = await _authService.getUserById(userId);
        if (mounted) {
          setState(() => _currentUser = user);
        }
      }
    } catch (e) {
      print('Error cargando usuario: $e');
    }
  }

  void _startAutoScroll() {
    Stream.periodic(const Duration(milliseconds: 50)).listen((_) {
      if (_isDragging && _scrollSpeed != 0 && mounted) {
        final newOffset = _scrollController.offset + _scrollSpeed;
        final maxScroll = _scrollController.position.maxScrollExtent;
        
        if (newOffset >= 0 && newOffset <= maxScroll) {
          _scrollController.jumpTo(newOffset);
        }
      }
    });
  }

  void _updateAutoScroll(Offset globalPosition) {
    if (!_isDragging) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final screenWidth = box.size.width;

    const edgeThreshold = 100.0;
    const maxScrollSpeed = 15.0;

    if (localPosition.dx < edgeThreshold) {
      final distance = edgeThreshold - localPosition.dx;
      _scrollSpeed = -(distance / edgeThreshold * maxScrollSpeed);
    } else if (localPosition.dx > screenWidth - edgeThreshold) {
      final distance = localPosition.dx - (screenWidth - edgeThreshold);
      _scrollSpeed = distance / edgeThreshold * maxScrollSpeed;
    } else {
      _scrollSpeed = 0;
    }
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty || _batchFilter != null;
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _batchFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // LOCALIZACION
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.kanban)),
        body: Center(child: Text(l10n.noOrganizationAssigned)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kanbanBoardGlobal),
        actions: [
          StreamBuilder<Map<String, dynamic>>(
            stream: _getStatsStream(user!.organizationId!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final stats = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.inventory_2,
                      value: stats['totalProducts'].toString(),
                      color: Colors.blue,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersBar(user, l10n),
          Expanded(
            child: StreamBuilder<List<ProductionPhase>>(
              stream: _phaseService.getOrganizationPhasesStream(user.organizationId!),
              builder: (context, phasesSnapshot) {
                if (phasesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!phasesSnapshot.hasData || phasesSnapshot.data!.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                final phases = phasesSnapshot.data!
                    .where((p) => p.isActive)
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));
                
                _cachedPhases = phases;
                
                return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                  future: _getAllProductsGroupedByPhase(user.organizationId!, phases),
                  builder: (context, productsSnapshot) {
                    if (productsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final productsByPhase = productsSnapshot.data ?? {};
                    _cachedProductsByPhase = productsByPhase;
                    
                    return _buildKanbanBoard(phases, productsByPhase, user, l10n);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(UserModel user, AppLocalizations l10n) {
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
            hintText: l10n.searchByNameOrRef,
            searchQuery: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          
          const SizedBox(height: 10),
          
          Row(
            children: [
              Expanded(
                child: _buildFilterChips(user, l10n),
              ),
              FilterUtils.buildClearFiltersButton(
                context: context,
                onPressed: _clearAllFilters,
                hasActiveFilters: _hasActiveFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(UserModel user, AppLocalizations l10n) {
    return StreamBuilder<List<ProductionBatchModel>>(
      stream: Provider.of<ProductionBatchService>(context, listen: false)
          .watchBatches(user.organizationId!),
      builder: (context, snapshot) {
        final batches = snapshot.data ?? [];
        
        return Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          alignment: WrapAlignment.start,
          children: [
            FilterUtils.buildFilterOption<String>(
              context: context,
              label: l10n.batchLabel, // Usando clave existente hack
              value: _batchFilter,
              icon: Icons.inventory_2_outlined,
              allLabel: l10n.selectAll.replaceAll(' Seleccionar ', ''), // Usando "Todo" o similar
              items: batches.map((b) => DropdownMenuItem(
                value: b.id,
                child: Text(b.batchNumber, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (val) => setState(() => _batchFilter = val),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getAllProductsGroupedByPhase(
    String organizationId,
    List<ProductionPhase> phases,
  ) async {
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    for (final phase in phases) {
      groupedProducts[phase.id] = [];
    }

    try {
      final batches = await batchService.watchBatches(organizationId).first;

      for (final batch in batches) {
        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;

        for (final product in products) {
          bool passesFilter = true;

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            passesFilter = product.productName.toLowerCase().contains(query) ||
                          (product.productReference?.toLowerCase().contains(query) ?? false);
          }

          if (_batchFilter != null && batch.id != _batchFilter) {
            passesFilter = false;
          }

          if (passesFilter) {
            final phaseId = product.currentPhase;
            if (groupedProducts.containsKey(phaseId)) {
              groupedProducts[phaseId]!.add({
                'product': product,
                'batch': batch,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error cargando productos: $e');
    }

    return groupedProducts;
  }

  Widget _buildKanbanBoard(
    List<ProductionPhase> phases,
    Map<String, List<Map<String, dynamic>>> productsByPhase,
    UserModel user,
    AppLocalizations l10n,
  ) {
    return Listener(
      onPointerMove: (details) {
        if (_isDragging) {
          _updateAutoScroll(details.position);
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: phases.length,
        itemBuilder: (context, index) {
          final phase = phases[index];
          final productsData = productsByPhase[phase.id] ?? [];
          final isAtWipLimit = productsData.length >= phase.wipLimit;
          
          return DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) {
              if (data == null || _currentUser == null) return false;
              
              if (!_kanbanService.canUserMoveToPhase(
                user: _currentUser!,
                phaseId: phase.id,
              )) {
                return false;
              }
              
              final productData = data['product'] as BatchProductModel;

              if (productData.currentPhase == phase.id) return false;

              if (productData.currentPhase != phase.id && isAtWipLimit) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.wipLimitReachedIn} ${phase.name}'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return false;
              }
              
              return true;
            },
            onAccept: (data) {
              _showMoveConfirmationDialog(data, phase, l10n);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: isHovering
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildKanbanColumn(phase, productsData, phases, isAtWipLimit, l10n),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showMoveConfirmationDialog(
    Map<String, dynamic> data,
    ProductionPhase toPhase,
    AppLocalizations l10n,
  ) async {
    final product = data['product'] as BatchProductModel;
    final batch = data['batch'] as ProductionBatchModel;
    
    final currentPhaseIndex = _cachedPhases.indexWhere((p) => p.id == product.currentPhase);
    final newPhaseIndex = _cachedPhases.indexWhere((p) => p.id == toPhase.id);
    final isForward = newPhaseIndex > currentPhaseIndex;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isForward ? Icons.arrow_forward : Icons.arrow_back,
              color: isForward ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isForward ? l10n.moveProductForward : l10n.moveProductBackward,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.batchLabel}: ${batch.batchNumber}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              '${l10n.skuLabel}: ${product.productReference}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.forSearch.replaceAll('para', 'De').trim()}: ${product.currentPhaseName}', // "De" makeshift
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.forSearch.replaceAll('para', 'A').trim()}: ${toPhase.name}', // "A" makeshift
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (!isForward) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.moveWarningPart1} ${toPhase.name}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isForward ? Colors.green : Colors.orange,
            ),
            child: Text(isForward ? l10n.moveForward : l10n.moveBackward),
          ),
        ],
      ),
    );

    if (result == true) {
      await _handleProductMove(data, toPhase, l10n);
    }
  }

  Future<void> _handleProductMove(
    Map<String, dynamic> data,
    ProductionPhase toPhase,
    AppLocalizations l10n,
  ) async {
    try {
      final product = data['product'] as BatchProductModel;
      final batch = data['batch'] as ProductionBatchModel;
      final fromPhaseId = product.currentPhase;
      
      if (fromPhaseId == toPhase.id) return;
      
      final batchService = Provider.of<ProductionBatchService>(context, listen: false);
      
      final success = await batchService.updateProductPhaseFromKanban(
        organizationId: _currentUser!.organizationId!,
        batchId: product.batchId,
        productId: product.id,
        newPhaseId: toPhase.id,
        newPhaseName: toPhase.name,
        userId: _currentUser!.uid,
        userName: _currentUser!.name,
        allPhases: _cachedPhases,
      );
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _cachedProductsByPhase[fromPhaseId]?.removeWhere(
            (item) => (item['product'] as BatchProductModel).id == product.id
          );
          
          final updatedProduct = product.copyWith(
            currentPhase: toPhase.id,
            currentPhaseName: toPhase.name,
          );
          
          _cachedProductsByPhase[toPhase.id]?.add({
            'product': updatedProduct,
            'batch': batch,
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.productMovedTo} ${toPhase.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(l10n.phaseUpdateError);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildKanbanColumn(
    ProductionPhase phase,
    List<Map<String, dynamic>> productsData,
    List<ProductionPhase> allPhases,
    bool isAtWipLimit,
    AppLocalizations l10n,
  ) {
    final color = _parseColor(phase.color);
    
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAtWipLimit ? Colors.orange : Colors.grey.shade300,
          width: isAtWipLimit ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumnHeader(phase, color, productsData.length, isAtWipLimit, l10n),
          const Divider(height: 1),
          Expanded(
            child: productsData.isEmpty
                ? _buildEmptyColumnState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: productsData.length,
                    itemBuilder: (context, index) {
                      final product = productsData[index]['product'] as BatchProductModel;
                      final batch = productsData[index]['batch'] as ProductionBatchModel;
                      
                      return DraggableProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        allPhases: allPhases,
                        batchNumber: batch.batchNumber,
                        batch: batch,
                        onTap: () => _handleProductTap(product, batch),
                                    onDragStarted: () { _isDragging = true; },
                                    onDragEnd: () { _isDragging = false; _scrollSpeed = 0; },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(ProductionPhase phase, Color color, int count, bool isAtWipLimit, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getPhaseIcon(phase.icon),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${l10n.products}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAtWipLimit) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.limitReached,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyColumnState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(l10n.emptyColumnState, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_kanban, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(l10n.noPhasesConfigured, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(l10n.configurePhasesFirst, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>> _getStatsStream(String organizationId) {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final batchService = Provider.of<ProductionBatchService>(context, listen: false);
      
      try {
        final batches = await batchService.watchBatches(organizationId).first;
        int totalProducts = 0;

        for (final batch in batches) {
          final products = await batchService.watchBatchProducts(organizationId, batch.id).first;
          totalProducts += products.length;
        }

        return {'totalProducts': totalProducts};
      } catch (e) {
        return {'totalProducts': 0};
      }
    });
  }

  void _handleProductTap(BatchProductModel product, ProductionBatchModel batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchProductDetailScreen(
          organizationId: batch.organizationId,
          batchId: batch.id,
          productId: product.id,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getPhaseIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'planned': return Icons.calendar_today;
      case 'cutting': return Icons.content_cut;
      case 'skiving': return Icons.layers;
      case 'assembly': return Icons.construction;
      case 'studio': return Icons.brush;
      default: return Icons.work;
    }
  }
}