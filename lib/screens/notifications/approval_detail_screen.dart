import 'package:cloud_firestore/cloud_firestore.dart';
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
                        ..._buildModelDataWidgets(pendingObject.modelData, l10n, pendingObject.objectType),
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

  // Widget _buildInfoRow(String label, String value, IconData icon) {
  //   return Row(
  //     children: [
  //       Icon(icon, size: 16, color: Colors.grey.shade600),
  //       const SizedBox(width: 8),
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 12,
  //           color: Colors.grey.shade600,
  //         ),
  //       ),
  //       const SizedBox(width: 8),
  //       Expanded(
  //         child: Text(
  //           value,
  //           style: const TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w500,
  //           ),
  //           textAlign: TextAlign.right,
  //         ),
  //       ),
  //     ],
  //   );
  // }

List<Widget> _buildModelDataWidgets(
  Map<String, dynamic> modelData,
  AppLocalizations l10n,
  PendingObjectType objectType,
) {
  // Si es un lote, usar vista personalizada
  if (objectType == PendingObjectType.batch) {
    return _buildBatchDataWidgets(modelData, l10n);
  }

  // Para otros tipos de objetos, usar vista genérica
  final widgets = <Widget>[];

  modelData.forEach((key, value) {
    // Omitir campos internos y arrays complejos
    if (value != null && 
        value.toString().isNotEmpty && 
        key != 'products' && 
        key != 'createdAt' && 
        key != 'updatedAt') {
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

/// Vista personalizada para datos de batch
List<Widget> _buildBatchDataWidgets(
  Map<String, dynamic> modelData,
  AppLocalizations l10n,
) {
  final widgets = <Widget>[];

  // 1. Batch Number
  if (modelData['batchNumber'] != null) {
    widgets.add(_buildInfoRow(
      'Número de Lote',
      modelData['batchNumber'].toString(),
      Icons.numbers,
    ));
  }

  // 2. Client Name
  if (modelData['clientName'] != null) {
    widgets.add(_buildInfoRow(
      l10n.client,
      modelData['clientName'].toString(),
      Icons.business,
    ));
  }

  // 3. Project Name
  if (modelData['projectName'] != null) {
    widgets.add(_buildInfoRow(
      l10n.project,
      modelData['projectName'].toString(),
      Icons.folder_outlined,
    ));
  }

  // 4. Notes (si existe)
  if (modelData['notes'] != null && 
      modelData['notes'].toString().isNotEmpty) {
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Notas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                modelData['notes'].toString(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Product Count
  final products = modelData['products'] as List?;
  final productCount = products?.length ?? 0;
  
  widgets.add(_buildInfoRow(
    'Cantidad de Productos',
    productCount.toString(),
    Icons.inventory_2_outlined,
  ));

  // 6. Products List
  if (products != null && products.isNotEmpty) {
    widgets.add(const SizedBox(height: 8));
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.list_alt, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Productos del Lote',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    for (final product in products) {
      widgets.add(_buildProductCard(product as Map<String, dynamic>));
    }
  }

  return widgets;
}

/// Widget de fila de información con icono
Widget _buildInfoRow(String label, String value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Card individual de producto
Widget _buildProductCard(Map<String, dynamic> productData) {
  final productNumber = productData['productNumber']?.toString() ?? '?';
  final productReference = productData['productReference']?.toString() ?? 'Sin ref.';
  final family = productData['family']?.toString();
  final urgencyLevel = productData['urgencyLevel']?.toString() ?? 'medium';
  final isUrgent = urgencyLevel == 'urgent' || urgencyLevel == 'high';
  
  // Parsear fecha
  String? deliveryDateStr;
  final deliveryDate = productData['expectedDeliveryDate'];
  if (deliveryDate != null) {
    try {
      if (deliveryDate is Timestamp) {
        final date = deliveryDate.toDate();
        deliveryDateStr = '${date.day}/${date.month}/${date.year}';
      } else if (deliveryDate is String) {
        deliveryDateStr = deliveryDate;
      }
    } catch (e) {
      deliveryDateStr = null;
    }
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isUrgent ? Colors.orange.shade200 : Colors.grey.shade200,
        width: isUrgent ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con número y urgencia
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#$productNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.priority_high,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'URGENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Referencia
        _buildProductInfoRow(
          Icons.tag,
          'Referencia',
          productReference,
        ),
        
        // Familia (si existe)
        if (family != null && family.isNotEmpty)
          _buildProductInfoRow(
            Icons.category_outlined,
            'Familia',
            family,
          ),
        
        // Fecha de entrega (si existe)
        if (deliveryDateStr != null)
          _buildProductInfoRow(
            Icons.calendar_today,
            'Entrega Estimada',
            deliveryDateStr,
          ),
      ],
    ),
  );
}

/// Fila de información dentro del card de producto
Widget _buildProductInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
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