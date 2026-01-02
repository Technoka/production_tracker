import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/batch_product_model.dart';
import '../models/production_batch_model.dart';
import '../services/production_batch_service.dart';
import '../screens/production/production_batches_list_screen.dart';

class ProductionDashboardWidget extends StatelessWidget {
  final String organizationId;

  const ProductionDashboardWidget({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductionBatchModel>>(
      stream: Provider.of<ProductionBatchService>(context, listen: false)
          .watchBatches(organizationId),
      builder: (context, batchSnapshot) {
        if (batchSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (batchSnapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${batchSnapshot.error}'),
            ),
          );
        }

        final batches = batchSnapshot.data ?? [];

        // Obtener todos los productos de todos los lotes
        return FutureBuilder<Map<String, int>>(
          future: _getProductStatistics(context, batches),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final stats = statsSnapshot.data ?? {};

            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductionBatchesListScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.dashboard,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Dashboard de Producción',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 3),
                      const SizedBox(height: 16),

                      // Dos columnas: Fases y Estados
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // COLUMNA 1: FASES DE PRODUCCIÓN
                          Expanded(
                            child: _buildPhasesSection(stats),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Divisor vertical
                          Container(
                            width: 1,
                            height: 280,
                            color: Colors.grey[300],
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // COLUMNA 2: ESTADOS
                          Expanded(
                            child: _buildStatusSection(stats),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhasesSection(Map<String, int> stats) {
    // 1. Calcular el total de productos en fases
    int totalPhases = (stats['phase_planned'] ?? 0) +
        (stats['phase_cutting'] ?? 0) +
        (stats['phase_skiving'] ?? 0) +
        (stats['phase_assembly'] ?? 0) +
        (stats['phase_studio'] ?? 0);

    // 2. Determinar si todos están en Studio (y hay al menos 1 producto)
    bool isAllStudio = totalPhases > 0 && (stats['phase_studio'] ?? 0) == totalPhases;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.precision_manufacturing, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fases de Producción',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTotalItem(
          'TOTAL', 
          totalPhases, 
          isAllStudio ? Colors.green[700]! : Colors.black87, // Verde si todo es Studio
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 3),
        const SizedBox(height: 8),

        _buildPhaseItem(
          'Planned',
          stats['phase_planned'] ?? 0,
          Colors.grey[700]!,
          Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        
        _buildPhaseItem(
          'Cutting',
          stats['phase_cutting'] ?? 0,
          Colors.amber[700]!,
          Icons.content_cut,
        ),
        const SizedBox(height: 8),
        
        _buildPhaseItem(
          'Skiving',
          stats['phase_skiving'] ?? 0,
          Colors.blue[700]!,
          Icons.layers,
        ),
        const SizedBox(height: 8),
        
        _buildPhaseItem(
          'Assembly',
          stats['phase_assembly'] ?? 0,
          Colors.purple[700]!,
          Icons.construction,
        ),
        const SizedBox(height: 8),
        
        _buildPhaseItem(
          'Studio',
          stats['phase_studio'] ?? 0,
          Colors.green[700]!,
          Icons.brush,
        ),
      ],
    );
  }

  Widget _buildStatusSection(Map<String, int> stats) {
    // 1. Calcular el total de productos en estados
    int totalStatus = (stats['status_pending'] ?? 0) +
        (stats['status_cao'] ?? 0) +
        (stats['status_hold'] ?? 0) +
        (stats['status_control'] ?? 0) +
        (stats['status_ok'] ?? 0);

    // 2. Determinar si todos están OK (y hay al menos 1 producto)
    bool isAllOk = totalStatus > 0 && (stats['status_ok'] ?? 0) == totalStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.info_outline, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Estados',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTotalItem(
          'TOTAL', 
          totalStatus, 
          isAllOk ? Colors.green[700]! : Colors.black87, // Verde si todo es OK
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 3),
        const SizedBox(height: 8),

        _buildStatusItem(
          'Pending',
          stats['status_pending'] ?? 0,
          Colors.grey[700]!,
          Icons.schedule,
        ),
        const SizedBox(height: 8),
        
        _buildStatusItem(
          'CAO',
          stats['status_cao'] ?? 0,
          Colors.red[700]!,
          Icons.error,
        ),
        const SizedBox(height: 8),
        
        _buildStatusItem(
          'Hold',
          stats['status_hold'] ?? 0,
          Colors.orange[700]!,
          Icons.pause_circle,
        ),
        const SizedBox(height: 8),
        
        _buildStatusItem(
          'Control',
          stats['status_control'] ?? 0,
          Colors.blue[700]!,
          Icons.verified,
        ),
        const SizedBox(height: 8),
        
        _buildStatusItem(
          'OK',
          stats['status_ok'] ?? 0,
          Colors.green[700]!,
          Icons.check_circle,
        ),
      ],
    );
  }

  // Widget específico para el Total
  Widget _buildTotalItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 2), // Borde más grueso
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseItem(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color, IconData icon) {
    return _buildPhaseItem(label, count, color, icon);
  }

  Future<Map<String, int>> _getProductStatistics(
    BuildContext context,
    List<ProductionBatchModel> batches,
  ) async {
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    
    final stats = <String, int>{
      // Fases
      'phase_planned': 0,
      'phase_cutting': 0,
      'phase_skiving': 0,
      'phase_assembly': 0,
      'phase_studio': 0,
      // Estados
      'status_pending': 0,
      'status_cao': 0,
      'status_hold': 0,
      'status_control': 0,
      'status_ok': 0,
    };

    // Obtener productos de cada lote
    for (final batch in batches) {
      try {
        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;

        for (final product in products) {
          // Contar por fase
          final phaseKey = 'phase_${product.currentPhase}';
          if (stats.containsKey(phaseKey)) {
            stats[phaseKey] = (stats[phaseKey] ?? 0) + 1;
          }

          // Contar por estado
          final statusKey = 'status_${product.productStatus}';
          if (stats.containsKey(statusKey)) {
            stats[statusKey] = (stats[statusKey] ?? 0) + 1;
          }
        }
      } catch (e) {
        // Ignorar errores individuales
      }
    }

    return stats;
  }
}