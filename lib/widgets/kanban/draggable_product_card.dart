import 'package:flutter/material.dart';
import 'package:gestion_produccion/widgets/chat/chat_button.dart';
import 'package:provider/provider.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/production_batch_model.dart';
import '../../services/auth_service.dart';
import '../../../widgets/sla/sla_status_indicator.dart';

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
    required this.batch,
    this.onTap,
    this.onDragStarted,
    this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // (El código del LongPressDraggable sigue igual...)
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'product': product,
        'batch': batch,
        'fromPhase': product.currentPhase,
      },
      onDragStarted: onDragStarted,
      onDraggableCanceled: (_, __) => onDragEnd?.call(),
      onDragEnd: (_) => onDragEnd?.call(),
      onDragCompleted: onDragEnd,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: 0.8,
          child: SizedBox(
            width: 280,
            child: _buildCard(context, isFeedback: true),
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

  Widget _buildCard(BuildContext context, {bool isFeedback = false}) {
    final user =
        Provider.of<AuthService>(context, listen: false).currentUserData;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isFeedback ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER: Lote y Badges ---
              // (Este bloque sigue igual...)
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2,
                            size: 10, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Lote: $batchNumber (#${product.productNumber}/${batch.totalProducts})',
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
                  if (product.urgencyLevel == UrgencyLevel.urgent.value)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.urgencyDisplayName,
                        style: TextStyle(
                          color: product.urgencyColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // --- NOMBRE Y ESTADO ---
              // (Este bloque sigue igual...)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SLAStatusIndicator(
                    organizationId: batch.organizationId,
                    productId: product.id,
                    compact: true, // Modo compacto para que salga solo el icono/badge
                  ),
                  const SizedBox(width: 8),
                  if (product.productStatus != ProductStatus.pending.value)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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

              // ✅ ESTRUCTURA NUEVA: Bloque de Info + Botón de Chat Centrado
              Row(
                // Al usar center aquí, el elemento de la derecha (el botón)
                // se centrará respecto a la altura total del elemento de la izquierda (la columna de texto)
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  // --- Columna Izquierda: SKU, Cantidad, Detalles ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SKU (Si existe) ---
                        if (product.productReference != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.tag,
                                  size: 12, color: Colors.grey),
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

                        // --- Cantidad ---
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Cantidad: ${product.quantity}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),

                        // --- Material y Color (Si existen) ---
                        if (product.color != null ||
                            product.material != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (product.color != null) ...[
                                const Icon(Icons.palette,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    product.color!,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (product.color != null &&
                                  product.material != null)
                                const Text(' • ',
                                    style: TextStyle(color: Colors.grey)),
                              if (product.material != null)
                                Expanded(
                                  child: Text(
                                    product.material!,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
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

                  // --- Columna Derecha: Botón de Chat ---
                  // Se centrará automáticamente por el Row padre.
                  if (user != null && !isFeedback)
                   Padding(
                     padding: const EdgeInsets.only(left: 8.0), // Un poco de espacio a la izquierda del botón
                     child: ChatButton(
                          organizationId: batch.organizationId,
                          entityType: 'batch_product',
                          entityId: product.id,
                          parentId: product.batchId,
                          entityName:
                              '${product.productName} - ${product.productReference}',
                          user: user,
                          showInAppBar: true),
                   )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}