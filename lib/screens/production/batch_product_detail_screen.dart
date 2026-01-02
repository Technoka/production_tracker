import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/phase_service.dart';

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
  State<BatchProductDetailScreen> createState() => _BatchProductDetailScreenState();
}

class _BatchProductDetailScreenState extends State<BatchProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    return FutureBuilder<BatchProductModel?>(
      future: Provider.of<ProductionBatchService>(context, listen: false)
          .getBatchProduct(widget.organizationId, widget.batchId, widget.productId),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cargando...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (productSnapshot.hasError || productSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error al cargar el producto: ${productSnapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final product = productSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(product.productName),
            actions: [
              if (user?.canManageProduction ?? false)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleAction(value, product, user!),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Información del producto
                _buildProductInfoCard(product, user),
                const SizedBox(height: 16),

                // Progreso por fases
                _buildPhasesCard(product, user),
                const SizedBox(height: 16),

                // Personalización
                if (product.color != null ||
                    product.material != null ||
                    product.specialDetails != null)
                  _buildCustomizationCard(product),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfoCard(BatchProductModel product, UserModel? user) {
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
                const Text(
                  'Información del Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

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
            if (product.productReference != null) ...[
              Text(
                'Referencia: ${product.productReference}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Descripción
            if (product.description != null) ...[
              Text(
                product.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 8),

            // Cantidad
            _buildInfoRow(
              Icons.numbers,
              'Cantidad',
              '${product.quantity} unidades',
            ),
            const SizedBox(height: 8),

            // Precio (solo para roles autorizados)
            if ((user?.canViewFinancials ?? false) && product.unitPrice != null) ...[
              _buildInfoRow(
                Icons.euro,
                'Precio unitario',
                '${product.unitPrice!.toStringAsFixed(2)} €',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.account_balance_wallet,
                'Precio total',
                '${product.totalPrice?.toStringAsFixed(2) ?? "0.00"} €',
                isBold: true,
              ),
              const SizedBox(height: 8),
            ],

            // Progreso general
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progreso General',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${product.progressPercentage}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: product.totalProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          product.isCompleted ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.completedPhasesCount} de ${product.totalPhasesCount} fases completadas',
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

            // Estado actual
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Fase actual: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    product.currentPhaseName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhasesCard(BatchProductModel product, UserModel? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt),
                const SizedBox(width: 8),
                const Text(
                  'Fases de Producción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            FutureBuilder<List<ProductionPhase>>(
              future: Provider.of<PhaseService>(context, listen: false)
                  .getOrganizationPhases(widget.organizationId),
              builder: (context, phasesSnapshot) {
                if (phasesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (phasesSnapshot.hasError) {
                  return Text('Error: ${phasesSnapshot.error}');
                }

                final allPhases = phasesSnapshot.data ?? [];
                allPhases.sort((a, b) => a.order.compareTo(b.order));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allPhases.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
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
    final isPending = progress?.isPending ?? true;
    final isInProgress = progress?.isInProgress ?? false;
    final isCompleted = progress?.isCompleted ?? false;

    Color backgroundColor;
    Color borderColor;
    IconData icon;

    if (isCompleted) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isInProgress || isCurrentPhase) {
      backgroundColor = Colors.blue[50]!;
      borderColor = Colors.blue;
      icon = Icons.play_circle;
    } else {
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.grey;
      icon = Icons.radio_button_unchecked;
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
                    if (phase.description != null)
                      Text(
                        phase.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (isCurrentPhase && (user?.canManageProduction ?? false)) ...[
                // Botón para avanzar a siguiente fase
                if (currentIndex < allPhases.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _showAdvancePhaseDialog(
                      product,
                      allPhases[currentIndex + 1],
                      user!,
                    ),
                    tooltip: 'Avanzar fase',
                  ),
              ],
            ],
          ),

          // Detalles de la fase
          if (progress != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            if (progress.startedAt != null)
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Iniciado: ${_formatDateTime(progress.startedAt!)}',
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
                    'Completado: ${_formatDateTime(progress.completedAt!)}',
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
                    'Por: ${progress.completedByName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            if (progress.notes != null && progress.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notas: ${progress.notes}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCustomizationCard(BatchProductModel product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                const Text(
                  'Personalización',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (product.color != null) ...[
              _buildInfoRow(Icons.color_lens, 'Color', product.color!),
              const SizedBox(height: 8),
            ],

            if (product.material != null) ...[
              _buildInfoRow(Icons.texture, 'Material', product.material!),
              const SizedBox(height: 8),
            ],

            if (product.specialDetails != null) ...[
              _buildInfoRow(Icons.notes, 'Detalles especiales', product.specialDetails!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isBold = false}) {
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAdvancePhaseDialog(
    BatchProductModel product,
    ProductionPhase nextPhase,
    UserModel user,
  ) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avanzar Fase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Completar fase actual y avanzar a "${nextPhase.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Añade observaciones...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final batchService = Provider.of<ProductionBatchService>(
                context,
                listen: false,
              );

              Navigator.pop(context); // Cerrar diálogo

              final success = await batchService.updateProductPhase(
                organizationId: widget.organizationId,
                batchId: widget.batchId,
                productId: widget.productId,
                newPhaseId: nextPhase.id,
                newPhaseName: nextPhase.name,
                userId: user.uid,
                userName: user.name,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Avanzado a fase: ${nextPhase.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {}); // Refrescar pantalla
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al avanzar fase'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Avanzar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    String action,
    BatchProductModel product,
    UserModel user,
  ) async {
    if (action == 'delete') {
      _showDeleteConfirmation(product);
    }
  }

  void _showDeleteConfirmation(BatchProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de eliminar "${product.productName}" del lote?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final batchService = Provider.of<ProductionBatchService>(
                context,
                listen: false,
              );

              Navigator.pop(context); // Cerrar diálogo

              final success = await batchService.deleteProductFromBatch(
                widget.organizationId,
                widget.batchId,
                widget.productId,
              );

              if (success && mounted) {
                Navigator.pop(context); // Volver a detalle del lote
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}