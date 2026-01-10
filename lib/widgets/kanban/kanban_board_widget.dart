// lib/widgets/kanban_board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/production_batch_model.dart';
import '../../models/user_model.dart';
import '../../services/kanban_service.dart';
import '../../services/phase_service.dart';
import '../../services/production_batch_service.dart';
import 'draggable_product_card.dart';
import '../../screens/production/batch_product_detail_screen.dart';
import '../../l10n/app_localizations.dart';

class KanbanBoardWidget extends StatefulWidget {
  final String organizationId;
  final UserModel currentUser;
  final double? maxHeight;
  final bool showFilters;
  final String? initialBatchFilter;
  final String? initialClientFilter;
  final String? initialProjectFilter;
  final bool? initialUrgentFilter;

  const KanbanBoardWidget({
    Key? key,
    required this.organizationId,
    required this.currentUser,
    this.maxHeight,
    this.showFilters = false,
    this.initialBatchFilter,
    this.initialClientFilter,
    this.initialProjectFilter,
    this.initialUrgentFilter,
  }) : super(key: key);

  @override
  State<KanbanBoardWidget> createState() => _KanbanBoardWidgetState();
}

class _KanbanBoardWidgetState extends State<KanbanBoardWidget> {
  final KanbanService _kanbanService = KanbanService();
  final PhaseService _phaseService = PhaseService();
  final ScrollController _scrollController = ScrollController();
  
  bool _isDragging = false;
  double _scrollSpeed = 0;

  String? _batchFilter;
  String? _clientFilter;
  String? _projectFilter;
  bool _onlyUrgentFilter = false;

  Map<String, List<Map<String, dynamic>>> _cachedProductsByPhase = {};
  List<ProductionPhase> _cachedPhases = [];

  @override
  void initState() {
    super.initState();
    _batchFilter = widget.initialBatchFilter;
    _clientFilter = widget.initialClientFilter;
    _projectFilter = widget.initialProjectFilter;
    _onlyUrgentFilter = widget.initialUrgentFilter ?? false;
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<ProductionPhase>>(
      stream: _phaseService.getOrganizationPhasesStream(widget.organizationId),
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
          future: _getAllProductsGroupedByPhase(widget.organizationId, phases),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final productsByPhase = productsSnapshot.data ?? {};
            _cachedProductsByPhase = productsByPhase;
            
            return _buildKanbanBoard(phases, productsByPhase, l10n);
          },
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
        if (_batchFilter != null && batch.id != _batchFilter) continue;
        if (_clientFilter != null && batch.clientId != _clientFilter) continue;
        if (_projectFilter != null && batch.projectId != _projectFilter) continue;

        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;

        for (final product in products) {
          bool passesFilter = true;

          if (_onlyUrgentFilter) {
            if (product.urgencyLevel != UrgencyLevel.urgent.value) {
              passesFilter = false;
            }
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
    AppLocalizations l10n,
  ) {
    final content = Listener(
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
              if (data == null) return false;
              
              if (!_kanbanService.canUserMoveToPhase(
                user: widget.currentUser,
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
                child: _buildKanbanColumn(phase, productsData, isAtWipLimit, l10n),
              );
            },
          );
        },
      ),
    );

    if (widget.maxHeight != null) {
      return SizedBox(height: widget.maxHeight, child: content);
    }

    return content;
  }

  Widget _buildKanbanColumn(
    ProductionPhase phase,
    List<Map<String, dynamic>> productsData,
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
                        allPhases: _cachedPhases,
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
              '${l10n.batchLabel} ${batch.batchNumber}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              '${l10n.skuLabel} ${product.productReference}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'De: ${product.currentPhaseName}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'A: ${toPhase.name}',
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
        organizationId: widget.organizationId,
        batchId: product.batchId,
        productId: product.id,
        newPhaseId: toPhase.id,
        newPhaseName: toPhase.name,
        userId: widget.currentUser.uid,
        userName: widget.currentUser.name,
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