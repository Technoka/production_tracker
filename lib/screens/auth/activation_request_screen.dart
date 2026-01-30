import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/activation_code_service.dart';

/// Pantalla para solicitar código de activación
/// 
/// El usuario llena un formulario con datos de su empresa
/// y recibe confirmación de que recibirá el código por email
class ActivationRequestScreen extends StatefulWidget {
  const ActivationRequestScreen({super.key});

  @override
  State<ActivationRequestScreen> createState() =>
      _ActivationRequestScreenState();
}

class _ActivationRequestScreenState extends State<ActivationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final activationCodeService =
        Provider.of<ActivationCodeService>(context, listen: false);

    final success = await activationCodeService.createActivationRequest(
      companyName: _companyNameController.text.trim(),
      contactName: _contactNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Mostrar diálogo de éxito
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.requestSentTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.requestSentMessage),
              const SizedBox(height: 16),
              Text(
                l10n.requestSentNextSteps,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a welcome
              },
              child: Text(l10n.understood),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activationCodeService.error ?? l10n.requestSendError,
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
        title: Text(l10n.requestActivationCodeTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icono
                Icon(
                  Icons.business_center,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // Título
                Text(
                  l10n.requestCodeSubtitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Descripción
                Text(
                  l10n.requestCodeDescription,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Nombre de la empresa
                TextFormField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    labelText: l10n.companyNameLabel,
                    hintText: l10n.companyNameHint,
                    prefixIcon: const Icon(Icons.business),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.companyNameRequired;
                    }
                    if (value.length < 2) {
                      return l10n.companyNameTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nombre del contacto
                TextFormField(
                  controller: _contactNameController,
                  decoration: InputDecoration(
                    labelText: l10n.contactNameLabel,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.contactNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email del contacto
                TextFormField(
                  controller: _contactEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.contactEmailLabel,
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.contactEmailRequired;
                    }
                    if (!value.contains('@')) {
                      return l10n.contactEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Teléfono del contacto
                TextFormField(
                  controller: _contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.contactPhoneLabel,
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.contactPhoneRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mensaje opcional
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.messageOptionalLabel,
                    hintText: l10n.messageOptionalHint,
                    prefixIcon: const Icon(Icons.message),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.activationRequestInfo,
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

                // Botón enviar
                FilledButton(
                  onPressed:
                      activationCodeService.isLoading ? null : _handleSubmit,
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
                            l10n.sendRequestButton,
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
}