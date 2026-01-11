/// Sistema de registro dinámico de permisos
/// Permite añadir nuevos módulos y acciones fácilmente

/// Scope de un permiso
enum PermissionScope {
  none('none', 'Sin acceso'),
  assigned('assigned', 'Solo asignados'),
  all('all', 'Todos');

  final String value;
  final String displayName;
  const PermissionScope(this.value, this.displayName);

  static PermissionScope fromString(String value) {
    return PermissionScope.values.firstWhere(
      (scope) => scope.value == value,
      orElse: () => PermissionScope.none,
    );
  }
}

/// Tipo de acción de permiso
enum PermissionActionType {
  boolean,  // true/false simple
  scoped,   // con scope (none/assigned/all)
}

/// Definición de una acción de permiso
class PermissionAction {
  final String key;           // Ej: "view", "create", "edit"
  final String displayName;   // Ej: "Ver", "Crear", "Editar"
  final String? description;  // Descripción detallada
  final PermissionActionType type;
  final bool defaultValue;    // Valor por defecto

  const PermissionAction({
    required this.key,
    required this.displayName,
    this.description,
    this.type = PermissionActionType.boolean,
    this.defaultValue = false,
  });

  /// Crea una acción booleana simple
  const PermissionAction.boolean({
    required this.key,
    required this.displayName,
    this.description,
    this.defaultValue = false,
  }) : type = PermissionActionType.boolean;

  /// Crea una acción con scope
  const PermissionAction.scoped({
    required this.key,
    required this.displayName,
    this.description,
    this.defaultValue = false,
  }) : type = PermissionActionType.scoped;
}

/// Definición de un módulo de permisos
class PermissionModule {
  final String key;           // Ej: "kanban", "batches"
  final String displayName;   // Ej: "Tablero Kanban", "Lotes"
  final String icon;          // Material Icons name
  final String? description;
  final List<PermissionAction> actions;

  const PermissionModule({
    required this.key,
    required this.displayName,
    required this.icon,
    this.description,
    required this.actions,
  });
}

/// Registro central de todos los módulos y permisos
class PermissionRegistry {
  // ==================== DEFINICIÓN DE MÓDULOS ====================
  
  static const List<PermissionModule> modules = [
    // KANBAN
    PermissionModule(
      key: 'kanban',
      displayName: 'Tablero Kanban',
      icon: 'view_kanban',
      description: 'Vista de productos por fases',
      actions: [
        PermissionAction.boolean(
          key: 'view',
          displayName: 'Ver tablero',
        ),
        PermissionAction.scoped(
          key: 'moveProducts',
          displayName: 'Mover productos',
          description: 'Cambiar productos entre fases',
        ),
        PermissionAction.scoped(
          key: 'editProductDetails',
          displayName: 'Editar detalles',
          description: 'Modificar información de productos',
        ),
      ],
    ),

    // FASES
    PermissionModule(
      key: 'phases',
      displayName: 'Gestión de Fases',
      icon: 'linear_scale',
      description: 'Configuración de fases de producción',
      actions: [
        PermissionAction.boolean(key: 'view', displayName: 'Ver fases'),
        PermissionAction.boolean(key: 'create', displayName: 'Crear fases'),
        PermissionAction.boolean(key: 'edit', displayName: 'Editar fases'),
        PermissionAction.boolean(key: 'delete', displayName: 'Eliminar fases'),
        PermissionAction.boolean(
          key: 'assignToMembers',
          displayName: 'Asignar a miembros',
        ),
        PermissionAction.boolean(
          key: 'manageTransitions',
          displayName: 'Gestionar transiciones',
          description: 'Configurar reglas de cambio de estado',
        ),
      ],
    ),

    // LOTES
    PermissionModule(
      key: 'batches',
      displayName: 'Lotes de Producción',
      icon: 'inventory_2',
      description: 'Gestión de lotes y órdenes',
      actions: [
        PermissionAction.scoped(key: 'view', displayName: 'Ver lotes'),
        PermissionAction.boolean(key: 'create', displayName: 'Crear lotes'),
        PermissionAction.scoped(key: 'edit', displayName: 'Editar lotes'),
        PermissionAction.scoped(key: 'delete', displayName: 'Eliminar lotes'),
        PermissionAction.boolean(
          key: 'startProduction',
          displayName: 'Iniciar producción',
        ),
        PermissionAction.boolean(
          key: 'completeBatch',
          displayName: 'Completar lote',
        ),
      ],
    ),

    // PRODUCTOS
    PermissionModule(
      key: 'products',
      displayName: 'Productos',
      icon: 'category',
      description: 'Gestión de productos en producción',
      actions: [
        PermissionAction.scoped(key: 'view', displayName: 'Ver productos'),
        PermissionAction.boolean(key: 'create', displayName: 'Crear productos'),
        PermissionAction.scoped(key: 'edit', displayName: 'Editar productos'),
        PermissionAction.scoped(key: 'delete', displayName: 'Eliminar productos'),
        PermissionAction.scoped(
          key: 'changeStatus',
          displayName: 'Cambiar estado',
          description: 'Modificar estado (OK, CAO, Control, etc.)',
        ),
        PermissionAction.scoped(
          key: 'changeUrgency',
          displayName: 'Cambiar urgencia',
        ),
      ],
    ),

    // PROYECTOS
    PermissionModule(
      key: 'projects',
      displayName: 'Proyectos',
      icon: 'folder',
      description: 'Gestión de proyectos y familias',
      actions: [
        PermissionAction.scoped(key: 'view', displayName: 'Ver proyectos'),
        PermissionAction.boolean(key: 'create', displayName: 'Crear proyectos'),
        PermissionAction.scoped(key: 'edit', displayName: 'Editar proyectos'),
        PermissionAction.scoped(key: 'delete', displayName: 'Eliminar proyectos'),
        PermissionAction.boolean(
          key: 'assignMembers',
          displayName: 'Asignar miembros',
        ),
      ],
    ),

    // CLIENTES
    PermissionModule(
      key: 'clients',
      displayName: 'Clientes',
      icon: 'people',
      description: 'Gestión de clientes',
      actions: [
        PermissionAction.boolean(key: 'view', displayName: 'Ver clientes'),
        PermissionAction.boolean(key: 'create', displayName: 'Crear clientes'),
        PermissionAction.boolean(key: 'edit', displayName: 'Editar clientes'),
        PermissionAction.boolean(key: 'delete', displayName: 'Eliminar clientes'),
      ],
    ),

    // CATÁLOGO
    PermissionModule(
      key: 'catalog',
      displayName: 'Catálogo',
      icon: 'shopping_bag',
      description: 'Catálogo de productos',
      actions: [
        PermissionAction.boolean(key: 'view', displayName: 'Ver catálogo'),
        PermissionAction.boolean(key: 'create', displayName: 'Crear productos'),
        PermissionAction.boolean(key: 'edit', displayName: 'Editar productos'),
        PermissionAction.boolean(key: 'delete', displayName: 'Eliminar productos'),
      ],
    ),

    // CHAT
    PermissionModule(
      key: 'chat',
      displayName: 'Chat y Mensajería',
      icon: 'chat',
      description: 'Sistema de mensajes',
      actions: [
        PermissionAction.boolean(key: 'view', displayName: 'Ver mensajes'),
        PermissionAction.boolean(key: 'send', displayName: 'Enviar mensajes'),
        PermissionAction.boolean(key: 'delete', displayName: 'Eliminar mensajes'),
        PermissionAction.boolean(key: 'pin', displayName: 'Fijar mensajes'),
        PermissionAction.boolean(
          key: 'viewInternal',
          displayName: 'Ver mensajes internos',
        ),
      ],
    ),

    // ORGANIZACIÓN
    PermissionModule(
      key: 'organization',
      displayName: 'Organización',
      icon: 'business',
      description: 'Configuración de la organización',
      actions: [
        PermissionAction.boolean(key: 'viewMembers', displayName: 'Ver miembros'),
        PermissionAction.boolean(key: 'inviteMembers', displayName: 'Invitar miembros'),
        PermissionAction.boolean(key: 'removeMembers', displayName: 'Eliminar miembros'),
        PermissionAction.boolean(key: 'manageRoles', displayName: 'Gestionar roles'),
        PermissionAction.boolean(
          key: 'manageSettings',
          displayName: 'Gestionar configuración',
        ),
      ],
    ),

    // REPORTES
    PermissionModule(
      key: 'reports',
      displayName: 'Reportes',
      icon: 'assessment',
      description: 'Generación de reportes',
      actions: [
        PermissionAction.boolean(key: 'view', displayName: 'Ver reportes'),
        PermissionAction.boolean(key: 'generate', displayName: 'Generar reportes'),
        PermissionAction.boolean(key: 'export', displayName: 'Exportar reportes'),
      ],
    ),
  ];

  // ==================== MÉTODOS DE BÚSQUEDA ====================

  /// Obtener módulo por key
  static PermissionModule? getModule(String moduleKey) {
    try {
      return modules.firstWhere((m) => m.key == moduleKey);
    } catch (e) {
      return null;
    }
  }

  /// Obtener acción de un módulo
  static PermissionAction? getAction(String moduleKey, String actionKey) {
    final module = getModule(moduleKey);
    if (module == null) return null;

    try {
      return module.actions.firstWhere((a) => a.key == actionKey);
    } catch (e) {
      return null;
    }
  }

  /// Verificar si una acción es scoped
  static bool isActionScoped(String moduleKey, String actionKey) {
    final action = getAction(moduleKey, actionKey);
    return action?.type == PermissionActionType.scoped;
  }

  /// Obtener todas las claves de módulos
  static List<String> get moduleKeys => modules.map((m) => m.key).toList();

  /// Obtener todas las claves de acciones de un módulo
  static List<String> getModuleActionKeys(String moduleKey) {
    final module = getModule(moduleKey);
    if (module == null) return [];
    return module.actions.map((a) => a.key).toList();
  }

  // ==================== PERMISOS POR DEFECTO ====================

  /// Crear mapa de permisos vacío
  static Map<String, dynamic> createEmptyPermissions() {
    final permissions = <String, dynamic>{};

    for (final module in modules) {
      final modulePerms = <String, dynamic>{};

      for (final action in module.actions) {
        if (action.type == PermissionActionType.scoped) {
          modulePerms[action.key] = false;
          modulePerms['${action.key}Scope'] = PermissionScope.none.value;
        } else {
          modulePerms[action.key] = false;
        }
      }

      permissions[module.key] = modulePerms;
    }

    return permissions;
  }

  /// Crear permisos completos (todos en true)
  static Map<String, dynamic> createFullPermissions() {
    final permissions = <String, dynamic>{};

    for (final module in modules) {
      final modulePerms = <String, dynamic>{};

      for (final action in module.actions) {
        if (action.type == PermissionActionType.scoped) {
          modulePerms[action.key] = true;
          modulePerms['${action.key}Scope'] = PermissionScope.all.value;
        } else {
          modulePerms[action.key] = true;
        }
      }

      permissions[module.key] = modulePerms;
    }

    return permissions;
  }

  // ==================== VALIDACIÓN ====================

  /// Validar estructura de permisos
  static bool validatePermissionsStructure(Map<String, dynamic> permissions) {
    try {
      for (final module in modules) {
        if (!permissions.containsKey(module.key)) return false;

        final modulePerms = permissions[module.key] as Map<String, dynamic>?;
        if (modulePerms == null) return false;

        for (final action in module.actions) {
          if (!modulePerms.containsKey(action.key)) return false;

          if (action.type == PermissionActionType.scoped) {
            if (!modulePerms.containsKey('${action.key}Scope')) return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Normalizar permisos (añadir campos faltantes con valores por defecto)
  static Map<String, dynamic> normalizePermissions(Map<String, dynamic> permissions) {
    final normalized = Map<String, dynamic>.from(permissions);

    for (final module in modules) {
      if (!normalized.containsKey(module.key)) {
        normalized[module.key] = <String, dynamic>{};
      }

      final modulePerms = normalized[module.key] as Map<String, dynamic>;

      for (final action in module.actions) {
        if (!modulePerms.containsKey(action.key)) {
          modulePerms[action.key] = action.defaultValue;
        }

        if (action.type == PermissionActionType.scoped) {
          if (!modulePerms.containsKey('${action.key}Scope')) {
            modulePerms['${action.key}Scope'] = PermissionScope.none.value;
          }
        }
      }
    }

    return normalized;
  }

  // ==================== HELPERS PARA UI ====================

  /// Agrupar módulos por categoría (para UI organizada)
  static Map<String, List<PermissionModule>> get modulesByCategory {
    return {
      'Producción': modules.where((m) => 
        ['kanban', 'phases', 'batches', 'products'].contains(m.key)
      ).toList(),
      'Gestión': modules.where((m) => 
        ['projects', 'clients', 'catalog'].contains(m.key)
      ).toList(),
      'Comunicación': modules.where((m) => 
        ['chat'].contains(m.key)
      ).toList(),
      'Administración': modules.where((m) => 
        ['organization', 'reports'].contains(m.key)
      ).toList(),
    };
  }
}

/// Clase helper para trabajar con permisos dinámicos
class DynamicPermissions {
  final Map<String, dynamic> _permissions;

  DynamicPermissions(this._permissions);

  /// Obtener valor de un permiso
  bool getBoolean(String moduleKey, String actionKey) {
    try {
      final modulePerms = _permissions[moduleKey] as Map<String, dynamic>?;
      if (modulePerms == null) return false;
      return modulePerms[actionKey] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Obtener scope de un permiso
  PermissionScope getScope(String moduleKey, String actionKey) {
    try {
      final modulePerms = _permissions[moduleKey] as Map<String, dynamic>?;
      if (modulePerms == null) return PermissionScope.none;

      final scopeValue = modulePerms['${actionKey}Scope'] as String?;
      if (scopeValue == null) return PermissionScope.none;

      return PermissionScope.fromString(scopeValue);
    } catch (e) {
      return PermissionScope.none;
    }
  }

  /// Establecer valor booleano
  void setBoolean(String moduleKey, String actionKey, bool value) {
    if (!_permissions.containsKey(moduleKey)) {
      _permissions[moduleKey] = <String, dynamic>{};
    }
    final modulePerms = _permissions[moduleKey] as Map<String, dynamic>;
    modulePerms[actionKey] = value;
  }

  /// Establecer scope
  void setScope(String moduleKey, String actionKey, PermissionScope scope) {
    if (!_permissions.containsKey(moduleKey)) {
      _permissions[moduleKey] = <String, dynamic>{};
    }
    final modulePerms = _permissions[moduleKey] as Map<String, dynamic>;
    modulePerms['${actionKey}Scope'] = scope.value;
  }

  /// Exportar como mapa
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_permissions);

  /// Verificar si puede realizar una acción
  bool can(String moduleKey, String actionKey) {
    return getBoolean(moduleKey, actionKey);
  }

  /// Verificar con scope
  bool canWithScope({
    required String moduleKey,
    required String actionKey,
    required bool isAssigned,
  }) {
    if (!can(moduleKey, actionKey)) return false;

    final scope = getScope(moduleKey, actionKey);
    switch (scope) {
      case PermissionScope.all:
        return true;
      case PermissionScope.assigned:
        return isAssigned;
      case PermissionScope.none:
        return false;
    }
  }

  /// Merge con otro conjunto de permisos (overrides)
  DynamicPermissions mergeWith(DynamicPermissions overrides) {
    final merged = Map<String, dynamic>.from(_permissions);

    for (final moduleKey in overrides._permissions.keys) {
      if (!merged.containsKey(moduleKey)) {
        merged[moduleKey] = <String, dynamic>{};
      }

      final modulePerms = merged[moduleKey] as Map<String, dynamic>;
      final overrideModulePerms = overrides._permissions[moduleKey] as Map<String, dynamic>;

      for (final actionKey in overrideModulePerms.keys) {
        // Solo aplicar override si es diferente del valor por defecto
        final overrideValue = overrideModulePerms[actionKey];
        
        // Para valores booleanos
        if (overrideValue is bool && overrideValue != false) {
          modulePerms[actionKey] = overrideValue;
        }
        // Para scopes
        else if (overrideValue is String && overrideValue != PermissionScope.none.value) {
          modulePerms[actionKey] = overrideValue;
        }
      }
    }

    return DynamicPermissions(merged);
  }
}