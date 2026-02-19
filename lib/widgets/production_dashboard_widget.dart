// lib/widgets/production_dashboard_widget.dart
// ✅ OPTIMIZADO: Usa ProductionDataProvider para datos y permisos

import 'package:flutter/material.dart';
import 'package:gestion_produccion/l10n/app_localizations.dart';
import 'package:gestion_produccion/models/phase_model.dart';
import 'package:gestion_produccion/models/product_status_model.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
import 'package:provider/provider.dart';
import '../models/batch_product_model.dart';
import '../providers/production_data_provider.dart';
import '../screens/production/production_screen.dart';

class ProductionDashboardWidget extends StatelessWidget {
  final String organizationId;
  final String? clientId;

  const ProductionDashboardWidget({
    super.key,
    required this.organizationId,
    this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final productionProvider = Provider.of<ProductionDataProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // ✅ OPTIMIZACIÓN: Verificar si el provider está inicializado
    if (!productionProvider.isInitialized) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // ✅ OPTIMIZACIÓN: Obtener datos directamente del provider
    final phases = productionProvider.phases;
    final statuses =
        productionProvider.statuses.where((s) => s.isActive).toList();
    final batches = clientId != null
        ? productionProvider.filterBatches(clientId: clientId)
        : productionProvider.batches;

    // ✅ OPTIMIZACIÓN: Calcular estadísticas en memoria
    final stats = _calculateProductStatistics(productionProvider, batches);

    return Center(
      child: Container(
        constraints:
            const BoxConstraints(maxWidth: UIConstants.SCREEN_MAX_WIDTH),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // TÍTULO
                Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.productionDashboardTitleLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // COLUMNAS DE CONTENIDO
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildPhasesSection(context, stats, phases)),
                      const SizedBox(width: 12),
                      // Divisor vertical dinámico
                      VerticalDivider(
                          width: 1, thickness: 1, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatusSection(context, stats, statuses)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // BOTÓN INFERIOR
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductionScreen(),
                        ),
                      );
                    },
                    child: Text(l10n.viewAllBatches),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para alinear los encabezados (Solución al problema de alineación)
  Widget _buildSectionHeader(IconData icon, String title) {
    return Container(
      // Establecemos una altura mínima. Si el texto ocupa 2 líneas (~40px),
      // el otro encabezado también medirá eso, alineando los botones de TOTAL.
      constraints: const BoxConstraints(minHeight: 42),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasesSection(BuildContext context, Map<String, int> stats,
      List<ProductionPhase> phases) {
    final l10n = AppLocalizations.of(context)!;
    int totalPhases = 0;
    for (final phase in phases) {
      totalPhases += stats['phase_${phase.id}'] ?? 0;
    }

    // Verificar si todas están en la última fase
    final lastPhase = phases.isNotEmpty
        ? phases.reduce((a, b) => a.order > b.order ? a : b)
        : null;
    bool isAllLastPhase = totalPhases > 0 &&
        lastPhase != null &&
        (stats['phase_${lastPhase.id}'] ?? 0) == totalPhases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado alineado
        _buildSectionHeader(
            Icons.precision_manufacturing, l10n.productionPhasesLabel),

        const SizedBox(height: 12),
        _buildTotalItem('TOTAL', totalPhases,
            isAllLastPhase ? Colors.green[700]! : Colors.grey[800]!),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 3),
        const SizedBox(height: 8),

        // Mostrar fases dinámicamente
        ...phases.map((phase) {
          final count = stats['phase_${phase.id}'] ?? 0;
          final color = UIConstants.parseColor(phase.color);
          final icon = UIConstants.getIcon(phase.icon);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPhaseItem(
                context, phase.name, count, color, icon, phase.id),
          );
        }),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, Map<String, int> stats,
      List<ProductStatusModel> statuses) {
    final l10n = AppLocalizations.of(context)!;
    int totalStatus = 0;
    for (final status in statuses) {
      totalStatus += stats['status_${status.id}'] ?? 0;
    }

    // Verificar si todos están en el último estado (estado con mayor orden)
    final lastStatus = statuses.isNotEmpty
        ? statuses.reduce((a, b) => a.order > b.order ? a : b)
        : null;
    bool isAllLastStatus = totalStatus > 0 &&
        lastStatus != null &&
        (stats['status_${lastStatus.id}'] ?? 0) == totalStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado alineado
        _buildSectionHeader(Icons.info_outline, l10n.status),

        const SizedBox(height: 12),
        _buildTotalItem(l10n.totalLabel.toUpperCase(), totalStatus,
            isAllLastStatus ? Colors.green[700]! : Colors.grey[800]!),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 3),
        const SizedBox(height: 8),

        // Mostrar estados dinámicamente
        ...statuses.map((status) {
          final count = stats['status_${status.id}'] ?? 0;
          final color = status.colorValue;
          final icon = UIConstants.getIcon(status.icon);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildStatusItem(
                context, status.name, count, color, icon, status.id),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotalItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(128), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildPhaseItem(BuildContext context, String label, int count,
      Color color, IconData icon, String phaseId) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductionScreen(
              initialView: ProductionView.products,
              initialPhaseFilter: phaseId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800])),
            ),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String label, int count,
      Color color, IconData icon, String? statusValue) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductionScreen(
              initialView: ProductionView.products,
              initialStatusFilter: statusValue,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800])),
            ),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  /// Calcular estadísticas de productos en memoria
  Map<String, int> _calculateProductStatistics(
    ProductionDataProvider provider,
    List batches,
  ) {
    final Map<String, int> stats = {
      'total': 0,
      'pending': 0,
      'inProgress': 0,
      'completed': 0,
      'urgent': 0,
    };

    // Por fase
    for (final phase in provider.phases) {
      stats['phase_${phase.id}'] = 0;
    }

    // Por estado
    for (final status in provider.statuses) {
      stats['status_${status.id}'] = 0;
    }

    // Contar productos
    final allProducts = provider.getAllProducts();
    for (final item in allProducts) {
      final product = item['product'] as BatchProductModel;
      final batch = item['batch'];

      // Filtrar por lotes permitidos
      if (!batches.any((b) => b.id == batch.id)) continue;

      stats['total'] = (stats['total'] ?? 0) + 1;

      // Por urgencia
      if (product.urgencyLevel == 'urgent') {
        stats['urgent'] = (stats['urgent'] ?? 0) + 1;
      }

      // Por fase
      stats['phase_${product.currentPhase}'] =
          (stats['phase_${product.currentPhase}'] ?? 0) + 1;

      // Por estado
      if (product.statusId != null) {
        stats['status_${product.statusId}'] =
            (stats['status_${product.statusId}'] ?? 0) + 1;
      }

      // Por progreso
      final phases = provider.phases;
      if (phases.isNotEmpty) {
        final lastPhase = phases.last;
        if (product.currentPhase == lastPhase.id) {
          stats['completed'] = (stats['completed'] ?? 0) + 1;
        } else if (product.currentPhase == phases.first.id) {
          stats['pending'] = (stats['pending'] ?? 0) + 1;
        } else {
          stats['inProgress'] = (stats['inProgress'] ?? 0) + 1;
        }
      }
    }

    return stats;
  }
}
