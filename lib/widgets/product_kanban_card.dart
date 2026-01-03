import 'package:flutter/material.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';

class ProductKanbanCard extends StatelessWidget {
  final BatchProductModel product;
  final List<ProductionPhase> allPhases;
  final VoidCallback? onTap;
  final VoidCallback? onBlock;

  const ProductKanbanCard({
    Key? key,
    required this.product,
    required this.allPhases,
    this.onTap,
    this.onBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysInPhase = product.getDaysInCurrentPhase();
    final totalProgress = product.totalProgress;
    
    return Card(
      elevation: product.isBlocked ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: product.isBlocked
            ? BorderSide(color: Colors.red.shade700, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con nombre y badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${product.productName} - SKU: ${product.productReference}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.isBlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BLOQUEADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Cantidad
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Cantidad: ${product.quantity}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Días en fase
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: _getDaysColor(daysInPhase),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$daysInPhase ${daysInPhase == 1 ? "día" : "días"} en esta fase',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDaysColor(daysInPhase),
                      fontWeight: daysInPhase > 7 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Barra de progreso total
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progreso total',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        '${(totalProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalProgress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(totalProgress),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              
              // Botones de acción
              if (onBlock != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onBlock,
                        icon: Icon(
                          product.isBlocked ? Icons.lock_open : Icons.block,
                          size: 14,
                        ),
                        label: Text(
                          product.isBlocked ? 'Desbloquear' : 'Bloquear',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
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

  Color _getDaysColor(int days) {
    if (days > 14) return Colors.red.shade700;
    if (days > 7) return Colors.orange.shade700;
    if (days > 3) return Colors.amber.shade700;
    return Colors.grey;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green.shade600;
    if (progress >= 0.5) return Colors.blue.shade600;
    if (progress >= 0.3) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}