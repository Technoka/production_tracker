import 'package:flutter/material.dart';

/// Constantes de UI centralizadas para colores e iconos
/// Reutilizable en clientes, fases, estados, transiciones, roles, etc.
class UIConstants {
  UIConstants._(); // Private constructor to prevent instantiation

  // ==================== COLORES PREDEFINIDOS ====================

  /// Lista de colores predefinidos para selección
  static const List<String> presetColors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#9E9E9E', // Grey
    '#607D8B', // Blue Grey
    '#000000', // Black
  ];

  /// Nombres legibles de los colores para UI
  static const Map<String, String> colorNames = {
    '#F44336': 'Rojo',
    '#E91E63': 'Rosa',
    '#9C27B0': 'Púrpura',
    '#673AB7': 'Violeta',
    '#3F51B5': 'Índigo',
    '#2196F3': 'Azul',
    '#03A9F4': 'Azul Claro',
    '#00BCD4': 'Cian',
    '#009688': 'Verde Azulado',
    '#4CAF50': 'Verde',
    '#8BC34A': 'Verde Claro',
    '#CDDC39': 'Lima',
    '#FFEB3B': 'Amarillo',
    '#FFC107': 'Ámbar',
    '#FF9800': 'Naranja',
    '#FF5722': 'Naranja Intenso',
    '#795548': 'Marrón',
    '#9E9E9E': 'Gris',
    '#607D8B': 'Gris Azulado',
    '#000000': 'Negro',
  };

  // ==================== ICONOS DISPONIBLES ====================

  /// Mapa de iconos disponibles (nombre -> IconData)
  static const Map<String, IconData> availableIcons = {
    // Producción
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
    'inventory_2': Icons.inventory_2,
    'local_shipping': Icons.local_shipping,
    'build': Icons.build,
    'brush': Icons.brush,
    'engineering': Icons.engineering,
    'handyman': Icons.handyman,
    'precision_manufacturing': Icons.precision_manufacturing,

    // Gestión
    'folder': Icons.folder,
    'folder_open': Icons.folder_open,
    'business': Icons.business,
    'people': Icons.people,
    'person': Icons.person,
    'group': Icons.group,
    'shopping_bag': Icons.shopping_bag,
    'store': Icons.store,

    // Estados y transiciones
    'pending': Icons.pending,
    'pending_actions': Icons.pending_actions,
    'schedule': Icons.schedule,
    'check_circle': Icons.check_circle,
    'check_circle_outline': Icons.check_circle_outline,
    'cancel': Icons.cancel,
    'error': Icons.error,
    'warning': Icons.warning,
    'info': Icons.info,
    'help': Icons.help,
    'pause_circle': Icons.pause_circle,
    'circle': Icons.circle,

    // Comunicación
    'chat': Icons.chat,
    'message': Icons.message,
    'comment': Icons.comment,
    'notifications': Icons.notifications,
    'email': Icons.email,

    // Análisis
    'assessment': Icons.assessment,
    'analytics': Icons.analytics,
    'bar_chart': Icons.bar_chart,
    'pie_chart': Icons.pie_chart,
    'trending_up': Icons.trending_up,
    'trending_down': Icons.trending_down,

    // Configuración
    'settings': Icons.settings,
    'tune': Icons.tune,
    'admin_panel_settings': Icons.admin_panel_settings,
    'security': Icons.security,
    'shield': Icons.shield,
    'lock': Icons.lock,

    // Acciones
    'edit': Icons.edit,
    'delete': Icons.delete,
    'add': Icons.add,
    'remove': Icons.remove,
    'save': Icons.save,
    'copy': Icons.copy,
    'share': Icons.share,

    // Otros
    'star': Icons.star,
    'favorite': Icons.favorite,
    'bookmark': Icons.bookmark,
    'flag': Icons.flag,
    'label': Icons.label,
    'category': Icons.category,
  };

  /// Categorías de iconos para organización en UI
  static const Map<String, List<String>> iconCategories = {
    'production': [
      'work',
      'assignment',
      'content_cut',
      'layers',
      'construction',
      'palette',
      'design_services',
      'checkroom',
      'verified',
      'inventory',
      'inventory_2',
      'local_shipping',
      'build',
      'brush',
      'engineering',
      'handyman',
      'precision_manufacturing',
    ],
    'management': [
      'folder',
      'folder_open',
      'business',
      'people',
      'person',
      'group',
      'shopping_bag',
      'store',
    ],
    'status': [
      'pending',
      'pending_actions',
      'schedule',
      'check_circle',
      'check_circle_outline',
      'cancel',
      'error',
      'warning',
      'info',
      'help',
    ],
    'communication': [
      'chat',
      'message',
      'comment',
      'notifications',
      'email',
    ],
    'analytics': [
      'assessment',
      'analytics',
      'bar_chart',
      'pie_chart',
      'trending_up',
      'trending_down',
    ],
    'settings': [
      'settings',
      'tune',
      'admin_panel_settings',
      'security',
      'shield',
      'lock',
    ],
    'actions': [
      'edit',
      'delete',
      'add',
      'remove',
      'save',
      'copy',
      'share',
    ],
    'other': [
      'star',
      'favorite',
      'bookmark',
      'flag',
      'label',
      'category',
    ],
  };

  // ==================== HELPERS ====================

  /// Parsea un color en formato hex (#RRGGBB) a Color
  static Color parseColor(String colorString) {
    try {
      final cleanColor = colorString.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('FF$cleanColor', radix: 16));
      }
      return Colors.blue; // Fallback color
    } catch (e) {
      return Colors.blue; // Fallback color
    }
  }

  /// Convierte un Color a formato hex (#RRGGBB)
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Valida si un color hex es válido
  static bool isValidHexColor(String color) {
    try {
      final hexColor = color.replaceAll('#', '');
      return hexColor.length == 6 && int.tryParse(hexColor, radix: 16) != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el IconData de un nombre de icono o código unicode
  static IconData getIcon(String iconName) {
    // Intentar parsearlo como número unicode (ej: "57691", "57846")
    final codePoint = int.tryParse(iconName);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    // Si no es un número, buscar por nombre en el mapa
    return availableIcons[iconName.toLowerCase()] ?? Icons.help_outline;
  }

  /// Obtiene el nombre legible de un color
  static String getColorName(String hexColor) {
    return colorNames[hexColor.toUpperCase()] ?? hexColor;
  }

  /// Verifica si un color es oscuro (para determinar color de texto)
  static bool isColorDark(Color color) {
    final luminance = color.computeLuminance();
    return luminance < 0.5;
  }

  /// Obtiene el color de texto apropiado para un fondo
  static Color getTextColorForBackground(Color backgroundColor) {
    return isColorDark(backgroundColor) ? Colors.white : Colors.black;
  }

  /// Obtiene todos los nombres de iconos disponibles
  static List<String> get iconNames => availableIcons.keys.toList();

  /// Obtiene los iconos de una categoría específica
  static List<String> getIconsByCategory(String category) {
    return iconCategories[category] ?? [];
  }

  /// Obtiene todas las categorías de iconos
  static List<String> get categories => iconCategories.keys.toList();
}
