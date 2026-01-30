import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );    
    
    // CORRECCIÓN: Si es exitoso, navegar al Home
    if (success) {
      if (mounted) {
        // Usamos pushReplacementNamed para que el usuario no pueda volver
        // al login presionando "atrás".
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error ?? l10n.loginError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn(AppLocalizations l10n) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Primero, intentar iniciar sesión con Google
    final tempSuccess = await authService.signInWithGoogle(role: null);

    // Si es exitoso, navegar al Home
    if (tempSuccess) {
      if (mounted) {
        // Usamos pushReplacementNamed para que el usuario no pueda volver
        // al login presionando "atrás".
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    // Si no fue exitoso, verificar el error
    if (authService.error == 'Selecciona un tipo de cuenta') {
      // Es un usuario nuevo, necesita elegir rol
      if (!mounted) return;
      
      final role = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.accountTypeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.selectAccountTypeMessage),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(l10n.roleClient),
                subtitle: Text(l10n.roleClientSubtitle),
                onTap: () => Navigator.pop(context, 'client'),
              ),
              ListTile(
                leading: const Icon(Icons.factory),
                title: Text(l10n.roleManufacturer),
                subtitle: Text(l10n.roleManufacturerSubtitle),
                onTap: () => Navigator.pop(context, 'manufacturer'),
              ),
              ListTile(
                leading: const Icon(Icons.precision_manufacturing),
                title: Text(l10n.roleOperator),
                subtitle: Text(l10n.roleOperatorSubtitle),
                onTap: () => Navigator.pop(context, 'operator'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(l10n.roleAccountant),
                subtitle: Text(l10n.roleAccountantSubtitle),
                onTap: () => Navigator.pop(context, 'accountant'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (role == null) return;

      // Intentar de nuevo con el rol seleccionado
      final success = await authService.signInWithGoogle(role: role);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(authService.error ?? l10n.googleLoginError),
            backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted && authService.error != null) {
      // Otro tipo de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.factory,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterPasswordError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PasswordResetScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.forgotPasswordLink),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: authService.isLoading ? null : () => _handleLogin(l10n),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: authService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.loginButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.orContinueWith,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed:
                        authService.isLoading ? null : () => _handleGoogleSignIn(l10n),
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 24);
                      },
                    ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        l10n.continueWithGoogle,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}