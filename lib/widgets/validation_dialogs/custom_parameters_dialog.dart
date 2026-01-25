import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/status_transition_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/validation_config_model.dart';
import '../../l10n/app_localizations.dart';

class CustomParametersDialog extends StatefulWidget {
  final StatusTransitionModel transition;
  final BatchProductModel product;

  const CustomParametersDialog({
    Key? key,
    required this.transition,
    required this.product,
  }) : super(key: key);

  @override
  State<CustomParametersDialog> createState() => _CustomParametersDialogState();
}

class _CustomParametersDialogState extends State<CustomParametersDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, bool> _boolValues = {};
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores y valores
    final params = widget.transition.validationConfig.customParameters ?? [];
    for (var param in params) {
      if (param.type == CustomParameterType.text || 
          param.type == CustomParameterType.number) {
        _textControllers[param.id] = TextEditingController(
          text: param.defaultValue?.toString() ?? '',
        );
      } else if (param.type == CustomParameterType.boolean) {
        _boolValues[param.id] = param.defaultValue as bool? ?? false;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final params = widget.transition.validationConfig.customParameters ?? [];

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.tune,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Parámetros'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info del producto
              _buildProductInfo(l10n),
              const SizedBox(height: 16),

              // Lista de parámetros
              ...params.map((param) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildParameterField(param, l10n),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _canSubmit() ? _handleSubmit : null,
          icon: const Icon(Icons.check),
          label: Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _buildProductInfo(AppLocalizations l10n) {
    return Container(
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
            widget.product.productName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.skuLabel} ${widget.product.productReference!}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.transition.fromStatusName,
                style: const TextStyle(fontSize: 12),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 14),
              ),
              Text(
                widget.transition.toStatusName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterField(CustomParameter param, AppLocalizations l10n) {
    switch (param.type) {
      case CustomParameterType.text:
        return TextFormField(
          controller: _textControllers[param.id],
          decoration: InputDecoration(
            labelText: '${param.label}${param.required ? ' *' : ''}',
            hintText: param.placeholder,
            border: const OutlineInputBorder(),
          ),
          maxLines: 1,
          validator: param.required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.fieldRequired;
                  }
                  return null;
                }
              : null,
        );

      case CustomParameterType.number:
        return TextFormField(
          controller: _textControllers[param.id],
          decoration: InputDecoration(
            labelText: '${param.label}${param.required ? ' *' : ''}',
            hintText: param.placeholder,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: param.required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.fieldRequired;
                  }
                  if (int.tryParse(value) == null) {
                    return l10n.invalidNumber;
                  }
                  return null;
                }
              : null,
        );

      case CustomParameterType.boolean:
        return SwitchListTile(
          title: Text(param.label),
          value: _boolValues[param.id] ?? false,
          onChanged: (value) {
            setState(() {
              _boolValues[param.id] = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        );
    }
  }

  bool _canSubmit() {
    final params = widget.transition.validationConfig.customParameters ?? [];
    
    for (var param in params) {
      if (!param.required) continue;
      
      if (param.type == CustomParameterType.text ||
          param.type == CustomParameterType.number) {
        final controller = _textControllers[param.id];
        if (controller == null || controller.text.trim().isEmpty) {
          return false;
        }
      }
    }
    
    return true;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> parametersData = {};
    
    for (var entry in _textControllers.entries) {
      final param = widget.transition.validationConfig.customParameters!
          .firstWhere((p) => p.id == entry.key);
      
      if (param.type == CustomParameterType.text) {
        parametersData[entry.key] = entry.value.text.trim();
      } else if (param.type == CustomParameterType.number) {
        parametersData[entry.key] = int.tryParse(entry.value.text) ?? 0;
      }
    }
    
    for (var entry in _boolValues.entries) {
      parametersData[entry.key] = entry.value;
    }

    final validationData = ValidationDataModel(
      customParametersData: parametersData,
      timestamp: DateTime.now(),
    );

    Navigator.pop(context, validationData);
  }
}