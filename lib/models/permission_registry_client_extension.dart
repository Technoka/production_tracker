import 'package:gestion_produccion/l10n/app_localizations.dart';

import 'permission_registry_model.dart';

/// Extensión de PermissionRegistry para gestión de permisos de clientes
extension PermissionRegistryClientExtension on PermissionRegistry {
  /// Obtener solo los permisos que son aplicables a clientes
  ///
  /// Estos permisos pueden ser asignados como "permisos especiales"
  /// a un cliente y se aplicarán como overrides a todos los miembros
  /// con rol "client" asociados a ese cliente
  static List<ClientApplicablePermission> getClientApplicablePermissions(
      AppLocalizations l10n) {
    return [
      // BATCHES - Crear lotes (incluye crear productos de lote)
      ClientApplicablePermission(
        moduleKey: 'batches',
        actionKey: 'create',
        displayName: l10n.canCreateBatches,
        description:
            'El cliente puede crear lotes de producción y añadir productos. Scope siempre limitado a solo asignados.',
        requiresApproval: true,
        usesScope: false, // Scope siempre 'assigned', no configurable
        defaultScope: PermissionScope.assigned,
      ),

      // PROJECTS - Crear proyectos
      ClientApplicablePermission(
        moduleKey: 'projects',
        actionKey: 'create',
        displayName: l10n.canCreateProjects,
        description:
            'El cliente puede crear proyectos nuevos. Scope siempre limitado a solo asignados.',
        requiresApproval: true,
        usesScope: false, // Scope siempre 'assigned', no configurable
        defaultScope: PermissionScope.assigned,
      ),

      // PRODUCT_CATALOG - Crear productos de catálogo
      ClientApplicablePermission(
        moduleKey: 'product_catalog',
        actionKey: 'create',
        displayName: l10n.canCreateCatalogProducts,
        description:
            'El cliente puede crear productos personalizados en el catálogo',
        requiresApproval: true,
        usesScope: false,
      ),

      // CHAT - Enviar mensajes
      ClientApplicablePermission(
        moduleKey: 'chat',
        actionKey: 'send',
        displayName: l10n.canSendMessagesDesc,
        description: 'Puede enviar mensajes en el chat',
        requiresApproval: false,
        usesScope: false,
      ),
    ];
  }

  /// Obtener permisos aplicables agrupados por módulo
  static Map<String, List<ClientApplicablePermission>>
      getClientApplicablePermissionsByModule(AppLocalizations l10n) {
    final permissions = getClientApplicablePermissions(l10n);
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
  static bool isPermissionClientApplicable(
      String moduleKey, String actionKey, AppLocalizations l10n) {
    return getClientApplicablePermissions(l10n).any(
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
  final bool
      requiresApproval; // Si las acciones del cliente requieren aprobación
  final bool usesScope; // Si el permiso tiene scope (all/assigned)
  final PermissionScope? defaultScope; // Scope por defecto si aplica
  final String? note; // Nota adicional para mostrar al usuario

  const ClientApplicablePermission({
    required this.moduleKey,
    required this.actionKey,
    required this.displayName,
    required this.description,
    this.requiresApproval = false,
    this.usesScope = false,
    this.defaultScope,
    this.note,
  });

  /// Genera la clave completa del permiso (module.action)
  String get fullKey => '$moduleKey.$actionKey';

  /// Obtiene el módulo desde el registry
  PermissionModule? get module => PermissionRegistry.getModule(moduleKey);

  /// Obtiene la acción desde el registry
  PermissionAction? get action =>
      PermissionRegistry.getAction(moduleKey, actionKey);

  /// Nombre del módulo para mostrar
  String get moduleDisplayName => module?.displayName ?? moduleKey;
}
