import 'package:flutter/material.dart';
import '../models/phase_model.dart';
import '../models/user_model.dart';
import '../services/phase_service.dart';
import 'package:intl/intl.dart';

class PhaseProgressWidget extends StatelessWidget {
  final String organizationId;
  final String projectId;
  final String productId;
  final UserModel currentUser;
  final bool isReadOnly;

  const PhaseProgressWidget({
    Key? key,
    required this.organizationId,
    required this.projectId,
    required this.productId,
    required this.currentUser,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phaseService = PhaseService();

    return StreamBuilder<List<ProductionPhase>>(
      stream: phaseService.getActivePhasesStream(organizationId),
      builder: (orgPhasesContext, orgPhasesSnapshot) {
        final orgPhases = orgPhasesSnapshot.data ?? [];
        
        // Create a map for quick lookup
        final orgPhasesMap = {
          for (var phase in orgPhases) phase.id: phase
        };

        return StreamBuilder<List<ProductPhaseProgress>>(
          stream: phaseService.getProductPhaseProgressStream(
            organizationId,
            projectId,
            productId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final phases = snapshot.data ?? [];

            if (phases.isEmpty) {
              return const Center(
                child: Text('No hay fases configuradas'),
              );
            }

            final completedCount = phases.where((p) => p.isCompleted).length;
            final progressPercentage = (completedCount / phases.length) * 100;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall progress
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progreso General',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${progressPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedCount de ${phases.length} fases completadas',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Phase list
                Expanded(
                  child: ListView.builder(
                    itemCount: phases.length,
                    itemBuilder: (context, index) {
                      final phase = phases[index];
                      final orgPhase = orgPhasesMap[phase.phaseId];
                      
                      return PhaseProgressCard(
                        phase: phase,
                        orgPhase: orgPhase,
                        organizationId: organizationId,
                        projectId: projectId,
                        productId: productId,
                        currentUser: currentUser,
                        isReadOnly: isReadOnly,
                        canMoveToNext: index < phases.length - 1,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class PhaseProgressCard extends StatelessWidget {
  final ProductPhaseProgress phase;
  final ProductionPhase? orgPhase; // Fase de organización con personalización
  final String organizationId;
  final String projectId;
  final String productId;
  final UserModel currentUser;
  final bool isReadOnly;
  final bool canMoveToNext;

  const PhaseProgressCard({
    Key? key,
    required this.phase,
    this.orgPhase,
    required this.organizationId,
    required this.projectId,
    required this.productId,
    required this.currentUser,
    required this.isReadOnly,
    required this.canMoveToNext,
  }) : super(key: key);

  Color _getStatusColor(PhaseStatus status) {
    switch (status) {
      case PhaseStatus.pending:
        return Colors.grey;
      case PhaseStatus.inProgress:
        return Colors.orange;
      case PhaseStatus.completed:
        return Colors.green;
    }
  }

  Color _getPhaseColor() {
    if (orgPhase != null) {
      try {
        return Color(int.parse(orgPhase!.color.replaceAll('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  IconData _getPhaseIcon() {
    if (orgPhase != null) {
      final iconMap = {
        'work': Icons.work,
        'assignment': Icons.assignment,
        'content_cut': Icons.content_cut,
        'layers': Icons.layers,
        'construction': Icons.construction,
        'palette': Icons.palette,
        'design_services': Icons.design_services,
        'checkroom': Icons.checkroom,
        'verified': Icons.verified,
        'inventory': Icons.inventory,
        'local_shipping': Icons.local_shipping,
        'build': Icons.build,
        'brush': Icons.brush,
        'engineering': Icons.engineering,
        'handyman': Icons.handyman,
        'precision_manufacturing': Icons.precision_manufacturing,
      };
      return iconMap[orgPhase!.icon.toLowerCase()] ?? Icons.work;
    }
    return Icons.work;
  }

  IconData _getStatusIcon(PhaseStatus status) {
    switch (status) {
      case PhaseStatus.pending:
        return Icons.radio_button_unchecked;
      case PhaseStatus.inProgress:
        return Icons.access_time;
      case PhaseStatus.completed:
        return Icons.check_circle;
    }
  }

  bool _canUserEdit() {
    if (isReadOnly) return false;
    
    final role = currentUser.role.toLowerCase();
    return role == 'admin' || 
           role == 'production_manager' || 
           role == 'operator';
  }

  Future<void> _showStatusMenu(BuildContext context) async {
    if (!_canUserEdit()) return;

    final phaseService = PhaseService();
    
    // Check if operator has permission for this phase
    if (currentUser.role.toLowerCase() == 'operator') {
      final canManage = await phaseService.canUserManagePhase(
        currentUser.uid,
        organizationId,
        phase.phaseId,
      );
      
      if (!canManage) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes permiso para gestionar esta fase'),
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    final phaseColor = _getPhaseColor();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with phase info
            Container(
              padding: const EdgeInsets.all(16),
              color: phaseColor.withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: phaseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPhaseIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.phaseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Cambiar estado',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.radio_button_unchecked,
                color: _getStatusColor(PhaseStatus.pending),
              ),
              title: const Text('Pendiente'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, PhaseStatus.pending);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.access_time,
                color: _getStatusColor(PhaseStatus.inProgress),
              ),
              title: const Text('En Proceso'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, PhaseStatus.inProgress);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_circle,
                color: _getStatusColor(PhaseStatus.completed),
              ),
              title: const Text('Completado'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, PhaseStatus.completed);
              },
            ),
            if (phase.isInProgress && canMoveToNext)
              ListTile(
                leading: const Icon(Icons.arrow_forward, color: Colors.blue),
                title: const Text('Completar y pasar a siguiente'),
                onTap: () {
                  Navigator.pop(context);
                  _moveToNext(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, PhaseStatus newStatus) async {
    try {
      final phaseService = PhaseService();
      await phaseService.updatePhaseStatus(
        organizationId,
        projectId,
        productId,
        phase.phaseId,
        newStatus,
        currentUser,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _moveToNext(BuildContext context) async {
    try {
      final phaseService = PhaseService();
      await phaseService.moveToNextPhase(
        organizationId,
        projectId,
        productId,
        phase.phaseId,
        currentUser,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fase completada, siguiente iniciada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final phaseColor = _getPhaseColor();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _canUserEdit() ? () => _showStatusMenu(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Phase icon with custom color
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: phaseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: phaseColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getPhaseIcon(),
                      color: phaseColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.phaseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(phase.status),
                              color: _getStatusColor(phase.status),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              phase.status.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: _getStatusColor(phase.status),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_canUserEdit())
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (phase.startedAt != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                _buildInfoRow(
                  icon: Icons.play_arrow,
                  label: 'Iniciado',
                  value: dateFormat.format(phase.startedAt!),
                  subtitle: phase.startedByUserName,
                ),
              ],
              if (phase.completedAt != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.check,
                  label: 'Completado',
                  value: dateFormat.format(phase.completedAt!),
                  subtitle: phase.completedByUserName,
                ),
              ],
              if (phase.notes != null && phase.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phase.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $value',
                style: const TextStyle(fontSize: 13),
              ),
              if (subtitle != null)
                Text(
                  'por $subtitle',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}