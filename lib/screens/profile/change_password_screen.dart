import 'package:flutter/material.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart'; // ✅ Importar l10n

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!; // ✅ Referencia a l10n

    authService.clearError();

    final success = await authService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordUpdatedSuccess), // ✅ Traducido
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage =
            authService.error ?? l10n.changePasswordError; // ✅ Traducido

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final l10n = AppLocalizations.of(context)!; // ✅ Referencia a l10n

    return AppScaffold(
      currentIndex: AppNavIndex.profile,
      title: l10n.changePasswordTitle,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_reset,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.updatePasswordSubtitle, // ✅ Traducido
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.securePasswordAdvice, // ✅ Traducido
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Contraseña actual
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: l10n.currentPasswordLabel, // ✅ Traducido
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterCurrentPasswordError; // ✅ Traducido
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nueva contraseña
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: l10n.newPasswordLabel, // ✅ Traducido
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                    helperText:
                        l10n.passwordMinLengthHelper, // ✅ Traducido (reusado)
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterNewPasswordError; // ✅ Traducido
                    }
                    if (value.length < 6) {
                      return l10n.passwordTooShort; // ✅ Traducido (reusado)
                    }
                    if (value == _currentPasswordController.text) {
                      return l10n.passwordDiffError; // ✅ Traducido
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar nueva contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPasswordLabel, // ✅ Traducido
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return l10n.passwordsDontMatch; // ✅ Traducido (reusado)
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Consejos de seguridad
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.passwordTipsTitle, // ✅ Traducido
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTip(l10n.passwordTip1), // ✅ Traducido
                      _buildTip(l10n.passwordTip2), // ✅ Traducido
                      _buildTip(l10n.passwordTip3), // ✅ Traducido
                      _buildTip(l10n.passwordTip4), // ✅ Traducido
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed:
                      authService.isLoading ? null : _handleChangePassword,
                  child: Padding(
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
                            l10n.changePasswordTitle, // ✅ Traducido
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
