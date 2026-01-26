import 'permission_registry_model.dart';

/// Extensión de PermissionRegistry para gestión de permisos de clientes
extension PermissionRegistryClientExtension on PermissionRegistry {
  /// Obtener solo los permisos que son aplicables a clientes
  /// 
  /// Estos permisos pueden ser asignados como "permisos especiales" 
  /// a un cliente y se aplicarán como overrides a todos los miembros
  /// con rol "client" asociados a ese cliente
  static List<ClientApplicablePermission> getClientApplicablePermissions() {
    return [
      // BATCHES - Crear lotes
      const ClientApplicablePermission(
        moduleKey: 'batches',
        actionKey: 'create',
        displayName: 'Puede crear lotes',
        description: 'El cliente puede crear lotes de producción',
        requiresApproval: true,
      ),
      
      // BATCH_PRODUCTS - Crear productos
      const ClientApplicablePermission(
        moduleKey: 'batch_products',
        actionKey: 'create',
        displayName: 'Puede crear productos',
        description: 'El cliente puede crear productos personalizados',
        requiresApproval: true,
      ),
      
      // PROJECTS - Ver todos los proyectos
      const ClientApplicablePermission(
        moduleKey: 'projects',
        actionKey: 'view',
        displayName: 'Ver todos los proyectos',
        description: 'Puede ver todos los proyectos o solo los asignados',
        requiresApproval: false,
        usesScope: true,
        defaultScope: PermissionScope.assigned,
      ),
      
      // BATCHES - Ver todos los lotes
      const ClientApplicablePermission(
        moduleKey: 'batches',
        actionKey: 'view',
        displayName: 'Ver todos los lotes',
        description: 'Puede ver todos los lotes o solo los asignados',
        requiresApproval: false,
        usesScope: true,
        defaultScope: PermissionScope.assigned,
      ),
      
      // BATCH_PRODUCTS - Editar productos
      const ClientApplicablePermission(
        moduleKey: 'batch_products',
        actionKey: 'edit',
        displayName: 'Editar productos',
        description: 'Puede editar información de productos',
        requiresApproval: true,
        usesScope: true,
        defaultScope: PermissionScope.assigned,
      ),
      
      // CHAT - Enviar mensajes
      const ClientApplicablePermission(
        moduleKey: 'chat',
        actionKey: 'send',
        displayName: 'Enviar mensajes',
        description: 'Puede enviar mensajes en el chat',
        requiresApproval: false,
      ),
    ];
  }

  /// Obtener permisos aplicables agrupados por módulo
  static Map<String, List<ClientApplicablePermission>> getClientApplicablePermissionsByModule() {
    final permissions = getClientApplicablePermissions();
    final Map<String, List<ClientApplicablePermission>> grouped = {};

    for (final permission in permissions) {
      if (!grouped.containsKey(permission.moduleKey)) {
        grouped[permission.moduleKey] = [];
      }
      grouped[permission.moduleKey]!.add(permission);
    }

    return grouped;
  }

  /// Verificar si un permiso es aplicable a clientes
  static bool isPermissionClientApplicable(String moduleKey, String actionKey) {
    return getClientApplicablePermissions().any(
      (p) => p.moduleKey == moduleKey && p.actionKey == actionKey,
    );
  }
}

/// Definición de un permiso aplicable a clientes
class ClientApplicablePermission {
  final String moduleKey;
  final String actionKey;
  final String displayName;
  final String description;
  final bool requiresApproval; // Si las acciones del cliente requieren aprobación
  final bool usesScope; // Si el permiso tiene scope (all/assigned)
  final PermissionScope? defaultScope; // Scope por defecto si aplica

  const ClientApplicablePermission({
    required this.moduleKey,
    required this.actionKey,
    required this.displayName,
    required this.description,
    this.requiresApproval = false,
    this.usesScope = false,
    this.defaultScope,
  });

  /// Genera la clave completa del permiso (module.action)
  String get fullKey => '$moduleKey.$actionKey';

  /// Obtiene el módulo desde el registry
  PermissionModule? get module => PermissionRegistry.getModule(moduleKey);

  /// Obtiene la acción desde el registry
  PermissionAction? get action => PermissionRegistry.getAction(moduleKey, actionKey);

  /// Nombre del módulo para mostrar
  String get moduleDisplayName => module?.displayName ?? moduleKey;
}