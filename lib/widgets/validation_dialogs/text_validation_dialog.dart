import 'package:flutter/material.dart';
import '../../models/status_transition_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/validation_config_model.dart';
import '../../l10n/app_localizations.dart';

class TextValidationDialog extends StatefulWidget {
  final StatusTransitionModel transition;
  final BatchProductModel product;
  final bool isRequired;

  const TextValidationDialog({
    Key? key,
    required this.transition,
    required this.product,
    required this.isRequired,
  }) : super(key: key);

  @override
  State<TextValidationDialog> createState() => _TextValidationDialogState();
}

class _TextValidationDialogState extends State<TextValidationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
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
            Icons.edit,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              config.textLabel ?? l10n.enterText,
              overflow: TextOverflow.ellipsis,
            ),
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

              // Campo de texto
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: config.textLabel ?? l10n.text,
                  hintText: config.textPlaceholder ?? l10n.enterTextHint,
                  border: const OutlineInputBorder(),
                  errorText: _errorText,
                  helperText: _buildHelperText(config, l10n),
                  helperMaxLines: 2,
                  suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _textController.clear();
                              _errorText = null;
                            });
                          },
                        )
                      : null,
                ),
                maxLines: 5,
                maxLength: config.textMaxLength ?? 500,
                onChanged: (value) {
                  setState(() {
                    _errorText = _validateText(value, config);
                  });
                },
              ),
              const SizedBox(height: 8),

              // Contador de caracteres con colores
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_textController.text.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getCounterColor(
                        _textController.text.length,
                        config,
                      ),
                    ),
                  ),
                  Text(
                    ' / ${config.textMaxLength ?? 500}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
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

  String _buildHelperText(ValidationConfigModel config, AppLocalizations l10n) {
    final minLength = config.textMinLength ?? 0;
    final maxLength = config.textMaxLength ?? 500;

    if (widget.isRequired) {
      return '${l10n.required} • ${l10n.minLength}: $minLength, ${l10n.maxLength}: $maxLength';
    } else {
      return '${l10n.optional} • ${l10n.maxLength}: $maxLength';
    }
  }

  String? _validateText(String text, ValidationConfigModel config) {
    if (widget.isRequired && text.trim().isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired;
    }

    if (text.trim().isNotEmpty) {
      final minLength = config.textMinLength ?? 0;
      if (text.trim().length < minLength) {
        return '${AppLocalizations.of(context)!.textTooShort} (min: $minLength)';
      }
    }

    return null;
  }

  Color _getCounterColor(int length, ValidationConfigModel config) {
    final minLength = config.textMinLength ?? 0;
    final maxLength = config.textMaxLength ?? 500;

    if (length < minLength) {
      return Colors.red;
    } else if (length >= maxLength * 0.9) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  bool _canSubmit() {
    if (widget.isRequired && _textController.text.trim().isEmpty) {
      return false;
    }

    return _errorText == null;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final validationData = ValidationDataModel(
        text: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        timestamp: DateTime.now(),
      );
      Navigator.pop(context, validationData);
    }
  }
}
