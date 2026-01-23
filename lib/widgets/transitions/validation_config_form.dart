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
    _quantityMaxController.text = widget.config.quantityMax?.toString() ?? '999';
    _minPhotosController.text = widget.config.minPhotos?.toString() ?? '1';
    _minApprovalsController.text = widget.config.minApprovals?.toString() ?? '1';
    _checklistItems = List.from(widget.config.checklistItems ?? []);
    _allItemsRequired = widget.config.checklistAllRequired ?? false;
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
      textLabel: _textLabelController.text.isEmpty
          ? null
          : _textLabelController.text,
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
    );

    widget.onConfigChanged(newConfig);
  }
}