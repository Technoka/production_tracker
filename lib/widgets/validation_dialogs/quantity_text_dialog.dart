import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/status_transition_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/validation_config_model.dart';
import '../../l10n/app_localizations.dart';

class QuantityTextDialog extends StatefulWidget {
  final StatusTransitionModel transition;
  final BatchProductModel product;

  const QuantityTextDialog({
    Key? key,
    required this.transition,
    required this.product,
  }) : super(key: key);

  @override
  State<QuantityTextDialog> createState() => _QuantityTextDialogState();
}

class _QuantityTextDialogState extends State<QuantityTextDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _textController = TextEditingController();
  
  String? _quantityError;
  String? _textError;
  ConditionalActionResult? _conditionalResult;

  @override
  void dispose() {
    _quantityController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = widget.transition.validationConfig;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.format_list_numbered,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.quantityAndDescription),
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

              // Campo de cantidad
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: config.quantityLabel ?? l10n.quantity,
                  hintText: config.quantityPlaceholder ?? l10n.enterQuantity,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                  errorText: _quantityError,
                  helperText: _buildQuantityHelperText(config, l10n),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {
                    _quantityError = _validateQuantity(value, config);
                    _evaluateConditionalLogic();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Campo de texto/descripción
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: config.textLabel ?? l10n.description,
                  hintText: config.textPlaceholder ?? l10n.describeIssue,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                  errorText: _textError,
                  helperText: _buildTextHelperText(config, l10n),
                ),
                maxLines: 4,
                maxLength: config.textMaxLength ?? 500,
                onChanged: (value) {
                  setState(() {
                    _textError = _validateText(value, config);
                  });
                },
              ),

              // Mostrar resultado de lógica condicional
              if (_conditionalResult != null) ...[
                const SizedBox(height: 16),
                _buildConditionalResultWidget(l10n),
              ],
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
            '${l10n.totalQuantity}: ${widget.product.quantity}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
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

  Widget _buildConditionalResultWidget(AppLocalizations l10n) {
    final result = _conditionalResult!;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (result.type) {
      case ConditionalActionType.blockTransition:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.block;
        break;
      case ConditionalActionType.showWarning:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.warning;
        break;
      case ConditionalActionType.requireApproval:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        icon = Icons.approval;
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade900;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.message ?? l10n.conditionalRuleTriggered,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (result.type == ConditionalActionType.requireApproval) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.approvalWillBeRequired,
                    style: TextStyle(fontSize: 12, color: textColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildQuantityHelperText(
      ValidationConfigModel config, AppLocalizations l10n) {
    final min = config.quantityMin ?? 0;
    final max = config.quantityMax ?? 999;
    return '${l10n.range}: $min - $max';
  }

  String _buildTextHelperText(
      ValidationConfigModel config, AppLocalizations l10n) {
    final minLength = config.textMinLength ?? 10;
    final maxLength = config.textMaxLength ?? 500;
    return '${l10n.minLength}: $minLength, ${l10n.maxLength}: $maxLength';
  }

  String? _validateQuantity(String value, ValidationConfigModel config) {
    if (value.trim().isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired;
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return AppLocalizations.of(context)!.invalidNumber;
    }

    final min = config.quantityMin ?? 0;
    final max = config.quantityMax ?? 999;

    if (quantity < min) {
      return '${AppLocalizations.of(context)!.minimumValue}: $min';
    }

    if (quantity > max) {
      return '${AppLocalizations.of(context)!.maximumValue}: $max';
    }

    return null;
  }

  String? _validateText(String value, ValidationConfigModel config) {
    if (value.trim().isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired;
    }

    final minLength = config.textMinLength ?? 10;
    if (value.trim().length < minLength) {
      return '${AppLocalizations.of(context)!.textTooShort} (min: $minLength)';
    }

    return null;
  }

  void _evaluateConditionalLogic() {
    if (!widget.transition.hasConditionalLogic) {
      _conditionalResult = null;
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null) {
      _conditionalResult = null;
      return;
    }

    final validationData = {
      'quantity': quantity,
      'textLength': _textController.text.length,
    };

    final conditionMet =
        widget.transition.conditionalLogic!.evaluate(validationData);

    if (conditionMet) {
      final action = widget.transition.conditionalLogic!.action;
      _conditionalResult = ConditionalActionResult(
        type: action.type,
        message: action.parameters?['message']?.toString() ??
            action.parameters?['reason']?.toString(),
        requiredRoles: action.parameters?['requiredRoles'] as List<String>?,
      );
    } else {
      _conditionalResult = null;
    }
  }

  bool _canSubmit() {
    // Si la lógica condicional bloquea, no se puede enviar
    if (_conditionalResult?.type == ConditionalActionType.blockTransition) {
      return false;
    }

    return _quantityError == null && _textError == null &&
        _quantityController.text.isNotEmpty &&
        _textController.text.isNotEmpty;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _canSubmit()) {
      final validationData = ValidationDataModel(
        quantity: int.parse(_quantityController.text),
        text: _textController.text.trim(),
        timestamp: DateTime.now(),
      );
      Navigator.pop(context, validationData);
    }
  }
}

/// Resultado de evaluar lógica condicional
class ConditionalActionResult {
  final ConditionalActionType type;
  final String? message;
  final List<String>? requiredRoles;

  ConditionalActionResult({
    required this.type,
    this.message,
    this.requiredRoles,
  });
}