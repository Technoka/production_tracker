import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/client_service.dart';
import '../../services/organization_service.dart';
import '../../services/project_product_service.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';
import '../../models/project_product_model.dart';
import '../../utils/role_utils.dart';
import 'edit_project_screen.dart';
import '../products/add_product_to_project_screen.dart';
import '../products/project_product_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId; // Cambiar a recibir solo el ID

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectProductService _productService = ProjectProductService();
  final ProjectService _projectService = ProjectService();
  int _selectedTab = 0; // 0: Detalles, 1: Productos

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Usar StreamBuilder para actualización en tiempo real
    return StreamBuilder<ProjectModel?>(
      stream: _projectService.watchProjects(user.organizationId ?? '').map(
        (projects) => projects.firstWhere(
          (p) => p.id == widget.projectId,
          orElse: () => projects.isNotEmpty ? projects.first : throw Exception('Project not found'),
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del Proyecto')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del Proyecto')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Proyecto no encontrado o sin permisos'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final project = snapshot.data!;
        
        // Verificar si el usuario tiene permisos para ver este proyecto
        if (!project.assignedMembers.contains(user.uid) && 
            !RoleUtils.canManageProjects(user.role)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acceso Denegado')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('No tienes permisos para ver este proyecto'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final canEdit = user.canManageProduction;
        final canDelete = user.hasAdminAccess;
        final canManageProducts = RoleUtils.canManageProjects(user.role);

        return _buildScaffold(context, project, user, canEdit, canDelete, canManageProducts);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ProjectModel project,
    UserModel user,
    bool canEdit,
    bool canDelete,
    bool canManageProducts,
  ) {
    final projectService = Provider.of<ProjectService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Proyecto'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProjectScreen(project: project),
                  ),
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context, projectService, project),
            ),
        ],
        bottom: TabBar(
          controller: null,
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          tabs: const [
            Tab(text: 'Detalles', icon: Icon(Icons.info_outline)),
            Tab(text: 'Productos', icon: Icon(Icons.inventory_2_outlined)),
          ],
        ),
      ),
      body: _selectedTab == 0
          ? _buildDetailsTab(context, user, projectService, project)
          : _buildProductsTab(context, user, project),
      floatingActionButton: _selectedTab == 1 && canManageProducts
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductToProjectScreen(
                      projectId: project.id,
                      organizationId: project.organizationId,
                      currentUser: user,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Añadir Producto'),
            )
          : null,
    );
  }

  Widget _buildDetailsTab(
      BuildContext context, UserModel user, ProjectService projectService, ProjectModel project) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8)
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.work_outline, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(project.description),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Cliente'),
                  const SizedBox(height: 8),
                  FutureBuilder<ClientModel?>(
                    future: Provider.of<ClientService>(context, listen: false)
                        .getClient(project.clientId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
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
                        ListTile(
                          leading: const Icon(Icons.play_arrow),
                          title: const Text('Inicio'),
                          subtitle: Text(_formatDate(project.startDate)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.event),
                          title: const Text('Entrega estimada'),
                          subtitle:
                              Text(_formatDate(project.estimatedEndDate)),
                        ),
                        if (project.isOverdue) ...[
                          const Divider(),
                          ListTile(
                            leading: Icon(Icons.warning, color: Colors.red[700]),
                            title: Text(
                              'Atrasado',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                            subtitle: Text(
                              '${project.daysRemaining.abs()} días de retraso',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                      context, 'Miembros Asignados (${project.memberCount})'),
                  const SizedBox(height: 8),
                  StreamBuilder<List<UserModel>>(
                    stream: Provider.of<OrganizationService>(context, listen: false)
                        .watchOrganizationMembers(project.organizationId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final allMembers = snapshot.data!;
                      final assignedMembers = allMembers
                          .where((m) => project.assignedMembers.contains(m.uid))
                          .toList();

                      assignedMembers.sort((a, b) => a.uid == user.uid ? -1 : 1);

                      return Card(
                        child: Column(
                          children: assignedMembers.map((member) {
                            final isMe = member.uid == user.uid;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isMe ? Colors.blue : null,
                                child: Text(
                                  member.name[0],
                                  style: TextStyle(
                                      color: isMe ? Colors.white : null),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(member.name),
                                  if (isMe) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: const Text(
                                        'Tú',
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
                              subtitle: Text(member.roleDisplayName),
                              tileColor:
                                  isMe ? Colors.blue.withOpacity(0.05) : null,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  if (user.canManageProduction) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Cambiar Estado'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ProjectStatus.values
                          .map((status) => FilterChip(
                                label: Text(status.displayName),
                                selected: project.status == status.value,
                                onSelected: (selected) async {
                                  if (selected) {
                                    final success = await projectService
                                        .updateProjectStatus(
                                            project.id, status.value);
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Estado actualizado'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      setState(() {});
                                    }
                                  }
                                },
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context, UserModel user, ProjectModel project) {
    final canViewPrices = RoleUtils.canViewFinancials(user.role);

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: StreamBuilder<List<ProjectProductModel>>(
        stream: _productService.watchProjectProducts(project.id),
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

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay productos en este proyecto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Añade productos desde el catálogo',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Calcular totales
          final totalUnits =
              products.fold<int>(0, (sum, p) => sum + p.quantity);
          final totalValue =
              products.fold<double>(0, (sum, p) => sum + p.totalPrice);

          return Column(
            children: [
              // Resumen
              if (canViewPrices)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        context,
                        'Productos',
                        products.length.toString(),
                        Icons.inventory_2,
                      ),
                      _buildStatCard(
                        context,
                        'Unidades',
                        totalUnits.toString(),
                        Icons.numbers,
                      ),
                      _buildStatCard(
                        context,
                        'Valor Total',
                        '€${totalValue.toStringAsFixed(2)}',
                        Icons.euro,
                      ),
                    ],
                  ),
                ),
              // Lista de productos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      showPrice: canViewPrices,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectProductDetailScreen(
                              projectId: project.id,
                              productId: product.id,
                              currentUser: user,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showDeleteDialog(BuildContext context, ProjectService projectService, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Proyecto'),
        content:
            Text('¿Estás seguro de que deseas eliminar "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await projectService.deleteProject(project.id);
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proyecto eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(projectService.error ?? 'Error'),
                      backgroundColor: Colors.red,
                    ),
                  );
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

// Widget para tarjeta de producto
class _ProductCard extends StatelessWidget {
  final ProjectProductModel product;
  final bool showPrice;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.showPrice,
    required this.onTap,
  });

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.catalogProductName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${product.catalogProductReference}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.statusDisplayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(product.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.numbers, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${product.quantity} unidades',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  if (showPrice) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.euro, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${product.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              if (product.customization.hasCustomizations) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: product.customization
                      .getCustomizationSummary()
                      .map((custom) => Chip(
                            label: Text(custom),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'en_produccion':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}