import '../models/permission_model.dart';
import '../models/permission_registry.dart';
import '../models/organization_member_model.dart';
import '../models/role_model.dart';

/// Utilidad simplificada para verificar permisos usando el Registry dinámico
class PermissionUtils {
  // ==================== VERIFICACIÓN DINÁMICA ====================

  /// Verificar si un miembro puede realizar una acción (dinámico)
  static bool can({
    required OrganizationMemberModel member,
    required RoleModel role,
    required String module,
    required String action,
  }) {
    final effectivePermissions = member.getEffectivePermissions(role);
    return effectivePermissions.can(module, action);
  }

  /// Verificar scope de un permiso (dinámico)
  static PermissionScope getScope({
    required OrganizationMemberModel member,
    required RoleModel role,
    required String module,
    required String action,
  }) {
    final effectivePermissions = member.getEffectivePermissions(role);
    return effectivePermissions.getScope(module, action);
  }

  /// Verificar si puede ver algo según el scope
  static bool canViewWithScope({
    required OrganizationMemberModel member,
    required RoleModel role,
    required String module,
    required bool isAssignedToUser,
  }) {
    final scope = getScope(
      member: member,
      role: role,
      module: module,
      action: 'view',
    );

    return _evaluateScope(scope, isAssignedToUser);
  }

  /// Verificar si puede editar según el scope
  static bool canEditWithScope({
    required OrganizationMemberModel member,
    required RoleModel role,
    required String module,
    required bool isAssignedToUser,
  }) {
    if (!can(member: member, role: role, module: module, action: 'edit')) {
      return false;
    }

    final scope = getScope(
      member: member,
      role: role,
      module: module,
      action: 'edit',
    );

    return _evaluateScope(scope, isAssignedToUser);
  }

  /// Verificar si puede eliminar según el scope
  static bool canDeleteWithScope({
    required OrganizationMemberModel member,
    required RoleModel role,
    required String module,
    required bool isAssignedToUser,
  }) {
    if (!can(member: member, role: role, module: module, action: 'delete')) {
      return false;
    }

    final scope = getScope(
      member: member,
      role: role,
      module: module,
      action: 'delete',
    );

    return _evaluateScope(scope, isAssignedToUser);
  }

  /// Evaluar scope
  static bool _evaluateScope(PermissionScope scope, bool isAssigned) {
    switch (scope) {
      case PermissionScope.all:
        return true;
      case PermissionScope.assigned:
        return isAssigned;
      case PermissionScope.none:
        return false;
    }
  }

  // ==================== HELPERS ESPECÍFICOS POR MÓDULO ====================
  // Mantenemos helpers comunes para facilitar el uso

  // KANBAN
  static bool canViewKanban(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'kanban', action: 'view');

  static bool canMoveProducts(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'kanban', action: 'moveProducts');

  static bool canMoveProductInPhase({
    required OrganizationMemberModel member,
    required RoleModel role,
    required String phaseId,
  }) {
    if (!canMoveProducts(member, role)) return false;

    final scope = getScope(
      member: member,
      role: role,
      module: 'kanban',
      action: 'moveProducts',
    );

    switch (scope) {
      case PermissionScope.all:
        return true;
      case PermissionScope.assigned:
        return member.canManagePhase(phaseId);
      case PermissionScope.none:
        return false;
    }
  }

  // BATCHES
  static bool canViewBatches(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'batches', action: 'view');

  static bool canCreateBatches(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'batches', action: 'create');

  static bool canEditBatch({
    required OrganizationMemberModel member,
    required RoleModel role,
    required bool isAssignedToUser,
  }) => canEditWithScope(
        member: member,
        role: role,
        module: 'batches',
        isAssignedToUser: isAssignedToUser,
      );

  static bool canDeleteBatch({
    required OrganizationMemberModel member,
    required RoleModel role,
    required bool isAssignedToUser,
  }) => canDeleteWithScope(
        member: member,
        role: role,
        module: 'batches',
        isAssignedToUser: isAssignedToUser,
      );

  static bool canStartProduction(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'batches', action: 'startProduction');

  static bool canCompleteBatch(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'batches', action: 'completeBatch');

  // PRODUCTS
  static bool canChangeProductStatus({
    required OrganizationMemberModel member,
    required RoleModel role,
    required bool isAssignedToUser,
  }) {
    if (!can(member: member, role: role, module: 'products', action: 'changeStatus')) {
      return false;
    }

    final scope = getScope(
      member: member,
      role: role,
      module: 'products',
      action: 'changeStatus',
    );

    return _evaluateScope(scope, isAssignedToUser);
  }

  static bool canChangeProductUrgency({
    required OrganizationMemberModel member,
    required RoleModel role,
    required bool isAssignedToUser,
  }) {
    if (!can(member: member, role: role, module: 'products', action: 'changeUrgency')) {
      return false;
    }

    final scope = getScope(
      member: member,
      role: role,
      module: 'products',
      action: 'changeUrgency',
    );

    return _evaluateScope(scope, isAssignedToUser);
  }

  // PHASES
  static bool canManagePhases(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'phases', action: 'edit') ||
      can(member: member, role: role, module: 'phases', action: 'create');

  static bool canAssignPhases(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'phases', action: 'assignToMembers');

  // CLIENTS
  static bool canManageClients(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'clients', action: 'create') ||
      can(member: member, role: role, module: 'clients', action: 'edit') ||
      can(member: member, role: role, module: 'clients', action: 'delete');

  // ORGANIZATION
  static bool canManageOrganization(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'organization', action: 'manageSettings') ||
      can(member: member, role: role, module: 'organization', action: 'manageRoles');

  static bool canInviteMembers(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'organization', action: 'inviteMembers');

  static bool canRemoveMembers(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'organization', action: 'removeMembers');

  // CHAT
  static bool canViewInternalMessages(OrganizationMemberModel member, RoleModel role) =>
      can(member: member, role: role, module: 'chat', action: 'viewInternal');

  // ==================== VALIDACIÓN DE MÓDULOS Y ACCIONES ====================

  /// Verificar si un módulo existe
  static bool isValidModule(String moduleKey) {
    return PermissionRegistry.getModule(moduleKey) != null;
  }

  /// Verificar si una acción existe en un módulo
  static bool isValidAction(String moduleKey, String actionKey) {
    return PermissionRegistry.getAction(moduleKey, actionKey) != null;
  }

  /// Obtener nombre legible de un módulo
  static String getModuleDisplayName(String moduleKey) {
    return PermissionRegistry.getModule(moduleKey)?.displayName ?? moduleKey;
  }

  /// Obtener nombre legible de una acción
  static String getActionDisplayName(String moduleKey, String actionKey) {
    return PermissionRegistry.getAction(moduleKey, actionKey)?.displayName ?? actionKey;
  }

  /// Verificar si una acción tiene scope
  static bool hasScope(String moduleKey, String actionKey) {
    return PermissionRegistry.isActionScoped(moduleKey, actionKey);
  }
}