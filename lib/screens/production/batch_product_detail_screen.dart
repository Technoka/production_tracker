import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/services/kanban_service.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
import 'package:gestion_produccion/widgets/ui_widgets.dart';
import 'package:provider/provider.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../models/production_batch_model.dart';
import 'production_batch_detail_screen.dart';
import '../../widgets/chat/chat_button.dart';
import '../../services/message_service.dart';
import '../../screens/chat/chat_screen.dart';
import '../../services/organization_member_service.dart';

import '../../services/status_transition_service.dart';
import '../../models/status_transition_model.dart';
import '../../models/role_model.dart';
import '../../widgets/validation_dialogs/validation_dialog_manager.dart';
import '../../models/validation_config_model.dart';
import '../../utils/filter_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/error_display_widget.dart';
import '../../l10n/app_localizations.dart';

class BatchProductDetailScreen extends StatefulWidget {
  final String organizationId;
  final String batchId;
  final String productId;

  const BatchProductDetailScreen({
    super.key,
    required this.organizationId,
    required this.batchId,
    required this.productId,
  });

  @override
  State<BatchProductDetailScreen> createState() =>
      _BatchProductDetailScreenState();
}

class _BatchProductDetailScreenState extends State<BatchProductDetailScreen> {
  bool _isLoadingPermissions = true;
  bool _isPhasesExpanded = false; // Comprimido por defecto
  bool _isHistoryExpanded = false; // Historial comprimido por defecto

  final MessageService _messageService = MessageService();

  RoleModel? _currentRole; // ← NUEVO

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);

    final role = memberService.currentRole;

    if (mounted) {
      setState(() {
        _currentRole = role;
        _isLoadingPermissions = false;
      });
    }
  }

  /// Cargar transiciones disponibles desde el estado actual del producto
  Future<List<StatusTransitionModel>> _loadAvailableTransitions(
    String currentStatusId,
  ) async {
    if (_currentRole == null) return [];

    final transitionService = Provider.of<StatusTransitionService>(
      context,
      listen: false,
    );

    try {
      // Obtener todas las transiciones desde el estado actual
      final transitions =
          await transitionService.getAvailableTransitionsFromStatus(
        organizationId: widget.organizationId,
        fromStatusId: currentStatusId,
        userRoleId: _currentRole!.id,
      );

      // Filtrar solo las activas
      return transitions.where((t) => t.isActive).toList();
    } catch (e) {
      if (mounted) {
        AppErrorSnackBar.showFromException(context, e);
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;
    final permissionService = Provider.of<PermissionService>(context);
    final l10n = AppLocalizations.of(context)!;

    final canViewChat = permissionService.canViewChat;

    // ✅ Mostrar loading mientras cargan permisos
    if (_isLoadingPermissions) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.loading)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final canEditBatchProducts = permissionService.canEditBatchProducts;

    return Consumer<ProductionDataProvider>(
      builder: (context, dataProvider, _) {
        final products = dataProvider.getProductsForBatch(widget.batchId);

        if (products.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.error)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.productNotFound),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.back),
                  ),
                ],
              ),
            ),
          );
        }

        BatchProductModel? product;
        try {
          product = products.firstWhere((p) => p.id == widget.productId);
        } catch (e) {
          product = null;
        }

        // Si el producto no se encuentra (porque se acaba de eliminar),
        // cerrar la pantalla automáticamente
        if (product == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(product.productName),
            actions: [
              // Botón de chat en el AppBar con badge
              if (canViewChat)
                ChatButton(
                    organizationId: widget.organizationId,
                    entityType: 'batch_product',
                    entityId: product.id,
                    parentId: product.batchId,
                    entityName:
                        '${product.productName} - ${product.productReference}',
                    user: user!,
                    showInAppBar: true),

              if (canEditBatchProducts)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleAction(value, product!),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.editProductTitle),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {},
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Definimos el breakpoint para "Escritorio" (ej: 900px)
                final isDesktop = constraints.maxWidth > 900;

                // Si es móvil, mantenemos el ListView original (1 columna)
                if (!isDesktop) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProductInfoCard(product!, user),
                      const SizedBox(height: 16),
                      _buildPhasesCard(product, user),
                      const SizedBox(height: 16),
                      _buildProductStatusCard(product, user),
                      const SizedBox(height: 16),
                      _buildStatusHistoryCard(product),
                      const SizedBox(height: 16),
                      if (canViewChat)
                        _buildChatSection(product, user), // Ver helper abajo
                    ],
                  );
                }

                // Si es Escritorio, usamos ScrollView con Filas
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(24), // Un poco más de margen en web
                  child: Column(
                    children: [
                      // FILA 1: Info y Estado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _buildProductInfoCard(product!, user)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildPhasesCard(product, user)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // FILA 2: Fases y Chat
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _buildProductStatusCard(product, user)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildStatusHistoryCard(product)),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildChatSection(product, user),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfoCard(BatchProductModel product, UserModel? user) {
    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  l10n.productInfoTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nombre
            Text(
              product.productName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Referencia
            Text(
              '${l10n.skuLabel} ${product.productReference}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

// Lote (Obtenido asíncronamente)
            if (user?.organizationId != null)
              Consumer<ProductionDataProvider>(
                builder: (context, dataProvider, _) {
                  final batch = dataProvider.getBatchById(product.batchId);

                  if (batch == null) {
                    // Si falla o no encuentra el lote, mostramos el ID o un texto genérico
                    return Text(
                      l10n.batchNotAvailable,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.batch}: ${batch.batchNumber} (${l10n.product} # ${product.productNumber} / ${batch.totalProducts})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32, // Altura reducida para botón pequeño
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductionBatchDetailScreen(
                                  organizationId: user!.organizationId!,
                                  batchId: batch.id,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: Text(l10n.viewBatchBtn),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 8),

            // Descripción
            if (product.description != null) ...[
              Text(
                '${l10n.description}: ${product.description!}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Notas
            if (product.productNotes != null) ...[
              Text(
                '${l10n.notes}: ${product.productNotes!}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Cantidad
            _buildInfoRow(
              Icons.numbers,
              l10n.quantity,
              '${product.quantity} ${l10n.quantityUnitsPlural}',
            ),
            const SizedBox(
              height: 24,
            ),

            // Cantidad
            _buildInfoRow(
              UIConstants.getIcon(
                  dataProvider.getPhaseById(product.currentPhase)!.icon),
              l10n.phase,
              product.currentPhaseName,
            ),
            const SizedBox(height: 8),

            // Cantidad
            _buildInfoRow(
              UIConstants.getIcon(
                  dataProvider.getStatusById(product.statusId!)!.icon),
              l10n.status,
              product.statusDisplayName,
            ),
            const SizedBox(height: 8),

            // Precio (solo para roles autorizados)
            if ((user!.canViewFinancials) && product.unitPrice != null) ...[
              _buildInfoRow(
                Icons.euro,
                l10n.unitPrice,
                '${product.unitPrice!.toStringAsFixed(2)} €',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.account_balance_wallet,
                l10n.totalPrice,
                '${product.totalPrice?.toStringAsFixed(2) ?? "0.00"} €',
                isBold: true,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

// ================= NUEVO CÃ“DIGO PARA ESTADOS DEL PRODUCTO =================
  Widget _buildProductStatusCard(BatchProductModel product, UserModel? user) {
    // Obtener el icono desde statusIcon si existe, sino usar el statusId

    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    final statusIconValue = dataProvider.getStatusById(product.statusId!)!.icon;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.productStatusTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (product.urgencyLevel == UrgencyLevel.urgent.value) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: product.urgencyColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  product.urgencyDisplayName,
                  style: TextStyle(
                    color: product.urgencyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Estado actual
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: product.effectiveStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: product.effectiveStatusColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    UIConstants.getIcon(statusIconValue),
                    color: product.effectiveStatusColor,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.effectiveStatusName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: product.effectiveStatusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildProductStatusActions(product, user),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryCard(BatchProductModel product) {
    final l10n = AppLocalizations.of(context)!;
    final hasHistory = product.statusHistory.isNotEmpty;

    return Card(
      // 1. Envolver en StatefulBuilder para aislar el renderizado
      child: StatefulBuilder(
        builder: (context, setStateLocal) {
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  l10n.statusHistoryTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(
                  _isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () {
                  // 2. Usar setStateLocal en lugar de setState global
                  setStateLocal(() {
                    _isHistoryExpanded = !_isHistoryExpanded;
                  });
                },
              ),
              if (_isHistoryExpanded) ...[
                // const Divider(height: 1),
                if (!hasHistory)
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      l10n.noStatusHistory,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: product.statusHistory.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final entry = product.statusHistory[index];
                      return _buildHistoryEntry(entry);
                    },
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryEntry(StatusHistoryEntry entry) {
    // Parsear color desde hex string
    Color statusColor = UIConstants.parseColor(entry.statusColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Estado y fecha
        Row(
          children: [
            // Icono del estado
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                UIConstants.getIcon(entry.statusIcon),
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del estado
                  Text(
                    entry.statusName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Fecha y usuario
                  Text(
                    '${_formatDateTime(entry.timestamp)} • ${entry.userName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Notas si existen
        if (entry.notes != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Datos de validación si existen y tienen algo más que solo el timestamp
        if (entry.validationData != null &&
            entry.validationData!.keys.any((k) => k != 'timestamp')) ...[
          const SizedBox(height: 8),
          _buildValidationDataSection(entry.validationData!),
        ],
      ],
    );
  }

  Widget _buildValidationDataSection(Map<String, dynamic> validationData) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                l10n.validationData,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cantidad
          if (validationData['quantity'] != null)
            _buildValidationDataRow(
              l10n.quantity,
              '${validationData['quantity']}',
            ),

          // Texto
          if (validationData['text'] != null)
            _buildValidationDataRow(
              l10n.description,
              validationData['text'] as String,
            ),

          // Checklist
          if (validationData['checklistAnswers'] != null)
            ...() {
              // Aquí SÍ puedes declarar variables porque es una función
              final answers =
                  validationData['checklistAnswers'] as Map<String, dynamic>;
              final completed = answers.values.where((v) => v == true).length;

              // Retornas la lista de widgets
              return [
                _buildValidationDataRow(
                  l10n.checklist,
                  '$completed/${answers.length} ${l10n.completed.toLowerCase()}',
                ),
              ];
            }(), // <--- Nota los paréntesis aquí para ejecutar la función

          // Fotos
          if (validationData['photoUrls'] != null)
            ...() {
              final photos = validationData['photoUrls'] as List;
              if (photos.isNotEmpty) {
                return [
                  _buildValidationDataRow(
                    l10n.photos,
                    '${photos.length} ${l10n.attachedPlural.toLowerCase()}',
                  ),
                ];
              }
              return <Widget>[];
            }(),

          // Aprobadores
          if (validationData['approvedBy'] != null)
            ...() {
              final approvers = validationData['approvedBy'] as List;
              if (approvers.isNotEmpty) {
                return [
                  _buildValidationDataRow(
                    l10n.approvedBy,
                    '${approvers.length} ${l10n.users.toLowerCase()}',
                  ),
                ];
              }
              return <Widget>[];
            }(),

          // Custom Parameters
          if (validationData['customParametersData'] != null)
            ...() {
              final params = validationData['customParametersData']
                  as Map<String, dynamic>;
              return params.entries.map((entry) {
                return _buildValidationDataRow(
                  entry.key,
                  entry.value.toString(),
                );
              }).toList();
            }(),

          // Modo de texto
          if (validationData['textMode'] != null)
            _buildValidationDataRow(
              l10n.mode,
              validationData['textMode'] == 'single'
                  ? l10n.generalDescription
                  : l10n.individualDescription,
            ),

          // Defectos individuales
          if (validationData['individualDefects'] != null)
            ...() {
              final defects =
                  validationData['individualDefects'] as Map<String, dynamic>;
              return [
                const SizedBox(height: 4),
                Text(
                  l10n.individualDescriptions,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                // Aquí expandimos los widgets del mapa dentro de la lista que retornamos
                ...defects.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      '${int.parse(entry.key) + 1}. ${entry.value}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }),
              ];
            }(),
        ],
      ),
    );
  }

  Widget _buildValidationDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStatusActions(
    BatchProductModel product,
    UserModel? user,
  ) {
    // Si no tiene permisos, no mostramos nada
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    final canChangeStatus = permissionService.canChangeProductStatus;

    if (!canChangeStatus) return const SizedBox.shrink();

    // Verificar si está en la última fase
    return Consumer<ProductionDataProvider>(
      builder: (context, dataProvider, _) {
        final phases = dataProvider.phases;

        // Encontrar la última fase (mayor order)
        ProductionPhase? lastPhase;
        if (phases.isNotEmpty) {
          lastPhase = phases.reduce((a, b) => a.order > b.order ? a : b);
        }

        // Verificar si el producto está en la última fase
        final lastPhaseCompleted = lastPhase != null &&
            product.currentPhase == lastPhase.id &&
            product.phaseProgress[product.currentPhase]!.status ==
                'completed'; //TODO: cambiar a enum con nombre de estados de phase.

        if (!lastPhaseCompleted) {
          // No está en la última fase, no mostrar acciones
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 24,
              ),
              Text(
                l10n.availableActionsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.actionsOnlyAtLastPhase} (${lastPhase?.name ?? l10n.unknown})',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Está en la última fase, cargar transiciones disponibles
        final currentStatusId = product.statusId ?? 'pending';

        return FutureBuilder<List<StatusTransitionModel>>(
          future: _loadAvailableTransitions(currentStatusId),
          builder: (context, transSnapshot) {
            if (transSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (transSnapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar transiciones: ${transSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final transitions = transSnapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.availableActionsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (transitions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.noTransitionsAvailable,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ...transitions.map((transition) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildTransitionButton(
                        transition: transition,
                        product: product,
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  /// Construir botón para una transición específica
  Widget _buildTransitionButton({
    required StatusTransitionModel transition,
    required BatchProductModel product,
  }) {
    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    final status = dataProvider.getStatusById(transition.toStatusId)!;
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleTransitionAction(transition, product),
        icon: Icon(UIConstants.getIcon(status.icon), color: status.colorValue),
        label: Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.changeTo}: ${transition.toStatusName}',
                style: TextStyle(
                  color: status.colorValue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Badge con tipo de validación
            if (transition.validationType != ValidationType.simpleApproval)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status.colorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: status.colorValue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      transition.validationType.icon,
                      size: 12,
                      color: status.colorValue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getValidationLabel(transition.validationType),
                      style: TextStyle(
                        fontSize: 10,
                        color: status.colorValue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: status.colorValue, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  /// Manejar acción de transición usando ValidationDialogManager
  Future<void> _handleTransitionAction(
    StatusTransitionModel transition,
    BatchProductModel product,
  ) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar el diálogo de validación apropiado
    final validationData = await ValidationDialogManager.showValidationDialog(
      context: context,
      transition: transition,
      product: product,
    );

    // Si el usuario canceló, salir
    if (validationData == null) {
      return;
    }

    // Ejecutar el cambio de estado con los datos validados
    await _executeStatusChangeWithValidation(
      product: product,
      toStatusId: transition.toStatusId,
      validationData: validationData.toMap(),
    );
  }

  String _getValidationLabel(ValidationType type) {
    final l10n = AppLocalizations.of(context)!;

    switch (type) {
      case ValidationType.textRequired:
        return l10n.text.capitalize;
      case ValidationType.quantityAndText:
        return l10n.quantity.capitalize;
      case ValidationType.checklist:
        return l10n.checklist.capitalize;
      case ValidationType.photoRequired:
        return l10n.photo.capitalize;
      case ValidationType.multiApproval:
        return l10n.approval.capitalize;
      default:
        return '';
    }
  }

  Widget _buildPhasesCard(BatchProductModel product, UserModel? user) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          // ✅ CAMBIADO: Usar StatefulBuilder
          builder: (context, setStateLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con botón de expandir/contraer
                InkWell(
                  onTap: () {
                    setStateLocal(() {
                      _isPhasesExpanded = !_isPhasesExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.productionPhasesLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _isPhasesExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Consumer<ProductionDataProvider>(
                  builder: (context, dataProvider, _) {
                    final allPhases = dataProvider.phases;

                    // Si está comprimido, mostrar solo la fase actual
                    if (!_isPhasesExpanded) {
                      final currentPhase = allPhases.firstWhere(
                        (phase) => phase.id == product.currentPhase,
                        orElse: () => allPhases.first,
                      );
                      final phaseProgress =
                          product.phaseProgress[currentPhase.id];
                      final currentIndex = allPhases.indexOf(currentPhase);

                      return _buildPhaseItem(
                        currentPhase,
                        phaseProgress,
                        true, // Es la fase actual
                        user,
                        product,
                        allPhases,
                        currentIndex,
                      );
                    }

                    // Si está expandido, mostrar todas las fases
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allPhases.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final phase = allPhases[index];
                        final phaseProgress = product.phaseProgress[phase.id];
                        final isCurrentPhase = product.currentPhase == phase.id;

                        return _buildPhaseItem(
                          phase,
                          phaseProgress,
                          isCurrentPhase,
                          user,
                          product,
                          allPhases,
                          index,
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhaseItem(
    ProductionPhase phase,
    PhaseProgressData? progress,
    bool isCurrentPhase,
    UserModel? user,
    BatchProductModel product,
    List<ProductionPhase> allPhases,
    int currentIndex,
  ) {
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    final isInProgress = progress?.isInProgress ?? false;
    final isCompleted = progress?.isCompleted ?? false;

    Color backgroundColor;
    Color borderColor;
    IconData icon = UIConstants.getIcon(phase.icon);

    if (isCompleted) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green;
    } else if (isInProgress || isCurrentPhase) {
      backgroundColor = Colors.blue[50]!;
      borderColor = Colors.blue;
    } else {
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción
              if (user?.canManageProduction ??
                  false || memberService.currentMember!.isClient) ...[
                // Retroceder (solo admin)
                if ((user?.isAdmin ?? false) &&
                    isCompleted &&
                    currentIndex < allPhases.length - 1) ...[
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.orange),
                    onPressed: () => _showChangePhaseDialog(
                      product,
                      allPhases[currentIndex],
                      false, // isForward = false
                    ),
                    tooltip: l10n.rollbackPhaseTooltip,
                  ),
                ],

                // Avanzar
                if (isCurrentPhase && currentIndex < allPhases.length - 1) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _showChangePhaseDialog(
                      product,
                      allPhases[currentIndex + 1],
                      true,
                    ),
                    tooltip: l10n.advancePhaseTooltip,
                  ),
                ],
              ],
            ],
          ),
          // Detalles de la fase
          if (progress != null) ...[
            if (progress.startedAt != null)
              Row(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Icon(Icons.play_arrow, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.startedLabel.capitalize}: ${_formatDateTime(progress.startedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            if (progress.completedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.completed.capitalize}: ${_formatDateTime(progress.completedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (progress.completedByName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.by.capitalize}: ${progress.completedByName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (progress.notes != null && progress.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.notes.capitalize}: ${progress.notes}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Diálogo unificado para avanzar o retroceder fase.
  /// Usa AppDialogs.showPhaseMoveConfirmation y delega a KanbanService.
  Future<void> _showChangePhaseDialog(
    BatchProductModel product,
    ProductionPhase targetPhase,
    bool isForward,
  ) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final kanbanService = Provider.of<KanbanService>(context, listen: false);
    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final batch = dataProvider.getBatchById(product.batchId);
    if (batch == null) return;
    final allPhases = dataProvider.phases.where((p) => p.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final result = await AppDialogs.showPhaseMoveConfirmation(
      context: context,
      productName: product.productName,
      batchNumber: batch.batchNumber,
      productReference: product.productReference,
      fromPhaseName: product.currentPhaseName,
      toPhaseName: targetPhase.name,
      isForward: isForward,
    );

    if (!result.confirmed || !mounted) return;

    try {
      await kanbanService.moveProductToPhase(
        organizationId: widget.organizationId,
        product: product,
        toPhase: targetPhase,
        allPhases: allPhases,
        userId: user.uid,
        userName: user.name,
        notes: result.notes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isForward
                ? '${l10n.phaseAdvancedSuccess}: ${targetPhase.name}'
                : '${l10n.phaseRolledBackSuccess}: ${targetPhase.name}',
          ),
          backgroundColor: isForward ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppErrorSnackBar.showFromException(context, e);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleAction(String action, BatchProductModel product) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null || _currentRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo verificar los permisos del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    switch (action) {
      case 'delete':
        _showDeleteConfirmation(product);
        break;

      case 'edit':
        _showEditProductDialog(product);
        break;
    }
  }

  Future<void> _showEditProductDialog(BatchProductModel product) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final quantityController =
        TextEditingController(text: product.quantity.toString());
    final notesController =
        TextEditingController(text: product.productNotes ?? '');
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    DateTime? selectedDate = product.expectedDeliveryDate;
    UrgencyLevel selectedUrgency =
        UrgencyLevel.fromString(product.urgencyLevel);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.editProductTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgencia
                  Text(
                    l10n.urgency,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilterUtils.buildUrgencyBinaryToggle(
                    context: context,
                    urgencyLevel: selectedUrgency,
                    onChanged: (newLevel) {
                      setState(() {
                        selectedUrgency = UrgencyLevel.fromString(newLevel);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fecha
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(l10n.deliveryDate),
                    subtitle: Text(
                      selectedDate != null
                          ? _formatDateTime(selectedDate!)
                          : l10n.noDeliveryDate,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cantidad
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: l10n.quantity,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Notas
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: l10n.notes.capitalize,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text);
                  if (quantity == null || quantity < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.invalidQuantity),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'quantity': quantity,
                    'notes': notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    'dueDate': selectedDate,
                    'urgencyLevel': selectedUrgency.value,
                  });
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      // Actualizar producto en Firestore
      try {
        await batchService.updateBatchProduct(
          organizationId: widget.organizationId,
          batchId: widget.batchId,
          product: product, // ← modelo completo
          userName: authService.currentUserData!.name,
          quantity: result['quantity'],
          dueDate: result['dueDate'],
          productNotes: result['notes'],
          urgencyLevel: result['urgencyLevel'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.productUpdatedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppErrorSnackBar.showFromException(context, e);
        }
      }
    }
  }

  Future<void> _executeStatusChangeWithValidation({
    required BatchProductModel product,
    required String toStatusId,
    required Map<String, dynamic> validationData,
  }) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    if (user == null || _currentRole == null) {
      return;
    }

    try {
      final success = await batchService.changeProductStatus(
          organizationId: widget.organizationId,
          batchId: widget.batchId,
          productId: widget.productId,
          toStatusId: toStatusId,
          userId: user.uid,
          userName: user.name,
          validationData: validationData,
          l10n: l10n);

      if (!mounted) return;

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.statusChangedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(batchService.error ?? 'Error al cambiar estado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppErrorSnackBar.showFromException(context, e);
      }
    }
  }

  void _showDeleteConfirmation(BatchProductModel product) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    try {
      final resultDelete = await AppDialogs.showDeletePermanently(
          context: context, itemName: product.productReference);

      if (resultDelete) {
        await batchService.removeBatchProduct(
            organizationId: widget.organizationId,
            batchId: product.batchId,
            productId: product.id,
            userId: user!.uid);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.productDeletedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volver a la pantalla anterior
        }
      }
    } catch (e) {
      if (mounted) {
        AppErrorSnackBar.showFromException(context, e);
      }
    }
  }

// Helper para mostrar el chat condicionalmente
  Widget _buildChatSection(BatchProductModel product, UserModel? user) {
    final permissionService = Provider.of<PermissionService>(context);
    final canViewChat = permissionService.canViewChat;

    if (!canViewChat) return const SizedBox.shrink();

    return _buildChatPreviewCard(product, user);
  }

  /// Vista previa de chat (solo lectura, últimos 10 mensajes)
  Widget _buildChatPreviewCard(BatchProductModel product, UserModel? user) {
    if (user == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      // ✅ CAMBIADO: Envolver Card en InkWell
      onTap: () => _openChat(product), // ✅ AÑADIDO: Al hacer tap abre el chat
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline),
                  SizedBox(width: 8),
                  Text(
                    l10n.productChat,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.chatQuickViewSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Divider(height: 24),

              // Stream de los últimos 10 mensajes
              StreamBuilder(
                stream: _messageService.getMessages(
                  organizationId: widget.organizationId,
                  entityType: 'batch_product',
                  entityId: product.id,
                  parentId: product.batchId,
                  limit: 10,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error al cargar mensajes: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noMessagesYet,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Mostrar los mensajes (read-only)
                  return Column(
                    children: [
                      // Lista de mensajes (sin scroll, máximo 10)
                      ...messages.reversed.map((message) {
                        final isSystemMessage = message.isSystemGenerated;
                        final isCurrentUser = message.authorId == user.uid;

                        // Mensaje del sistema (centrado)
                        if (isSystemMessage) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                children: [
                                  // Header del mensaje
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.system,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatMessageTime(message.createdAt),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Contenido del mensaje
                                  Text(
                                    message.content,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Mensaje de usuario (derecha) o de otro (izquierda)
                        return Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: 12,
                              left: isCurrentUser ? 40 : 0,
                              right: isCurrentUser ? 0 : 40,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.green[50]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrentUser
                                      ? Colors.green[200]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header del mensaje
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isCurrentUser
                                            ? '${message.authorName ?? l10n.unknownUser} (${l10n.you})'
                                            : (message.authorName ??
                                                l10n.unknownUser),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatMessageTime(message.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Contenido del mensaje
                                  Text(
                                    message.content,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 12),

                      // Botón "Ver chat completo"
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openChat(product),
                          icon: const Icon(Icons.chat),
                          label: Text(l10n.viewFullChatBtn),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatear tiempo del mensaje
  String _formatMessageTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.now;
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Abrir pantalla de chat
  void _openChat(BatchProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          organizationId: widget.organizationId,
          entityType: 'batch_product',
          entityId: product.id,
          parentId: product.batchId,
          entityName: '${product.productName} - ${product.productReference}',
          showInternalMessages:
              true, // Mostrar mensajes internos para el equipo
        ),
      ),
    );
  }
}
