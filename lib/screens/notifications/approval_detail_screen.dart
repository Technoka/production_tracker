import 'package:flutter/material.dart';
import 'package:gestion_produccion/services/phase_service.dart';
import 'package:gestion_produccion/services/product_catalog_service.dart';
import 'package:gestion_produccion/services/production_batch_service.dart';
import 'package:gestion_produccion/services/project_service.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/pending_object_service.dart';
import '../../services/notification_service.dart';
import '../../models/pending_object_model.dart';
import '../../helpers/approval_helper.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final String notificationId;
  final String pendingObjectId;

  const ApprovalDetailScreen({
    super.key,
    required this.notificationId,
    required this.pendingObjectId,
  });

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  final _rejectionReasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final pendingService = Provider.of<PendingObjectService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    final user = authService.currentUserData;
    final organizationId = user?.organizationId;

    if (user == null || organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.pendingApproval)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pendingApproval),
      ),
      body: FutureBuilder<PendingObjectModel?>(
        future: pendingService.getPendingObject(organizationId, widget.pendingObjectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.objectNotFound,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final pendingObject = snapshot.data!;

          // Si ya fue revisado, mostrar estado
          if (!pendingObject.isPending) {
            return _buildReviewedState(context, l10n, pendingObject);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tipo de objeto
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(pendingObject.objectType.icon,
                                color: pendingObject.objectType.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pendingObject.objectType.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pendingObject.objectName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          l10n.requestedBy,
                          pendingObject.createdByName,
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          l10n.requestedAt,
                          _formatDate(pendingObject.createdAt),
                          Icons.access_time,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Datos del objeto
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.detailsLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildModelDataWidgets(pendingObject.modelData, l10n),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botones de acción
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(
                            context,
                            l10n,
                            pendingObject,
                            organizationId,
                            user.uid,
                            user.name,
                            pendingService,
                            notificationService,
                          ),
                          icon: const Icon(Icons.close),
                          label: Text(l10n.rejectRequest),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _handleApprove(
                            context,
                            l10n,
                            organizationId,
                            user.uid,
                            user.name,
                            pendingService,
                            notificationService,
                          ),
                          icon: const Icon(Icons.check),
                          label: Text(l10n.approveRequest),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewedState(
    BuildContext context,
    AppLocalizations l10n,
    PendingObjectModel pendingObject,
  ) {
    final isApproved = pendingObject.isApproved;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApproved ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: isApproved ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isApproved ? l10n.requestApproved : l10n.requestRejected,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${isApproved ? l10n.approvedBy : l10n.rejectedBy}: ${pendingObject.reviewedByName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isApproved && pendingObject.rejectionReason != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rejectionReason,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pendingObject.rejectionReason!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildModelDataWidgets(
    Map<String, dynamic> modelData,
    AppLocalizations l10n,
  ) {
    final widgets = <Widget>[];

    modelData.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatFieldName(key),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return widgets;
  }

  String _formatFieldName(String key) {
    // Convertir camelCase a Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

Future<void> _handleApprove(
  BuildContext context,
  AppLocalizations l10n,
  String organizationId,
  String userId,
  String userName,
  PendingObjectService pendingService,
  NotificationService notificationService,
) async {
  setState(() => _isLoading = true);

  // Obtener servicios necesarios para crear objetos
  final batchService = Provider.of<ProductionBatchService>(context, listen: false);
  final projectService = Provider.of<ProjectService>(context, listen: false);
  final catalogService = Provider.of<ProductCatalogService>(context, listen: false);
  final phaseService = Provider.of<PhaseService>(context, listen: false);

  final success = await ApprovalHelper.approveRequest(
    organizationId: organizationId,
    pendingObjectId: widget.pendingObjectId,
    approvedBy: userId,
    approvedByName: userName,
    notificationId: widget.notificationId,
    pendingService: pendingService,
    notificationService: notificationService,
    // Pasar servicios para crear objetos
    batchService: batchService,
    projectService: projectService,
    catalogService: catalogService,
    phaseService: phaseService,
  );

    if (context.mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.approvalSuccessful),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorApprovingRequest),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    AppLocalizations l10n,
    PendingObjectModel pendingObject,
    String organizationId,
    String userId,
    String userName,
    PendingObjectService pendingService,
    NotificationService notificationService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectRequest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enterRejectionReason),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: InputDecoration(
                labelText: l10n.rejectionReason,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.reject),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = _rejectionReasonController.text.trim();
      
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

      final success = await ApprovalHelper.rejectRequest(
        organizationId: organizationId,
        pendingObjectId: widget.pendingObjectId,
        rejectedBy: userId,
        rejectedByName: userName,
        rejectionReason: reason,
        notificationId: widget.notificationId,
        pendingService: pendingService,
        notificationService: notificationService,
      );

      if (context.mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.rejectionSuccessful),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
  }
}