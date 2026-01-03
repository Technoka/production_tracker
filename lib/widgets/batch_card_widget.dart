import 'package:flutter/material.dart';
import '../models/production_batch_model.dart';

/// Widget reutilizable para mostrar una tarjeta de lote de producción
class BatchCardWidget extends StatelessWidget {
  final ProductionBatchModel batch;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool compact;

  const BatchCardWidget({
    super.key,
    required this.batch,
    this.onTap,
    this.showProgress = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batch.batchNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(batch.status),
                ],
              ),
              const SizedBox(height: 8),

              // Proyecto y Cliente
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      batch.projectName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      batch.clientName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              if (showProgress) ...[
                const SizedBox(height: 12),
                // Progreso
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
                                'Progreso',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${batch.completedProducts}/${batch.totalProducts} productos',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: batch.progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              batch.isComplete
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${batch.progressPercentage}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // Fecha
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado: ${_formatDate(batch.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Indicadores
              if (batch.isDelayed || batch.urgencyNumericValue <= 2) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (batch.isDelayed)
                      _buildChip(
                        'Retrasado',
                        Icons.warning,
                        Colors.orange[100]!,
                        Colors.orange[900]!,
                      ),
                    if (batch.urgencyNumericValue <= 2)
                      _buildChip(
                        'Prioridad Alta',
                        Icons.priority_high,
                        Colors.red[100]!,
                        Colors.red[900]!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono de estado
              CircleAvatar(
                backgroundColor: _getStatusColor(batch.status).withOpacity(0.2),
                child: Icon(
                  _getStatusIcon(batch.status),
                  color: _getStatusColor(batch.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.batchNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      batch.projectName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Progreso
              if (showProgress) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${batch.progressPercentage}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${batch.completedProducts}/${batch.totalProducts}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color bgColor, Color textColor) {
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      backgroundColor: bgColor,
      labelStyle: TextStyle(
        fontSize: 12,
        color: textColor,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'in_progress':
        return 'En Producción';
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}