import 'package:flutter/material.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';

class DraggableProductCard extends StatelessWidget {
  final BatchProductModel product;
  final List<ProductionPhase> allPhases;
  final String batchNumber;
  final VoidCallback? onTap;

  const DraggableProductCard({
    Key? key,
    required this.product,
    required this.allPhases,
    required this.batchNumber,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'product': product,
        'fromPhase': product.currentPhase,
      },
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: 0.8,
          child: Container(
            width: 280,
            child: _buildCard(context),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCard(context),
      ),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final totalProgress = product.totalProgress;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // NUEVO: Número de lote arriba
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, size: 10, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          batchNumber,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Estado del producto
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.statusDisplayName,
                      style: TextStyle(
                        color: product.statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Nombre del producto
              Text(
                product.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Referencia si existe
              if (product.productReference != null) ...[
                Row(
                  children: [
                    const Icon(Icons.tag, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.productReference!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              // Cantidad
              Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Cantidad: ${product.quantity}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              
              // Personalización si existe
              if (product.color != null || product.material != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.color != null) ...[
                      const Icon(Icons.palette, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        product.color!,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                    if (product.color != null && product.material != null)
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                    if (product.material != null)
                      Expanded(
                        child: Text(
                          product.material!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green.shade600;
    if (progress >= 0.5) return Colors.blue.shade600;
    if (progress >= 0.3) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}