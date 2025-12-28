import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../models/project_model.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final projectService = Provider.of<ProjectService>(context);
    final user = authService.currentUserData;

    if (user == null || user.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proyectos')),
        body: const Center(child: Text('Debes pertenecer a una organización')),
      );
    }

    final canCreate = user.canManageProduction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos', icon: Icon(Icons.folder_outlined)),
            Tab(text: 'Mis Proyectos', icon: Icon(Icons.person_outline)),
          ],
        ),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen())),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => projectService.setStatusFilter(value == 'all' ? null : value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todos los estados')),
              ...ProjectStatus.values.map((status) =>
                PopupMenuItem(value: status.value, child: Text(status.displayName))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar proyectos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: projectService.searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        projectService.setSearchQuery('');
                      })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: projectService.setSearchQuery,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectsList(user.organizationId!, null, projectService),
                _buildProjectsList(user.organizationId!, user.uid, projectService),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen())),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProjectsList(String orgId, String? userId, ProjectService projectService) {
    return StreamBuilder<List<ProjectModel>>(
      stream: userId != null
          ? projectService.watchUserProjects(userId, orgId)
          : projectService.watchProjects(orgId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final projects = projectService.filteredProjects;

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No hay proyectos', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: projects.length,
          itemBuilder: (context, index) => _ProjectCard(
            project: projects[index],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: projects[index]),
            )),
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(project.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _buildStatusChip(project.statusEnum),
                ],
              ),
              const SizedBox(height: 8),
              Text(project.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.calendar_today, 'Entrega: ${_formatDate(project.estimatedEndDate)}'),
                  _buildInfoChip(Icons.people, '${project.memberCount} miembros'),
                  if (project.isOverdue)
                    _buildInfoChip(Icons.warning, 'Atrasado', color: Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    final colors = {
      ProjectStatus.preparation: Colors.blue,
      ProjectStatus.production: Colors.orange,
      ProjectStatus.completed: Colors.green,
      ProjectStatus.delivered: Colors.purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[status]!.withOpacity(0.3)),
      ),
      child: Text(status.displayName, style: TextStyle(color: colors[status], fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600])),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}