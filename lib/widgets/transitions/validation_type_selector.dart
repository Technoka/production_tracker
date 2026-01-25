import 'package:flutter/material.dart';
import '../../models/validation_config_model.dart';
import '../../l10n/app_localizations.dart';

class ValidationTypeSelector extends StatelessWidget {
  final ValidationType selectedType;
  final Function(ValidationType) onTypeSelected;

  const ValidationTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: ValidationType.values.map((type) {
        final isSelected = type == selectedType;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: () => onTypeSelected(type),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Radio button
                  Radio<ValidationType>(
                    value: type,
                    groupValue: selectedType,
                    onChanged: (value) {
                      if (value != null) onTypeSelected(value);
                    },
                  ),
                  const SizedBox(width: 12),

                  // Icono
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      type.icon,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}