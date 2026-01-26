import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/ui_constants.dart';

/// Widget para seleccionar color del cliente
class ClientColorPicker extends StatelessWidget {
  final String? currentColor;
  final ValueChanged<String> onColorChanged;
  final bool enabled;

  const ClientColorPicker({
    super.key,
    this.currentColor,
    required this.onColorChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedColor = currentColor != null 
        ? UIConstants.parseColor(currentColor!) 
        : null;

    return InkWell(
      onTap: enabled ? () => _showColorPickerDialog(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Indicador de color actual
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedColor ?? Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectColorLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentColor != null
                        ? UIConstants.getColorName(currentColor!)
                        : l10n.selectColorHelper,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(Icons.palette, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.colorPickerTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ColorPickerGrid(
            currentColor: currentColor,
            onColorSelected: (color) {
              onColorChanged(color);
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

/// Grid de colores predefinidos
class ColorPickerGrid extends StatelessWidget {
  final String? currentColor;
  final ValueChanged<String> onColorSelected;

  const ColorPickerGrid({
    super.key,
    this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.defaultColors,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),

        // Grid de colores
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: UIConstants.presetColors.length,
          itemBuilder: (context, index) {
            final colorHex = UIConstants.presetColors[index];
            final color = UIConstants.parseColor(colorHex);
            final isSelected = currentColor?.toUpperCase() == colorHex.toUpperCase();

            return _ColorButton(
              color: color,
              colorHex: colorHex,
              isSelected: isSelected,
              onTap: () => onColorSelected(colorHex),
            );
          },
        ),
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final String colorHex;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.colorHex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              )
            : null,
      ),
    );
  }
}

/// Indicador simple de color (para mostrar en listas)
class ClientColorIndicator extends StatelessWidget {
  final String? color;
  final double size;

  const ClientColorIndicator({
    super.key,
    this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color != null
        ? UIConstants.parseColor(color!)
        : Colors.grey.shade300;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: displayColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1.5,
        ),
      ),
    );
  }
}