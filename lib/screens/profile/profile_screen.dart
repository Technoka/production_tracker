import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/role_utils.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con nombre
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Avatar inicial
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nombre
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Badge de rol
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RoleUtils.getRoleIcon(user.role),
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.roleDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Información del perfil
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Información Personal'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    children: [
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        label: 'Nombre',
                        value: user.name,
                      ),
                      const Divider(),
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Correo electrónico',
                        value: user.email,
                      ),
                      if (user.phone != null) ...[
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: user.phone!,
                        ),
                      ],
                      const Divider(),
                      _buildInfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Miembro desde',
                        value: _formatDate(user.createdAt),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Seguridad'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Cambiar contraseña'),
                        subtitle: Text(
                          _isGoogleUser(context)
                              ? 'No disponible para cuentas de Google'
                              : 'Actualiza tu contraseña',
                        ),
                        trailing: _isGoogleUser(context)
                            ? null
                            : const Icon(Icons.chevron_right),
                        enabled: !_isGoogleUser(context),
                        onTap: _isGoogleUser(context)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChangePasswordScreen(),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Cuenta'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    context,
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Colors.red[700],
                        ),
                        title: Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        onTap: () => _showLogoutDialog(context, authService),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
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