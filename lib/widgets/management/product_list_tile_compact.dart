// lib/widgets/management/product_list_tile_compact.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_product_model.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/products/project_product_detail_screen.dart';

class ProductListTileCompact extends StatelessWidget {
  final dynamic product; // ProjectProductModel
  final String projectId;

  const ProductListTileCompact({
    Key? key,
    required this.product,
    required this.projectId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    // Determinar fase actual y urgencia (adaptar según tu modelo)
    final currentPhase = product.currentPhase ?? l10n.pending;
    final isUrgent = product.urgencyLevel == 'urgent';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              product.catalogProductName ?? product.productName ?? l10n.product,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 10,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    l10n.urgentLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 11,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(
            currentPhase,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${product.quantity} ${l10n.unitsSuffix}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 14),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectProductDetailScreen(
                projectId: projectId,
                productId: product.id,
                currentUser: user,
              ),
            ),
          );
        },
        tooltip: l10n.viewDetailsTooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}