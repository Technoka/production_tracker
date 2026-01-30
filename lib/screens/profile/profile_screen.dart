import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/profile/user_preferences_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // ✅ Asegúrate de tener intl
import '../../services/auth_service.dart';
import '../../utils/role_utils.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../widgets/common_refresh.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../l10n/app_localizations.dart'; // ✅ Importar l10n

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!; // ✅ Referencia a l10n

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Future<void> handleRefresh() async {
      await Provider.of<AuthService>(context, listen: false).loadUserData();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfileTitle), // ✅ Traducido
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
            tooltip: l10n.edit, // ✅ Traducido
          ),
        ],
      ),
      body: CommonRefresh(
        onRefresh: handleRefresh,
        child: SingleChildScrollView(
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
                    colors: [
                      Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.4)
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      backgroundImage:
                          (user.photoURL != null && user.photoURL!.isNotEmpty)
                              ? NetworkImage(user.photoURL!)
                              : null,
                      child: (user.photoURL == null || user.photoURL!.isEmpty)
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.labelLarge!.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .color!
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: RoleUtils.buildRoleBadge(user.role, compact: true),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                        context, l10n.personalInfo), // ✅ Traducido
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          label: l10n.name, // ✅ Traducido
                          value: user.name,
                        ),
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          label: l10n.email, // ✅ Traducido
                          value: user.email,
                        ),
                        if (user.phone != null) ...[
                          const Divider(),
                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            label: l10n.phone, // ✅ Traducido
                            value: user.phone!,
                          ),
                        ],
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.memberSince, // ✅ Traducido
                          // Usamos DateFormat con el locale actual para formatear la fecha automáticamente
                          value: DateFormat.yMMMMd(
                                  Localizations.localeOf(context).toString())
                              .format(user.createdAt),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(
                        context, l10n.securityTitle), // ✅ Traducido
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(l10n.changePassword), // ✅ Traducido
                          subtitle: Text(
                            _isGoogleUser(context)
                                ? l10n.googleAccountAlert // ✅ Traducido
                                : l10n.updatePasswordSubtitle, // ✅ Traducido
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
                    _buildSectionTitle(
                        context, l10n.accountSection), // ✅ Traducido
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.settings,
                            color: Colors.black,
                          ),
                          title: Text(
                            l10n.settings, // ✅ Traducido
                            style: const TextStyle(color: Colors.black),
                          ),
                          onTap: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UserPreferencesScreen(),
                              ),
                            )
                          },
                        ),
                      ],
                    ),
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
                            l10n.logout, // ✅ Traducido
                            style: TextStyle(color: Colors.red[700]),
                          ),
                          onTap: () =>
                              _showLogoutDialog(context, authService, l10n),
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
      ),
      bottomNavigationBar: BottomNavBarWidget(currentIndex: 3, user: user),
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

  // ✅ Método _showLogoutDialog actualizado para recibir l10n
  void _showLogoutDialog(
      BuildContext context, AuthService authService, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout), // ✅ Traducido
        content: Text(l10n.logoutConfirmMessage), // ✅ Traducido
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel), // ✅ Traducido
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              await authService.signOut();

              // 3. Navegar al Login y eliminar todo el historial de pantallas anterior
              // Verifica si el widget sigue montado antes de usar el contexto tras el await
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', // ⚠️ Asegúrate de que esta ruta esté definida en tu main.dart
                  (route) => false, // Esto elimina todas las rutas anteriores
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.logout), // ✅ Traducido
          ),
        ],
      ),
    );
  }
}
