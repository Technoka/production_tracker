import 'package:flutter/material.dart';
import '../../models/sla_alert_model.dart';
import '../../models/user_model.dart';
import '../../services/sla_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Panel lateral deslizable con lista de alertas
class SLAAlertsPanel extends StatefulWidget {
  final String organizationId;
  final UserModel currentUser;

  const SLAAlertsPanel({
    Key? key,
    required this.organizationId,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<SLAAlertsPanel> createState() => _SLAAlertsPanelState();
}

class _SLAAlertsPanelState extends State<SLAAlertsPanel> {
  final SLAService _slaService = SLAService();
  SLAAlertStatus? _filterStatus;
  SLAAlertSeverity? _filterSeverity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      constraints: const BoxConstraints(maxWidth: 400),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(l10n),
            
            // Filters
            _buildFilters(l10n),
            
            const Divider(height: 1),
            
            // Alerts list
            Expanded(
              child: StreamBuilder<List<SLAAlert>>(
                stream: _slaService.getOrganizationAlertsStream(
                  widget.organizationId,
                  status: _filterStatus,
                  severity: _filterSeverity,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('${l10n.error}: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final alerts = snapshot.data ?? [];

                  if (alerts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noAlertsActive,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return SLAAlertCard(
                        alert: alerts[index],
                        organizationId: widget.organizationId,
                        currentUser: widget.currentUser,
                        onAlertChanged: () {
                          // Refresh handled by stream
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.alertsPanel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter
          Row(
            children: [
              Text(
                l10n.filterByStatus,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(l10n.allStatuses),
                      selected: _filterStatus == null,
                      onSelected: (selected) {
                        setState(() => _filterStatus = null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Active'),
                      selected: _filterStatus == SLAAlertStatus.active,
                      onSelected: (selected) {
                        setState(() => _filterStatus = selected ? SLAAlertStatus.active : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Resolved'),
                      selected: _filterStatus == SLAAlertStatus.resolved,
                      onSelected: (selected) {
                        setState(() => _filterStatus = selected ? SLAAlertStatus.resolved : null);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Severity filter
          Row(
            children: [
              Text(
                l10n.filterBySeverity,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(l10n.allSeverities),
                      selected: _filterSeverity == null,
                      onSelected: (selected) {
                        setState(() => _filterSeverity = null);
                      },
                    ),
                    FilterChip(
                      label: Text(l10n.criticalSeverity),
                      selected: _filterSeverity == SLAAlertSeverity.critical,
                      selectedColor: Colors.red[100],
                      onSelected: (selected) {
                        setState(() => _filterSeverity = selected ? SLAAlertSeverity.critical : null);
                      },
                    ),
                    FilterChip(
                      label: Text(l10n.warningSeverity),
                      selected: _filterSeverity == SLAAlertSeverity.warning,
                      selectedColor: Colors.orange[100],
                      onSelected: (selected) {
                        setState(() => _filterSeverity = selected ? SLAAlertSeverity.warning : null);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card individual de alerta
class SLAAlertCard extends StatelessWidget {
  final SLAAlert alert;
  final String organizationId;
  final UserModel currentUser;
  final VoidCallback onAlertChanged;

  const SLAAlertCard({
    Key? key,
    required this.alert,
    required this.organizationId,
    required this.currentUser,
    required this.onAlertChanged,
  }) : super(key: key);

  Color _getSeverityColor() {
    return alert.isCritical ? Colors.red : Colors.orange;
  }

  IconData _getAlertIcon() {
    switch (alert.alertType) {
      case SLAAlertType.slaExceeded:
        return Icons.schedule;
      case SLAAlertType.slaWarning:
        return Icons.warning_amber;
      case SLAAlertType.phaseBlocked:
        return Icons.block;
      case SLAAlertType.wipLimitExceeded:
        return Icons.workspaces;
    }
  }

  Future<void> _handleAcknowledge(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final slaService = SLAService();

    try {
      await slaService.acknowledgeAlert(
        organizationId,
        alert.id,
        currentUser.uid,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.alertAcknowledged)),
        );
      }
      onAlertChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _handleResolve(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final slaService = SLAService();

    final notes = await showDialog<String>(
      context: context,
      builder: (context) => _ResolveAlertDialog(l10n: l10n),
    );

    if (notes == null) return;

    try {
      await slaService.resolveAlert(
        organizationId,
        alert.id,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.alertResolved)),
        );
      }
      onAlertChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final severityColor = _getSeverityColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: alert.isResolved ? Colors.grey[300]! : severityColor,
          width: alert.isResolved ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: alert.isResolved 
            ? Colors.grey[50] 
            : severityColor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alert.isResolved 
                  ? Colors.grey[200] 
                  : severityColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alert.isResolved ? Colors.grey : severityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getAlertIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.alertType.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: alert.isResolved ? Colors.grey[700] : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: alert.isResolved ? Colors.grey : severityColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              alert.severity.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            alert.status.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.entityName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Metrics
                if (!alert.isResolved) ...[
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${alert.currentValue.toStringAsFixed(1)}h / ${alert.thresholdValue.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      if (alert.isCritical)
                        Text(
                          '${l10n.excess} ${alert.excessHours.toStringAsFixed(1)} ${l10n.hoursLetter}}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                
                Text(
                  dateFormat.format(alert.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          if (!alert.isResolved) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (alert.isActive)
                    TextButton.icon(
                      onPressed: () => _handleAcknowledge(context),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: Text(l10n.acknowledge),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _handleResolve(context),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text(l10n.resolve),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
}

/// Dialog para resolver alerta con notas
class _ResolveAlertDialog extends StatefulWidget {
  final AppLocalizations l10n;

  const _ResolveAlertDialog({required this.l10n});

  @override
  State<_ResolveAlertDialog> createState() => _ResolveAlertDialogState();
}

class _ResolveAlertDialogState extends State<_ResolveAlertDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.resolve),
      content: TextField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: widget.l10n.resolutionNotes,
          hintText: 'Opcional',
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notesController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.l10n.resolve),
        ),
      ],
    );
  }
}