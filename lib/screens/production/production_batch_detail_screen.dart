import 'package:flutter/material.dart';
import 'package:gestion_produccion/l10n/app_localizations.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/services/permission_service.dart';
import 'package:gestion_produccion/widgets/access_control_widget.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import 'package:gestion_produccion/widgets/ui_widgets.dart';
import 'package:provider/provider.dart';
import '../../models/production_batch_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import 'add_product_to_batch_screen.dart';
import 'batch_product_detail_screen.dart';
import '../../services/organization_member_service.dart';

// TODO: comprobar que se usa scope y assignedMembers correctamente

class ProductionBatchDetailScreen extends StatefulWidget {
  final String organizationId;
  final String batchId;

  const ProductionBatchDetailScreen({
    super.key,
    required this.organizationId,
    required this.batchId,
  });

  @override
  State<ProductionBatchDetailScreen> createState() =>
      _ProductionBatchDetailScreenState();
}

class _ProductionBatchDetailScreenState
    extends State<ProductionBatchDetailScreen> {
  List<String> _selectedMembers = [];

  @override
  void initState() {
    super.initState();
    _loadBatchMembers();
  }

  // AGREGAR: método para cargar miembros iniciales
  Future<void> _loadBatchMembers() async {
    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    final batch = dataProvider.getBatchById(widget.batchId);

    if (batch != null && mounted) {
      setState(() {
        _selectedMembers = List<String>.from(batch.assignedMembers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;
    final memberService = Provider.of<OrganizationMemberService>(context);
    final permissionService = Provider.of<PermissionService>(context);
    final canEditBatches = permissionService.canEditBatches;
    final canDeleteBatches = permissionService.canDeleteBatches;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ProductionDataProvider>(
      builder: (context, dataProvider, _) {
        final batch = dataProvider.getBatchById(widget.batchId);

        if (batch == null) {
          return AppScaffold(
            title: l10n.productionTitle,
            currentIndex: AppNavIndex.production,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.batchNotFound),
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

        return AppScaffold(
            title: l10n.productionTitle,
            currentIndex: AppNavIndex.production,
            actions: [
              // 1. Solo mostramos el botón de menú si tiene permiso de Editar O Eliminar.
              // Si no tiene ninguno, no se muestra nada.
              if (canEditBatches || canDeleteBatches)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) =>
                      _handleAction(value, batch, user!, memberService),
                  itemBuilder: (context) => [
                    // 2. Opción Editar: Solo si canEditBatches es true
                    if (canEditBatches)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.editNotes),
                          ],
                        ),
                      ),

                    // 3. Opción Eliminar: Solo si canDeleteBatches es true
                    if (canDeleteBatches)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete,
                                size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deleteBatchAction,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],

          body: RefreshIndicator(
            onRefresh: () async {
              final dataProvider =
                  Provider.of<ProductionDataProvider>(context, listen: false);
              await dataProvider.refreshBatch(
                  widget.organizationId, widget.batchId);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Información del lote
                _buildBatchInfoCard(batch, user),
                const SizedBox(height: 16),

                // Progreso general
                _buildProgressCard(batch),
                const SizedBox(height: 16),

                // Lista de productos
                _buildProductsSection(batch, user, memberService),

                if (memberService.currentMember?.clientId != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: StatefulBuilder(
                        // CAMBIAR: Usar StatefulBuilder
                        builder:
                            (BuildContext context, StateSetter setStateLocal) {
                          return AccessControlWidget(
                              organizationId: widget.organizationId,
                              currentUserId: authService.currentUser!.uid,
                              clientId: batch.clientId,
                              selectedMembers: _selectedMembers,
                              onMembersChanged: (members) {
                                setStateLocal(() {
                                  // CAMBIAR: usar setStateLocal en lugar de setState
                                  _selectedMembers = members;
                                });
                              },
                              readOnly: true,
                              showTitle: true,
                              resourceType: 'batch',
                              customTitle: l10n.accessControlBatchTitle,
                              customDescription: l10n.accessControlDescription);
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
          // Botones flotantes con Chat y Añadir Producto
          floatingActionButton:
              _buildFloatingButtons(user, batch, memberService),
        );
      },
    );
  }

  /// Construir botones flotantes (Chat + Añadir Producto)
  Widget _buildFloatingButtons(UserModel? user, ProductionBatchModel batch,
      OrganizationMemberService memberService) {
    final permissionService = Provider.of<PermissionService>(context);
    final canEditBatches = permissionService.canEditBatches;
    final l10n = AppLocalizations.of(context)!;

// Si no tiene permisos, cortamos aquí devolviendo un widget vacío
    if (!canEditBatches) return const SizedBox.shrink();

// Si tiene permisos, continuamos y devolvemos la columna con el botón
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          heroTag: 'add_product_btn',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductToBatchScreen(
                  organizationId: widget.organizationId,
                  batchId: widget.batchId,
                  clientName: batch.clientName,
                  projectName: batch.projectName,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addProductsTitle),
        ),
      ],
    );
  }

  Widget _buildBatchInfoCard(ProductionBatchModel batch, UserModel? user) {
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
                  l10n.batchInfoTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Estado
            Row(
              children: [
                Text(
                  '${l10n.status}:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(batch.status),
              ],
            ),
            const SizedBox(height: 12),

            // Proyecto
            _buildInfoRow(
              Icons.folder_outlined,
              l10n.project,
              batch.projectName,
            ),
            const SizedBox(height: 8),

            // Cliente
            _buildInfoRow(
              Icons.person_outline,
              l10n.client,
              batch.clientName,
            ),
            const SizedBox(height: 8),

            // Fecha de creación
            _buildInfoRow(
              Icons.calendar_today,
              l10n.createdLabel,
              _formatDate(batch.createdAt),
            ),
            const SizedBox(height: 8),

            // Creado por
            _buildInfoRow(
              Icons.person,
              l10n.createdBy,
              user?.name ?? l10n.unknownUser,
            ),

            // Notas
            if (batch.notes != null && batch.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                l10n.notes,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                batch.notes!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ProductionBatchModel batch) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ProductionDataProvider>(
      builder: (context, dataProvider, _) {
        final stats = dataProvider.getBatchProgress(widget.batchId);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined),
                    const SizedBox(width: 8),
                    Text(
                      l10n.generalProgress,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fases
                Row(
                  children: [
                    Icon(Icons.precision_manufacturing,
                        size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.phases}: ${stats['completedPhases'] ?? 0}/${stats['totalProducts'] ?? 0} en ${stats['lastPhaseName'] ?? l10n.na}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Estados
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 18, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.statuses}: ${stats['completedStatuses'] ?? 0}/${stats['totalProducts'] ?? 0} en ${stats['lastStatusName'] ?? l10n.na}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsSection(ProductionBatchModel batch, UserModel? user,
      OrganizationMemberService memberService) {
    // Solo mostrar productos si tiene permiso
    final permissionService = Provider.of<PermissionService>(context);
    final canViewBatches = permissionService.canViewBatches;

    if (!canViewBatches) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ProductionDataProvider>(
      builder: (context, dataProvider, _) {
        final products = dataProvider.getProductsForBatch(widget.batchId);

        if (products.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noProductsInBatch,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${l10n.productsInBatchTitle} (${batch.totalProducts})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Usamos directamente la lista 'products' que ya obtuvimos arriba.
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final urgencyLevel =
                      UrgencyLevel.fromString(product.urgencyLevel);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BatchProductDetailScreen(
                            organizationId: widget.organizationId,
                            batchId: widget.batchId,
                            productId: product.id,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        // border: Border(bottom: BorderSide(color: Colors.grey.shade200)), // Ya lo hace el separator
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. LEADING: Avatar con número
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                urgencyLevel.color.withOpacity(0.2),
                            child: Text(
                              '#${product.productNumber}',
                              style: TextStyle(
                                color: urgencyLevel.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 2. CENTRO: Información del producto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.skuLabel}: ${product.productReference}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // CORRECCIÓN 3: Verificar nulo antes de formatear
                                if (product.expectedDeliveryDate != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l10n.estimatedDeliveryDate}: ${_formatDate(product.expectedDeliveryDate!)}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                                // Notas (si tu modelo BatchProductModel las tiene)
                                if (product.productNotes != null &&
                                    product.productNotes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${l10n.notes}: ${product.productNotes}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[800],
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. DERECHA: Chip arriba, Cantidad abajo
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Chip de urgencia
                              if (urgencyLevel == UrgencyLevel.urgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: urgencyLevel.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: urgencyLevel.color
                                            .withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    urgencyLevel.displayName,
                                    style: TextStyle(
                                      color: urgencyLevel.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // Cantidad
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'x${product.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

// AÑADIR métodos helper:

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = BatchStatus.fromString(status).getDisplayName(l10n);
        break;
      case 'in_progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        label = BatchStatus.fromString(status).getDisplayName(l10n);
        break;
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        label = BatchStatus.fromString(status).getDisplayName(l10n);
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleAction(String action, ProductionBatchModel batch,
      UserModel user, OrganizationMemberService memberService) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'start':
        final success = await batchService.changeBatchStatus(
            organizationId: widget.organizationId,
            batchId: widget.batchId,
            newStatus: BatchStatus.inProgress,
            userId: user.uid);

        if (success && mounted) {
          AppSnackBars.success(context, l10n.batchStartedSuccess);
        }
        break;

      case 'complete':
        final success = await batchService.changeBatchStatus(
            organizationId: widget.organizationId,
            batchId: widget.batchId,
            newStatus: BatchStatus.completed,
            userId: user.uid);

        if (success && mounted) {
          AppSnackBars.success(context, l10n.batchCompletedSuccess);
        }
        break;

      case 'edit':
        final canEdit = await memberService.can('batches', 'edit');

        if (canEdit) _showEditNotesDialog(batch, user.uid);
        break;

      case 'delete':
        final canDelete = await memberService.can('batches', 'delete');

        if (canDelete) _showDeleteConfirmation(batch, user.uid);
        break;
    }
  }

  void _showEditNotesDialog(ProductionBatchModel batch, String userId) {
    final notesController = TextEditingController(text: batch.notes);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editNotes),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.notesHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final batchService = Provider.of<ProductionBatchService>(
                context,
                listen: false,
              );

              final success = await batchService.updateBatch(
                organizationId: widget.organizationId,
                batchId: widget.batchId,
                userId: userId,
                notes: notesController.text.trim(),
              );

              if (success && context.mounted) {
                Navigator.pop(context);
                AppSnackBars.success(context, l10n.updatedSuccess);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      ProductionBatchModel batch, String userId) async {
    final l10n = AppLocalizations.of(context)!;
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);

    final resultDelete = await AppDialogs.showDeletePermanently(
        context: context, itemName: batch.batchNumber);

    if (resultDelete) {
      final success = await batchService.deleteBatch(
          organizationId: widget.organizationId,
          batchId: widget.batchId,
          userId: userId);

      if (success && mounted) {
        AppSnackBars.success(context, l10n.batchDeletedSuccess);
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
  }
}
