import 'package:flutter/material.dart';
import '../models/user_model.dart';

class RoleUtils {
  // Obtener todos los roles disponibles
  static List<UserRole> getAllRoles() {
    return UserRole.values;
  }

  // Obtener roles disponibles para registro (excluye admin)
  static List<UserRole> getRegistrationRoles() {
    return [
      UserRole.client,
      UserRole.manufacturer,
      UserRole.operator,
      UserRole.accountant,
    ];
  }

  // Obtener roles que solo admin puede asignar
  static List<UserRole> getAdminOnlyRoles() {
    return [
      UserRole.admin,
      UserRole.productionManager,
    ];
  }

  // Obtener icono para cada rol
  static IconData getRoleIcon(String roleValue) {
    final role = UserRole.fromString(roleValue);
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.productionManager:
        return Icons.engineering;
      case UserRole.operator:
        return Icons.precision_manufacturing;
      case UserRole.accountant:
        return Icons.account_balance;
      case UserRole.client:
        return Icons.person;
      case UserRole.manufacturer:
        return Icons.factory;
    }
  }

  // Obtener color para cada rol
  static Color getRoleColor(String roleValue) {
    final role = UserRole.fromString(roleValue);
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.productionManager:
        return Colors.blue;
      case UserRole.operator:
        return Colors.green;
      case UserRole.accountant:
        return Colors.orange;
      case UserRole.client:
        return Colors.purple;
      case UserRole.manufacturer:
        return Colors.indigo;
    }
  }

  // Obtener descripción del rol
  static String getRoleDescription(String roleValue) {
    final role = UserRole.fromString(roleValue);
    switch (role) {
      case UserRole.admin:
        return 'Acceso completo al sistema, gestión de usuarios y configuración';
      case UserRole.productionManager:
        return 'Gestión de producción, proyectos y supervisión de operarios';
      case UserRole.operator:
        return 'Operación de máquinas y registro de procesos productivos';
      case UserRole.accountant:
        return 'Acceso a información financiera, costos y reportes contables';
      case UserRole.client:
        return 'Visualización del estado de sus productos y proyectos';
      case UserRole.manufacturer:
        return 'Gestión completa de producción y proyectos';
    }
  }

  // Verificar si un usuario puede realizar una acción específica
  static bool canPerformAction(UserModel user, String action) {
    switch (action) {
      case 'create_project':
        return user.canManageProduction;
      case 'edit_project':
        return user.canManageProduction;
      case 'delete_project':
        return user.hasAdminAccess;
      case 'create_product':
        return user.canManageProduction;
      case 'edit_product':
        return user.canOperate;
      case 'delete_product':
        return user.hasAdminAccess;
      case 'view_financials':
        return user.canViewFinancials;
      case 'manage_users':
        return user.hasAdminAccess;
      case 'update_stage':
        return user.canOperate;
      case 'view_reports':
        return user.canManageProduction || user.canViewFinancials;
      default:
        return false;
    }
  }

  // Widget para mostrar badge de rol
  static Widget buildRoleBadge(String roleValue, {bool compact = false}) {
    final role = UserRole.fromString(roleValue);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: getRoleColor(roleValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getRoleColor(roleValue).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getRoleIcon(roleValue),
            size: compact ? 14 : 16,
            color: getRoleColor(roleValue),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            role.displayName,
            style: TextStyle(
              color: getRoleColor(roleValue),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para selector de roles
class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;
  final List<UserRole>? availableRoles;
  final bool showDescriptions;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.availableRoles,
    this.showDescriptions = true,
  });

  @override
  Widget build(BuildContext context) {
    final roles = availableRoles ?? RoleUtils.getRegistrationRoles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de cuenta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: roles.asMap().entries.map((entry) {
              final index = entry.key;
              final role = entry.value;
              final isSelected = selectedRole == role.value;

              return Column(
                children: [
                  if (index > 0) const Divider(height: 1),
                  RadioListTile<String>(
                    value: role.value,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      if (value != null) onRoleChanged(value);
                    },
                    title: Row(
                      children: [
                        Icon(
                          RoleUtils.getRoleIcon(role.value),
                          size: 20,
                          color: isSelected
                              ? RoleUtils.getRoleColor(role.value)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          role.displayName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: showDescriptions
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4, left: 28),
                            child: Text(
                              RoleUtils.getRoleDescription(role.value),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}