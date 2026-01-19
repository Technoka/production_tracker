// lib/utils/filter_utils.dart

import 'package:flutter/material.dart';
import '../../models/production_batch_model.dart';

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: isSelected
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allLabel,
                    style: TextStyle(
                      fontWeight:
                          !isSelected ? FontWeight.bold : FontWeight.normal,
                      color: !isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
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
                    color: isItemActive
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                    fontWeight:
                        isItemActive ? FontWeight.bold : FontWeight.normal,
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
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
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
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                isSelected ? displayValue : label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dropdown estilo moderno con ancho completo (para formularios)
  static Widget buildFullWidthDropdown<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    IconData? icon,
    String? hintText,
    bool isRequired = false,
    String? Function(T?)? validator,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              color: Colors.white,
              surfaceTintColor: Colors.white,
            ),
          ),
          child: PopupMenuButton<T?>(
            tooltip: label,
            offset: const Offset(0, 50),
            onSelected: (T? newValue) {
              onChanged(newValue);
            },
            itemBuilder: (BuildContext context) {
              return items.map((item) {
                final isItemActive = item.value == value;
                return PopupMenuItem<T?>(
                  value: item.value,
                  height: 48,
                  child: SizedBox(
                    width: constraints.maxWidth - 32,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: isItemActive
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight:
                            isItemActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      child: item.child,
                    ),
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value != null
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: value != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: value != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$label${isRequired ? ' *' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: value != null
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (value != null)
                          _extractTextFromChild(items
                              .firstWhere((item) => item.value == value)
                              .child)
                        else
                          Text(
                            hintText ?? 'Seleccionar...',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: value != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper para extraer texto del child de DropdownMenuItem
  static Widget _extractTextFromChild(Widget child) {
    if (child is Text) {
      return Text(
        child.data ?? '',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      );
    } else if (child is Row) {
      final children = (child as Row).children;
      for (var item in children) {
        if (item is Text) {
          return Text(
            item.data ?? '',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          );
        }
      }
    } else if (child is Column) {
      final children = (child as Column).children;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children.map((item) {
          if (item is Text) {
            return Text(
              item.data ?? '',
              style: TextStyle(
                fontSize: item.style?.fontSize ?? 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }
          return item;
        }).toList(),
      );
    }
    return child;
  }

  /// Campo de búsqueda reutilizable
  static Widget buildSearchField({
    required String hintText,
    required String searchQuery,
    required Function(String) onChanged,
    TextEditingController? controller,
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
      controller: controller,
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

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          // Si está activo, fondo rojo suave. Si no, blanco como los otros.
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // Si está activo, borde rojo. Si no, gris como los otros.
            color: Colors.red.shade700,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear_all,
              size: 14,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'Quitar filtros',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contador de filtros activos
  static int countActiveFilters(List<dynamic> filterValues) {
    return filterValues
        .where((v) => v != null && (v is! String || v.isNotEmpty))
        .length;
  }

  /// Widget de selector de urgencia circular (cicla entre niveles)
  static Widget buildUrgencySelector({
    required BuildContext context,
    required String urgencyLevel,
    required Function(String) onChanged,
    bool compact = false,
  }) {
    // 1. Obtenemos el nivel actual usando el método estático del Enum
    final currentLevel = UrgencyLevel.fromString(urgencyLevel);

    return InkWell(
      onTap: () {
        // 2. Lógica de ciclado usando la lista de valores del Enum
        const allLevels = UrgencyLevel.values;
        final currentIndex = allLevels.indexOf(currentLevel);
        final nextIndex = (currentIndex + 1) % allLevels.length;

        // Devolvemos el string value ('low', 'medium', etc.)
        onChanged(allLevels[nextIndex].value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: currentLevel.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: currentLevel.color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              Icons.priority_high_rounded,
              color: currentLevel.color,
              size: compact ? 18 : 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact)
                    Text(
                      'Urgencia',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (!compact) const SizedBox(height: 4),
                  Text(
                    currentLevel.displayName, // Usamos la propiedad del Enum
                    style: TextStyle(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      color: currentLevel.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.refresh_rounded,
              color: currentLevel.color.withOpacity(0.6),
              size: compact ? 16 : 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle de urgencia simple (Normal / Urgente) para formularios de creación
  /// Alterna entre 'medium' (Normal) y 'urgent' (Urgente)
  static Widget buildUrgencyBinaryToggle({
    required BuildContext context,
    required UrgencyLevel urgencyLevel,
    required Function(String) onChanged,
  }) {
    // Lógica binaria: si es 'urgent', es urgente. Cualquier otra cosa (low, medium, high) se trata como normal.
    // Al cambiar a normal, usamos 'medium' por defecto.
    final isUrgent = urgencyLevel == UrgencyLevel.urgent;

    // Colores basados en el enum UrgencyLevel (hardcodeados aquí para evitar dependencias circulares complejas si no se pasa el enum)
    final activeColor = isUrgent ? urgencyLevel.color : Colors.orange;
    final backgroundColor = activeColor.withOpacity(0.1);
    final borderColor = activeColor.withOpacity(0.3);

    return InkWell(
      onTap: () {
        // Toggle simple
        final newValue =
            isUrgent ? UrgencyLevel.medium.value : UrgencyLevel.urgent.value;
        onChanged(newValue);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              isUrgent
                  ? Icons.priority_high_rounded
                  : Icons.low_priority_rounded,
              color: activeColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Prioridad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUrgent ? 'Urgente' : 'Normal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ),
            // Switch visual simulado
            Container(
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isUrgent ? activeColor : Colors.grey.shade300,
              ),
              alignment:
                  isUrgent ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip de filtro para urgencia en Kanban
  /// Mantiene la estética de los otros filtros (gris/borde) pero funciona como toggle
  static Widget buildUrgencyFilterChip({
    required BuildContext context,
    required bool isUrgentOnly,
    required VoidCallback onToggle,
  }) {
    final isActive = isUrgentOnly;
    final activeColor = UrgencyLevel.urgent.color; // Rojo urgente

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          // Si está activo, fondo rojo suave. Si no, blanco como los otros.
          color: isActive ? activeColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // Si está activo, borde rojo. Si no, gris como los otros.
            color: isActive ? activeColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.priority_high : Icons.filter_list,
              size: 14,
              color: isActive ? activeColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? 'Solo Urgentes' : 'Urgencia',
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey.shade700,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (!isActive) ...[
              const SizedBox(width: 2),
              // Icono opcional para indicar que es clickeable
              Icon(Icons.add_circle_outline,
                  size: 12, color: Colors.grey.shade400),
            ]
          ],
        ),
      ),
    );
  }
}
