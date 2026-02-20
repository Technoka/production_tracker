import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:provider/provider.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../services/phase_service.dart';
import '../../l10n/app_localizations.dart';
import 'phase_editor_screen.dart';

class ManagePhasesScreen extends StatefulWidget {
  final String organizationId;
  final UserModel currentUser;

  const ManagePhasesScreen({
    Key? key,
    required this.organizationId,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ManagePhasesScreen> createState() => _ManagePhasesScreenState();
}

class _ManagePhasesScreenState extends State<ManagePhasesScreen> {
  final PhaseService _phaseService = PhaseService();
  bool _isInitializing = false;
  bool _isReordering = false;

  bool get _canEdit {
    final role = widget.currentUser.role.toLowerCase();
    return role == 'admin' || role == 'production_manager' || role == 'owner';
  }

  Future<void> _initializeDefaultPhases() async {
    if (!_canEdit) return;
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.initializePhasesTitle),
        content: Text(l10n.initializePhasesConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isInitializing = true);

    try {
      await _phaseService.initializeDefaultPhases(widget.organizationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.phasesInitializedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _togglePhaseStatus(ProductionPhase phase) async {
    if (!_canEdit) return;
    final l10n = AppLocalizations.of(context)!;

    try {
      await _phaseService.togglePhaseStatus(
        widget.organizationId,
        phase.id,
        !phase.isActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              phase.isActive ? l10n.phaseDeactivated : l10n.phaseActivated,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _deletePhase(ProductionPhase phase) async {
    if (!_canEdit) return;
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeletePhase),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deletePhaseWarning),
            const SizedBox(height: 8),
            Text(
              phase.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _phaseService.deletePhase(widget.organizationId, phase.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.phaseDeletedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Cannot delete phase')
                  ? l10n.phaseInUse
                  : '${l10n.error}: $e',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _editPhase(ProductionPhase phase) async {
    if (!_canEdit) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PhaseEditorScreen(
          organizationId: widget.organizationId,
          phase: phase,
        ),
      ),
    );

    if (result == true && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phaseUpdatedSuccess)),
      );
    }
  }

  Future<void> _createPhase() async {
    if (!_canEdit) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PhaseEditorScreen(
          organizationId: widget.organizationId,
        ),
      ),
    );

    if (result == true && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phaseCreatedSuccess)),
      );
    }
  }

  Future<void> _reorderPhases(List<ProductionPhase> phases) async {
    if (!_canEdit) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isReordering = true);

    try {
      final orderedIds = phases.map((p) => p.id).toList();
      await _phaseService.reorderPhases(widget.organizationId, orderedIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReordering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.managePhasesTitle),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createPhase,
              tooltip: l10n.createPhaseTitle,
            ),
        ],
      ),
      body: Consumer<ProductionDataProvider>(
        builder: (context, dataProvider, _) {
          final phases = dataProvider.phases;

          if (phases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.format_list_numbered,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPhasesConfiguredTitle,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noPhasesConfiguredSubtitle,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_canEdit)
                    ElevatedButton.icon(
                      onPressed:
                          _isInitializing ? null : _initializeDefaultPhases,
                      icon: _isInitializing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(l10n.initializePhasesButton),
                    ),
                ],
              ),
            );
          }

          final activePhases = phases.where((p) => p.isActive).toList();
          final inactivePhases = phases.where((p) => !p.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header with info
              _buildHeaderCard(l10n, activePhases.length, phases.length),

              const SizedBox(height: 16),

              // Active phases
              if (activePhases.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.activePhasesSection,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_canEdit && activePhases.length > 1)
                      TextButton.icon(
                        onPressed: _isReordering
                            ? null
                            : () => _showReorderDialog(activePhases),
                        icon: const Icon(Icons.reorder, size: 18),
                        label: Text(l10n.reorderPhases),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ...activePhases.map((phase) => _buildPhaseCard(phase)),
              ],

              // Inactive phases
              if (inactivePhases.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.inactivePhasesSection,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...inactivePhases.map((phase) => _buildPhaseCard(phase)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
      AppLocalizations l10n, int activeCount, int totalCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.phases,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.totalPhasesLabel}: $totalCount (${l10n.activePhasesSection}: $activeCount)',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.activePhasesNote,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(ProductionPhase phase) {
    final l10n = AppLocalizations.of(context)!;
    final color = _parseColor(phase.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: phase.isActive ? 2 : 1,
      child: InkWell(
        onTap: _canEdit ? () => _editPhase(phase) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Color indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: phase.isActive ? color : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPhaseIcon(phase.icon),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Phase info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${phase.order}.',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                phase.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: phase.isActive ? null : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (phase.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            phase.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: phase.isActive
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions menu
                  if (_canEdit)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editPhase(phase);
                            break;
                          case 'toggle':
                            _togglePhaseStatus(phase);
                            break;
                          case 'delete':
                            _deletePhase(phase);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                phase.isActive
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                phase.isActive
                                    ? l10n.deactivateAction
                                    : l10n.activateAction,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete,
                                  size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Badges row
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // WIP limit badge
                  _buildBadge(
                    icon: Icons.workspaces,
                    label: 'WIP: ${phase.wipLimit}',
                    color: Colors.blue,
                  ),

                  // SLA badge
                  if (phase.hasSLA)
                    _buildBadge(
                      icon: Icons.timer,
                      label: '${phase.maxDurationHours}h SLA',
                      color: Colors.orange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReorderDialog(List<ProductionPhase> phases) async {
    final l10n = AppLocalizations.of(context)!;

    final reorderedPhases = await showDialog<List<ProductionPhase>>(
      context: context,
      builder: (context) => ReorderPhasesDialog(
        phases: phases,
        l10n: l10n,
      ),
    );

    if (reorderedPhases != null) {
      await _reorderPhases(reorderedPhases);
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getPhaseIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'content_cut':
        return Icons.content_cut;
      case 'layers':
        return Icons.layers;
      case 'construction':
        return Icons.construction;
      case 'palette':
        return Icons.palette;
      case 'design_services':
        return Icons.design_services;
      case 'checkroom':
        return Icons.checkroom;
      case 'verified':
        return Icons.verified;
      case 'inventory':
        return Icons.inventory;
      case 'local_shipping':
        return Icons.local_shipping;
      default:
        return Icons.work;
    }
  }
}

// ==================== REORDER DIALOG ====================

class ReorderPhasesDialog extends StatefulWidget {
  final List<ProductionPhase> phases;
  final AppLocalizations l10n;

  const ReorderPhasesDialog({
    Key? key,
    required this.phases,
    required this.l10n,
  }) : super(key: key);

  @override
  State<ReorderPhasesDialog> createState() => _ReorderPhasesDialogState();
}

class _ReorderPhasesDialogState extends State<ReorderPhasesDialog> {
  late List<ProductionPhase> _phases;

  @override
  void initState() {
    super.initState();
    _phases = List.from(widget.phases);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.reorderPhases),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.l10n.dragToReorder,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _phases.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _phases.removeAt(oldIndex);
                    _phases.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final phase = _phases[index];
                  return ListTile(
                    key: ValueKey(phase.id),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(phase.color),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(phase.name),
                    trailing: const Icon(Icons.drag_handle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _phases),
          child: Text(widget.l10n.save),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
