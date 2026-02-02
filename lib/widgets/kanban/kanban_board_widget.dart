// lib/widgets/kanban/kanban_board_widget.dart

import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/services/organization_member_service.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/production_batch_model.dart';
import '../../models/product_status_model.dart';
import '../../services/production_batch_service.dart';
import '../../services/auth_service.dart';
import '../../services/status_transition_service.dart';
import 'draggable_product_card.dart';
import '../../screens/production/batch_product_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/validation_dialogs/validation_dialog_manager.dart';
import '../../utils/message_events_helper.dart';

enum KanbanViewMode { phases, statuses }

class KanbanBoardWidget extends StatefulWidget {
  final String organizationId;
  final double? maxHeight;
  final bool showFilters;
  final String? initialBatchFilter;
  final String? initialClientFilter;
  final String? initialProjectFilter;
  final bool? initialUrgentFilter;

  const KanbanBoardWidget({
    Key? key,
    required this.organizationId,
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
  final ScrollController _scrollController = ScrollController();

  bool _isDragging = false;
  double _scrollSpeed = 0;
  KanbanViewMode _viewMode = KanbanViewMode.phases;

  String? _batchFilter;
  String? _clientFilter;
  String? _projectFilter;
  bool _onlyUrgentFilter = false;

  Map<String, List<String>> _availableTransitions = {};
  bool _isLoadingTransitions = true;

  @override
  void initState() {
    super.initState();
    _batchFilter = widget.initialBatchFilter;
    _clientFilter = widget.initialClientFilter;
    _projectFilter = widget.initialProjectFilter;
    _onlyUrgentFilter = widget.initialUrgentFilter ?? false;
    _startAutoScroll();
    _loadAvailableTransitions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KanbanBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los filtros que vienen del padre han cambiado, actualizamos el estado local
    if (widget.initialBatchFilter != oldWidget.initialBatchFilter) {
      setState(() {
        _batchFilter = widget.initialBatchFilter;
      });
    }
    if (widget.initialClientFilter != oldWidget.initialClientFilter) {
      setState(() {
        _clientFilter = widget.initialClientFilter;
      });
    }
    if (widget.initialProjectFilter != oldWidget.initialProjectFilter) {
      setState(() {
        _projectFilter = widget.initialProjectFilter;
      });
    }
    if (widget.initialUrgentFilter != oldWidget.initialUrgentFilter) {
      setState(() {
        _onlyUrgentFilter = widget.initialUrgentFilter ?? false;
      });
    }
  }

  Future<void> _loadAvailableTransitions() async {
    try {
      final transitionService = Provider.of<StatusTransitionService>(
        context,
        listen: false,
      );
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);

      // Obtener todas las transiciones posibles
      final allTransitions = await transitionService.getAvailableTransitions(
        organizationId: widget.organizationId,
        userRoleId: memberService.currentRole!.id,
      );

      // Crear mapa de transiciones disponibles por estado origen
      final Map<String, List<String>> transitionsMap = {};

      for (final transition in allTransitions) {
        if (transition.isActive) {
          transitionsMap
              .putIfAbsent(transition.fromStatusId, () => [])
              .add(transition.toStatusId);
        }
      }

      setState(() {
        _availableTransitions = transitionsMap;
        _isLoadingTransitions = false;
      });
    } catch (e) {
      debugPrint('Error loading transitions: $e');
      setState(() => _isLoadingTransitions = false);
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

    return Column(
      children: [
        // Toggle de vista
        _buildViewToggle(l10n),
        const SizedBox(height: 8),

        // Board principal
        Expanded(
          child: _viewMode == KanbanViewMode.phases
              ? _buildPhaseView(l10n)
              : _buildStatusView(l10n),
        ),
      ],
    );
  }

  Widget _buildViewToggle(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: l10n.viewByPhases,
              icon: Icons.view_column,
              isSelected: _viewMode == KanbanViewMode.phases,
              onTap: () {
                setState(() => _viewMode = KanbanViewMode.phases);
              },
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: l10n.viewByStatus,
              icon: Icons.assignment_turned_in,
              isSelected: _viewMode == KanbanViewMode.statuses,
              onTap: () {
                setState(() => _viewMode = KanbanViewMode.statuses);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== VISTA POR FASES ====================

  Widget _buildPhaseView(AppLocalizations l10n) {
    final productionProvider = Provider.of<ProductionDataProvider>(context);

    if (!productionProvider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ Obtener fases del provider (sin query)
    final phases = productionProvider.phases.where((p) => p.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (phases.isEmpty) {
      return _buildNoAccessState(l10n);
    }

    // Obtener datos ya cacheados
    final batches = productionProvider.filterBatches(
      clientId: _clientFilter,
      projectId: _projectFilter,
      searchQuery: null,
    );

    // ✅ Filtrar también por lote si se especifica
    final filteredBatches = _batchFilter != null
        ? batches.where((b) => b.id == _batchFilter).toList()
        : batches;

    // Obtener productos agrupados por fase/estado
    final productsByPhase = _groupProductsByPhase(
      productionProvider.getAllProducts(),
      filteredBatches,
    );

    // Contar productos totales
    final totalProducts = productsByPhase.values
        .fold<int>(0, (sum, products) => sum + products.length);

    return Column(
      children: [
        if (totalProducts > 100)
          _buildTooManyProductsWarning(l10n, totalProducts),
        Expanded(
          child: _buildKanbanBoard(
            phases,
            productsByPhase,
            l10n,
            isPhaseView: true,
          ),
        ),
      ],
    );
  }

  // ==================== VISTA POR ESTADOS ====================

  Widget _buildStatusView(AppLocalizations l10n) {
    final productionProvider = Provider.of<ProductionDataProvider>(context);

    if (!productionProvider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Obtener datos ya cacheados
    final batches = productionProvider.filterBatches(
      clientId: _clientFilter,
      projectId: _projectFilter,
      searchQuery: null,
    );

    // ✅ Filtrar también por lote si se especifica
    final filteredBatches = _batchFilter != null
        ? batches.where((b) => b.id == _batchFilter).toList()
        : batches;

    final statuses = productionProvider.statuses
        .where((s) => s.isActive)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (statuses.isEmpty) {
      return _buildNoAccessState(l10n);
    }

    // Obtener productos agrupados por estado
    final productsByStatus = _groupProductsByStatus(
      productionProvider.getAllProducts(),
      filteredBatches,
    );

    // Contar productos totales
    final totalProducts = productsByStatus.values
        .fold<int>(0, (sum, products) => sum + products.length);

    return Column(
      children: [
        if (totalProducts > 100)
          _buildTooManyProductsWarning(l10n, totalProducts),
        Expanded(
          child: _buildKanbanBoard(
            statuses,
            productsByStatus,
            l10n,
            isPhaseView: false,
          ),
        ),
      ],
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupProductsByPhase(
    List<Map<String, dynamic>> allProducts,
    List batches,
  ) {
    final productionProvider = Provider.of<ProductionDataProvider>(context);
    final phases = productionProvider.phases.where((p) => p.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // Inicializar todas las fases
    for (final phase in phases) {
      grouped[phase.id] = [];
    }

    // Filtrar y agrupar productos
    for (final item in allProducts) {
      final product = item['product'];
      final batch = item['batch'];

      // Aplicar filtros
      if (!batches.any((b) => b.id == batch.id)) continue;
      if (_onlyUrgentFilter && product.urgencyLevel != 'urgent') continue;

      // Agrupar por fase
      final phaseId = product.currentPhase;
      if (grouped.containsKey(phaseId)) {
        grouped[phaseId]!.add(item);
      }
    }

    return grouped;
  }

  Map<String, List<Map<String, dynamic>>> _groupProductsByStatus(
    List<Map<String, dynamic>> allProducts,
    List batches,
  ) {
    final productionProvider = Provider.of<ProductionDataProvider>(context);
    final statuses = productionProvider.statuses
        .where((s) => s.isActive)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // Inicializar todos los estados
    for (final status in statuses) {
      grouped[status.id] = [];
    }

    // Filtrar y agrupar productos
    for (final item in allProducts) {
      final product = item['product'];
      final batch = item['batch'];

      // Aplicar filtros
      if (!batches.any((b) => b.id == batch.id)) continue;
      if (_onlyUrgentFilter && product.urgencyLevel != 'urgent') continue;

      // Agrupar por estado
      if (product.statusId != null && grouped.containsKey(product.statusId)) {
        grouped[product.statusId]!.add(item);
      }
    }

    return grouped;
  }

  /// Verificar si el usuario puede mover productos desde una fase
  bool _canMoveFromPhase(BuildContext context, String phaseId) {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    return permissionService.canManagePhase(phaseId);
  }

  bool _canMoveToPhase(BuildContext context, String phaseId) {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    return permissionService.canManagePhase(phaseId);
  }

  bool _canChangeStatus(BuildContext context) {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    return permissionService.canChangeProductStatus;
  }

  // ==================== BOARD PRINCIPAL ====================

  Widget _buildKanbanBoard(
    List<dynamic>
        columns, // Puede ser List<ProductionPhase> o List<ProductStatusModel>
    Map<String, List<Map<String, dynamic>>> productsByColumn,
    AppLocalizations l10n, {
    required bool isPhaseView,
  }) {
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
        itemCount: columns.length,
        itemBuilder: (context, index) {
          final column = columns[index];
          final String columnId = isPhaseView
              ? (column as ProductionPhase).id
              : (column as ProductStatusModel).id;
          final productsData = productsByColumn[columnId] ?? [];

          // Verificar si tiene acceso a esta columna
          final bool hasAccess = isPhaseView
              ? _canMoveToPhase(context, columnId)
              : _canChangeStatus(context);

          final bool isAtWipLimit = isPhaseView &&
              (column as ProductionPhase).wipLimit > 0 &&
              productsData.length >= column.wipLimit;

          return DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) {
              if (data == null) return false;

              final productData = data['product'] as BatchProductModel;
              final fromColumnId = isPhaseView
                  ? productData.currentPhase
                  : (productData.statusId ?? 'pending');

              // No permitir drop en la misma columna
              if (fromColumnId == columnId) return false;

              // Vista por fases: verificar permisos de fase
              if (isPhaseView) {
                if (!_canMoveFromPhase(context, fromColumnId)) {
                  // _showPermissionDeniedSnackbar(
                  //   l10n.cannotMoveFromPhase,
                  //   l10n,
                  // );
                  return false;
                }

                if (!_canMoveToPhase(context, columnId)) {
                  // _showPermissionDeniedSnackbar(
                  //   l10n.cannotMoveToPhase,
                  //   l10n,
                  // );
                  return false;
                }

                // Verificar WIP limit
                if (isAtWipLimit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${l10n.wipLimitReachedIn} ${column.name}',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return false;
                }
              }
              // Vista por estados: verificar permisos de cambio de estado
              else {
                if (!_canChangeStatus(context)) {
                  // _showPermissionDeniedSnackbar(
                  //   l10n.cannotChangeStatus,
                  //   l10n,
                  // );
                  return false;
                }

                // Verificar si la transición está disponible
                final fromStatusId = productData.statusId ?? 'pending';
                final toStatusId = columnId;

                final availableTargets =
                    _availableTransitions[fromStatusId] ?? [];
                if (!availableTargets.contains(toStatusId)) {
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text(l10n.invalidTransition),
                  //     backgroundColor: Colors.red,
                  //   ),
                  // );
                  return false;
                }
              }

              return true;
            },
            onAccept: (data) {
              if (isPhaseView) {
                _showPhaseMoveConfirmationDialog(
                  data,
                  column as ProductionPhase,
                  l10n,
                );
              } else {
                _showStatusChangeConfirmationDialog(
                  data,
                  column as ProductStatusModel,
                  l10n,
                );
              }
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
                child: _buildKanbanColumn(
                  column,
                  productsData,
                  isAtWipLimit,
                  hasAccess,
                  l10n,
                  isPhaseView: isPhaseView,
                ),
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

  // Continúa en PARTE 3...
// CONTINUACIÓN PARTE 3/3

  Widget _buildKanbanColumn(
    dynamic column,
    List<Map<String, dynamic>> productsData,
    bool isAtWipLimit,
    bool hasAccess,
    AppLocalizations l10n, {
    required bool isPhaseView,
  }) {
    final productionProvider = Provider.of<ProductionDataProvider>(context);

    final String columnName = isPhaseView
        ? (column as ProductionPhase).name
        : (column as ProductStatusModel).name;
    final String columnColor = isPhaseView
        ? (column as ProductionPhase).color
        : (column as ProductStatusModel).color;
    final String columnIcon = isPhaseView
        ? (column as ProductionPhase).icon
        : (column as ProductStatusModel).icon;

    final color = UIConstants.parseColor(columnColor);

    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAtWipLimit
              ? Colors.orange
              : !hasAccess
                  ? Colors.grey.shade400
                  : Colors.grey.shade300,
          width: isAtWipLimit || !hasAccess ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumnHeader(
            columnName,
            color,
            columnIcon,
            productsData.length,
            isAtWipLimit,
            hasAccess,
            l10n,
            isPhaseView: isPhaseView,
            wipLimit: isPhaseView ? (column as ProductionPhase).wipLimit : 0,
          ),
          const Divider(height: 1),
          Expanded(
            child: productsData.isEmpty
                ? _buildEmptyColumnState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: productsData.length,
                    itemBuilder: (context, index) {
                      final product =
                          productsData[index]['product'] as BatchProductModel;
                      final batch =
                          productsData[index]['batch'] as ProductionBatchModel;

                      // 3. Ahora podemos buscar el color directamente aquí
                      // Usamos el mapa que acabamos de crear arriba
                      Color clientColor = UIConstants.parseColor(
                          productionProvider
                              .getClientById(batch.clientId)!
                              .color!);

                      // ✅ Determinar si se puede arrastrar
                      final String columnId = isPhaseView
                          ? (column as ProductionPhase).id
                          : (column as ProductStatusModel).id;

                      final bool canDrag = isPhaseView
                          ? _canMoveFromPhase(context, product.currentPhase)
                          : _canChangeStatus(context);

                      return DraggableProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        allPhases: productionProvider.phases,
                        batchNumber: batch.batchNumber,
                        batch: batch,
                        clientColor: clientColor,
                        canDrag: canDrag,
                        onTap: () => _handleProductTap(product, batch),
                        onDragStarted: canDrag
                            ? () {
                                _isDragging = true;
                              }
                            : null,
                        onDragEnd: canDrag
                            ? () {
                                _isDragging = false;
                                _scrollSpeed = 0;
                              }
                            : null,
                        showStatus: isPhaseView,
                        statusName: _getStatusName(product.statusId!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(
    String name,
    Color color,
    String iconName,
    int count,
    bool isAtWipLimit,
    bool hasAccess,
    AppLocalizations l10n, {
    required bool isPhaseView,
    int wipLimit = 0,
  }) {
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
                  UIConstants.getIcon(iconName),
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
                      name,
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
              if (!hasAccess)
                Tooltip(
                  message: l10n.phaseReadOnly,
                  child: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.grey.shade600,
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
                  Icon(Icons.warning_amber,
                      size: 14, color: Colors.orange.shade700),
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

  // ==================== DIÁLOGOS DE CONFIRMACIÓN ====================

  Future<void> _showPhaseMoveConfirmationDialog(
    Map<String, dynamic> data,
    ProductionPhase toPhase,
    AppLocalizations l10n,
  ) async {
    print("dentro de on phase move, data: ${data}, toPhase: ${toPhase}");
    final productionProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    print("after provider");

    if (!_canMoveFromPhase(context, data['fromPhase'] as String)) {
      return;
    }
    print("after canmovefromphase");

    final product = data['product'] as BatchProductModel;
    final batch = data['batch'] as ProductionBatchModel;

    final phases = productionProvider.phases.where((p) => p.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final currentPhaseIndex =
        phases.indexWhere((p) => p.id == product.currentPhase);
    final newPhaseIndex = phases.indexWhere((p) => p.id == toPhase.id);
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
                    Icon(Icons.warning_amber,
                        color: Colors.orange.shade700, size: 20),
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
      await _handlePhaseMove(data, toPhase, l10n);
    }
  }

  Future<void> _showStatusChangeConfirmationDialog(
    Map<String, dynamic> data,
    ProductStatusModel toStatus,
    AppLocalizations l10n,
  ) async {
    final product = data['product'] as BatchProductModel;
    final fromStatusId = product.statusId ?? 'pending';

    // 1. Obtener la transición configurada
    final transitionService =
        Provider.of<StatusTransitionService>(context, listen: false);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);

    final transition = await transitionService.getTransitionBetweenStatuses(
      organizationId: widget.organizationId,
      fromStatusId: fromStatusId,
      toStatusId: toStatus.id,
    );

    // Si no existe transición configurada, mostrar error
    if (transition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noTransitionConfigured),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que la transición esté activa
    if (!transition.isActive) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transitionNotActive),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. Verificar permisos del usuario (rol permitido)
    if (permissionService.currentRole != null &&
        !transition.allowedRoles.contains(permissionService.currentRole!.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.roleNotAuthorized),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Mostrar diálogo de validación apropiado
    final validationData = await ValidationDialogManager.showValidationDialog(
      context: context,
      transition: transition,
      product: product,
    );

    // Si el usuario canceló, salir
    if (validationData == null) {
      return;
    }

    // 4. Ejecutar el cambio de estado con los datos validados
    await _handleStatusChange(
      data,
      toStatus,
      l10n,
      validationData.toMap(),
    );
  }

  // ==================== MANEJO DE MOVIMIENTOS ====================

  Future<void> _handlePhaseMove(
    Map<String, dynamic> data,
    ProductionPhase toPhase,
    AppLocalizations l10n,
  ) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUserData!;

      final product = data['product'] as BatchProductModel;
      final fromPhaseId = product.currentPhase;

      if (fromPhaseId == toPhase.id) return;

      // Actualizar la fase del producto directamente en Firestore
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('production_batches')
          .doc(product.batchId)
          .collection('batch_products')
          .doc(product.id)
          .update({
        'currentPhase': toPhase.id,
        'currentPhaseName': toPhase.name,
        'updatedAt': FieldValue.serverTimestamp(),

        // Actualizar progreso de fases
        'phaseProgress.$fromPhaseId.status': 'completed',
        'phaseProgress.$fromPhaseId.completedAt': FieldValue.serverTimestamp(),
        'phaseProgress.$fromPhaseId.completedBy': user.uid,
        'phaseProgress.$fromPhaseId.completedByName': user.name,

        'phaseProgress.${toPhase.id}.status': 'in_progress',
        'phaseProgress.${toPhase.id}.startedAt': FieldValue.serverTimestamp(),
      });

      try {
        // Generar evento de cambio de fase (mejorado)
        await MessageEventsHelper.onProductPhaseChanged(
          organizationId: widget.organizationId,
          batchId: product.batchId,
          productId: product.id,
          productName: product.productName,
          productNumber: product.productNumber,
          productCode: product.productCode,
          oldPhaseName: product.currentPhaseName,
          newPhaseName: toPhase.name,
          changedBy: user.name,
          validationData:
              null, // Sin validación en movimientos simples de Kanban
        );
      } catch (e) {
        debugPrint('Error generating event: $e');
        // No bloquear si falla el evento
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.productMovedTo} ${toPhase.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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

  Future<void> _handleStatusChange(
    Map<String, dynamic> data,
    ProductStatusModel toStatus,
    AppLocalizations l10n,
    Map<String, dynamic>? validationData,
  ) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUserData!;

      final product = data['product'] as BatchProductModel;
      final fromStatusId = product.statusId ?? 'pending';

      if (fromStatusId == toStatus.id) return;

      final batchService =
          Provider.of<ProductionBatchService>(context, listen: false);

      // Cambiar el estado del producto
      final success = await batchService.changeProductStatus(
        organizationId: widget.organizationId,
        batchId: product.batchId,
        productId: product.id,
        toStatusId: toStatus.id,
        userId: user.uid,
        userName: user.name,
        validationData: validationData,
        l10n: l10n,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.statusChangedSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(l10n.statusChangeError);
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

  // ==================== WIDGETS DE ESTADOS VACÍOS ====================

  Widget _buildEmptyColumnState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              l10n.emptyColumnState,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccessState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.orange.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noAccessToPhase,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onlyAssignedPhases,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooManyProductsWarning(AppLocalizations l10n, int totalCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tooManyProducts,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tooManyProductsDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  void _handleProductTap(
      BatchProductModel product, ProductionBatchModel batch) {
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

  String _getStatusName(String statusId) {
    final productionProvider = Provider.of<ProductionDataProvider>(context);

    final statuses = productionProvider.statuses
        .where((s) => s.isActive)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final status = statuses.firstWhere(
      (s) => s.id == statusId,
      orElse: () => ProductStatusModel(
        id: statusId,
        name: statusId,
        description: '',
        color: '#808080',
        icon: 'help',
        order: 0,
        isSystem: false,
        organizationId: widget.organizationId,
        createdBy: '',
        createdAt: DateTime.now(),
      ),
    );

    return status.name;
  }
}
