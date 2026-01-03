import 'package:flutter/material.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';
import 'product_kanban_card.dart';

/// Widget que envuelve ProductKanbanCard con capacidad de arrastre
class DraggableProductCard extends StatelessWidget {
  final BatchProductModel product;
  final List<ProductionPhase> allPhases;
  final VoidCallback? onTap;
  final VoidCallback? onBlock;

  const DraggableProductCard({
    Key? key,
    required this.product,
    required this.allPhases,
    this.onTap,
    this.onBlock,
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
            child: ProductKanbanCard(
              product: product,
              allPhases: allPhases,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: ProductKanbanCard(
          product: product,
          allPhases: allPhases,
        ),
      ),
      child: ProductKanbanCard(
        product: product,
        allPhases: allPhases,
        onTap: onTap,
        onBlock: onBlock,
      ),
    );
  }
}