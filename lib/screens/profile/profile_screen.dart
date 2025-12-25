import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/role_utils.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../widgets/common_refresh.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
Widget build(BuildContext context) {
  final authService = Provider.of<AuthService>(context);
  final user = authService.currentUserData;

  if (user == null) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Función para recargar los datos del perfil
  Future<void> handleRefresh() async {
    // Usamos listen: false porque estamos dentro de una función asíncrona
    await Provider.of<AuthService>(context, listen: false).loadUserData();
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Mi Perfil'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
          tooltip: 'Editar perfil',
        ),
      ],
    ),
    // AQUI EMPIEZA LA MAGIA DEL REFRESH
    body: CommonRefresh(
      onRefresh: handleRefresh,
      child: SingleChildScrollView(
        // IMPORTANTE: Esto permite hacer scroll (y refresh) aunque el contenido sea corto
        physics: const AlwaysScrollableScrollPhysics(), 
        child: Column(
          children: [
            // Header con nombre
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.roleDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Información detallada
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoTile(label: 'Correo electrónico', value: user.email, icon: Icons.email),
                  const Divider(),
                  if (user.phone != null) ...[
                    _buildInfoTile(label: 'Teléfono', value: user.phone!, icon: Icons.phone),
                    const Divider(),
                  ],
                  _buildInfoTile(
                    label: 'Miembro desde',
                    value: _formatDate(user.createdAt),
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón Cerrar Sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, authService),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  // Espacio extra para asegurar que el scroll llegue hasta abajo
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  bool _isGoogleUser(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final providers = authService.currentUser?.providerData ?? [];
    return providers.any((provider) => provider.providerId == 'google.com');
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
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
              // Cerrar el diálogo
              Navigator.pop(context);
              // Cerrar la pantalla de perfil (volver al home)
              Navigator.pop(context);
              // Cerrar sesión
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