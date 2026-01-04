import 'package:flutter/material.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';
import '../models/production_batch_model.dart';

class DraggableProductCard extends StatelessWidget {
  final BatchProductModel product;
  final List<ProductionPhase> allPhases;
  final String batchNumber;
  final ProductionBatchModel batch;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const DraggableProductCard({
    Key? key,
    required this.product,
    required this.allPhases,
    required this.batchNumber,
    required this.batch, // AÑADIR: Parámetro requerido
    this.onTap,
    this.onDragStarted,
    this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'product': product,
        'batch': batch, // CORRECCIÓN: Incluir el batch completo
        'fromPhase': product.currentPhase,
      },

      // ASIGNAR CALLBACKS AQUÍ PARA EVITAR ERROR DE BUILD
      onDragStarted: onDragStarted,
      onDraggableCanceled: (_, __) => onDragEnd?.call(),
      onDragEnd: (_) => onDragEnd?.call(),
      onDragCompleted: onDragEnd,

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
                          'Lote: $batchNumber (#${product.productNumber})',
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
              
              if (product.productReference != null) ...[
                Row(
                  children: [
                    const Icon(Icons.tag, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'SKU: ${product.productReference!}',
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
}