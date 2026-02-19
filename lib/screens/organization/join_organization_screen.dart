import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/invitation_service.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/auth/register_screen.dart';
import '../../utils/ui_constants.dart';

class JoinOrganizationScreen extends StatefulWidget {
  const JoinOrganizationScreen({super.key});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinOrganization() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final invitationService = Provider.of<InvitationService>(
      context,
      listen: false,
    );

    // ✅ Validar código usando Cloud Function
    final invitation = await invitationService.validateInvitationCode(
      code: _codeController.text.trim(),
    );

    if (!mounted) return;

    if (invitation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invitationService.error ?? l10n.invalidInvitationCode,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Navegar a registro con datos de invitación
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          invitation: invitation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invitationService = Provider.of<InvitationService>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinOrganizationTitle),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: UIConstants.SCREEN_MAX_WIDTH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.vpn_key,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.inviteCodeTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.inviteCodeSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Campo de código
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(
                              text: newValue.text.toUpperCase());
                        }),
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-HJKLMNP-Z2-9]')),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.inviteCodeLabel,
                        border: const OutlineInputBorder(),
                        helperText: l10n.inviteCodeHelper,
                        prefixIcon: const Icon(Icons.qr_code),
                      ),
                      maxLength: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterInviteCodeError;
                        }
                        if (value.length != 8) {
                          return l10n.inviteCodeLengthError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Información
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.inviteCodeInfoBox,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón unirse
                    FilledButton(
                      onPressed: invitationService.isLoading
                          ? null
                          : _handleJoinOrganization,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: invitationService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.joinButton,
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
