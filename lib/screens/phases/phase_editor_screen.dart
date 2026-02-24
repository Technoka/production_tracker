import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import '../../models/phase_model.dart';
import '../../services/phase_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhaseEditorScreen extends StatefulWidget {
  final String organizationId;
  final ProductionPhase? phase; // null = create new

  const PhaseEditorScreen({
    Key? key,
    required this.organizationId,
    this.phase,
  }) : super(key: key);

  @override
  State<PhaseEditorScreen> createState() => _PhaseEditorScreenState();
}

class _PhaseEditorScreenState extends State<PhaseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phaseService = PhaseService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _wipLimitController;
  late TextEditingController _maxDurationController;
  late TextEditingController _warningThresholdController;

  String _selectedColor = '#2196F3';
  String _selectedIcon = 'work';
  bool _slaEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final phase = widget.phase;

    _nameController = TextEditingController(text: phase?.name ?? '');
    _descriptionController =
        TextEditingController(text: phase?.description ?? '');
    _wipLimitController = TextEditingController(
      text: phase?.wipLimit.toString() ?? '10',
    );
    _maxDurationController = TextEditingController(
      text: phase?.maxDurationHours?.toString() ?? '',
    );
    _warningThresholdController = TextEditingController(
      text: phase?.warningThresholdPercent?.toString() ?? '80',
    );

    if (phase != null) {
      _selectedColor = phase.color;
      _selectedIcon = phase.icon;
      _slaEnabled = phase.hasSLA;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _wipLimitController.dispose();
    _maxDurationController.dispose();
    _warningThresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': _selectedColor,
        'icon': _selectedIcon,
        'wipLimit': int.parse(_wipLimitController.text),
      };

      // Handle SLA settings properly
      if (_slaEnabled && _maxDurationController.text.isNotEmpty) {
        updates['maxDurationHours'] = int.parse(_maxDurationController.text);
        updates['warningThresholdPercent'] =
            int.parse(_warningThresholdController.text);
      } else {
        // Use FieldValue.delete() for removing fields in Firestore
        updates['maxDurationHours'] = FieldValue.delete();
        updates['warningThresholdPercent'] = FieldValue.delete();
      }

      if (widget.phase == null) {
        // Create new
        final existingPhases =
            await _phaseService.getOrganizationPhases(widget.organizationId);
        final newOrder = existingPhases.isEmpty
            ? 1
            : existingPhases
                    .map((p) => p.order)
                    .reduce((a, b) => a > b ? a : b) +
                1;

        final newPhase = ProductionPhase(
          id: '', // Firestore will generate
          name: updates['name'] as String,
          description: updates['description'] as String,
          order: newOrder,
          isActive: true,
          createdAt: DateTime.now(),
          color: updates['color'] as String,
          icon: updates['icon'] as String,
          wipLimit: updates['wipLimit'] as int,
          kanbanPosition: newOrder,
          maxDurationHours:
              _slaEnabled && _maxDurationController.text.isNotEmpty
                  ? int.parse(_maxDurationController.text)
                  : null,
          warningThresholdPercent:
              _slaEnabled && _warningThresholdController.text.isNotEmpty
                  ? int.parse(_warningThresholdController.text)
                  : null,
        );

        await _phaseService.createCustomPhase(widget.organizationId, newPhase);
      } else {
        // Update existing
        // Remove FieldValue.delete() for update, just don't include the field
        final updateData = <String, dynamic>{
          'name': updates['name'],
          'description': updates['description'],
          'color': updates['color'],
          'icon': updates['icon'],
          'wipLimit': updates['wipLimit'],
        };

        if (_slaEnabled && _maxDurationController.text.isNotEmpty) {
          updateData['maxDurationHours'] =
              int.parse(_maxDurationController.text);
          updateData['warningThresholdPercent'] =
              int.parse(_warningThresholdController.text);
        }
        // Note: To actually remove fields in Firestore when updating existing doc,
        // we need to use FieldValue.delete(), but only if the phase exists
        else if (widget.phase!.hasSLA) {
          updateData['maxDurationHours'] = FieldValue.delete();
          updateData['warningThresholdPercent'] = FieldValue.delete();
        }

        await _phaseService.updatePhase(
          widget.organizationId,
          widget.phase!.id,
          updateData,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.phase != null;

    return AppScaffold(
      title: isEditing ? l10n.editPhaseTitle : l10n.createPhaseTitle,
      currentIndex: AppNavIndex.production,
      actions: [
        if (_isSaving)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton(
            onPressed: _save,
            child: Text(
              l10n.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==================== BASIC SETTINGS ====================
            _buildSectionHeader(l10n.basicSettings, Icons.edit),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.phaseNameLabel,
                        hintText: 'e.g., Cutting, Assembly',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.fieldRequired;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.phaseDescriptionLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================== VISUAL SETTINGS ====================
            _buildSectionHeader(l10n.visualSettings, Icons.palette),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color picker
                    Text(
                      l10n.selectColor,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildColorPicker(),

                    const Divider(height: 32),

                    // Icon picker
                    Text(
                      l10n.selectIcon,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildIconPicker(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================== ADVANCED SETTINGS ====================
            _buildSectionHeader(l10n.advancedSettings, Icons.settings),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WIP Limit
                    Text(
                      l10n.wipSettings,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _wipLimitController,
                      decoration: InputDecoration(
                        labelText: l10n.wipLimitLabel,
                        hintText: '10',
                        helperText: l10n.wipLimitHelper,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.workspaces),
                        suffixText: 'productos',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.fieldRequired;
                        }
                        final number = int.tryParse(value);
                        if (number == null || number < 1) {
                          return l10n.wipLimitError;
                        }
                        return null;
                      },
                    ),

                    const Divider(height: 32),

                    // SLA Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.slaSettings,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Switch(
                          value: _slaEnabled,
                          onChanged: (value) {
                            setState(() => _slaEnabled = value);
                          },
                        ),
                      ],
                    ),

                    if (_slaEnabled) ...[
                      const SizedBox(height: 12),

                      // Max Duration
                      TextFormField(
                        controller: _maxDurationController,
                        decoration: InputDecoration(
                          labelText: l10n.maxDurationLabel,
                          hintText: '48',
                          helperText: l10n.maxDurationHelper,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.timer),
                          suffixText: 'horas',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _slaEnabled
                            ? (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.fieldRequired;
                                }
                                final number = int.tryParse(value);
                                if (number == null || number < 1) {
                                  return 'Debe ser mayor a 0';
                                }
                                return null;
                              }
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Warning Threshold
                      TextFormField(
                        controller: _warningThresholdController,
                        decoration: InputDecoration(
                          labelText: l10n.warningThresholdLabel,
                          hintText: '80',
                          helperText: l10n.warningThresholdHelper,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.warning_amber),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _slaEnabled
                            ? (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.fieldRequired;
                                }
                                final number = int.tryParse(value);
                                if (number == null ||
                                    number < 1 ||
                                    number > 100) {
                                  return 'Debe estar entre 1 y 100';
                                }
                                return null;
                              }
                            : null,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.slaNotConfigured,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      '#F44336',
      '#E91E63',
      '#9C27B0',
      '#673AB7',
      '#3F51B5',
      '#2196F3',
      '#03A9F4',
      '#00BCD4',
      '#009688',
      '#4CAF50',
      '#8BC34A',
      '#CDDC39',
      '#FFEB3B',
      '#FFC107',
      '#FF9800',
      '#FF5722',
      '#795548',
      '#9E9E9E',
      '#607D8B',
      '#000000',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = color == _selectedColor;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedColor = color);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _parseColor(color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _parseColor(color).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconPicker() {
    final icons = {
      'work': Icons.work,
      'assignment': Icons.assignment,
      'content_cut': Icons.content_cut,
      'layers': Icons.layers,
      'construction': Icons.construction,
      'palette': Icons.palette,
      'design_services': Icons.design_services,
      'checkroom': Icons.checkroom,
      'verified': Icons.verified,
      'inventory': Icons.inventory,
      'local_shipping': Icons.local_shipping,
      'build': Icons.build,
      'brush': Icons.brush,
      'engineering': Icons.engineering,
      'handyman': Icons.handyman,
      'precision_manufacturing': Icons.precision_manufacturing,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: icons.entries.map((entry) {
        final isSelected = entry.key == _selectedIcon;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedIcon = entry.key);
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  isSelected ? _parseColor(_selectedColor) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? _parseColor(_selectedColor)
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Icon(
              entry.value,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 28,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
