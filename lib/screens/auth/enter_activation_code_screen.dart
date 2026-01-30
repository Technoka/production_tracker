import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/activation_code_service.dart';
import 'register_screen.dart';

/// Pantalla para ingresar código de activación
///
/// Usuario que recibió código lo ingresa aquí para validarlo
class EnterActivationCodeScreen extends StatefulWidget {
  const EnterActivationCodeScreen({super.key});

  @override
  State<EnterActivationCodeScreen> createState() =>
      _EnterActivationCodeScreenState();
}

class _EnterActivationCodeScreenState extends State<EnterActivationCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleValidate() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final activationCodeService =
        Provider.of<ActivationCodeService>(context, listen: false);

    final code = await activationCodeService.validateActivationCode(
      _codeController.text.trim(),
    );

    if (!mounted) return;

    if (code != null) {
      // Código válido, ir a registro
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(
            activationCodeId: code.id,
            companyName: code.companyName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activationCodeService.error ?? l10n.codeValidationError,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activationCodeService = Provider.of<ActivationCodeService>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enterActivationCodeTitle),
      ),
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
                    Icons.vpn_key,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.enterActivationCodeTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.enterActivationCodeSubtitle,
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
                      // 1. Primero: Convertir todo a mayúsculas
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(text: newValue.text.toUpperCase());
                      }),
                      
                      // 2. Segundo: Permitir SOLO los caracteres de tu lista
                      // La lista es: ABCDEFGHJKLMNPQRSTUVWXYZ23456789
                      // Excluye: I, O, 0, 1 (para evitar confusiones)
                      FilteringTextInputFormatter.allow(RegExp(r'[A-HJKLMNP-Z2-9]')),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.activationCodeLabel,
                      hintText: l10n.activationCodeHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.qr_code),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.activationCodeRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón validar
                  FilledButton(
                    onPressed: activationCodeService.isLoading
                        ? null
                        : _handleValidate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: activationCodeService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.validateCodeButton,
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
    );
  }
}
