import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/permission_registry_model.dart';
import '../../models/permission_registry_client_extension.dart';

/// Widget para seleccionar permisos especiales de un cliente
///
/// Los permisos seleccionados se aplicarán como overrides a todos los miembros
/// con rol 'client' asociados a este cliente
class ClientPermissionsSelector extends StatefulWidget {
  final Map<String, dynamic> initialPermissions;
  final ValueChanged<Map<String, dynamic>>? onPermissionsChanged;
  final bool enabled;
  final bool readOnly; // Nuevo: modo solo lectura

  const ClientPermissionsSelector({
    super.key,
    required this.initialPermissions,
    this.onPermissionsChanged,
    this.enabled = true,
    this.readOnly = false,
  });

  @override
  State<ClientPermissionsSelector> createState() =>
      _ClientPermissionsSelectorState();
}

class _ClientPermissionsSelectorState extends State<ClientPermissionsSelector> {
  late Map<String, dynamic> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = Map.from(widget.initialPermissions);
  }

  void _updatePermission(String key, dynamic value) {
    if (!widget.enabled || widget.readOnly) return;

    setState(() {
      if (value == null || value == false || value == 'none') {
        _permissions.remove(key);
      } else {
        _permissions[key] = value;
      }
    });

    widget.onPermissionsChanged?.call(_permissions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final applicablePermissions =
        PermissionRegistryClientExtension.getClientApplicablePermissions();

    if (applicablePermissions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.noSpecialPermissions,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Agrupar por módulo
    final grouped = <String, List<ClientApplicablePermission>>{};
    for (final permission in applicablePermissions) {
      if (!grouped.containsKey(permission.moduleKey)) {
        grouped[permission.moduleKey] = [];
      }
      grouped[permission.moduleKey]!.add(permission);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descripción
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.clientPermissionsDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lista de permisos por módulo
        ...grouped.entries.map((entry) {
          final moduleKey = entry.key;
          final permissions = entry.value;
          final module = PermissionRegistry.getModule(moduleKey);

          return _buildModuleSection(
            context,
            moduleDisplayName: module?.displayName ?? moduleKey,
            permissions: permissions,
          );
        }),
      ],
    );
  }

  Widget _buildModuleSection(
    BuildContext context, {
    required String moduleDisplayName,
    required List<ClientApplicablePermission> permissions,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del módulo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  moduleDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Permisos del módulo
            ...permissions.map((permission) {
              return _buildPermissionTile(context, permission);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context,
    ClientApplicablePermission permission,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final key = permission.fullKey;

    // Determinar si está habilitado
    final currentValue = _permissions[key];
    final isEnabled =
        currentValue != null && currentValue != false && currentValue != 'none';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Switch o Dropdown según el tipo
          if (permission.usesScope)
            _buildScopedPermissionRow(
              context,
              permission: permission,
              currentValue: currentValue?.toString() ?? 'none',
            )
          else
            _buildBooleanPermissionRow(
              context,
              permission: permission,
              isEnabled: isEnabled,
            ),

          // Nota adicional si existe
          if (permission.note != null && !widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      permission.note!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Nota de aprobación si aplica
          if (isEnabled && permission.requiresApproval && !widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 12,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.requiresApprovalNote,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBooleanPermissionRow(
    BuildContext context, {
    required ClientApplicablePermission permission,
    required bool isEnabled,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: isEnabled,
      onChanged: (widget.enabled && !widget.readOnly)
          ? (value) => _updatePermission(permission.fullKey, value)
          : null,
      title: Text(
        permission.displayName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        permission.description,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildScopedPermissionRow(
    BuildContext context, {
    required ClientApplicablePermission permission,
    required String currentValue,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          permission.displayName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          permission.description,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentValue,
              items: [
                DropdownMenuItem(
                  value: 'none',
                  child: Text(l10n.scopeNone,
                      style: const TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'assigned',
                  child: Text(l10n.scopeAssigned,
                      style: const TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'all',
                  child:
                      Text(l10n.scopeAll, style: const TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (widget.enabled && !widget.readOnly)
                  ? (value) {
                      if (value != null) {
                        _updatePermission(permission.fullKey, value);
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Resumen compacto de permisos habilitados
class ClientPermissionsSummary extends StatelessWidget {
  final Map<String, dynamic> permissions;
  final VoidCallback? onTap;

  const ClientPermissionsSummary({
    super.key,
    required this.permissions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final applicablePermissions =
        PermissionRegistryClientExtension.getClientApplicablePermissions();

    final enabledPermissions = applicablePermissions.where((p) {
      final key = p.fullKey;
      final value = permissions[key];
      return value != null && value != false && value != 'none';
    }).toList();

    final count = enabledPermissions.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: count > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                count > 0 ? Icons.verified_user : Icons.shield_outlined,
                size: 20,
                color: count > 0 ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clientSpecialPermissions,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? l10n.noSpecialPermissions
                        : l10n.permissionsCount(count),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
