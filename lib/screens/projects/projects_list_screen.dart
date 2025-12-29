import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  String? _statusFilter;

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
    final user = authService.currentUserData;

    if (user == null || user.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proyectos')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Debes pertenecer a una organización'),
            ],
          ),
        ),
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todos los estados')),
              ...ProjectStatus.values.map(
                (status) => PopupMenuItem(
                  value: status.value,
                  child: Text(status.displayName),
                ),
              ),
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllProjectsList(user),
                _buildMyProjectsList(user),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // Todos los proyectos de la organización
Widget _buildAllProjectsList(UserModel user) {
    return StreamBuilder<List<ProjectModel>>(
      stream: Provider.of<ProjectService>(context, listen: false)
          .watchProjects(user.organizationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        var projects = snapshot.data ?? [];

        // Aplicar filtros localmente
        projects = _applyFilters(projects);

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _statusFilter != null
                      ? 'No se encontraron proyectos'
                      : 'No hay proyectos',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return _buildListView(projects, user);
      },
    );
  }

  Widget _buildMyProjectsList(UserModel user) {
    return StreamBuilder<List<ProjectModel>>(
      stream: Provider.of<ProjectService>(context, listen: false)
          .watchUserProjects(user.uid, user.organizationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final projects = _applyFilters(snapshot.data ?? []);

        return _buildListView(projects, user);
      },
    );
  }

  // Widget común para renderizar la lista y manejar la navegación
  Widget _buildListView(List<ProjectModel> projects, UserModel user) {
    if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty || _statusFilter != null
                      ? 'No se encontraron proyectos'
                      : 'No tienes proyectos asignados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (_searchQuery.isEmpty && _statusFilter == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Los proyectos aparecerán aquí cuando seas asignado',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          );
    }

    return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return _ProjectCard(
            project: project,
            currentUser: user,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(projectId: project.id),
              ),
            ),
          );
        },
      ),
    );
  }

  // Aplicar filtros de búsqueda y estado
  List<ProjectModel> _applyFilters(List<ProjectModel> projects) {
    var filtered = projects;

    // Filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        final nameMatch = project.name.toLowerCase().contains(_searchQuery);
        final descMatch = project.description.toLowerCase().contains(_searchQuery);
        return nameMatch || descMatch;
      }).toList();
    }

    // Filtro de estado
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((project) => project.status == _statusFilter).toList();
    }

    return filtered;
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final UserModel currentUser;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.currentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAssignedToMe = project.assignedMembers.contains(currentUser.uid);

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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAssignedToMe) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Asignado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(project.statusEnum),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Entrega: ${_formatDate(project.estimatedEndDate)}',
                  ),
                  _buildInfoChip(
                    Icons.people,
                    '${project.memberCount} ${project.memberCount == 1 ? "miembro" : "miembros"}',
                  ),
                  if (project.isOverdue)
                    _buildInfoChip(
                      Icons.warning,
                      '${project.daysRemaining.abs()} ${project.daysRemaining.abs() == 1 ? "día" : "días"} atrasado',
                      color: Colors.red,
                    ),
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
      child: Text(
        status.displayName,
        style: TextStyle(
          color: colors[status],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}