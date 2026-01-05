import 'package:flutter/material.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../services/phase_service.dart';
import '../../l10n/app_localizations.dart';

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

  bool get _canEdit {
    final role = widget.currentUser.role.toLowerCase();
    return role == 'admin' || role == 'production_manager';
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
          SnackBar(
            content: Text(l10n.phasesInitializedSuccess),
          ),
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
              phase.isActive
                  ? l10n.phaseDeactivated
                  : l10n.phaseActivated,
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

  Future<void> _editPhase(ProductionPhase phase) async {
    if (!_canEdit) return;
    final l10n = AppLocalizations.of(context)!;

    final nameController = TextEditingController(text: phase.name);
    final descriptionController = TextEditingController(text: phase.description ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editPhaseTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.phaseName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.phaseDescriptionLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
              });
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result['name'].isEmpty) return;

    try {
      await _phaseService.updatePhase(
        widget.organizationId,
        phase.id,
        result,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.phaseUpdatedSuccess)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.managePhasesTitle),
      ),
      body: StreamBuilder<List<ProductionPhase>>(
        stream: _phaseService.getOrganizationPhasesStream(widget.organizationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${snapshot.error}'),
                ],
              ),
            );
          }

          final phases = snapshot.data ?? [];

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
                      onPressed: _isInitializing ? null : _initializeDefaultPhases,
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
              Card(
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
                        '${l10n.totalPhasesLabel}: ${phases.length} (${l10n.activePhasesSection}: ${activePhases.length})',
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
              ),
              const SizedBox(height: 16),
              // Active phases
              if (activePhases.isNotEmpty) ...[
                Text(
                  l10n.activePhasesSection,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildPhaseCard(ProductionPhase phase) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: phase.isActive ? 2 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: phase.isActive
              ? Theme.of(context).primaryColor
              : Colors.grey,
          child: Text(
            phase.order.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          phase.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: phase.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: phase.description != null
            ? Text(
                phase.description!,
                style: TextStyle(
                  color: phase.isActive ? Colors.grey : Colors.grey[400],
                ),
              )
            : null,
        trailing: _canEdit
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'toggle':
                      _togglePhaseStatus(phase);
                      break;
                    case 'edit':
                      _editPhase(phase);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          phase.isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        const SizedBox(width: 8),
                        Text(phase.isActive ? l10n.deactivateAction : l10n.activateAction),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}