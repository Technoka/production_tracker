import 'package:flutter/material.dart';
import 'package:gestion_produccion/services/phase_service.dart';
import 'package:gestion_produccion/services/product_catalog_service.dart';
import 'package:gestion_produccion/services/production_batch_service.dart';
import 'package:gestion_produccion/services/project_service.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pending_object_model.dart';
import '../../models/user_model.dart';
import '../../services/pending_object_service.dart';
import '../../services/notification_service.dart';
import '../../helpers/approval_helper.dart';

/// Columna especial del Kanban que muestra los lotes/productos pendientes de aprobación.
///
/// - Solo aparece si hay al menos un objeto pendiente.
/// - Solo lectura para usuarios sin permiso `approveClientRequests`.
/// - Con permiso: arrastrando una tarjeta al primer estado real se activa
///   el diálogo de confirmación con todos los datos del lote.
class PendingApprovalColumn extends StatelessWidget {
  final String organizationId;

  /// Si es true, las tarjetas son arrastrables (usuario puede aprobar).
  final bool canApprove;

  /// Callback invocado al soltar una tarjeta sobre el primer estado real.
  /// El widget padre muestra el diálogo de confirmación.
  final void Function(PendingObjectModel pendingObject) onDropToApprove;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const PendingApprovalColumn({
    super.key,
    required this.organizationId,
    required this.canApprove,
    required this.onDropToApprove,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final pendingService = Provider.of<PendingObjectService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<PendingObjectModel>>(
      stream: pendingService.getPendingObjectsStream(
        organizationId,
        status: PendingObjectStatus.pendingApproval,
      ),
      builder: (context, snapshot) {
        // Mientras carga, no mostrar nada para no interrumpir el layout
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data ?? [];

        // Columna se oculta automáticamente si no hay pendientes
        if (items.isEmpty) return const SizedBox.shrink();

        return Container(
          width: UIConstants.KANBAN_CARD_WIDTH,
          margin: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, l10n, items.length),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _PendingApprovalCard(
                      pendingObject: items[index],
                      canApprove: canApprove,
                      onDropToApprove: onDropToApprove,
                      onDragStarted: onDragStarted,
                      onDragEnd: onDragEnd
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

  Widget _buildHeader(
      BuildContext context, AppLocalizations l10n, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.pendingApprovalColumnTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta individual de pending approval
// ─────────────────────────────────────────────────────────────────────────────

class _PendingApprovalCard extends StatelessWidget {
  final PendingObjectModel pendingObject;
  final bool canApprove;
  final void Function(PendingObjectModel) onDropToApprove;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const _PendingApprovalCard({
    required this.pendingObject,
    required this.canApprove,
    required this.onDropToApprove,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    if (!canApprove) return card;

    // Con permiso: la tarjeta es arrastrable
    return LongPressDraggable<PendingObjectModel>(
      data: pendingObject,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 280, child: _buildCard(context, isDragging: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
      onDragStarted: onDragStarted,
      onDraggableCanceled: (_, __) => onDragEnd?.call(),
      onDragEnd: (_) => onDragEnd?.call(),
      onDragCompleted: onDragEnd,
    );
  }

  Widget _buildCard(BuildContext context, {bool isDragging = false}) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDragging ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del objeto (lote/producto/proyecto)
            Row(
              children: [
                Icon(
                  pendingObject.objectType.icon,
                  size: 16,
                  color: pendingObject.objectType.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pendingObject.objectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Tipo de objeto
            Text(
              pendingObject.objectType.label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 6),

            // Solicitante
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pendingObject.createdByName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Fecha de solicitud
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(pendingObject.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Chip de estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    l10n.yourRequestAwaitingApproval,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Indicador de que es arrastrable si tiene permiso
                if (canApprove)
                  Icon(Icons.drag_indicator,
                      size: 16, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DragTarget wrapper para la primera columna real del Kanban
//
// Envuelve el widget de columna existente y activa el callback al soltar
// un PendingObjectModel encima.
// ─────────────────────────────────────────────────────────────────────────────

class PendingApprovalDragTarget extends StatelessWidget {
  /// El widget de la primera columna real (se renderiza sin cambios dentro).
  final Widget child;

  /// Callback invocado cuando se suelta un PendingObjectModel aquí.
  final void Function(PendingObjectModel pendingObject) onPendingDropped;

  /// Si es false, el DragTarget está desactivado (no se acepta el drop).
  final bool enabled;

  const PendingApprovalDragTarget({
    super.key,
    required this.child,
    required this.onPendingDropped,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return DragTarget<PendingObjectModel>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onPendingDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isHovering
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade400, width: 2),
                  color: Colors.green.shade50,
                )
              : null,
          child: child,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de confirmación de aprobación de lote desde el Kanban
// ─────────────────────────────────────────────────────────────────────────────

class BatchApprovalConfirmationDialog extends StatefulWidget {
  final PendingObjectModel pendingObject;
  final String organizationId;
  final UserModel currentUser;

  const BatchApprovalConfirmationDialog({
    super.key,
    required this.pendingObject,
    required this.organizationId,
    required this.currentUser,
  });

  /// Muestra el diálogo y devuelve true si fue aprobado, false si rechazado,
  /// null si fue cancelado.
  static Future<bool?> show(
    BuildContext context, {
    required PendingObjectModel pendingObject,
    required String organizationId,
    required UserModel currentUser,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BatchApprovalConfirmationDialog(
        pendingObject: pendingObject,
        organizationId: organizationId,
        currentUser: currentUser,
      ),
    );
  }

  @override
  State<BatchApprovalConfirmationDialog> createState() =>
      _BatchApprovalConfirmationDialogState();
}

class _BatchApprovalConfirmationDialogState
    extends State<BatchApprovalConfirmationDialog> {
  final _rejectionController = TextEditingController();
  bool _showRejectionField = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pendingService =
        Provider.of<PendingObjectService>(context, listen: false);
    final notifService =
        Provider.of<NotificationService>(context, listen: false);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.confirmBatchApprovalTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos del lote
              _buildBatchSummary(l10n),

              const Divider(height: 24),

              // Lista de productos del lote
              Text(
                l10n.productsInBatch,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildProductsList(),

              const SizedBox(height: 12),

              // Nota informativa de qué ocurrirá
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.batchWillMoveToFirstPhase,
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),

              // Campo de motivo de rechazo (aparece dinámicamente)
              if (_showRejectionField) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.rejectionReason,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rejectionController,
                  decoration: InputDecoration(
                    hintText: l10n.enterRejectionReason,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: _isLoading
          ? [const Center(child: CircularProgressIndicator())]
          : _showRejectionField
              ? [
                  // Confirmando rechazo
                  TextButton(
                    onPressed: () =>
                        setState(() => _showRejectionField = false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => _handleReject(
                        context, l10n, pendingService, notifService),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: Text(l10n.reject),
                  ),
                ]
              : [
                  // Opciones principales
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showRejectionField = true),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: Text(
                      l10n.rejectRequest,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _handleApprove(
                        context, l10n, pendingService, notifService),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.approveAll),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                ],
    );
  }

  Widget _buildBatchSummary(AppLocalizations l10n) {
    final obj = widget.pendingObject;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(obj.objectType.icon, color: obj.objectType.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                obj.objectName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _summaryRow(Icons.person_outline, l10n.requestedBy, obj.createdByName),
        const SizedBox(height: 4),
        _summaryRow(
          Icons.access_time,
          l10n.requestedAt,
          '${obj.createdAt.day}/${obj.createdAt.month}/${obj.createdAt.year}',
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Extrae y renderiza la lista de productos del modelData del pending object.
  Widget _buildProductsList() {
    final modelData = widget.pendingObject.modelData;

    // Los productos pueden estar en distintas claves según el tipo de objeto
    final rawProducts = modelData['products'] as List<dynamic>?
        ?? modelData['items'] as List<dynamic>?
        ?? [];

    if (rawProducts.isEmpty) {
      // Si no hay lista anidada, mostrar los datos del objeto directamente
      return _buildSingleObjectInfo(modelData);
    }

    return Column(
      children: rawProducts.map<Widget>((item) {
        final product = item as Map<String, dynamic>;
        final name = product['productName'] as String?
            ?? product['name'] as String?
            ?? '—';
        final qty = product['quantity'];
        final ref = product['productReference'] as String?;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ref != null)
                Text(
                  ref,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
              const SizedBox(width: 8),
              if (qty != null)
                Text(
                  'x$qty',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleObjectInfo(Map<String, dynamic> data) {
    // Renderizar pares clave-valor filtrando campos técnicos irrelevantes
    const _skip = {
      'id', 'batchId', 'organizationId', 'createdAt', 'updatedAt',
      'phaseProgress', 'statusHistory',
    };

    final entries = data.entries
        .where((e) =>
            !_skip.contains(e.key) &&
            e.value != null &&
            e.value.toString().isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _formatKey(e.key),
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  e.value.toString(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ')
        .trim();
  }

  Future<void> _handleApprove(
    BuildContext context,
    AppLocalizations l10n,
    PendingObjectService pendingService,
    NotificationService notifService,
  ) async {
    setState(() => _isLoading = true);

    final notificationId =
        widget.pendingObject.notificationId ?? '';

    // Obtener servicios necesarios para crear objetos
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final projectService = Provider.of<ProjectService>(context, listen: false);
    final catalogService =
        Provider.of<ProductCatalogService>(context, listen: false);
    final phaseService = Provider.of<PhaseService>(context, listen: false);

    final success = await ApprovalHelper.approveRequest(
      organizationId: widget.organizationId,
      pendingObjectId: widget.pendingObject.id,
      approvedBy: widget.currentUser.uid,
      approvedByName: widget.currentUser.name,
      notificationId: notificationId,
      pendingService: pendingService,
      notificationService: notifService,
      // Pasar servicios para crear objetos
      batchService: batchService,
      projectService: projectService,
      catalogService: catalogService,
      phaseService: phaseService,
    );

    if (!context.mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.approvalSuccessful),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorApprovingRequest),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    AppLocalizations l10n,
    PendingObjectService pendingService,
    NotificationService notifService,
  ) async {
    final reason = _rejectionController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rejectionReasonRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final notificationId =
        widget.pendingObject.notificationId ?? '';

    final success = await ApprovalHelper.rejectRequest(
      organizationId: widget.organizationId,
      pendingObjectId: widget.pendingObject.id,
      rejectedBy: widget.currentUser.uid,
      rejectedByName: widget.currentUser.name,
      rejectionReason: reason,
      notificationId: notificationId,
      pendingService: pendingService,
      notificationService: notifService,
    );

    if (!context.mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rejectionSuccessful),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorRejectingRequest),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}