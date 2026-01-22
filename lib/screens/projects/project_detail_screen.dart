import 'package:flutter/material.dart';
import 'package:gestion_produccion/models/product_catalog_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/client_service.dart';
import '../../services/product_catalog_service.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';
import '../../models/organization_member_model.dart';
import '../../models/role_model.dart';
import '../../utils/permission_utils.dart';
import 'edit_project_screen.dart';
import '../catalog/product_catalog_detail_screen.dart';
import '../../services/organization_member_service.dart';
import '../../widgets/universal_loading_screen.dart';
import '../../widgets/access_control_widget.dart';
import '../clients/client_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final ProductCatalogService _productService = ProductCatalogService();

  late TabController _tabController;
  int _selectedTab = 0;

  OrganizationMemberModel? _currentMember;
  RoleModel? _currentRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);
    final ProjectService projectService =
        ProjectService(memberService: memberService);

    if (user == null) {
      return const UniversalLoadingScreen();
    }

    return StreamBuilder<ProjectModel?>(
      stream: projectService.watchProjects(user.organizationId ?? '').map(
            (projects) => projects.firstWhere(
              (p) => p.id == widget.projectId,
              orElse: () => projects.isNotEmpty
                  ? projects.first
                  : throw Exception('Project not found'),
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

        return FutureBuilder<Map<String, dynamic>>(
          future: _loadPermissions(user, project),
          builder: (context, permSnapshot) {
            if (permSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('Detalle del Proyecto')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final permissions = permSnapshot.data ?? {};
            final canView = permissions['canView'] ?? false;

            if (!canView) {
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

            return _buildScaffold(context, project, user, permissions);
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadPermissions(
      UserModel user, ProjectModel project) async {
    try {
      final memberDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(user.organizationId)
          .collection('members')
          .doc(user.uid)
          .get();

      if (!memberDoc.exists) {
        return {'canView': false};
      }

      _currentMember = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      final roleDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(user.organizationId)
          .collection('roles')
          .doc(_currentMember!.roleId)
          .get();

      if (!roleDoc.exists) {
        return {'canView': false};
      }

      _currentRole = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);

      final isAssigned = project.assignedMembers.contains(user.uid);

      final canView = PermissionUtils.canViewWithScope(
        member: _currentMember!,
        role: _currentRole!,
        module: 'projects',
        isAssignedToUser: isAssigned,
      );

      if (!canView) {
        return {'canView': false};
      }

      final canEdit = PermissionUtils.canEditWithScope(
        member: _currentMember!,
        role: _currentRole!,
        module: 'projects',
        isAssignedToUser: isAssigned,
      );

      final canDelete = PermissionUtils.canDeleteWithScope(
        member: _currentMember!,
        role: _currentRole!,
        module: 'projects',
        isAssignedToUser: isAssigned,
      );

      final canDuplicate = PermissionUtils.can(
        member: _currentMember!,
        role: _currentRole!,
        module: 'projects',
        action: 'create',
      );

      final canManageProducts = PermissionUtils.can(
        member: _currentMember!,
        role: _currentRole!,
        module: 'catalog',
        action: 'edit',
      );

      final canViewPrices = PermissionUtils.can(
        member: _currentMember!,
        role: _currentRole!,
        module: 'financials',
        action: 'view',
      );

      return {
        'canView': true,
        'canEdit': canEdit,
        'canDelete': canDelete,
        'canDuplicate': canDuplicate,
        'canManageProducts': canManageProducts,
        'canViewPrices': canViewPrices,
      };
    } catch (e) {
      return {'canView': false};
    }
  }

  Widget _buildScaffold(
    BuildContext context,
    ProjectModel project,
    UserModel user,
    Map<String, dynamic> permissions,
  ) {
    final projectService = Provider.of<ProjectService>(context);
    final canEdit = permissions['canEdit'] ?? false;
    final canDelete = permissions['canDelete'] ?? false;
    final canDuplicate = permissions['canDuplicate'] ?? false;
    final canManageProducts = permissions['canManageProducts'] ?? false;

    final hasAnyAction = canEdit || canDelete || canDuplicate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Proyecto'),
        actions: [
          if (hasAnyAction)
            PopupMenuButton(
              itemBuilder: (context) {
                final List<PopupMenuEntry> items = [];

                if (canEdit) {
                  items.add(
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                  );
                }

                if (canDuplicate) {
                  items.add(
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.content_copy, size: 20),
                          SizedBox(width: 8),
                          Text('Duplicar'),
                        ],
                      ),
                    ),
                  );
                }

                if (canEdit) {
                  items.add(
                    PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(
                            project.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(project.isActive ? 'Desactivar' : 'Reactivar'),
                        ],
                      ),
                    ),
                  );
                }

                if (canDelete && !project.isActive) {
                  items.add(
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                }

                return items;
              },
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProjectScreen(project: project),
                    ),
                  );
                } else if (value == 'duplicate') {
                  await _duplicateProject(context, projectService, project);
                } else if (value == 'deactivate') {
                  await _toggleProjectActive(
                      context, projectService, project, user.organizationId!);
                } else if (value == 'delete') {
                  await _showDeleteDialog(
                      context, projectService, project, user.organizationId!);
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(context, user, project),
          _buildProductsTab(context, user, project, permissions),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(
      BuildContext context, UserModel user, ProjectModel project) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Project Information Card
            _buildSectionTitle(context, 'Información del Proyecto'),
            const SizedBox(height: 8),
            _buildInfoCard(
              context,
              icon: Icons.work_outline,
              iconColor: Colors.blue,
              children: [
                _buildCardRow(
                  label: 'Nombre',
                  value: project.name,
                ),
                _buildCardRow(
                  label: 'Descripción',
                  value: project.description,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Client Information Card
            _buildSectionTitle(context, 'Cliente'),
            const SizedBox(height: 8),

            _buildClientCard(context, project),
            const SizedBox(height: 16),

            // Access Control Card - Miembros Asignados
            _buildSectionTitle(context, 'Control de Acceso'),
            const SizedBox(height: 8),
            _buildAccessControlCard(project, user),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context, UserModel user,
      ProjectModel project, Map<String, dynamic> permissions) {
    final canViewPrices = permissions['canViewPrices'] ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: StreamBuilder<List<ProductCatalogModel>>(
        stream: _productService.getProjectProductsStream(
            project.organizationId, project.id),
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

          return Column(
            children: [
              // Resumen
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
                      project: project,
                      user: user,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductCatalogDetailScreen(
                              productId: product.id,
                              currentUser: user,
                              organizationId: user.organizationId!,
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    VoidCallback? onTap, // 1. Nuevo parámetro opcional
  }) {
    // 2. Usamos Material en lugar de Container para soportar gestos y bordes
    return Material(
      color: Colors.white,
      clipBehavior: Clip
          .antiAlias, // Importante: recorta el efecto de click en las esquinas
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap, // 3. Ejecuta la función al pulsar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono
            Container(
              width:
                  double.infinity, // Asegura que el header cubra todo el ancho
              // padding: const EdgeInsets.all(12), // Añadido un poco de padding para que se vea bien
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
                // El Material padre ya recorta las esquinas superiores,
                // pero mantener esto no hace daño visualmente.
              ),
              // child: Row(
              //   children: [
              //     Icon(icon, color: iconColor),
              //   ],
              // ),
            ),
            // Contenido
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateProject(BuildContext context,
      ProjectService projectService, ProjectModel project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar Proyecto'),
        content: Text('¿Deseas duplicar "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de duplicación no implementada aún'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _toggleProjectActive(
    BuildContext context,
    ProjectService projectService,
    ProjectModel project,
    String organizationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            project.isActive ? 'Desactivar Proyecto' : 'Reactivar Proyecto'),
        content: Text(project.isActive
            ? '¿Deseas desactivar "${project.name}"?'
            : '¿Deseas reactivar "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(project.isActive ? 'Desactivar' : 'Reactivar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de activar/desactivar no implementada aún'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context,
      ProjectService projectService,
      ProjectModel project,
      String organizationId) {
    return showDialog(
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
              final success = await projectService.deleteProject(
                  organizationId, project.id);
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

  Widget _buildClientCard(BuildContext context, ProjectModel project) {
    if (project.clientId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<ClientModel?>(
      future: Provider.of<ClientService>(context, listen: false)
          .getClient(project.organizationId, project.clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInfoCard(
            context,
            icon: Icons.person_outline,
            iconColor: Colors.green,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }

        if (!snapshot.hasData) {
          return _buildInfoCard(
            context,
            icon: Icons.person_outline,
            iconColor: Colors.grey,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Client not found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          );
        }

        final client = snapshot.data!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              // Verificar permiso antes de navegar
              final memberService = Provider.of<OrganizationMemberService>(
                  context,
                  listen: false);
              // Aseguramos cargar permisos del usuario
              await memberService.getCurrentMember(
                  project.organizationId,
                  Provider.of<AuthService>(context, listen: false)
                      .currentUserData!
                      .uid);

              if (await memberService.can('clients', 'view')) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClientDetailScreen(client: client),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'No tienes permiso para ver detalles de clientes')),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          client.initials,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (client.company.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      client.company,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessControlCard(ProjectModel project, UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AccessControlWidget(
          organizationId: project.organizationId,
          currentUserId: user.uid,
          selectedMembers: project.assignedMembers,
          onMembersChanged: (_) {}, // Solo lectura en detalle
          readOnly: true, // Se muestra igual pero desactivado
          showTitle: false,
          resourceType: 'project',
          customTitle: 'Control de Acceso al Proyecto',
          customDescription:
              'Gestiona quiénes pueden ver y trabajar con este proyecto',
        ),
      ),
    );
  }
}

// Widget para tarjeta de producto
class _ProductCard extends StatelessWidget {
  final ProductCatalogModel product;
  final bool showPrice;
  final VoidCallback onTap;
  final ProjectModel project;
  final UserModel user;

  const _ProductCard({
    required this.product,
    required this.showPrice,
    required this.onTap,
    required this.project,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${product.family ?? "Sin familia"} • SKU: ${product.reference ?? "N/A"}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () async {
          // Verificar permiso product_catalog.view
          final memberService =
              Provider.of<OrganizationMemberService>(context, listen: false);
          if (await memberService.can('product_catalog', 'view')) {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductCatalogDetailScreen(
                    productId: product.id, // ID del catálogo
                    currentUser: user,
                    organizationId: project.organizationId,
                  ),
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('No tienes permiso para ver el catálogo')),
              );
            }
          }
        },
      ),
    );
  }
}
