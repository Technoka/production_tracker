import 'package:flutter/material.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/organization_service.dart';
import '../../services/auth_service.dart';
import '../../services/phase_service.dart';
import '../home_screen.dart';

/// Wizard para configurar organización tras usar código de activación
/// 
/// Pasos:
/// 1. Información básica (nombre, descripción)
/// 2. Configuración de fases (opcional)
/// 3. ¡Listo!
class OrganizationSetupWizardScreen extends StatefulWidget {
  final String companyName; // Viene del código de activación

  const OrganizationSetupWizardScreen({
    super.key,
    required this.companyName,
  });

  @override
  State<OrganizationSetupWizardScreen> createState() =>
      _OrganizationSetupWizardScreenState();
}

class _OrganizationSetupWizardScreenState
    extends State<OrganizationSetupWizardScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _initializePhasesWithDefaults = true;

  @override
  void initState() {
    super.initState();
    // Prellenar nombre con el de la empresa
    _nameController.text = widget.companyName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final organizationService =
        Provider.of<OrganizationService>(context, listen: false);
    final phaseService = Provider.of<PhaseService>(context, listen: false);

    final user = authService.currentUserData;
    if (user == null) return;

    // Crear organización
    final organizationId = await organizationService.createOrganization(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      ownerId: user.uid,
    );

    if (organizationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            organizationService.error ?? l10n.createOrganizationError,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Inicializar fases si se eligió
    if (_initializePhasesWithDefaults) {
      await phaseService.initializeDefaultPhases(
        organizationId,
      );
    }

    // Recargar datos del usuario
    await authService.loadUserData();

    if (!mounted) return;

    // Navegar al home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.organizationCreatedSuccess),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final organizationService = Provider.of<OrganizationService>(context);

    return AppScaffold(
      title: l10n.setupOrganizationTitle,
      currentIndex: AppNavIndex.organization,
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              if (_currentStep == 0) {
                if (_formKey.currentState!.validate()) {
                  setState(() => _currentStep++);
                }
              } else {
                setState(() => _currentStep++);
              }
            } else {
              _handleComplete();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            final isLastStep = details.currentStep == 2;
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: organizationService.isLoading
                        ? null
                        : details.onStepContinue,
                    child: organizationService.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isLastStep ? l10n.finish : l10n.next),
                  ),
                  const SizedBox(width: 12),
                  if (details.currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(l10n.back),
                    ),
                ],
              ),
            );
          },
          steps: [
            // Paso 1: Información básica
            Step(
              title: Text(l10n.step1BasicInfo),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.organizationName,
                        border: const OutlineInputBorder(),
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
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        hintText: l10n.orgDescriptionHelper,
                        border: const OutlineInputBorder(),
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
                  ],
                ),
              ),
            ),

            // Paso 2: Configuración de fases
            Step(
              title: Text(l10n.step2PhaseConfiguration),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.phasesConfigurationDescription,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(l10n.useDefaultPhases),
                    subtitle: Text(l10n.useDefaultPhasesDescription),
                    value: _initializePhasesWithDefaults,
                    onChanged: (value) {
                      setState(() => _initializePhasesWithDefaults = value);
                    },
                  ),
                  if (_initializePhasesWithDefaults) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.defaultPhasesInclude,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Paso 3: ¡Listo!
            Step(
              title: Text(l10n.step3Ready),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 64,
                    color: Colors.green[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.organizationReadyMessage,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.organizationReadyDescription,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}