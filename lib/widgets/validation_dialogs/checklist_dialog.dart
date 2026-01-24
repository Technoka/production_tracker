import 'package:flutter/material.dart';
import '../../models/status_transition_model.dart';
import '../../models/batch_product_model.dart';
import '../../l10n/app_localizations.dart';

class ChecklistDialog extends StatefulWidget {
  final StatusTransitionModel transition;
  final BatchProductModel product;

  const ChecklistDialog({
    Key? key,
    required this.transition,
    required this.product,
  }) : super(key: key);

  @override
  State<ChecklistDialog> createState() => _ChecklistDialogState();
}

class _ChecklistDialogState extends State<ChecklistDialog> {
  final Map<String, bool> _checklistAnswers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final items = widget.transition.validationConfig.checklistItems ?? [];
    for (var item in items) {
      _checklistAnswers[item.id] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = widget.transition.validationConfig;
    final items = config.checklistItems ?? [];

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.checklist,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.verificationChecklist)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info del producto
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    widget.transition.toStatusName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info de items requeridos
            if (config.checklistAllRequired == true)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.allItemsMustBeChecked,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Lista de items
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return CheckboxListTile(
                    title: Text(item.label),
                    subtitle: item.description != null
                        ? Text(
                            item.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                    secondary: item.required
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.required,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    value: _checklistAnswers[item.id] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _checklistAnswers[item.id] = value ?? false;
                        _errorMessage = null;
                      });
                    },
                  );
                },
              ),
            ),

            // Mensaje de error
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Progreso
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_getCheckedCount()} / ${items.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getCheckedCount() == items.length
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.itemsCompleted,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
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

  int _getCheckedCount() {
    return _checklistAnswers.values.where((v) => v).length;
  }

  bool _canSubmit() {
    final config = widget.transition.validationConfig;
    final items = config.checklistItems ?? [];

    // Si todos son obligatorios, verificar que todos estén marcados
    if (config.checklistAllRequired == true) {
      return _checklistAnswers.values.every((v) => v);
    }

    // Si no, verificar que al menos los obligatorios estén marcados
    for (var item in items) {
      if (item.required && !(_checklistAnswers[item.id] ?? false)) {
        return false;
      }
    }

    return true;
  }

  void _handleSubmit() {
    if (!_canSubmit()) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.completeRequiredItems;
      });
      return;
    }

    final validationData = ValidationDataModel(
      checklistAnswers: _checklistAnswers,
      timestamp: DateTime.now(),
    );
    Navigator.pop(context, validationData);
  }
}