import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/client_service.dart';
import '../../services/organization_service.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';
import 'edit_project_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final projectService = Provider.of<ProjectService>(context);
    final user = authService.currentUserData;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final canEdit = user.canManageProduction;
    final canDelete = user.hasAdminAccess;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Proyecto'),
        actions: [
          if (canEdit)
            IconButton(icon: const Icon(Icons.edit), onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProjectScreen(project: project)));
            }),
          if (canDelete)
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _showDeleteDialog(context, projectService)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)]),
              ),
              child: Column(
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(project.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  _buildStatusChip(project.statusEnum),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Descripción'),
                  const SizedBox(height: 8),
                  Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(project.description))),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Cliente'),
                  const SizedBox(height: 8),
                  FutureBuilder<ClientModel?>(
                    future: Provider.of<ClientService>(context, listen: false).getClient(project.clientId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final client = snapshot.data!;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(client.initials)),
                          title: Text(client.name),
                          subtitle: Text(client.company),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Fechas'),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(leading: const Icon(Icons.play_arrow), title: const Text('Inicio'), subtitle: Text(_formatDate(project.startDate))),
                        const Divider(),
                        ListTile(leading: const Icon(Icons.event), title: const Text('Entrega estimada'), subtitle: Text(_formatDate(project.estimatedEndDate))),
                        if (project.isOverdue) ...[
                          const Divider(),
                          ListTile(
                            leading: Icon(Icons.warning, color: Colors.red[700]),
                            title: Text('Atrasado', style: TextStyle(color: Colors.red[700])),
                            subtitle: Text('${project.daysRemaining.abs()} días de retraso'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Miembros Asignados (${project.memberCount})'),
                  const SizedBox(height: 8),
                  StreamBuilder<List<UserModel>>(
                    stream: Provider.of<OrganizationService>(context, listen: false).watchOrganizationMembers(project.organizationId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final allMembers = snapshot.data!;
                      final assignedMembers = allMembers.where((m) => project.assignedMembers.contains(m.uid)).toList();
                      return Card(
                        child: Column(
                          children: assignedMembers.map((member) => ListTile(
                            leading: CircleAvatar(child: Text(member.name[0])),
                            title: Text(member.name),
                            subtitle: Text(member.roleDisplayName),
                          )).toList(),
                        ),
                      );
                    },
                  ),
                  if (canEdit) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Cambiar Estado'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ProjectStatus.values.map((status) => FilterChip(
                        label: Text(status.displayName),
                        selected: project.status == status.value,
                        onSelected: (selected) async {
                          if (selected) {
                            final success = await projectService.updateProjectStatus(project.id, status.value);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Estado actualizado'), backgroundColor: Colors.green),
                              );
                            }
                          }
                        },
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildStatusChip(ProjectStatus status) {
    final colors = {
      ProjectStatus.preparation: Colors.blue,
      ProjectStatus.production: Colors.orange,
      ProjectStatus.completed: Colors.green,
      ProjectStatus.delivered: Colors.purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(status.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showDeleteDialog(BuildContext context, ProjectService projectService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Proyecto'),
        content: Text('¿Estás seguro de que deseas eliminar "${project.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await projectService.deleteProject(project.id);
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proyecto eliminado'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(projectService.error ?? 'Error'), backgroundColor: Colors.red));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}