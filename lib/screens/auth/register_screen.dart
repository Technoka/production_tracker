import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_produccion/screens/organization/organization_setup_wizard_screen.dart';
import 'package:gestion_produccion/services/activation_code_service.dart';
import 'package:gestion_produccion/services/invitation_service.dart';
import 'package:gestion_produccion/services/organization_service.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../utils/role_utils.dart';

class RegisterScreen extends StatefulWidget {
  final String? activationCodeId;
  final String? companyName;
  final String? invitationId;
  final String? invitationOrganizationId;
  final String? invitationRoleId;

  const RegisterScreen({
    super.key,
    this.activationCodeId,
    this.companyName,
    this.invitationId,
    this.invitationOrganizationId,
    this.invitationRoleId,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'client';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showOptionalFields = false;

  bool get _isActivationMode => widget.activationCodeId != null;
  bool get _isInvitationMode => widget.invitationId != null;
  bool get _isNormalMode => !_isActivationMode && !_isInvitationMode;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    // Registro normal
    final success = await authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _selectedRole,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // ==================== MODO ACTIVACIÓN ====================
      if (_isActivationMode) {
        final activationCodeService = Provider.of<ActivationCodeService>(
          context,
          listen: false,
        );

        // Marcar código como usado
        await activationCodeService.markCodeAsUsed(
          codeId: widget.activationCodeId!,
          userId: authService.currentUser!.uid,
          organizationId: '', // Se llenará en el wizard
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizationSetupWizardScreen(
              companyName: widget.companyName ?? '',
            ),
          ),
        );
        return;
      }

      // ==================== MODO INVITACION ====================
      if (_isInvitationMode) {
        final organizationService = Provider.of<OrganizationService>(
          context,
          listen: false,
        );
        final invitationService = Provider.of<InvitationService>(
          context,
          listen: false,
        );

        // ✅ Crear miembro con notificación automática
        final memberCreated =
            await organizationService.createOrganizationMember(
          organizationId: widget.invitationOrganizationId!,
          userId: authService.currentUser!.uid,
          roleId: widget.invitationRoleId!,
        );

        if (!memberCreated && mounted) {
          // Manejar error si es necesario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(organizationService.error ?? 'Error al unirse'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Actualizar organizationId del usuario
        await _firestore
            .collection('users')
            .doc(authService.currentUser!.uid)
            .update({
          'organizationId': widget.invitationOrganizationId!,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Recargar datos del usuario
        await authService.loadUserData();

        // Marcar invitación como usada
        await invitationService.markInvitationAsUsed(
          organizationId: widget.invitationOrganizationId!,
          invitationId: widget.invitationId!,
          userId: authService.currentUser!.uid,
        );
        if (!mounted) return;

        // Navegar al home
        Navigator.pushReplacementNamed(context, '/home');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinOrganizationSuccess),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Modo normal
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.accountCreatedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error ?? l10n.registerError),
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
      appBar: AppBar(
        title: Text(l10n.registerTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_add,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.completeDetails,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Mostrar info si es modo activación o invitación
                if (_isActivationMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.activationCodeValidated,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                              ),
                              Text(
                                widget.companyName ?? '',
                                style: TextStyle(color: Colors.green[800]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_isInvitationMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group_add, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.invitationAccepted,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Nombre completo
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.fullNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterNameError;
                    }
                    if (value.length < 3) {
                      return l10n.nameMinLengthError;
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
                    labelText: l10n.emailLabel, // Usando clave existente
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

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.password, // Usando clave existente
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
                    helperText: l10n.passwordMinLengthHelper,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterPasswordError;
                    }
                    if (value.length < 6) {
                      return l10n.passwordMinLengthError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPasswordLabel,
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
                    if (value != _passwordController.text) {
                      return l10n.passwordsDoNotMatchError;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Selector de rol
                if (_isNormalMode) ...[
                  RoleSelector(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) {
                      setState(() {
                        _selectedRole = role;
                      });
                    },
                    showDescriptions: true,
                  ),
                ],

                const SizedBox(height: 24),

                // Campos opcionales
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showOptionalFields = !_showOptionalFields;
                    });
                  },
                  icon: Icon(
                    _showOptionalFields ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    _showOptionalFields
                        ? l10n.hideOptionalFields
                        : l10n.showOptionalFields,
                  ),
                ),

                if (_showOptionalFields) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.phoneOptionalLabel,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: const OutlineInputBorder(),
                      helperText: l10n.phoneHelper,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Botón de registro
                FilledButton(
                  onPressed: authService.isLoading
                      ? null
                      : () => _handleRegister(l10n),
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
                            l10n.registerTitle,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Términos y condiciones
                Text(
                  l10n.termsAndConditions,
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
}
