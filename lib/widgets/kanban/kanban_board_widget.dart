// lib/widgets/kanban/kanban_board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/production_batch_model.dart';
import '../../models/user_model.dart';
import '../../models/product_status_model.dart';
import '../../models/organization_member_model.dart';
import '../../models/client_model.dart';
import '../../models/role_model.dart';
import '../../models/permission_model.dart';
import '../../services/phase_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/product_status_service.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/organization_member_service.dart';
import '../../services/status_transition_service.dart';
import 'draggable_product_card.dart';
import '../../screens/production/batch_product_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/validation_dialogs/validation_dialog_manager.dart';
import '../../utils/message_events_helper.dart';

enum KanbanViewMode { phases, statuses }

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
  final PhaseService _phaseService = PhaseService();
  final ScrollController _scrollController = ScrollController();

  bool _isDragging = false;
  double _scrollSpeed = 0;
  KanbanViewMode _viewMode = KanbanViewMode.phases;

  String? _batchFilter;
  String? _clientFilter;
  String? _projectFilter;
  bool _onlyUrgentFilter = false;

  Map<String, List<Map<String, dynamic>>> _cachedProductsByPhase = {};
  Map<String, List<Map<String, dynamic>>> _cachedProductsByStatus = {};
  List<ProductionPhase> _cachedPhases = [];
  List<ProductStatusModel> _cachedStatuses = [];

  // Permisos y miembros
  OrganizationMemberModel? _currentMember;
  RoleModel? _currentRole;
  PermissionsModel? _effectivePermissions;
  List<String> _accessiblePhases = [];
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _batchFilter = widget.initialBatchFilter;
    _clientFilter = widget.initialClientFilter;
    _projectFilter = widget.initialProjectFilter;
    _onlyUrgentFilter = widget.initialUrgentFilter ?? false;
    _startAutoScroll();
    _loadUserPermissions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Cargar permisos del usuario actual
  Future<void> _loadUserPermissions() async {
    try {
      final memberService = Provider.of<OrganizationMemberService>(
        context,
        listen: false,
      );

      // Obtener miembro actual con rol y permisos
      final memberData = await memberService.getCurrentMember(
        widget.organizationId,
        widget.currentUser.uid,
      );

      if (memberData == null) {
        setState(() => _isLoadingPermissions = false);
        return;
      }

      // Obtener el rol completo para calcular permisos efectivos
      final roleDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('roles')
          .doc(memberData.member.roleId)
          .get();

      if (!roleDoc.exists) {
        setState(() => _isLoadingPermissions = false);
        return;
      }

      final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);
      final effectivePermissions =
          memberData.member.getEffectivePermissions(role);

      // Determinar fases accesibles
      List<String> accessiblePhases = [];
      if (memberData.member.canManageAllPhases) {
        // Puede ver todas las fases
        final allPhases = await _phaseService
            .getOrganizationPhasesStream(widget.organizationId)
            .first;
        accessiblePhases = allPhases.map((p) => p.id).toList();
      } else {
        // Solo sus fases asignadas
        accessiblePhases = memberData.member.assignedPhases;
      }

      setState(() {
        _currentMember = memberData.member;
        _currentRole = role;
        _effectivePermissions = effectivePermissions;
        _accessiblePhases = accessiblePhases;
        _isLoadingPermissions = false;
      });
    } catch (e) {
      debugPrint('Error loading user permissions: $e');
      setState(() => _isLoadingPermissions = false);
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

    if (_isLoadingPermissions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loadingPermissions),
          ],
        ),
      );
    }

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
    return StreamBuilder<List<ProductionPhase>>(
      stream: _phaseService.getOrganizationPhasesStream(widget.organizationId),
      builder: (context, phasesSnapshot) {
        if (phasesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loadingPhases),
              ],
            ),
          );
        }

        if (!phasesSnapshot.hasData || phasesSnapshot.data!.isEmpty) {
          return _buildEmptyState(l10n, isPhaseView: true);
        }

        // Filtrar fases según permisos
        final allPhases = phasesSnapshot.data!.where((p) => p.isActive).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        final accessiblePhases = _filterAccessiblePhases(allPhases);

        if (accessiblePhases.isEmpty) {
          return _buildNoAccessState(l10n);
        }

        _cachedPhases = accessiblePhases;

        return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _getAllProductsGroupedByPhase(
            widget.organizationId,
            accessiblePhases,
          ),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.loadingProducts),
                  ],
                ),
              );
            }

            final productsByPhase = productsSnapshot.data ?? {};
            _cachedProductsByPhase = productsByPhase;

            // Contar productos totales
            final totalProducts = productsByPhase.values
                .fold<int>(0, (sum, products) => sum + products.length);

            return Column(
              children: [
                if (totalProducts > 100)
                  _buildTooManyProductsWarning(l10n, totalProducts),
                Expanded(
                  child: _buildKanbanBoard(
                    accessiblePhases,
                    productsByPhase,
                    l10n,
                    isPhaseView: true,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Continúa en PARTE 2...
// CONTINUACIÓN PARTE 2/3

  // ==================== VISTA POR ESTADOS ====================

  Widget _buildStatusView(AppLocalizations l10n) {
    final _statusService = Provider.of<ProductStatusService>(context);

    return StreamBuilder<List<ProductStatusModel>>(
      stream: _statusService.watchStatuses(widget.organizationId),
      builder: (context, statusesSnapshot) {
        if (statusesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loadingStatuses),
              ],
            ),
          );
        }

        if (!statusesSnapshot.hasData || statusesSnapshot.data!.isEmpty) {
          return _buildEmptyState(l10n, isPhaseView: false);
        }

        final statuses = statusesSnapshot.data!
            .where((s) => s.isActive)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        _cachedStatuses = statuses;

        return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _getAllProductsGroupedByStatus(
            widget.organizationId,
            statuses,
          ),
          builder: (context, productsSnapshot) {
            if (productsSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.loadingProducts),
                  ],
                ),
              );
            }

            final productsByStatus = productsSnapshot.data ?? {};
            _cachedProductsByStatus = productsByStatus;

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
          },
        );
      },
    );
  }

  /// Filtrar fases accesibles según permisos del usuario
  List<ProductionPhase> _filterAccessiblePhases(List<ProductionPhase> phases) {
    if (_currentMember == null) return [];

    // Si puede gestionar todas las fases, devolver todas
    if (_currentMember!.canManageAllPhases) {
      return phases;
    }

    // Filtrar solo las fases asignadas
    return phases
        .where((phase) => _accessiblePhases.contains(phase.id))
        .toList();
  }

  /// Obtener todos los productos agrupados por fase
  Future<Map<String, List<Map<String, dynamic>>>> _getAllProductsGroupedByPhase(
    String organizationId,
    List<ProductionPhase> phases,
  ) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    for (final phase in phases) {
      groupedProducts[phase.id] = [];
    }

    try {
      final batches = await batchService.watchBatches(organizationId).first;
      int totalProductsProcessed = 0;
      const maxProducts = 100;

      for (final batch in batches) {
        // Aplicar filtros de batch/client/project
        if (_batchFilter != null && batch.id != _batchFilter) continue;
        if (_clientFilter != null && batch.clientId != _clientFilter) continue;
        if (_projectFilter != null && batch.projectId != _projectFilter)
          continue;

        // Verificar acceso al batch según scope
        if (!_canAccessBatch(batch)) continue;

        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;

        for (final product in products) {
          if (totalProductsProcessed >= maxProducts) {
            return groupedProducts;
          }

          bool passesFilter = true;

          // Filtro de urgencia
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
              totalProductsProcessed++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading products by phase: $e');
    }

    return groupedProducts;
  }

  /// Obtener todos los productos agrupados por estado
  Future<Map<String, List<Map<String, dynamic>>>>
      _getAllProductsGroupedByStatus(
    String organizationId,
    List<ProductStatusModel> statuses,
  ) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    for (final status in statuses) {
      groupedProducts[status.id] = [];
    }

    try {
      final batches = await batchService.watchBatches(organizationId).first;
      int totalProductsProcessed = 0;
      const maxProducts = 100;

      for (final batch in batches) {
        // Aplicar filtros
        if (_batchFilter != null && batch.id != _batchFilter) continue;
        if (_clientFilter != null && batch.clientId != _clientFilter) continue;
        if (_projectFilter != null && batch.projectId != _projectFilter)
          continue;

        // Verificar acceso
        if (!_canAccessBatch(batch)) continue;

        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;

        for (final product in products) {
          if (totalProductsProcessed >= maxProducts) {
            return groupedProducts;
          }

          bool passesFilter = true;

          if (_onlyUrgentFilter) {
            if (product.urgencyLevel != UrgencyLevel.urgent.value) {
              passesFilter = false;
            }
          }

          if (passesFilter) {
            final statusId = product.statusId ?? 'pending';
            if (groupedProducts.containsKey(statusId)) {
              groupedProducts[statusId]!.add({
                'product': product,
                'batch': batch,
              });
              totalProductsProcessed++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading products by status: $e');
    }

    return groupedProducts;
  }

  /// Verificar si el usuario tiene acceso a un batch
  bool _canAccessBatch(ProductionBatchModel batch) {
    if (_effectivePermissions == null) return false;

    // Si tiene scope "all" en batches, puede ver todos
    if (_effectivePermissions!.viewBatchesScope == PermissionScope.all) {
      return true;
    }

    // Si tiene scope "assigned", verificar si está asignado
    if (_effectivePermissions!.viewBatchesScope == PermissionScope.assigned) {
      return batch.assignedMembers.contains(widget.currentUser.uid);
    }

    return false;
  }

  /// Verificar si el usuario puede mover productos desde una fase
  bool _canMoveFromPhase(String phaseId) {
    if (_currentMember == null) return false;
    return _currentMember!.canManagePhase(phaseId);
  }

  /// Verificar si el usuario puede mover productos a una fase
  bool _canMoveToPhase(String phaseId) {
    if (_currentMember == null) return false;
    return _currentMember!.canManagePhase(phaseId);
  }

  /// Verificar si el usuario puede cambiar estados
  bool _canChangeStatus() {
    if (_effectivePermissions == null) return false;
    return _effectivePermissions!.canChangeProductStatus;
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
          final bool hasAccess =
              isPhaseView ? _canMoveToPhase(columnId) : _canChangeStatus();

          final bool isAtWipLimit = isPhaseView &&
              (column as ProductionPhase).wipLimit > 0 &&
              productsData.length >= (column as ProductionPhase).wipLimit;

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
                if (!_canMoveFromPhase(fromColumnId)) {
                  _showPermissionDeniedSnackbar(
                    l10n.cannotMoveFromPhase,
                    l10n,
                  );
                  return false;
                }

                if (!_canMoveToPhase(columnId)) {
                  _showPermissionDeniedSnackbar(
                    l10n.cannotMoveToPhase,
                    l10n,
                  );
                  return false;
                }

                // Verificar WIP limit
                if (isAtWipLimit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${l10n.wipLimitReachedIn} ${(column as ProductionPhase).name}',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return false;
                }
              }
              // Vista por estados: verificar permisos de cambio de estado
              else {
                if (!_canChangeStatus()) {
                  _showPermissionDeniedSnackbar(
                    l10n.cannotChangeStatus,
                    l10n,
                  );
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
    // 1. Necesitamos el ID de la organización para pedir los clientes
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;
    final clientService = Provider.of<ClientService>(context, listen: false);

    final String columnName = isPhaseView
        ? (column as ProductionPhase).name
        : (column as ProductStatusModel).name;
    final String columnColor = isPhaseView
        ? (column as ProductionPhase).color
        : (column as ProductStatusModel).color;
    final String columnIcon = isPhaseView
        ? (column as ProductionPhase).icon
        : (column as ProductStatusModel).icon;

    final color = _parseColor(columnColor);

    // 2. Envolvemos TODO el contenedor en un StreamBuilder de Clientes
    return FutureBuilder<List<ClientModel>>(
      future: clientService.getOrganizationClients(user!.organizationId!),
      builder: (context, snapshot) {
        
        // Creamos el mapa de colores (si no hay datos aún, mapa vacío)
        final clients = snapshot.data ?? [];
        final Map<String, String> clientColors = {
          for (var client in clients) client.id: client.color!
        };

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
                wipLimit:
                    isPhaseView ? (column as ProductionPhase).wipLimit : 0,
              ),
              const Divider(height: 1),
              Expanded(
                child: productsData.isEmpty
                    ? _buildEmptyColumnState(l10n)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: productsData.length,
                        itemBuilder: (context, index) {
                          final product = productsData[index]['product']
                              as BatchProductModel;
                          final batch = productsData[index]['batch']
                              as ProductionBatchModel;

                          // 3. Ahora podemos buscar el color directamente aquí
                          // Usamos el mapa que acabamos de crear arriba
                          Color clientColor = parseColorValue(clientColors[batch.clientId]);

                          return DraggableProductCard(
                            key: ValueKey(product.id),
                            product: product,
                            allPhases: _cachedPhases,
                            batchNumber: batch.batchNumber,
                            batch: batch,
                            clientColor: clientColor, // <--- Pasamos el color
                            onTap: () => _handleProductTap(product, batch),
                            onDragStarted: () {
                              _isDragging = true;
                            },
                            onDragEnd: () {
                              _isDragging = false;
                              _scrollSpeed = 0;
                            },
                            showStatus: isPhaseView,
                            statusName: _getStatusName(product.statusId),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
                  _getIcon(iconName),
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
    final product = data['product'] as BatchProductModel;
    final batch = data['batch'] as ProductionBatchModel;

    final currentPhaseIndex =
        _cachedPhases.indexWhere((p) => p.id == product.currentPhase);
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
  final transitionService = Provider.of<StatusTransitionService>(context, listen: false);
  
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
        content: Text(l10n.noTransitionConfigured ?? 'No hay transición configurada entre estos estados'),
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
        content: Text(l10n.transitionNotActive ?? 'Esta transición está desactivada'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // 2. Verificar permisos del usuario (rol permitido)
  if (_currentRole != null && !transition.allowedRoles.contains(_currentRole!.id)) {
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

  /// Diálogo de validación con campos requeridos
  Future<void> _showValidationDialog({
    required Map<String, dynamic> data,
    required ProductStatusModel toStatus,
    required Map<String, dynamic> validationResult,
    required AppLocalizations l10n,
  }) async {
    final product = data['product'] as BatchProductModel;
    final validationType = validationResult['validationType'];
    final validationConfig = validationResult['validationConfig'];

    final quantityController = TextEditingController();
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.validationRequired),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Campo de cantidad si es requerido
                if (validationType == 'quantity_and_text' ||
                    validationType == 'quantity_required') ...[
                  TextFormField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: l10n.validationDefectiveQuantity,
                      hintText: l10n.enterQuantity,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.fillRequiredFields;
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty < 1) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Campo de texto si es requerido
                if (validationType == 'quantity_and_text' ||
                    validationType == 'text_required') ...[
                  TextFormField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: l10n.defectDescription,
                      hintText: l10n.enterDescription,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.fillRequiredFields;
                      }
                      if (value.length < 10) {
                        return 'Mínimo 10 caracteres';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final validationData = <String, dynamic>{};
                if (quantityController.text.isNotEmpty) {
                  validationData['quantity'] =
                      int.parse(quantityController.text);
                }
                if (textController.text.isNotEmpty) {
                  validationData['text'] = textController.text;
                }
                Navigator.pop(context, validationData);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (result != null) {
      await _handleStatusChange(data, toStatus, l10n, result);
    }
  }

  // ==================== MANEJO DE MOVIMIENTOS ====================

  Future<void> _handlePhaseMove(
    Map<String, dynamic> data,
    ProductionPhase toPhase,
    AppLocalizations l10n,
  ) async {
    try {
      final product = data['product'] as BatchProductModel;
      final batch = data['batch'] as ProductionBatchModel;
      final fromPhaseId = product.currentPhase;

      if (fromPhaseId == toPhase.id) return;

      final batchService =
          Provider.of<ProductionBatchService>(context, listen: false);

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
        'phaseProgress.$fromPhaseId.completedAt':
            FieldValue.serverTimestamp(),
        'phaseProgress.$fromPhaseId.completedBy': widget.currentUser.uid,
        'phaseProgress.$fromPhaseId.completedByName': widget.currentUser.name,

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
        changedBy: widget.currentUser.name,
        validationData: null, // Sin validación en movimientos simples de Kanban
      );
      
      } catch (e) {
        debugPrint('Error generating event: $e');
        // No bloquear si falla el evento
      }

      if (!mounted) return;

      // Actualizar caché local
      setState(() {
        _cachedProductsByPhase[fromPhaseId]?.removeWhere(
            (item) => (item['product'] as BatchProductModel).id == product.id);

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
      final product = data['product'] as BatchProductModel;
      final batch = data['batch'] as ProductionBatchModel;
      final fromStatusId = product.statusId ?? 'pending';

      if (fromStatusId == toStatus.id) return;

      final batchService = Provider.of<ProductionBatchService>(context, listen: false);

      // Cambiar el estado del producto
      final success = await batchService.changeProductStatus(
        organizationId: widget.organizationId,
        batchId: product.batchId,
        productId: product.id,
        toStatusId: toStatus.id,
        userId: widget.currentUser.uid,
        userName: widget.currentUser.name,
        validationData: validationData,
        l10n: l10n,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _cachedProductsByStatus[fromStatusId]?.removeWhere((item) =>
              (item['product'] as BatchProductModel).id == product.id);

          final updatedProduct = product.copyWith(
            statusId: toStatus.id,
            statusName: toStatus.name,
          );

          _cachedProductsByStatus[toStatus.id]?.add({
            'product': updatedProduct,
            'batch': batch,
          });
        });

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

  // Continúa en siguiente mensaje (helpers finales)...
// CONTINUACIÓN PARTE 4/4 FINAL

  // ==================== VALIDACIONES ====================

  Future<Map<String, dynamic>> _validateStatusTransition({
    required BatchProductModel product,
    required String fromStatusId,
    required String toStatusId,
  }) async {
    if (_currentRole == null) {
      return {
        'isValid': false,
        'error': 'No se pudo verificar el rol del usuario',
        'requiresValidation': false,
      };
    }

    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);

    try {
      final result = await batchService.validateStatusTransition(
        organizationId: widget.organizationId,
        fromStatusId: fromStatusId,
        toStatusId: toStatusId,
        userName: widget.currentUser.name,
        userId: widget.currentUser.uid,
      );

      return result;
    } catch (e) {
      debugPrint('Error validating transition: $e');
      return {
        'isValid': false,
        'error': 'Error al validar transición: $e',
        'requiresValidation': false,
      };
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

  Widget _buildEmptyState(AppLocalizations l10n, {required bool isPhaseView}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPhaseView ? Icons.view_kanban : Icons.assignment_turned_in,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isPhaseView
                ? l10n.noPhasesConfigured
                : 'No hay estados configurados',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            isPhaseView
                ? l10n.configurePhasesFirst
                : 'Configura estados primero',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
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

  void _showPermissionDeniedSnackbar(String message, AppLocalizations l10n) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getStatusName(String? statusId) {
    if (statusId == null) return 'Pending';

    final status = _cachedStatuses.firstWhere(
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      // Iconos de fases
      case 'planned':
        return Icons.calendar_today;
      case 'cutting':
        return Icons.content_cut;
      case 'skiving':
        return Icons.layers;
      case 'assembly':
        return Icons.construction;
      case 'studio':
        return Icons.brush;
      case 'finishing':
        return Icons.brush;
      case 'quality':
        return Icons.verified;
      case 'packaging':
        return Icons.inventory_2;

      // Iconos de estados
      case 'pending':
        return Icons.schedule;
      case 'hold':
        return Icons.pause_circle_outline;
      case 'cao':
        return Icons.report_problem;
      case 'control':
        return Icons.fact_check;
      case 'ok':
        return Icons.check_circle;
      case 'approved':
        return Icons.thumb_up;
      case 'rejected':
        return Icons.thumb_down;

      // Genéricos
      case 'work':
        return Icons.work;
      case 'build':
        return Icons.build;
      case 'engineering':
        return Icons.engineering;
      case 'shield':
        return Icons.shield;
      case 'verified':
        return Icons.verified;
      case 'star':
        return Icons.star;
      case 'flag':
        return Icons.flag;

      default:
        return Icons.circle;
    }
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
