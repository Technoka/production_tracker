// Crear este archivo en: lib/utils/filter_utils.dart

import 'package:flutter/material.dart';

class FilterUtils {
  /// Widget de filtro tipo chip reutilizable
  static Widget buildFilterOption<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    IconData? icon,
    String allLabel = 'Todos',
  }) {
    final isSelected = value != null;
    
    String displayValue = label;
    if (isSelected) {
      try {
        final selectedItem = items.firstWhere((item) => item.value == value);
        if (selectedItem.child is Text) {
          displayValue = (selectedItem.child as Text).data ?? label;
        } else if (selectedItem.child is Row) {
          final children = (selectedItem.child as Row).children;
          for (var child in children) {
            if (child is Text) {
              displayValue = child.data ?? label;
              break;
            }
          }
        }
      } catch (e) {
        displayValue = label;
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      child: PopupMenuButton<T?>(
        initialValue: value,
        tooltip: 'Filtrar por $label',
        offset: const Offset(0, 35),
        onSelected: (T? newValue) {
          onChanged(newValue);
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<T?>(
              value: null,
              height: 36,
              child: Row(
                children: [
                  Icon(
                    Icons.restart_alt,
                    color: isSelected ? Colors.grey : Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allLabel,
                    style: TextStyle(
                      fontWeight: !isSelected ? FontWeight.bold : FontWeight.normal,
                      color: !isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            ...items.map((item) {
              final isItemActive = item.value == value;
              return PopupMenuItem<T?>(
                value: item.value,
                height: 36,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: isItemActive ? Theme.of(context).primaryColor : Colors.black87,
                    fontWeight: isItemActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  child: item.child,
                ),
              );
            }).toList(),
          ];
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                isSelected ? displayValue : label,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Campo de búsqueda reutilizable
  static Widget buildSearchField({
    required String hintText,
    required String searchQuery,
    required Function(String) onChanged,
    double fontSize = 13,
  }) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: fontSize),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        isDense: true,
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onChanged(''),
              )
            : null,
      ),
      style: TextStyle(fontSize: fontSize),
      onChanged: onChanged,
    );
  }

  /// Botón de limpiar filtros
  static Widget buildClearFiltersButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required bool hasActiveFilters,
  }) {
    if (!hasActiveFilters) return const SizedBox.shrink();
    
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.clear_all, size: 16),
      label: const Text('Quitar filtros', style: TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.red.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  /// Contador de filtros activos
  static int countActiveFilters(List<dynamic> filterValues) {
    return filterValues.where((v) => v != null && (v is! String || v.isNotEmpty)).length;
  }
}