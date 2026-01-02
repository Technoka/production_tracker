import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/production_batch_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import 'add_product_to_batch_screen.dart';
import 'batch_product_detail_screen.dart';

class ProductionBatchDetailScreen extends StatefulWidget {
  final String organizationId;
  final String batchId;

  const ProductionBatchDetailScreen({
    super.key,
    required this.organizationId,
    required this.batchId,
  });

  @override
  State<ProductionBatchDetailScreen> createState() => _ProductionBatchDetailScreenState();
}

class _ProductionBatchDetailScreenState extends State<ProductionBatchDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final batchService = Provider.of<ProductionBatchService>(context);
    final user = authService.currentUserData;

    return StreamBuilder<ProductionBatchModel?>(
      stream: batchService.watchBatch(widget.organizationId, widget.batchId),
      builder: (context, batchSnapshot) {
        if (batchSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cargando...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (batchSnapshot.hasError || batchSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error al cargar el lote: ${batchSnapshot.error}'),
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

        final batch = batchSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(batch.batchNumber),
            actions: [
              // Cambiar estado
              if (user?.canManageProduction ?? false)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleAction(value, batch, user!),
                  itemBuilder: (context) => [
                    if (batch.status != BatchStatus.inProgress.value)
                      const PopupMenuItem(
                        value: 'start',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 20),
                            SizedBox(width: 8),
                            Text('Iniciar Producción'),
                          ],
                        ),
                      ),
                    if (batch.status != BatchStatus.completed.value && batch.isComplete)
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Marcar Completado'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar Notas'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar Lote', style: TextStyle(color: Colors.red)),
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
                // Información del lote
                _buildBatchInfoCard(batch),
                const SizedBox(height: 16),

                // Progreso general
                _buildProgressCard(batch),
                const SizedBox(height: 16),

                // Lista de productos
                _buildProductsSection(batch, user),
              ],
            ),
          ),
          floatingActionButton: (user?.canManageProduction ?? false)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductToBatchScreen(
                          organizationId: widget.organizationId,
                          batchId: widget.batchId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Producto'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBatchInfoCard(ProductionBatchModel batch) {
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
                  'Información del Lote',
                  style: TextStyle(
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
                  'Estado:',
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
              'Proyecto',
              batch.projectName,
            ),
            const SizedBox(height: 8),

            // Cliente
            _buildInfoRow(
              Icons.person_outline,
              'Cliente',
              batch.clientName,
            ),
            const SizedBox(height: 8),

            // Fecha de creación
            _buildInfoRow(
              Icons.calendar_today,
              'Creado',
              _formatDate(batch.createdAt),
            ),

            if (batch.expectedCompletionDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.event,
                'Entrega esperada',
                _formatDate(batch.expectedCompletionDate!),
              ),
            ],

            // Prioridad y urgencia
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text('Prioridad: ${batch.priority}'),
                  avatar: const Icon(Icons.flag, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_getUrgencyLabel(batch.urgencyLevel)),
                  avatar: const Icon(Icons.speed, size: 16),
                  backgroundColor: _getUrgencyColor(batch.urgencyLevel),
                ),
              ],
            ),

            // Notas
            if (batch.notes != null && batch.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Notas:',
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
  return FutureBuilder<Map<String, double>>(
    future: _calculateProgressStats(batch),
    builder: (context, statsSnapshot) {
      final stats = statsSnapshot.data ?? {
        'phaseProgress': 0.0,
        'statusProgress': 0.0,
        'phaseCompleted': 0,
        'phaseTotal': 0,
        'statusCompleted': 0,
        'statusTotal': 0,
      };

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Progreso General',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PROGRESO 1: FASES DE PRODUCCIÓN
              Row(
                children: [
                  Icon(Icons.precision_manufacturing, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Fases de Producción',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${stats['phaseCompleted']?.toInt() ?? 0} de ${stats['phaseTotal']?.toInt() ?? 0} en Studio',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${((stats['phaseProgress'] ?? 0) * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: stats['phaseProgress'] ?? 0,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stats['phaseProgress'] == 1.0 
                                ? Colors.green 
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // PROGRESO 2: ESTADOS (OK)
              Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Estado Final (OK)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${stats['statusCompleted']?.toInt() ?? 0} de ${stats['statusTotal']?.toInt() ?? 0} aprobados',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${((stats['statusProgress'] ?? 0) * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: stats['statusProgress'] ?? 0,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stats['statusProgress'] == 1.0 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
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

// AÑADIR este método helper para calcular estadísticas:
Future<Map<String, double>> _calculateProgressStats(ProductionBatchModel batch) async {
  final batchService = Provider.of<ProductionBatchService>(context, listen: false);
  
  try {
    final products = await batchService
        .watchBatchProducts(widget.organizationId, widget.batchId)
        .first;

    if (products.isEmpty) {
      return {
        'phaseProgress': 0.0,
        'statusProgress': 0.0,
        'phaseCompleted': 0.0,
        'phaseTotal': 0.0,
        'statusCompleted': 0.0,
        'statusTotal': 0.0,
      };
    }

    // Contar productos en Studio (fase completada)
    final inStudio = products.where((p) => p.isInStudio).length;
    final phaseProgress = inStudio / products.length;

    // Contar productos en estado OK
    final okStatus = products.where((p) => p.isOK).length;
    final statusProgress = okStatus / products.length;

    return {
      'phaseProgress': phaseProgress,
      'statusProgress': statusProgress,
      'phaseCompleted': inStudio.toDouble(),
      'phaseTotal': products.length.toDouble(),
      'statusCompleted': okStatus.toDouble(),
      'statusTotal': products.length.toDouble(),
    };
  } catch (e) {
    return {
      'phaseProgress': 0.0,
      'statusProgress': 0.0,
      'phaseCompleted': 0.0,
      'phaseTotal': 0.0,
      'statusCompleted': 0.0,
      'statusTotal': 0.0,
    };
  }
}

Widget _buildProductsSection(ProductionBatchModel batch, UserModel? user) {
  return StreamBuilder<List<BatchProductModel>>(
    stream: Provider.of<ProductionBatchService>(context, listen: false)
        .watchBatchProducts(widget.organizationId, widget.batchId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (snapshot.hasError) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}'),
          ),
        );
      }

      final products = snapshot.data ?? [];

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
                  'No hay productos en este lote',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Añade productos usando el botón +',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Calcular estadísticas por fase y estado
      final phaseStats = _calculatePhaseStats(products);
      final statusStats = _calculateStatusStats(products);

      return Column(
        children: [
          const SizedBox(height: 16),

          // Lista de productos (código existente)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Productos (${products.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductTile(product, user);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

// AÑADIR métodos helper:

Map<String, int> _calculatePhaseStats(List<BatchProductModel> products) {
  final stats = <String, int>{
    'planned': 0,
    'cutting': 0,
    'skiving': 0,
    'assembly': 0,
    'studio': 0,
  };

  for (final product in products) {
    final phase = product.currentPhase;
    if (stats.containsKey(phase)) {
      stats[phase] = (stats[phase] ?? 0) + 1;
    }
  }

  return stats;
}

Map<String, int> _calculateStatusStats(List<BatchProductModel> products) {
  final stats = <String, int>{
    'pending': 0,
    'cao': 0,
    'hold': 0,
    'control': 0,
    'ok': 0,
  };

  for (final product in products) {
    final status = product.productStatus;
    if (stats.containsKey(status)) {
      stats[status] = (stats[status] ?? 0) + 1;
    }
  }

  return stats;
}

Widget _buildPhaseStatItem(String label, int count, Color color, int total) {
  final percentage = total > 0 ? (count / total * 100).round() : 0;
  
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($percentage%)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatusStatItem(String label, int count, Color color, int total) {
  final percentage = total > 0 ? (count / total * 100).round() : 0;
  
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($percentage%)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
  Widget _buildProductTile(BatchProductModel product, UserModel? user) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: product.isCompleted
            ? Colors.green[100]
            : Colors.blue[100],
        child: Icon(
          product.isCompleted ? Icons.check : Icons.work_outline,
          color: product.isCompleted ? Colors.green[700] : Colors.blue[700],
        ),
      ),
      title: Text(
        product.productName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cantidad: ${product.quantity}'),
          Text('Fase: ${product.currentPhaseName}'),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: product.totalProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              product.isCompleted ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
      trailing: Text(
        '${product.progressPercentage}%',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
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
    );
  }

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

    switch (status) {
      case 'pending':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = 'Pendiente';
        break;
      case 'in_progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        label = 'En Producción';
        break;
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        label = 'Completado';
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

  String _getUrgencyLabel(String urgency) {
    switch (urgency) {
      case 'low':
        return 'Baja';
      case 'medium':
        return 'Media';
      case 'high':
        return 'Alta';
      case 'critical':
        return 'Crítica';
      default:
        return urgency;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'low':
        return Colors.grey[200]!;
      case 'medium':
        return Colors.blue[100]!;
      case 'high':
        return Colors.orange[100]!;
      case 'critical':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleAction(
    String action,
    ProductionBatchModel batch,
    UserModel user,
  ) async {
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);

    switch (action) {
      case 'start':
        final success = await batchService.updateBatchStatus(
          widget.organizationId,
          widget.batchId,
          BatchStatus.inProgress.value,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lote iniciado')),
          );
        }
        break;

      case 'complete':
        final success = await batchService.updateBatchStatus(
          widget.organizationId,
          widget.batchId,
          BatchStatus.completed.value,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lote marcado como completado'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;

      case 'edit':
        _showEditNotesDialog(batch);
        break;

      case 'delete':
        _showDeleteConfirmation(batch);
        break;
    }
  }

  void _showEditNotesDialog(ProductionBatchModel batch) {
    final notesController = TextEditingController(text: batch.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Notas'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe las notas...',
            border: OutlineInputBorder(),
          ),
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

              final success = await batchService.updateBatch(
                organizationId: widget.organizationId,
                batchId: widget.batchId,
                notes: notesController.text.trim(),
              );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notas actualizadas')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

void _showDeleteConfirmation(ProductionBatchModel batch) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar Lote'),
      content: Text(
        '¿Estás seguro de eliminar el lote ${batch.batchNumber}?\n\n'
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
            Navigator.pop(context); // Volver a lista ANTES de eliminar

            final success = await batchService.deleteBatch(
              widget.organizationId,
              widget.batchId,
            );

            if (success && mounted) {
              // Mostrar mensaje en la pantalla anterior
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lote eliminado'),
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