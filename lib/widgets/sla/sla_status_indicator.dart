import 'package:flutter/material.dart';
import '../../models/sla_alert_model.dart';
import '../../services/sla_service.dart';

/// Indicador visual de estado SLA para productos
class SLAStatusIndicator extends StatelessWidget {
  final String organizationId;
  final String productId;
  final bool compact;

  const SLAStatusIndicator({
    Key? key,
    required this.organizationId,
    required this.productId,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slaService = SLAService();

    return StreamBuilder<List<SLAAlert>>(
      stream: slaService.getProductAlertsStream(organizationId, productId),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        
        if (alerts.isEmpty) {
          // Sin alertas - estado OK
          if (compact) {
            return const SizedBox.shrink();
          }
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'On Time',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          );
        }

        // Hay alertas - determinar la más severa
        final hasCritical = alerts.any((a) => a.isCritical && !a.isResolved);
        final hasWarning = alerts.any((a) => a.isWarning && !a.isResolved);

        if (!hasCritical && !hasWarning) {
          // Todas resueltas
          return const SizedBox.shrink();
        }

        final color = hasCritical ? Colors.red : Colors.orange;
        final icon = hasCritical ? Icons.error : Icons.warning_amber;
        final label = hasCritical ? 'SLA Exceeded' : 'SLA Warning';
        final activeCount = alerts.where((a) => !a.isResolved).length;

        if (compact) {
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (activeCount > 1) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activeCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Badge pequeño para mostrar en esquina de cards
class SLAAlertBadgeSmall extends StatelessWidget {
  final String organizationId;
  final String productId;

  const SLAAlertBadgeSmall({
    Key? key,
    required this.organizationId,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slaService = SLAService();

    return StreamBuilder<List<SLAAlert>>(
      stream: slaService.getProductAlertsStream(organizationId, productId),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        final activeAlerts = alerts.where((a) => !a.isResolved).toList();
        
        if (activeAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        final hasCritical = activeAlerts.any((a) => a.isCritical);
        final color = hasCritical ? Colors.red : Colors.orange;

        return Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              hasCritical ? Icons.priority_high : Icons.warning_amber,
              color: Colors.white,
              size: 16,
            ),
          ),
        );
      },
    );
  }
}

/// Barra de progreso con indicador SLA
class SLAProgressBar extends StatelessWidget {
  final double currentHours;
  final double maxHours;
  final int? warningThresholdPercent;

  const SLAProgressBar({
    Key? key,
    required this.currentHours,
    required this.maxHours,
    this.warningThresholdPercent = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (currentHours / maxHours).clamp(0.0, 1.0);
    final warningThreshold = (warningThresholdPercent ?? 80) / 100;

    Color getColor() {
      if (percent >= 1.0) return Colors.red;
      if (percent >= warningThreshold) return Colors.orange;
      return Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${currentHours.toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: getColor(),
              ),
            ),
            Text(
              'SLA: ${maxHours.toStringAsFixed(0)}h',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            color: getColor(),
          ),
        ),
        if (percent >= 1.0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.error, size: 14, color: Colors.red[700]),
              const SizedBox(width: 4),
              Text(
                'Exceeded by ${(currentHours - maxHours).toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}