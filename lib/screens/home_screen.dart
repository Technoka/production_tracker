import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';
import '../utils/role_utils.dart';
import 'profile/profile_screen.dart';
import 'organization/organization_home_screen.dart';
import 'clients/clients_list_screen.dart';
import 'projects/projects_list_screen.dart';
import 'catalog/product_catalog_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final organizationService = Provider.of<OrganizationService>(context);
    final user = authService.currentUserData;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Producción'),
        actions: [
          // Badge de rol
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: RoleUtils.buildRoleBadge(user.role, compact: true),
          ),
          // Botón de perfil
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            tooltip: 'Mi perfil',
          ),
        ],
      ),
      body: _buildBody(user),
      drawer: _buildDrawer(context, user, authService, organizationService),
      bottomNavigationBar: _buildBottomNavigationBar(user),
    );
  }

  Widget _buildBody(user) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.factory,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '¡Bienvenido, ${user.name}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo de cuenta: ${user.roleDisplayName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            _buildFeatureCards(user),
          ],
        ),
      ),
    );
  }

Widget _buildFeatureCards(user) {
    final features = <Map<String, dynamic>>[];

    if (user.canManageProduction) {
      features.addAll([
        {
          'icon': Icons.folder_outlined,
          'title': 'Proyectos',
          'subtitle': 'Gestionar proyectos',
          'color': Colors.green,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
            );
          },
        },
        {
          'icon': Icons.people_outline,
          'title': 'Clientes',
          'subtitle': 'Gestionar clientes',
          'color': Colors.purple,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientsListScreen()),
            );
          },
        },
        {
          'icon': Icons.inventory_2_outlined,
          'title': 'Gestionar Productos',
          'subtitle': 'Ver y editar catálogo',
          'color': Colors.green,
          'onTap': () {
            // FUNCIONALIDAD AÑADIDA: Navegación al catálogo
            if (user.organizationId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductCatalogScreen(
                    organizationId: user.organizationId!,
                    currentUser: user,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: No tienes una organización asignada')),
              );
            }
          },
        },
      ]);
    }

    if (user.canViewFinancials) {
      features.add({
        'icon': Icons.analytics_outlined,
        'title': 'Reportes',
        'subtitle': 'Ver análisis financiero',
        'color': Colors.purple,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función en desarrollo')),
          );
        },
      });
    }

    if (user.isClient) {
      features.add({
        'icon': Icons.track_changes_outlined,
        'title': 'Productos',
        'subtitle': 'Seguimiento de estado',
        'color': Colors.teal,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función en desarrollo')),
          );
        },
      });
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: features
          .map((feature) => _buildFeatureCard(
                icon: feature['icon'],
                title: feature['title'],
                subtitle: feature['subtitle'],
                color: feature['color'],
                onTap: feature['onTap'],
              ))
          .toList(),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildDrawer(BuildContext context, user, AuthService authService, OrganizationService organizationService) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            accountName: Text(user.name),
            accountEmail: Text(user.email),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          if (user.canManageProduction) ...[
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Proyectos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProjectsListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outlined),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientsListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                if (user.organizationId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductCatalogScreen(
                        organizationId: user.organizationId!,
                        currentUser: user,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          
          if (user.canViewFinancials)
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función en desarrollo')),
                );
              },
            ),
                      ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Mi Organización'),
  trailing: StreamBuilder<List<dynamic>>(
    stream: organizationService.getPendingInvitations(user.email),
    builder: (context, snapshot) {
      final count = snapshot.data?.length ?? 0;
      if (count == 0) return const Icon(Icons.chevron_right);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    },
  ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrganizationHomeScreen(),
                  ),
                );
              },
            ),
            const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función en desarrollo')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[700]),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red[700]),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(authService);
            },
          ),
        ],
      ),
    );
  }

Widget? _buildBottomNavigationBar(user) {
  final items = <BottomNavigationBarItem>[];

  items.add(
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Inicio',
    ),
  );

  if (user.canManageProduction) {
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_outlined),
        label: 'Proyectos',
      ),
    );
  }

  if (user.canViewFinancials) {
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.analytics_outlined),
        label: 'Reportes',
      ),
    );
  }

  items.add(
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Perfil',
    ),
  );

  if (items.length <= 2) return null;

  return BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (index) {
      setState(() {
        _selectedIndex = index;
      });

      // 1. Obtener la etiqueta (label) del ítem pulsado para saber qué acción tomar
      final label = items[index].label;

      if (label == 'Perfil') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
      } else if (label == 'Proyectos') {
        // 2. Navegar a la pantalla de lista de proyectos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProjectsListScreen(),
          ),
        );
      } else if (label == 'Inicio') {
        // Ya estamos en Inicio, no hace falta navegar, el setState ya actualiza la UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Función en desarrollo')),
        );
      }
    },
    items: items,
    type: BottomNavigationBarType.fixed,
  );
}

  void _showLogoutDialog(AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}