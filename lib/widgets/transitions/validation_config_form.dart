import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/validation_config_model.dart';
import '../../l10n/app_localizations.dart';

class ValidationConfigForm extends StatefulWidget {
  final ValidationType validationType;
  final ValidationConfigModel config;
  final Function(ValidationConfigModel) onConfigChanged;

  const ValidationConfigForm({
    Key? key,
    required this.validationType,
    required this.config,
    required this.onConfigChanged,
  }) : super(key: key);

  @override
  State<ValidationConfigForm> createState() => _ValidationConfigFormState();
}

class _ValidationConfigFormState extends State<ValidationConfigForm> {
  late TextEditingController _textLabelController;
  late TextEditingController _textMinController;
  late TextEditingController _textMaxController;
  late TextEditingController _quantityLabelController;
  late TextEditingController _quantityMinController;
  late TextEditingController _quantityMaxController;
  late TextEditingController _minPhotosController;
  late TextEditingController _minApprovalsController;

  List<ChecklistItem> _checklistItems = [];
  bool _allItemsRequired = false;
  List<CustomParameter> _customParameters = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadConfig();
  }

  void _initControllers() {
    _textLabelController = TextEditingController();
    _textMinController = TextEditingController();
    _textMaxController = TextEditingController();
    _quantityLabelController = TextEditingController();
    _quantityMinController = TextEditingController();
    _quantityMaxController = TextEditingController();
    _minPhotosController = TextEditingController();
    _minApprovalsController = TextEditingController();
  }

  void _loadConfig() {
    _textLabelController.text = widget.config.textLabel ?? '';
    _textMinController.text = widget.config.textMinLength?.toString() ?? '10';
    _textMaxController.text = widget.config.textMaxLength?.toString() ?? '500';
    _quantityLabelController.text = widget.config.quantityLabel ?? '';
    _quantityMinController.text = widget.config.quantityMin?.toString() ?? '1';
    _quantityMaxController.text =
        widget.config.quantityMax?.toString() ?? '999';
    _minPhotosController.text = widget.config.minPhotos?.toString() ?? '1';
    _minApprovalsController.text =
        widget.config.minApprovals?.toString() ?? '1';
    _checklistItems = List.from(widget.config.checklistItems ?? []);
    _allItemsRequired = widget.config.checklistAllRequired ?? false;
    _customParameters = List.from(widget.config.customParameters ?? []);
  }

  @override
  void dispose() {
    _textLabelController.dispose();
    _textMinController.dispose();
    _textMaxController.dispose();
    _quantityLabelController.dispose();
    _quantityMinController.dispose();
    _quantityMaxController.dispose();
    _minPhotosController.dispose();
    _minApprovalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.validationType == ValidationType.simpleApproval) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.simpleApprovalInfo,
                  style: TextStyle(color: Colors.green.shade900),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.validationType == ValidationType.textRequired ||
            widget.validationType == ValidationType.textOptional)
          _buildTextConfig(l10n),
        if (widget.validationType == ValidationType.quantityAndText)
          _buildQuantityAndTextConfig(l10n),
        if (widget.validationType == ValidationType.checklist)
          _buildChecklistConfig(l10n),
        if (widget.validationType == ValidationType.photoRequired)
          _buildPhotoConfig(l10n),
        if (widget.validationType == ValidationType.multiApproval)
          _buildMultiApprovalConfig(l10n),
        if (widget.validationType == ValidationType.customParameters)
          _buildCustomParametersConfig(l10n),
      ],
    );
  }

  Widget _buildTextConfig(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: _textLabelController,
          decoration: InputDecoration(
            labelText: l10n.fieldLabel,
            hintText: l10n.fieldLabelHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _updateConfig(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textMinController,
                decoration: InputDecoration(
                  labelText: l10n.minLength,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateConfig(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _textMaxController,
                decoration: InputDecoration(
                  labelText: l10n.maxLength,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateConfig(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityAndTextConfig(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: _quantityLabelController,
          decoration: InputDecoration(
            labelText: l10n.quantityLabel,
            hintText: l10n.quantityLabelHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _updateConfig(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityMinController,
                decoration: InputDecoration(
                  labelText: l10n.minQuantity,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateConfig(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _quantityMaxController,
                decoration: InputDecoration(
                  labelText: l10n.maxQuantity,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateConfig(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textLabelController,
          decoration: InputDecoration(
            labelText: l10n.descriptionLabel,
            hintText: l10n.descriptionLabelHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _updateConfig(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textMinController,
                decoration: InputDecoration(
                  labelText: l10n.minLength,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateConfig(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _textMaxController,
                decoration: InputDecoration(
                  labelText: l10n.maxLength,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateConfig(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChecklistConfig(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.allItemsRequired),
          value: _allItemsRequired,
          onChanged: (value) {
            setState(() {
              _allItemsRequired = value;
            });
            _updateConfig();
          },
        ),
        const SizedBox(height: 16),
        Text(
          l10n.checklistItems,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ..._checklistItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Checkbox(
                value: item.required,
                onChanged: (value) {
                  setState(() {
                    _checklistItems[index] = item.copyWith(required: value);
                  });
                  _updateConfig();
                },
              ),
              title: Text(item.label),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _checklistItems.removeAt(index);
                  });
                  _updateConfig();
                },
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddChecklistItemDialog(l10n),
          icon: const Icon(Icons.add),
          label: Text(l10n.addItem),
        ),
      ],
    );
  }

  Widget _buildPhotoConfig(AppLocalizations l10n) {
    return TextField(
      controller: _minPhotosController,
      decoration: InputDecoration(
        labelText: l10n.minPhotos,
        hintText: l10n.minPhotosHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.camera_alt),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _updateConfig(),
    );
  }

  Widget _buildMultiApprovalConfig(AppLocalizations l10n) {
    return TextField(
      controller: _minApprovalsController,
      decoration: InputDecoration(
        labelText: l10n.minApprovals,
        hintText: l10n.minApprovalsHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.people),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _updateConfig(),
    );
  }

  Widget _buildCustomParametersConfig(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info card
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Define parámetros personalizados que el usuario deberá completar',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de parámetros
        if (_customParameters.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.tune, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No hay parámetros configurados',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Añade al menos un parámetro',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customParameters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final param = _customParameters[index];
              return _buildParameterCard(param, index, l10n);
            },
          ),

        const SizedBox(height: 12),

        // Botón añadir parámetro
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddParameterDialog(l10n),
            icon: const Icon(Icons.add),
            label: const Text('Añadir parámetro'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterCard(
    CustomParameter param,
    int index,
    AppLocalizations l10n,
  ) {
    // Determinar color e icono según tipo
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (param.type) {
      case CustomParameterType.text:
        typeColor = Colors.blue;
        typeIcon = Icons.text_fields;
        typeLabel = 'Texto';
        break;
      case CustomParameterType.number:
        typeColor = Colors.green;
        typeIcon = Icons.numbers;
        typeLabel = 'Número';
        break;
      case CustomParameterType.boolean:
        typeColor = Colors.orange;
        typeIcon = Icons.toggle_on;
        typeLabel = 'Sí/No';
        break;
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinear todo arriba
          children: [
            // SECCIÓN IZQUIERDA: Icono + Título/Chips + Info (Expanded para evitar overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icono de tipo
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(typeIcon, size: 20, color: typeColor),
                      ),
                      const SizedBox(width: 8),
                      // Título
                      Text(
                        param.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // FILA 1: Icono + Título + Chips
                  Row(
                    children: [
                      // Título y Chips
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6, // Espacio horizontal entre elementos
                          runSpacing:
                              4, // Espacio vertical si hace salto de línea
                          children: [
                            // Chip de Tipo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Chip Obligatorio/Opcional
                            if (param.required)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Obligatorio',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Opcional',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // FILA 2: Placeholder (Ayuda)
                  if (param.placeholder != null &&
                      param.placeholder!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 4), // Alinear visualmente
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ayuda: ${param.placeholder}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // SECCIÓN DERECHA: Botones verticales
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: () => _showEditParameterDialog(param, index, l10n),
                  tooltip: 'Editar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _customParameters.removeAt(index);
                    });
                    _updateConfig();
                  },
                  tooltip: 'Eliminar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddParameterDialog(AppLocalizations l10n) {
    final labelController = TextEditingController();
    final placeholderController = TextEditingController();
    CustomParameterType selectedType = CustomParameterType.text;
    bool isRequired = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir parámetro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta *',
                    hintText: 'Ej: Cantidad reparada',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Tipo
                const Text(
                  'Tipo de dato',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                SegmentedButton<CustomParameterType>(
                  segments: const [
                    ButtonSegment(
                      value: CustomParameterType.text,
                      label: Text('Texto'),
                      icon: Icon(Icons.text_fields, size: 18),
                    ),
                    ButtonSegment(
                      value: CustomParameterType.number,
                      label: Text('Número'),
                      icon: Icon(Icons.numbers, size: 18),
                    ),
                    ButtonSegment(
                      value: CustomParameterType.boolean,
                      label: Text('Sí/No'),
                      icon: Icon(Icons.toggle_on, size: 18),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (Set<CustomParameterType> selected) {
                    setDialogState(() {
                      selectedType = selected.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Placeholder
                TextField(
                  controller: placeholderController,
                  decoration: const InputDecoration(
                    labelText: 'Texto de ayuda (opcional)',
                    hintText: 'Ej: Ingresa el número de productos reparados',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lightbulb_outline),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Required
                SwitchListTile(
                  title: const Text('Campo obligatorio'),
                  subtitle: const Text('El usuario debe completar este campo'),
                  value: isRequired,
                  onChanged: (value) {
                    setDialogState(() {
                      isRequired = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La etiqueta es obligatoria'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newParam = CustomParameter(
                  id: _generateParameterId(labelController.text.trim()),
                  label: labelController.text.trim(),
                  type: selectedType,
                  required: isRequired,
                  placeholder: placeholderController.text.trim().isEmpty
                      ? null
                      : placeholderController.text.trim(),
                );

                setState(() {
                  _customParameters.add(newParam);
                });
                _updateConfig();
                Navigator.pop(context);
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditParameterDialog(
    CustomParameter param,
    int index,
    AppLocalizations l10n,
  ) {
    final labelController = TextEditingController(text: param.label);
    final placeholderController =
        TextEditingController(text: param.placeholder ?? '');
    CustomParameterType selectedType = param.type;
    bool isRequired = param.required;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar parámetro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Tipo
                const Text(
                  'Tipo de dato',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                SegmentedButton<CustomParameterType>(
                  segments: const [
                    ButtonSegment(
                      value: CustomParameterType.text,
                      label: Text('Texto'),
                      icon: Icon(Icons.text_fields, size: 18),
                    ),
                    ButtonSegment(
                      value: CustomParameterType.number,
                      label: Text('Número'),
                      icon: Icon(Icons.numbers, size: 18),
                    ),
                    ButtonSegment(
                      value: CustomParameterType.boolean,
                      label: Text('Sí/No'),
                      icon: Icon(Icons.toggle_on, size: 18),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (Set<CustomParameterType> selected) {
                    setDialogState(() {
                      selectedType = selected.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Placeholder
                TextField(
                  controller: placeholderController,
                  decoration: const InputDecoration(
                    labelText: 'Texto de ayuda (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lightbulb_outline),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Required
                SwitchListTile(
                  title: const Text('Campo obligatorio'),
                  subtitle: const Text('El usuario debe completar este campo'),
                  value: isRequired,
                  onChanged: (value) {
                    setDialogState(() {
                      isRequired = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La etiqueta es obligatoria'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final updatedParam = param.copyWith(
                  label: labelController.text.trim(),
                  type: selectedType,
                  required: isRequired,
                  placeholder: placeholderController.text.trim().isEmpty
                      ? null
                      : placeholderController.text.trim(),
                );

                setState(() {
                  _customParameters[index] = updatedParam;
                });
                _updateConfig();
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateParameterId(String label) {
    // Convertir label a ID válido (snake_case)
    return label
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  void _showAddChecklistItemDialog(AppLocalizations l10n) {
    final controller = TextEditingController();
    bool isRequired = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.addChecklistItem),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.itemLabel,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: Text(l10n.required),
                value: isRequired,
                onChanged: (value) {
                  setDialogState(() {
                    isRequired = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _checklistItems.add(ChecklistItem(
                      id: controller.text.trim().toLowerCase(),
                      label: controller.text.trim(),
                      required: isRequired,
                    ));
                  });
                  _updateConfig();
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  void _updateConfig() {
    final newConfig = ValidationConfigModel(
      textLabel:
          _textLabelController.text.isEmpty ? null : _textLabelController.text,
      textMinLength: int.tryParse(_textMinController.text),
      textMaxLength: int.tryParse(_textMaxController.text),
      quantityLabel: _quantityLabelController.text.isEmpty
          ? null
          : _quantityLabelController.text,
      quantityMin: int.tryParse(_quantityMinController.text),
      quantityMax: int.tryParse(_quantityMaxController.text),
      checklistItems: _checklistItems.isEmpty ? null : _checklistItems,
      checklistAllRequired: _allItemsRequired,
      minPhotos: int.tryParse(_minPhotosController.text),
      minApprovals: int.tryParse(_minApprovalsController.text),
      customParameters: _customParameters.isEmpty ? null : _customParameters,
    );

    widget.onConfigChanged(newConfig);
  }
}
