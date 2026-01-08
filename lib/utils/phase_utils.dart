import 'package:flutter/material.dart';

class PhaseUtils {
  PhaseUtils._(); // Private constructor to prevent instantiation

  /// Mapea nombres de iconos a Material Icons
  static IconData getPhaseIcon(String iconName) {
    final iconMap = {
      'work': Icons.work,
      'assignment': Icons.assignment,
      'content_cut': Icons.content_cut,
      'layers': Icons.layers,
      'construction': Icons.construction,
      'palette': Icons.palette,
      'design_services': Icons.design_services,
      'checkroom': Icons.checkroom,
      'verified': Icons.verified,
      'inventory': Icons.inventory,
      'local_shipping': Icons.local_shipping,
      'build': Icons.build,
      'brush': Icons.brush,
      'engineering': Icons.engineering,
      'handyman': Icons.handyman,
      'precision_manufacturing': Icons.precision_manufacturing,
    };

    return iconMap[iconName.toLowerCase()] ?? Icons.work;
  }

  /// Parsea un color en formato hex (#RRGGBB) a Color
  static Color parsePhaseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue; // Fallback color
    }
  }

  /// Valida si un color hex es válido
  static bool isValidHexColor(String color) {
    final hexColor = color.replaceAll('#', '');
    return hexColor.length == 6 && int.tryParse(hexColor, radix: 16) != null;
  }

  /// Retorna una lista de colores predefinidos para el picker
  static List<String> getPresetColors() {
    return [
      '#F44336', '#E91E63', '#9C27B0', '#673AB7',
      '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
      '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
      '#FFEB3B', '#FFC107', '#FF9800', '#FF5722',
      '#795548', '#9E9E9E', '#607D8B', '#000000',
    ];
  }

  /// Retorna un mapa de iconos disponibles
  static Map<String, IconData> getAvailableIcons() {
    return {
      'work': Icons.work,
      'assignment': Icons.assignment,
      'content_cut': Icons.content_cut,
      'layers': Icons.layers,
      'construction': Icons.construction,
      'palette': Icons.palette,
      'design_services': Icons.design_services,
      'checkroom': Icons.checkroom,
      'verified': Icons.verified,
      'inventory': Icons.inventory,
      'local_shipping': Icons.local_shipping,
      'build': Icons.build,
      'brush': Icons.brush,
      'engineering': Icons.engineering,
      'handyman': Icons.handyman,
      'precision_manufacturing': Icons.precision_manufacturing,
    };
  }
}