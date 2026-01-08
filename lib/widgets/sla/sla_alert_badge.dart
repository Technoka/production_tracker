import 'package:flutter/material.dart';
import '../../models/sla_alert_model.dart';
import '../../services/sla_service.dart';

/// Badge de contador de alertas activas para el AppBar
class SLAAlertBadge extends StatelessWidget {
  final String organizationId;
  final VoidCallback onTap;

  const SLAAlertBadge({
    Key? key,
    required this.organizationId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slaService = SLAService();

    return StreamBuilder<List<SLAAlert>>(
      stream: slaService.getOrganizationAlertsStream(
        organizationId,
        status: SLAAlertStatus.active,
      ),
      builder: (context, snapshot) {
        final activeAlerts = snapshot.data ?? [];
        final criticalCount = activeAlerts.where((a) => a.isCritical).length;
        final totalCount = activeAlerts.length;

        if (totalCount == 0) {
          // Sin alertas - mostrar icono normal
          return IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onTap,
            tooltip: 'Alertas',
          );
        }

        // Con alertas - mostrar badge
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                criticalCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications,
                color: criticalCount > 0 ? Colors.red : null,
              ),
              onPressed: onTap,
              tooltip: 'Alertas activas: $totalCount',
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: criticalCount > 0 ? Colors.red : Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (criticalCount > 0 ? Colors.red : Colors.orange)
                          .withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  totalCount > 99 ? '99+' : totalCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}