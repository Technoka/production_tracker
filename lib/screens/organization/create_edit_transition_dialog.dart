import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/status_transition_model.dart';
import '../../models/product_status_model.dart';
import '../../models/role_model.dart';
import '../../models/validation_config_model.dart';
import '../../services/auth_service.dart';
import '../../services/status_transition_service.dart';
import '../../services/product_status_service.dart';
import '../../services/role_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/transitions/validation_type_selector.dart';
import '../../widgets/transitions/validation_config_form.dart';
import '../../widgets/transitions/conditional_logic_builder.dart';

class CreateEditTransitionDialog extends StatefulWidget {
  final String organizationId;
  final StatusTransitionModel? transition;

  const CreateEditTransitionDialog({
    Key? key,
    required this.organizationId,
    this.transition,
  }) : super(key: key);

  @override
  State<CreateEditTransitionDialog> createState() =>
      _CreateEditTransitionDialogState();
}

class _CreateEditTransitionDialogState
    extends State<CreateEditTransitionDialog> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // PASO 1: Selección básica
  String? _fromStatusId;
  String? _toStatusId;
  List<String> _selectedRoles = [];

  // PASO 2: Tipo de validación
  ValidationType _validationType = ValidationType.simpleApproval;

  // PASO 3: Configuración de validación
  ValidationConfigModel _validationConfig = ValidationConfigModel();

  // PASO 4: Lógica condicional
  bool _hasConditionalLogic = false;
  ConditionalLogic? _conditionalLogic;

  @override
  void initState() {
    super.initState();

    if (widget.transition != null) {
      // Modo edición - cargar datos existentes
      _fromStatusId = widget.transition!.fromStatusId;
      _toStatusId = widget.transition!.toStatusId;
      _selectedRoles = List.from(widget.transition!.allowedRoles);
      _validationType = widget.transition!.validationType;
      _validationConfig = widget.transition!.validationConfig;
      _hasConditionalLogic = widget.transition!.hasConditionalLogic;
      _conditionalLogic = widget.transition!.conditionalLogic;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.transition != null;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? l10n.editTransition
                              : l10n.createTransition,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.transitionWizardSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stepper indicator
            _buildStepIndicator(l10n),

            // Contenido de pasos
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Basic(l10n),
                  _buildStep2ValidationType(l10n),
                  _buildStep3ValidationConfig(l10n),
                  _buildStep4ConditionalLogic(l10n),
                  _buildStep5Summary(l10n),
                ],
              ),
            ),

            // Botones de navegación
            _buildNavigationButtons(l10n, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(AppLocalizations l10n) {
    final steps = [
      l10n.basicSettings,
      l10n.validationType,
      l10n.configuration,
      l10n.conditionalLogic,
      l10n.summary,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1Basic(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.step1Title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.step1Description,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Selector de estado origen
          StreamBuilder<List<ProductStatusModel>>(
            stream: Provider.of<ProductStatusService>(context, listen: false)
                .watchStatuses(widget.organizationId),
            builder: (context, snapshot) {
              final statuses = snapshot.data ?? [];

              return DropdownButtonFormField<String>(
                value: _fromStatusId,
                decoration: InputDecoration(
                  labelText: l10n.fromStatus,
                  prefixIcon: const Icon(Icons.label_outline),
                  border: const OutlineInputBorder(),
                ),
                items: statuses.map((status) {
                  return DropdownMenuItem(
                    value: status.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: status.colorValue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.transition != null
                    ? null // No editable si ya existe
                    : (value) {
                        setState(() {
                          _fromStatusId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) return l10n.fieldRequired;
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Selector de estado destino
          StreamBuilder<List<ProductStatusModel>>(
            stream: Provider.of<ProductStatusService>(context, listen: false)
                .watchStatuses(widget.organizationId),
            builder: (context, snapshot) {
              final statuses = snapshot.data ?? [];

              return DropdownButtonFormField<String>(
                value: _toStatusId,
                decoration: InputDecoration(
                  labelText: l10n.toStatus,
                  prefixIcon: const Icon(Icons.label),
                  border: const OutlineInputBorder(),
                ),
                items: statuses
                    .where((s) => s.id != _fromStatusId)
                    .map((status) {
                  return DropdownMenuItem(
                    value: status.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: status.colorValue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.transition != null
                    ? null // No editable si ya existe
                    : (value) {
                        setState(() {
                          _toStatusId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) return l10n.fieldRequired;
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Selector de roles permitidos
          Text(
            l10n.allowedRoles,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectRolesDescription,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<RoleModel>>(
            future: Provider.of<RoleService>(context, listen: false)
                .getAllRoles(widget.organizationId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final roles = snapshot.data!;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles.map((role) {
                  final isSelected = _selectedRoles.contains(role.id);

                  return FilterChip(
                    selected: isSelected,
                    label: Text(role.name),
                    avatar: Icon(
                      _getIconData(role.icon),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : _getColorFromHex(role.color),
                    ),
                    selectedColor: _getColorFromHex(role.color),
                    backgroundColor: _getColorFromHex(role.color).withOpacity(0.1),
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add(role.id);
                        } else {
                          _selectedRoles.remove(role.id);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),

          if (_selectedRoles.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.selectAtLeastOneRole,
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2ValidationType(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.step2Title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.step2Description,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          ValidationTypeSelector(
            selectedType: _validationType,
            onTypeSelected: (type) {
              // Cuando cambia el tipo de validación
setState(() {
  _validationType = type;
  // Inicializar config según tipo con valores por defecto
  _validationConfig = _getDefaultConfigForType(type);
});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3ValidationConfig(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.step3Title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.step3Description,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          ValidationConfigForm(
            validationType: _validationType,
            config: _validationConfig,
            onConfigChanged: (newConfig) {
              setState(() {
                _validationConfig = newConfig;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep4ConditionalLogic(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.step4Title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.step4Description,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            title: Text(l10n.enableConditionalLogic),
            subtitle: Text(l10n.conditionalLogicSubtitle),
            value: _hasConditionalLogic,
            onChanged: (value) {
              setState(() {
                _hasConditionalLogic = value;
                if (!value) {
                  _conditionalLogic = null;
                }
              });
            },
          ),

          if (_hasConditionalLogic) ...[
            const SizedBox(height: 16),
            ConditionalLogicBuilder(
              validationType: _validationType,
              logic: _conditionalLogic,
              organizationId: widget.organizationId,
              onLogicChanged: (logic) {
                setState(() {
                  _conditionalLogic = logic;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep5Summary(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.step5Title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.step5Description,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          _buildSummaryCard(l10n),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSummaryData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final fromStatus = data['fromStatus'] as ProductStatusModel?;
        final toStatus = data['toStatus'] as ProductStatusModel?;
        final roles = data['roles'] as List<RoleModel>;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transición
                _buildSummarySection(
                  l10n.transition,
                  Row(
                    children: [
                      if (fromStatus != null) ...[
                        _buildStatusChip(fromStatus),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                        const SizedBox(width: 8),
                      ],
                      if (toStatus != null) _buildStatusChip(toStatus),
                    ],
                  ),
                ),
                const Divider(height: 24),

                // Roles permitidos
                _buildSummarySection(
                  l10n.allowedRoles,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roles.map((role) {
                      return Chip(
                        label: Text(role.name),
                        avatar: Icon(
                          _getIconData(role.icon),
                          size: 16,
                        ),
                        backgroundColor:
                            _getColorFromHex(role.color).withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 24),

                // Tipo de validación
                _buildSummarySection(
                  l10n.validationType,
                  Chip(
                    label: Text(_validationType.displayName),
                    avatar: Icon(_validationType.icon, size: 16),
                  ),
                ),

                // Mostrar configuración si no es simple approval
                if (_validationType != ValidationType.simpleApproval) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.validationConfiguration,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getConfigSummary(l10n),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Lógica condicional
                if (_hasConditionalLogic && _conditionalLogic != null) ...[
                  const Divider(height: 24),
                  _buildSummarySection(
                    l10n.conditionalLogic,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.rule, color: Colors.amber.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _conditionalLogic!.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildStatusChip(ProductStatusModel status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.colorValue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.colorValue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.colorValue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.name,
            style: TextStyle(
              color: status.colorValue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AppLocalizations l10n, bool isEditing) {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == 4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirstStep)
            TextButton.icon(
              onPressed: _isLoading ? null : _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.previous),
            )
          else
            const SizedBox.shrink(),
          if (!isLastStep)
            ElevatedButton.icon(
              onPressed: _canProceedToNextStep() ? _nextStep : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.next),
            )
          else
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSubmit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(isEditing ? Icons.save : Icons.check),
              label: Text(isEditing ? l10n.save : l10n.create),
            ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Básico
        return _fromStatusId != null &&
            _toStatusId != null &&
            _selectedRoles.isNotEmpty;
      case 1: // Tipo de validación
        return true;
      case 2: // Configuración
        return true;
      case 3: // Lógica condicional
        return !_hasConditionalLogic || _conditionalLogic != null;
      case 4: // Resumen
        return true;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 4 && _canProceedToNextStep()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
    });

    final transitionService =
        Provider.of<StatusTransitionService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final statusService =
        Provider.of<ProductStatusService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Obtener nombres de estados
    final fromStatus =
        await statusService.getStatusById(widget.organizationId, _fromStatusId!);
    final toStatus =
        await statusService.getStatusById(widget.organizationId, _toStatusId!);

    bool success;
    if (widget.transition != null) {
      // Modo edición
      success = await transitionService.updateTransition(
        organizationId: widget.organizationId,
        transitionId: widget.transition!.id,
        validationType: _validationType,
        validationConfig: _validationConfig,
        conditionalLogic: _hasConditionalLogic ? _conditionalLogic : null,
        allowedRoles: _selectedRoles,
      );
    } else {
      // Modo creación
      final transitionId = await transitionService.createTransition(
        organizationId: widget.organizationId,
        fromStatusId: _fromStatusId!,
        toStatusId: _toStatusId!,
        fromStatusName: fromStatus?.name ?? '',
        toStatusName: toStatus?.name ?? '',
        validationType: _validationType,
        validationConfig: _validationConfig,
        conditionalLogic: _hasConditionalLogic ? _conditionalLogic : null,
        allowedRoles: _selectedRoles,
        createdBy: authService.currentUser!.uid,
      );

      success = transitionId != null;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transition != null
                ? l10n.transitionUpdated
                : l10n.transitionCreated,
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transition != null
                ? l10n.errorUpdatingTransition
                : l10n.errorCreatingTransition,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _loadSummaryData() async {
    final statusService =
        Provider.of<ProductStatusService>(context, listen: false);
    final roleService = Provider.of<RoleService>(context, listen: false);

    final fromStatus =
        await statusService.getStatusById(widget.organizationId, _fromStatusId!);
    final toStatus =
        await statusService.getStatusById(widget.organizationId, _toStatusId!);
    final allRoles = await roleService.getAllRoles(widget.organizationId);
    final selectedRoleModels =
        allRoles.where((r) => _selectedRoles.contains(r.id)).toList();

    return {
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'roles': selectedRoleModels,
    };
  }

  String _getConfigSummary(AppLocalizations l10n) {
    switch (_validationType) {
      case ValidationType.textRequired:
      case ValidationType.textOptional:
        return '${l10n.minLength}: ${_validationConfig.textMinLength ?? 0}, '
            '${l10n.maxLength}: ${_validationConfig.textMaxLength ?? 500}';

      case ValidationType.quantityAndText:
        return '${l10n.quantityRange}: ${_validationConfig.quantityMin ?? 0}-'
            '${_validationConfig.quantityMax ?? 999}, '
            '${l10n.required}';

      case ValidationType.checklist:
        return '${_validationConfig.checklistItems?.length ?? 0} ${l10n.items}';

      case ValidationType.photoRequired:
        return '${l10n.minPhotos}: ${_validationConfig.minPhotos ?? 1}';

      case ValidationType.multiApproval:
        return '${l10n.minApprovals}: ${_validationConfig.minApprovals ?? 1}';

      default:
        return l10n.noConfigurationRequired;
    }
  }

  IconData _getIconData(String iconName) {
    try {
      final codePoint = int.tryParse(iconName);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
      return Icons.person;
    } catch (e) {
      return Icons.person;
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  ValidationConfigModel _getDefaultConfigForType(ValidationType type) {
  switch (type) {
    case ValidationType.simpleApproval:
      return ValidationConfigModel();

    case ValidationType.textRequired:
      return ValidationConfigModel(
        textLabel: 'Descripción',
        textMinLength: 10,
        textMaxLength: 500,
      );

    case ValidationType.textOptional:
      return ValidationConfigModel(
        textLabel: 'Comentario (opcional)',
        textMaxLength: 500,
      );

    case ValidationType.quantityAndText:
      return ValidationConfigModel(
        quantityLabel: 'Cantidad',
        quantityMin: 1,
        quantityMax: 999,
        textLabel: 'Descripción',
        textMinLength: 10,
        textMaxLength: 500,
      );

    case ValidationType.checklist:
      return ValidationConfigModel(
        checklistItems: [
          ChecklistItem(
            id: 'item_1',
            label: 'Item de ejemplo',
            required: true,
          ),
        ],
        checklistAllRequired: false,
      );

    case ValidationType.photoRequired:
      return ValidationConfigModel(
        minPhotos: 1,
        maxPhotos: 5,
      );

    case ValidationType.multiApproval:
      return ValidationConfigModel(
        minApprovals: 2,
      );

    case ValidationType.customParameters:
      return ValidationConfigModel(
        customParameters: [
          CustomParameter(
            id: 'param_1',
            label: 'Parámetro de ejemplo',
            type: CustomParameterType.number,
            required: true,
            placeholder: 'Ingresa un valor',
          ),
        ],
      );
  }
}
}