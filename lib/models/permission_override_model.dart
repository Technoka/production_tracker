import 'package:cloud_firestore/cloud_firestore.dart';
import 'permission_model.dart';
import 'permission_registry.dart';

// Re-exportar PermissionScope para acceso fácil
export 'permission_registry.dart' show PermissionScope;

/// Tipo de override de permiso
enum OverrideType {
  /// Habilitar un permiso que estaba deshabilitado
  enable,
  
  /// Deshabilitar un permiso que estaba habilitado
  disable,
  
  /// Cambiar el scope de un permiso (assigned → all, all → assigned, etc.)
  changeScope,
}

extension OverrideTypeExtension on OverrideType {
  String get value {
    switch (this) {
      case OverrideType.enable:
        return 'enable';
      case OverrideType.disable:
        return 'disable';
      case OverrideType.changeScope:
        return 'change_scope';
    }
  }

  static OverrideType fromString(String value) {
    switch (value) {
      case 'enable':
        return OverrideType.enable;
      case 'disable':
        return OverrideType.disable;
      case 'change_scope':
        return OverrideType.changeScope;
      default:
        return OverrideType.enable;
    }
  }
}

/// Modelo de Override de Permiso Individual
/// 
/// Representa un override específico para un permiso
class PermissionOverrideEntry {
  final String moduleKey;
  final String actionKey;
  final OverrideType type;
  final dynamic value; // bool para enable/disable, PermissionScope para changeScope
  final String? reason; // Motivo del override (opcional, para auditoría)
  final DateTime createdAt;
  final String createdBy;

  PermissionOverrideEntry({
    required this.moduleKey,
    required this.actionKey,
    required this.type,
    required this.value,
    this.reason,
    required this.createdAt,
    required this.createdBy,
  });

  /// Crear desde Map
  factory PermissionOverrideEntry.fromMap(Map<String, dynamic> map) {
    final type = OverrideTypeExtension.fromString(map['type'] ?? 'enable');
    
    // Parsear value según el tipo
    dynamic parsedValue = map['value'];
    if (type == OverrideType.changeScope && parsedValue is String) {
      // Convertir string a PermissionScope
      switch (parsedValue) {
        case 'all':
          parsedValue = PermissionScope.all;
          break;
        case 'assigned':
          parsedValue = PermissionScope.assigned;
          break;
        case 'none':
          parsedValue = PermissionScope.none;
          break;
        default:
          parsedValue = PermissionScope.none;
      }
    }

    return PermissionOverrideEntry(
      moduleKey: map['moduleKey'] ?? '',
      actionKey: map['actionKey'] ?? '',
      type: type,
      value: parsedValue,
      reason: map['reason'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'moduleKey': moduleKey,
      'actionKey': actionKey,
      'type': type.value,
      'value': value is PermissionScope ? (value as PermissionScope).value : value,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Clave única del override (para identificarlo)
  String get key => '$moduleKey.$actionKey';

  @override
  String toString() {
    return 'PermissionOverrideEntry($key: ${type.value} = $value)';
  }
}

/// Modelo de Permission Overrides
/// 
/// Contiene todos los overrides de permisos para un miembro específico
/// Se aplican sobre los permisos base del rol
class PermissionOverridesModel {
  final Map<String, PermissionOverrideEntry> overrides;

  PermissionOverridesModel({
    Map<String, PermissionOverrideEntry>? overrides,
  }) : overrides = overrides ?? {};

  /// Crear modelo vacío
  factory PermissionOverridesModel.empty() {
    return PermissionOverridesModel(overrides: {});
  }

  /// Crear desde Map (Firestore)
  factory PermissionOverridesModel.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return PermissionOverridesModel.empty();
    }

    final overrides = <String, PermissionOverrideEntry>{};
    
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        overrides[key] = PermissionOverrideEntry.fromMap(value);
      }
    });

    return PermissionOverridesModel(overrides: overrides);
  }

  /// Crear desde lista de overrides
  factory PermissionOverridesModel.fromList(List<PermissionOverrideEntry> entries) {
    final overrides = <String, PermissionOverrideEntry>{};
    
    for (final entry in entries) {
      overrides[entry.key] = entry;
    }

    return PermissionOverridesModel(overrides: overrides);
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    
    overrides.forEach((key, entry) {
      map[key] = entry.toMap();
    });

    return map;
  }

  /// Añadir un override
  PermissionOverridesModel addOverride(PermissionOverrideEntry entry) {
    final newOverrides = Map<String, PermissionOverrideEntry>.from(overrides);
    newOverrides[entry.key] = entry;
    return PermissionOverridesModel(overrides: newOverrides);
  }

  /// Eliminar un override
  PermissionOverridesModel removeOverride(String moduleKey, String actionKey) {
    final key = '$moduleKey.$actionKey';
    final newOverrides = Map<String, PermissionOverrideEntry>.from(overrides);
    newOverrides.remove(key);
    return PermissionOverridesModel(overrides: newOverrides);
  }

  /// Obtener un override específico
  PermissionOverrideEntry? getOverride(String moduleKey, String actionKey) {
    final key = '$moduleKey.$actionKey';
    return overrides[key];
  }

  /// Verificar si existe un override para un permiso
  bool hasOverride(String moduleKey, String actionKey) {
    final key = '$moduleKey.$actionKey';
    return overrides.containsKey(key);
  }

  /// Obtener todos los overrides como lista
  List<PermissionOverrideEntry> get allOverrides => overrides.values.toList();

  /// Obtener overrides por módulo
  List<PermissionOverrideEntry> getOverridesByModule(String moduleKey) {
    return overrides.values
        .where((entry) => entry.moduleKey == moduleKey)
        .toList();
  }

  /// Obtener cantidad de overrides
  int get count => overrides.length;

  /// Verificar si está vacío
  bool get isEmpty => overrides.isEmpty;
  bool get isNotEmpty => overrides.isNotEmpty;

  // ==================== APLICAR OVERRIDES ====================

  /// Aplicar overrides sobre permisos base del rol
  /// 
  /// Retorna un nuevo PermissionsModel con los overrides aplicados
  PermissionsModel applyTo(PermissionsModel basePermissions) {
    // Empezar con los permisos base
    final resultMap = Map<String, dynamic>.from(basePermissions.toMap());

    // Aplicar cada override
    for (final entry in overrides.values) {
      _applySingleOverride(resultMap, entry);
    }

    return PermissionsModel.fromMap(resultMap);
  }

  void _applySingleOverride(
    Map<String, dynamic> permissionsMap,
    PermissionOverrideEntry entry,
  ) {
    // Asegurar que existe el módulo
    if (!permissionsMap.containsKey(entry.moduleKey)) {
      permissionsMap[entry.moduleKey] = <String, dynamic>{};
    }

    final moduleMap = permissionsMap[entry.moduleKey] as Map<String, dynamic>;

    switch (entry.type) {
      case OverrideType.enable:
        // Habilitar el permiso
        moduleMap[entry.actionKey] = true;
        break;

      case OverrideType.disable:
        // Deshabilitar el permiso
        moduleMap[entry.actionKey] = false;
        break;

      case OverrideType.changeScope:
        // Cambiar el scope
        if (entry.value is PermissionScope) {
          moduleMap[entry.actionKey] = (entry.value as PermissionScope).value;
        } else if (entry.value is String) {
          moduleMap[entry.actionKey] = entry.value;
        }
        break;
    }
  }

  // ==================== HELPERS DE CREACIÓN ====================

  /// Crear override para habilitar un permiso
  static PermissionOverrideEntry createEnableOverride({
    required String moduleKey,
    required String actionKey,
    required String createdBy,
    String? reason,
  }) {
    return PermissionOverrideEntry(
      moduleKey: moduleKey,
      actionKey: actionKey,
      type: OverrideType.enable,
      value: true,
      reason: reason,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  /// Crear override para deshabilitar un permiso
  static PermissionOverrideEntry createDisableOverride({
    required String moduleKey,
    required String actionKey,
    required String createdBy,
    String? reason,
  }) {
    return PermissionOverrideEntry(
      moduleKey: moduleKey,
      actionKey: actionKey,
      type: OverrideType.disable,
      value: false,
      reason: reason,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  /// Crear override para cambiar scope
  static PermissionOverrideEntry createScopeOverride({
    required String moduleKey,
    required String actionKey,
    required PermissionScope newScope,
    required String createdBy,
    String? reason,
  }) {
    return PermissionOverrideEntry(
      moduleKey: moduleKey,
      actionKey: actionKey,
      type: OverrideType.changeScope,
      value: newScope,
      reason: reason,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  // ==================== ANÁLISIS Y COMPARACIÓN ====================

  /// Obtener diferencias entre permisos base y efectivos
  /// 
  /// Retorna un mapa de módulo → acción → (base, efectivo)
  Map<String, Map<String, PermissionDifference>> getDifferences(
    PermissionsModel basePermissions,
  ) {
    final differences = <String, Map<String, PermissionDifference>>{};
    final effectivePermissions = applyTo(basePermissions);

    final baseHelper = basePermissions.dynamicHelper;
    final effectiveHelper = effectivePermissions.dynamicHelper;

    // Revisar todos los módulos del registry
    for (final module in PermissionRegistry.modules) {
      final moduleKey = module.key;
      final moduleDiffs = <String, PermissionDifference>{};

      for (final action in module.actions) {
        final actionKey = action.key;

        // Obtener valores base y efectivo
        final baseValue = _getPermissionValue(baseHelper, moduleKey, actionKey);
        final effectiveValue = _getPermissionValue(effectiveHelper, moduleKey, actionKey);

        // Si son diferentes, añadir a las diferencias
        if (baseValue != effectiveValue) {
          moduleDiffs[actionKey] = PermissionDifference(
            moduleKey: moduleKey,
            actionKey: actionKey,
            baseValue: baseValue,
            effectiveValue: effectiveValue,
            override: getOverride(moduleKey, actionKey),
          );
        }
      }

      if (moduleDiffs.isNotEmpty) {
        differences[moduleKey] = moduleDiffs;
      }
    }

    return differences;
  }

  dynamic _getPermissionValue(
    DynamicPermissions helper,
    String moduleKey,
    String actionKey,
  ) {
    final action = PermissionRegistry.getAction(moduleKey, actionKey);
    if (action == null) return null;

    if (action.type == PermissionActionType.boolean) {
      return helper.can(moduleKey, actionKey);
    } else {
      return helper.getScope(moduleKey, actionKey);
    }
  }

  @override
  String toString() {
    return 'PermissionOverridesModel(count: $count)';
  }
}

/// Diferencia entre permiso base y efectivo
class PermissionDifference {
  final String moduleKey;
  final String actionKey;
  final dynamic baseValue;
  final dynamic effectiveValue;
  final PermissionOverrideEntry? override;

  PermissionDifference({
    required this.moduleKey,
    required this.actionKey,
    required this.baseValue,
    required this.effectiveValue,
    this.override,
  });

  /// Si el permiso fue mejorado (más permisivo)
  bool get isUpgrade {
    // Boolean: false → true
    if (baseValue is bool && effectiveValue is bool) {
      return !baseValue && effectiveValue;
    }

    // Scope: assigned → all
    if (baseValue is PermissionScope && effectiveValue is PermissionScope) {
      return baseValue == PermissionScope.assigned &&
          effectiveValue == PermissionScope.all;
    }

    return false;
  }

  /// Si el permiso fue restringido (menos permisivo)
  bool get isDowngrade {
    // Boolean: true → false
    if (baseValue is bool && effectiveValue is bool) {
      return baseValue && !effectiveValue;
    }

    // Scope: all → assigned
    if (baseValue is PermissionScope && effectiveValue is PermissionScope) {
      return baseValue == PermissionScope.all &&
          effectiveValue == PermissionScope.assigned;
    }

    return false;
  }
}
