import 'package:flutter/material.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../services/phase_service.dart';

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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inicializar Fases'),
        content: const Text(
          '¿Deseas crear las fases de producción predeterminadas? '
          'Esto añadirá las 5 fases estándar del proceso de fabricación de bolsos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inicializar'),
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
          const SnackBar(
            content: Text('Fases inicializadas correctamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
                  ? 'Fase desactivada'
                  : 'Fase activada',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editPhase(ProductionPhase phase) async {
    if (!_canEdit) return;

    final nameController = TextEditingController(text: phase.name);
    final descriptionController = TextEditingController(text: phase.description ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Fase'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la fase',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
              });
            },
            child: const Text('Guardar'),
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
          const SnackBar(content: Text('Fase actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Fases de Producción'),
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
                  Text('Error: ${snapshot.error}'),
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
                  const Text(
                    'No hay fases configuradas',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicializa las fases predeterminadas para comenzar',
                    style: TextStyle(color: Colors.grey),
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
                      label: const Text('Inicializar Fases'),
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
                      const Text(
                        'Fases de Producción',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${phases.length} fases (${activePhases.length} activas)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Las fases activas se aplicarán automáticamente a todos los productos nuevos.',
                        style: TextStyle(
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
                const Text(
                  'Fases Activas',
                  style: TextStyle(
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
                const Text(
                  'Fases Inactivas',
                  style: TextStyle(
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
                        Text(phase.isActive ? 'Desactivar' : 'Activar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
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