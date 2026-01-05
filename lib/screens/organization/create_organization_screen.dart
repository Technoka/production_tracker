import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import '../../l10n/app_localizations.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final organizationService = Provider.of<OrganizationService>(context, listen: false);

    final user = authService.currentUserData;
    if (user == null) return;

    final organizationId = await organizationService.createOrganization(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      ownerId: user.uid,
    );

    // Verificamos 'mounted' antes de usar cualquier cosa que necesite el 'context'
    if (organizationId != null && mounted) {
      
      // 1. Refrescar los datos del usuario para que detecte su nueva organización
      await authService.getUserData(); 
      
      // 2. Cargar la organización en el servicio global
      await organizationService.loadOrganization(organizationId);

      // 3. Ahora sí, hacemos el pop con seguridad
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizationService = Provider.of<OrganizationService>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createOrganization),
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
                  Icons.add_business,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.newOrganizationTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createOrganizationSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Nombre de la organización
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.orgNameLabel,
                    prefixIcon: const Icon(Icons.business),
                    border: const OutlineInputBorder(),
                    helperText: l10n.orgNameHelper,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.orgNameError;
                    }
                    if (value.length < 3) {
                      return l10n.orgNameLengthError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.orgDescriptionLabel,
                    prefixIcon: const Icon(Icons.description),
                    border: const OutlineInputBorder(),
                    helperText: l10n.orgDescriptionHelper,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.orgDescriptionError;
                    }
                    if (value.length < 10) {
                      return l10n.orgDescriptionLengthError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            l10n.creatorBenefitsTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBenefit(l10n.benefitControl),
                      _buildBenefit(l10n.benefitInvite),
                      _buildBenefit(l10n.benefitRoles),
                      _buildBenefit(l10n.benefitProjects),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón crear
                FilledButton(
                  onPressed: organizationService.isLoading
                      ? null
                      : _handleCreateOrganization,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: organizationService.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.createOrganization,
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

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}