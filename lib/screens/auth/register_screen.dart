import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../models/invitation_model.dart';
import '../../utils/ui_constants.dart';

/// Pantalla de registro con invitación
///
/// VERSIÓN 2.0: Dos opciones de registro
/// 1. Crear con Google (Google Sign-In + Cloud Function)
/// 2. Crear con Email (Formulario + Cloud Function)
class RegisterScreen extends StatefulWidget {
  final InvitationModel invitation;

  const RegisterScreen({
    super.key,
    required this.invitation,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _showPasswordField = false; // Mostrar solo si elige email

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Crear cuenta con Google Sign-In
  Future<void> _handleGoogleSignUp() async {
    // Validar campos básicos
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nameRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // 1. Google Sign-In
    final userCredential = await authService.signInWithGoogleOnly();

    if (userCredential == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error ?? l10n.googleLoginError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // 2. Verificar si el usuario ya existe en Firestore
    final existingUser = await authService.getUserData();

    // Si ya tiene organización, significa que ya está registrado
    if (existingUser != null && existingUser.organizationId != null) {
      // ❌ Cuenta ya registrada - Mostrar error y hacer logout
      await authService.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.accountExistsMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // 3. Usuario nuevo o sin organización - Unirse con Cloud Function
    final result = await authService.joinOrganizationWithGoogle(
      invitationId: widget.invitation.id,
      organizationId: widget.invitation.organizationId,
      roleId: widget.invitation.roleId,
      clientId: widget.invitation.clientId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      // ✅ Éxito - Navegar a Home
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error ?? l10n.registrationError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Crear cuenta con Email/Password
  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que NO sea @gmail.com
    final email = _emailController.text.trim().toLowerCase();
    if (email.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.useGoogleSignIn),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Validar contraseña
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordTooShort),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Llamar Cloud Function para crear usuario y unirse
    final result = await authService.createUserWithEmailAndJoin(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      invitationId: widget.invitation.id,
      organizationId: widget.invitation.organizationId,
      roleId: widget.invitation.roleId,
      clientId: widget.invitation.clientId,
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      // ✅ Éxito - Navegar a Home
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } else {
      // ❌ Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error ?? l10n.registrationError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createAccount),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: UIConstants.SCREEN_MEDIUM_WIDTH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header con información de invitación
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.group_add,
                            color: Theme.of(context).primaryColor,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.joiningOrganization,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.invitation.organizationName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.asRole}: ${widget.invitation.roleId}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Título
                    Text(
                      l10n.completeYourProfile,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.fillRequiredFields,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.name,
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.nameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterEmailError;
                        }
                        if (!value.contains('@')) {
                          return l10n.enterValidEmailError;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Si escribe email, mostrar campo contraseña
                        if (value.isNotEmpty && !_showPasswordField) {
                          setState(() => _showPasswordField = true);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono (opcional)
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: '${l10n.phoneLabel} (${l10n.optional})',
                        prefixIcon: const Icon(Icons.phone),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contraseña (solo si elige email/password)
                    if (_showPasswordField) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: const OutlineInputBorder(),
                          helperText: l10n.passwordMinLength,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 8),

                    // Botón Google
                    OutlinedButton.icon(
                      onPressed:
                          authService.isLoading ? null : _handleGoogleSignUp,
                      icon: Image.asset(
                        'assets/google_logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.g_mobiledata, size: 24);
                        },
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          l10n.createWithGoogle,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.orLabel,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón Email
                    FilledButton.icon(
                      onPressed:
                          authService.isLoading ? null : _handleEmailSignUp,
                      icon: const Icon(Icons.email),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: authService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.createWithEmail,
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
