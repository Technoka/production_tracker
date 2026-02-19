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
  final _sameDescriptionTextController = TextEditingController();

  String? _quantityError;
  String? _singleTextError;
  final Map<int, String?> _individualTextErrors = {};
  ConditionalActionResult? _conditionalResult;
  TextDetailsMode _textMode = TextDetailsMode.single;
  final Map<int, TextEditingController> _individualTextControllers = {};
  final ValueNotifier<bool> _canSubmitNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_updateCanSubmit);
    _textController.addListener(_updateCanSubmit);
    _sameDescriptionTextController.addListener(_updateCanSubmit);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_updateCanSubmit);
    _textController.removeListener(_updateCanSubmit);
    _sameDescriptionTextController.removeListener(_updateCanSubmit);

    for (var ctrl in _individualTextControllers.values) {
      ctrl.removeListener(_updateCanSubmit);
      ctrl.dispose();
    }
    _quantityController.dispose();
    _textController.dispose();
    _sameDescriptionTextController.dispose();
    _canSubmitNotifier.dispose();
    super.dispose();
  }

  void _updateCanSubmit() {
    _canSubmitNotifier.value = _canSubmit();
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
                  _updateCanSubmit();
                },
              ),
              const SizedBox(height: 16),

// Selector de modo de detalles
              const Text(
                'Detalles de texto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              SegmentedButton<TextDetailsMode>(
                segments: [
                  ButtonSegment(
                    value: TextDetailsMode.single,
                    label: Text(TextDetailsMode.single.displayName,
                        style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.description, size: 18),
                  ),
                  ButtonSegment(
                    value: TextDetailsMode.individual,
                    label: Text(TextDetailsMode.individual.displayName,
                        style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.list, size: 18),
                  ),
                ],
                selected: {_textMode},
                onSelectionChanged: (Set<TextDetailsMode> selected) {
                  setState(() {
                    _textMode = selected.first;
                    if (_textMode == TextDetailsMode.individual) {
                      // Inicializar controladores individuales
                      final quantity =
                          int.tryParse(_quantityController.text) ?? 0;
                      for (int i = 0; i < quantity; i++) {
                        if (!_individualTextControllers.containsKey(i)) {
                          _individualTextControllers[i] =
                              TextEditingController();
                        }
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Campo de texto según modo
              if (_textMode == TextDetailsMode.single)
                TextField(
                  controller: _sameDescriptionTextController,
                  decoration: InputDecoration(
                    labelText: config.textLabel ?? l10n.description,
                    hintText: config.textPlaceholder ?? l10n.describeIssue,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.description),
                    helperText:
                        'Esta descripción se aplicará a todas las unidades',
                    errorText: _singleTextError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _singleTextError = _validateText(value, config);
                    });
                    _updateCanSubmit();
                  },
                  // Descripcion individual por cada producto
                )
              else ...[
                Text(
                  'Proporciona una descripción individual para cada unidad',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                // ...
                const SizedBox(height: 8),

                // Lista de campos individuales
                ...List.generate(
                  int.tryParse(_quantityController.text) ?? 0,
                  (index) {
                    if (!_individualTextControllers.containsKey(index)) {
                      final ctrl = TextEditingController();
                      ctrl.addListener(_updateCanSubmit);
                      _individualTextControllers[index] = ctrl;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _individualTextControllers[index],
                        decoration: InputDecoration(
                          labelText:
                              'Defecto #${index + 1}', // usar l10n, basado en
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.error_outline, size: 20),
                          errorText: _individualTextErrors[index],
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          setState(() {
                            _individualTextErrors[index] =
                                _validateText(value, config);
                          });
                          _updateCanSubmit();
                        },
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Campo de texto/descripción
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  hintText: l10n.notesHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                  helperText: _buildTextHelperText(config, l10n),
                ),
                maxLines: 4,
                maxLength: config.textMaxLength ?? 500,
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
        ValueListenableBuilder<bool>(
          valueListenable: _canSubmitNotifier,
          builder: (context, canSubmit, child) {
            return ElevatedButton.icon(
              onPressed: canSubmit ? _handleSubmit : null,
              icon: const Icon(Icons.check),
              label: Text(l10n.confirm),
            );
          },
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
    if (_conditionalResult?.type == ConditionalActionType.blockTransition) {
      return false;
    }

    if (_quantityError != null) return false;
    if (_textMode == TextDetailsMode.single && _singleTextError != null) {
      return false;
    }
    if (_textMode == TextDetailsMode.individual &&
        _individualTextErrors.values.any((e) => e != null)) {
      return false;
    }

    if (_quantityController.text.isEmpty) return false;

    // Solo exigir sameDescription si el modo es single
    if (_textMode == TextDetailsMode.single &&
        _sameDescriptionTextController.text.isEmpty) {
      return false;
    }

    // Si el modo es individual, todos los defectos deben rellenarse
    if (_textMode == TextDetailsMode.individual) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      if (quantity == 0) return false;
      for (int i = 0; i < quantity; i++) {
        final controller = _individualTextControllers[i];
        if (controller == null || controller.text.trim().isEmpty) return false;
      }
    }

    return true;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _canSubmit()) {
      final quantity = int.parse(_quantityController.text);

      // Preparar datos según modo
      String? singleText;
      Map<int, String>? individualTexts;

      if (_textMode == TextDetailsMode.single) {
        singleText = _sameDescriptionTextController.text.trim();
      } else {
        individualTexts = {};
        for (int i = 0; i < quantity; i++) {
          final text = _individualTextControllers[i]?.text.trim();
          if (text != null && text.isNotEmpty) {
            individualTexts[i] = text;
          }
        }
      }

      final validationData = ValidationDataModel(
        quantity: quantity,
        text: singleText,
        textMode: _textMode,
        singleTextReason: singleText,
        individualDefects: individualTexts,
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
