import 'package:flutter/material.dart';
import 'package:gestion_produccion/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/production_batch_model.dart';
import '../models/phase_model.dart';
import '../models/product_status_model.dart';
import '../services/production_batch_service.dart';
import '../services/phase_service.dart';
import '../services/product_status_service.dart';
import '../services/organization_member_service.dart';
import '../services/auth_service.dart';
import '../screens/production/production_screen.dart';
import '../models/permission_registry_model.dart';

class ProductionDashboardWidget extends StatelessWidget {
  final String organizationId;
  const ProductionDashboardWidget({super.key, required this.organizationId});

  @override
  Widget build(BuildContext context) {
    final phaseService = Provider.of<PhaseService>(context, listen: false);
    final statusService =
        Provider.of<ProductStatusService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<ProductionPhase>>(
      stream: phaseService.getActivePhasesStream(organizationId),
      builder: (context, phaseSnapshot) {
        if (phaseSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (phaseSnapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${l10n.error}: ${phaseSnapshot.error}'),
            ),
          );
        }

        final phases = phaseSnapshot.data ?? [];

        return StreamBuilder<List<ProductStatusModel>>(
          stream: statusService.watchActiveStatuses(organizationId),
          builder: (context, statusSnapshot) {
            if (statusSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (statusSnapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('${l10n.error}: ${statusSnapshot.error}'),
                ),
              );
            }

            // Filtrar solo estados activos
            final statuses = (statusSnapshot.data ?? [])
                .where((status) => status.isActive)
                .toList();

            return StreamBuilder<List<ProductionBatchModel>>(
              stream:
                  Provider.of<ProductionBatchService>(context, listen: false)
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
                      child: Text('${l10n.error}: ${batchSnapshot.error}'),
                    ),
                  );
                }

                final batches = batchSnapshot.data ?? [];

                return FutureBuilder<Map<String, int>>(
                  future:
                      _getProductStatistics(context, batches, phases, statuses),
                  builder: (context, statsSnapshot) {
                    if (statsSnapshot.connectionState ==
                        ConnectionState.waiting) {
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
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // TÍTULO FIJO (Sin lógica de expansión)
                            Row(
                              children: [
                                Icon(Icons.dashboard,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24),
                                const SizedBox(width: 12),
                                Text(l10n.productionDashboardTitleLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),

                            const Divider(height: 24),

                            // COLUMNAS DE CONTENIDO
                            // IntrinsicHeight hace que el divisor vertical tome la altura del hijo más alto
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: _buildPhasesSection(
                                          context, stats, phases)),
                                  const SizedBox(width: 12),
                                  // Divisor vertical dinámico
                                  VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Colors.grey[300]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildStatusSection(
                                          context, stats, statuses)),
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
                                      builder: (context) =>
                                          const ProductionScreen(),
                                    ),
                                  );
                                },
                                child: Text(l10n.viewAllBatches),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
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
          final color = _hexToColor(phase.color);
          final icon = _getIconData(phase.icon);

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
          final icon = _getIconData(status.icon);

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

  Future<Map<String, int>> _getProductStatistics(
    BuildContext context,
    List<ProductionBatchModel> batches,
    List<ProductionPhase> phases,
    List<ProductStatusModel> statuses,
  ) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Obtener el scope de permisos del usuario

    final viewScope = await memberService.getScope('batch_products', 'view');
    final currentUserId = authService.currentUserData?.uid;

    final stats = <String, int>{};

    // Inicializar contadores para todas las fases activas
    for (final phase in phases) {
      stats['phase_${phase.id}'] = 0;
    }

    // Inicializar contadores para todos los estados activos
    for (final status in statuses) {
      stats['status_${status.id}'] = 0;
    }

    for (final batch in batches) {
      try {
        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;

        for (final product in products) {
          // Filtrar por permisos de viewScope
          bool canViewProduct = false;

          switch (viewScope) {
            case PermissionScope.all:
              canViewProduct = true;
              break;
            case PermissionScope.assigned:
              // Verificar si el batch está asignado al usuario actual
              // Según la estructura de ProductionBatchModel, verificamos assignedTo
              canViewProduct = batch.assignedMembers.contains(currentUserId);
              break;
            case PermissionScope.none:
              canViewProduct = false;
              break;
          }

          if (!canViewProduct) continue;

          // Contar por fase
          final phaseKey = 'phase_${product.currentPhase}';
          if (stats.containsKey(phaseKey)) {
            stats[phaseKey] = (stats[phaseKey] ?? 0) + 1;
          }

          // Contar por estado
          final statusKey = 'status_${product.statusId}';
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

  // Helper para convertir hex a Color
  Color _hexToColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  // Helper para obtener IconData desde string
  IconData _getIconData(String iconName) {
    try {
      // Intentar parsear como código numérico
      final codePoint = int.tryParse(iconName);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }

      // Si no es numérico, mapear nombres comunes
      final iconMap = {
        'assignment': Icons.assignment,
        'content_cut': Icons.content_cut,
        'layers': Icons.layers,
        'construction': Icons.construction,
        'palette': Icons.palette,
        'schedule': Icons.schedule,
        'pause_circle': Icons.pause_circle,
        'error': Icons.error,
        'fact_check': Icons.fact_check,
        'check_circle': Icons.check_circle,
        'work': Icons.work,
        'category': Icons.category,
        'label': Icons.label,
      };

      return iconMap[iconName] ?? Icons.label;
    } catch (e) {
      return Icons.label;
    }
  }
}
