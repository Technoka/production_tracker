import 'package:flutter/material.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';
import 'product_kanban_card.dart';

class KanbanColumnWidget extends StatelessWidget {
  final ProductionPhase phase;
  final List<BatchProductModel> products;
  final List<ProductionPhase> allPhases;
  final bool isAtWipLimit;
  final Function(BatchProductModel) onProductTap;
  final Function(BatchProductModel) onProductBlock;
  final Function(BatchProductModel, int) onReorder;

  const KanbanColumnWidget({
    Key? key,
    required this.phase,
    required this.products,
    required this.allPhases,
    required this.isAtWipLimit,
    required this.onProductTap,
    required this.onProductBlock,
    required this.onReorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(phase.color);
    
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAtWipLimit ? Colors.orange : Colors.grey.shade300,
          width: isAtWipLimit ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la columna
          _buildColumnHeader(color, context),
          
          const Divider(height: 1),
          
          // Lista de productos
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getPhaseIcon(phase.icon),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Nombre de la fase
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${products.length} ${products.length == 1 ? "producto" : "productos"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // WIP Limit badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAtWipLimit ? Colors.orange : color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${products.length}/${phase.wipLimit}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          // Advertencia WIP
          if (isAtWipLimit) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Límite WIP alcanzado',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin productos',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Arrastra productos aquí',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: products.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        onReorder(products[oldIndex], newIndex);
      },
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final product = products[index];
        return ReorderableDragStartListener(
          key: ValueKey(product.id),
          index: index,
          child: ProductKanbanCard(
            product: product,
            allPhases: allPhases,
            onTap: () => onProductTap(product),
            onBlock: () => onProductBlock(product),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(
        int.parse(colorString.replaceAll('#', '0xFF')),
      );
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getPhaseIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'design':
      case 'diseño':
        return Icons.design_services;
      case 'cut':
      case 'corte':
        return Icons.content_cut;
      case 'sewing':
      case 'costura':
        return Icons.checkroom;
      case 'assembly':
      case 'montaje':
        return Icons.construction;
      case 'quality':
      case 'calidad':
        return Icons.verified;
      case 'packaging':
      case 'empaquetado':
        return Icons.inventory;
      case 'shipping':
      case 'envío':
        return Icons.local_shipping;
      default:
        return Icons.work;
    }
  }
}