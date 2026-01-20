import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/organization_member_model.dart';
import '../../models/role_model.dart';
import '../../models/permission_model.dart';
import '../../models/permission_override_model.dart';
import '../../models/permission_registry_model.dart';
import '../../services/permission_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/organization_member_service.dart';

/// Pantalla de gestiÃƒÂ³n de permisos de un miembro especÃƒÂ­fico
/// Permite visualizar y editar permisos individuales con overrides sobre el rol base
class MemberPermissionsScreen extends StatefulWidget {
  final OrganizationMemberWithUser memberData;
  final String organizationId;

  const MemberPermissionsScreen({
    Key? key,
    required this.memberData,
    required this.organizationId,
  }) : super(key: key);

  @override
  State<MemberPermissionsScreen> createState() =>
      _MemberPermissionsScreenState();
}

class _MemberPermissionsScreenState extends State<MemberPermissionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  RoleModel? _memberRole;
  PermissionsModel? _roleBasePermissions;
  PermissionOverridesModel _currentOverrides = PermissionOverridesModel.empty();
  PermissionOverridesModel _pendingOverrides = PermissionOverridesModel.empty();

  bool _hasChanges = false;
  bool _isViewingOwnPermissions = false;
  bool _isAdminOrOwner = false;

  @override
  void initState() {
    super.initState();

    // Determinar si está viendo sus propios permisos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUserData?.uid;
      final permissionService =
          Provider.of<PermissionService>(context, listen: false);

      setState(() {
        _isViewingOwnPermissions = widget.memberData.userId == currentUserId;
        _isAdminOrOwner =
            permissionService.hasPermission('organization', 'manageRoles');
      });
    });

    _loadPermissionsData();
  }

  /// Cargar datos del rol y permisos actuales
  Future<void> _loadPermissionsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Cargar el rol del miembro
      final roleDoc = await _firestore
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('roles')
          .doc(widget.memberData.member.roleId)
          .get();

      if (!roleDoc.exists) {
        throw Exception('Rol no encontrado');
      }

      final roleData = roleDoc.data();

      if (roleData == null) {
        throw Exception('Datos del rol vaci­os');
      }

      // Validar campos crÃ­ticos antes del casting
      if (roleData['name'] == null) {
        debugPrint('ERROR: Campo "name" es null en roleData');
        throw Exception('El rol no tiene nombre definido');
      }

      if (roleData['color'] == null) {
        debugPrint('ERROR: Campo "color" es null en roleData');
        throw Exception('El rol no tiene color definido');
      }

      if (roleData['icon'] == null) {
        debugPrint('ERROR: Campo "icon" es null en roleData');
        throw Exception('El rol no tiene icono definido');
      }

      if (roleData['organizationId'] == null) {
        debugPrint('ERROR: Campo "organizationId" es null en roleData');
        throw Exception('El rol no tiene organizationId definido');
      }

      if (roleData['createdBy'] == null) {
        debugPrint('ERROR: Campo "createdBy" es null en roleData');
        throw Exception('El rol no tiene createdBy definido');
      }

      final role = RoleModel.fromMap(roleData, docId: roleDoc.id);

      // 2. Obtener overrides actuales del miembro
      final memberDoc = await _firestore
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('members')
          .doc(widget.memberData.userId)
          .get();

      PermissionOverridesModel currentOverrides =
          PermissionOverridesModel.empty();

      if (memberDoc.exists &&
          memberDoc.data()?['permissionOverrides'] != null) {
        try {
          currentOverrides = PermissionOverridesModel.fromMap(
            memberDoc.data()!['permissionOverrides'] as Map<String, dynamic>,
          );
        } catch (e) {
          debugPrint('Error parseando overrides: $e');
          // Continuar sin overrides si hay error
        }
      }

      setState(() {
        _memberRole = role;
        _roleBasePermissions = role.permissions;
        _currentOverrides = currentOverrides;
        _pendingOverrides =
            PermissionOverridesModel.fromMap(currentOverrides.toMap());
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('=== ERROR CARGANDO PERMISOS ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      setState(() {
        _errorMessage = 'Error al cargar los permisos del usuario: $e';
        _isLoading = false;
      });
    }
  }

  /// Guardar cambios en Firebase
  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUserData?.uid;

      if (currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Actualizar overrides en Firebase
      await _firestore
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('members')
          .doc(widget.memberData.userId)
          .update({
        'permissionOverrides': _pendingOverrides.isEmpty
            ? FieldValue.delete()
            : _pendingOverrides.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentOverrides =
            PermissionOverridesModel.fromMap(_pendingOverrides.toMap());
        _hasChanges = false;
      });

      // ✅ AÑADIDO: Forzar recarga de permisos
      // ✅ AÑADIDO: Forzar recarga de permisos
      try {
        // Si estás editando tus propios permisos, recargar
        if (widget.memberData.userId == currentUserId) {
          final memberService =
              Provider.of<OrganizationMemberService>(context, listen: false);
          await memberService.refreshCurrentMember(
              widget.organizationId, currentUserId); // ✅ Pasar userId
        }
      } catch (refreshError) {
        debugPrint('Error al refrescar permisos: $refreshError');
        // No fallar si no se puede refrescar, los cambios ya están guardados
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.permissionsSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando permisos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Alternar un permiso boolean
  void _toggleBooleanPermission(
      String moduleKey, String actionKey, bool newValue) {
    // Bloquear edición si es modo solo lectura
    if (_isViewingOwnPermissions && !_isAdminOrOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.readOnlyMode),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Proteger permisos de organización cuando el usuario ve los suyos propios
    if (_isViewingOwnPermissions && moduleKey == 'organization') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.cannotModifyOrgPermissions),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUserData?.uid ?? '';

    // Obtener valor base del rol
    final baseValue =
        _roleBasePermissions?.dynamicHelper.can(moduleKey, actionKey) ?? false;

    // Si el nuevo valor es igual al base, eliminar el override
    if (newValue == baseValue) {
      setState(() {
        _pendingOverrides =
            _pendingOverrides.removeOverride(moduleKey, actionKey);
        _hasChanges = true;
      });
    } else {
      // Crear override según el nuevo valor
      final override = newValue
          ? PermissionOverridesModel.createEnableOverride(
              moduleKey: moduleKey,
              actionKey: actionKey,
              createdBy: currentUserId,
            )
          : PermissionOverridesModel.createDisableOverride(
              moduleKey: moduleKey,
              actionKey: actionKey,
              createdBy: currentUserId,
            );

      setState(() {
        _pendingOverrides = _pendingOverrides.addOverride(override);
        _hasChanges = true;
      });
    }
  }

  /// Cambiar scope de un permiso
  void _changeScopePermission(
      String moduleKey, String actionKey, PermissionScope newScope) {
    // Bloquear edición si es modo solo lectura
    if (_isViewingOwnPermissions && !_isAdminOrOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.readOnlyMode),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Proteger permisos de organización cuando el usuario ve los suyos propios
    if (_isViewingOwnPermissions && moduleKey == 'organization') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.cannotModifyOrgPermissions),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUserData?.uid ?? '';

    // Obtener scope base del rol
    final baseScope =
        _roleBasePermissions?.dynamicHelper.getScope(moduleKey, actionKey) ??
            PermissionScope.none;

    // Si el nuevo scope es igual al base, eliminar el override
    if (newScope == baseScope) {
      setState(() {
        _pendingOverrides =
            _pendingOverrides.removeOverride(moduleKey, actionKey);
        _hasChanges = true;
      });
    } else {
      // Crear override de scope
      final override = PermissionOverridesModel.createScopeOverride(
        moduleKey: moduleKey,
        actionKey: actionKey,
        newScope: newScope,
        createdBy: currentUserId,
      );

      setState(() {
        _pendingOverrides = _pendingOverrides.addOverride(override);
        _hasChanges = true;
      });
    }
  }

  /// Obtener el valor efectivo de un permiso booleano
  bool _getEffectiveBooleanValue(String moduleKey, String actionKey) {
    // 1. Verificar si hay override pendiente (cambios sin guardar)
    final pendingOverride = _pendingOverrides.getOverride(moduleKey, actionKey);
    if (pendingOverride != null &&
        pendingOverride.type != OverrideType.changeScope) {
      return pendingOverride.value as bool? ?? false;
    }

    // 2. Verificar si hay override guardado (ya en Firebase)
    final currentOverride = _currentOverrides.getOverride(moduleKey, actionKey);
    if (currentOverride != null &&
        currentOverride.type != OverrideType.changeScope) {
      return currentOverride.value as bool? ?? false;
    }

    // 3. Usar valor base del rol
    return _roleBasePermissions?.dynamicHelper.can(moduleKey, actionKey) ??
        false;
  }

  /// Obtener el scope efectivo de un permiso
  PermissionScope _getEffectiveScope(String moduleKey, String actionKey) {
    // 1. Verificar si hay override pendiente (cambios sin guardar)
    final pendingOverride = _pendingOverrides.getOverride(moduleKey, actionKey);
    if (pendingOverride != null &&
        pendingOverride.type == OverrideType.changeScope) {
      return pendingOverride.value as PermissionScope? ?? PermissionScope.none;
    }

    // 2. Verificar si hay override guardado (ya en Firebase)
    final currentOverride = _currentOverrides.getOverride(moduleKey, actionKey);
    if (currentOverride != null &&
        currentOverride.type == OverrideType.changeScope) {
      return currentOverride.value as PermissionScope? ?? PermissionScope.none;
    }

    // 3. Usar scope base del rol
    return _roleBasePermissions?.dynamicHelper.getScope(moduleKey, actionKey) ??
        PermissionScope.none;
  }

  /// Verificar si un permiso tiene override
  bool _hasOverride(String moduleKey, String actionKey) {
    return _pendingOverrides.hasOverride(moduleKey, actionKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.unsavedChanges),
              content: Text(l10n.unsavedChangesMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.discard),
                ),
              ],
            ),
          );
          return shouldDiscard ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.managePermissions),
              Text(
                widget.memberData.userName,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        bottomNavigationBar: _hasChanges
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveChanges,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      l10n.save,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? RefreshIndicator(
                    onRefresh: _loadPermissionsData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadPermissionsData,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPermissionsData,
                    child: Column(
                      children: [
                        // Banner informativo para modo solo lectura
                        if (_isViewingOwnPermissions && !_isAdminOrOwner)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.orange.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.viewingOwnPermissions,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.viewingOwnPermissionsDesc,
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Header con información del rol
                        _buildRoleHeader(themeProvider),

                        // Lista de permisos
                        Expanded(
                          child: _buildPermissionsList(),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Widget del header con informaciÃƒÂ³n del rol base
  Widget _buildRoleHeader(ThemeProvider themeProvider) {
    if (_memberRole == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final roleColor = _memberRole!.colorValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor,
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.baseRole}: ${_memberRole!.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_memberRole!.description.isNotEmpty)
                  Text(
                    _memberRole!.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (_pendingOverrides.isNotEmpty)
            Chip(
              label: Text('${_pendingOverrides.count} ${l10n.customizations}'),
              backgroundColor: Colors.orange.withOpacity(0.2),
              labelStyle: TextStyle(
                color: Colors.orange[800],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  /// Lista de permisos organizados por categorÃƒÂ­a
  Widget _buildPermissionsList() {
    final categories = PermissionRegistry.modulesByCategory;

    return ListView(
      children: categories.entries.map((entry) {
        final categoryName = entry.key.capitalize;
        final modules = entry.value;

        return ExpansionTile(
          title: Text(
            categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          initiallyExpanded: true,
          children: modules.map((module) {
            return _buildModuleCard(module);
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Card de un mÃƒÂ³dulo con sus permisos
  Widget _buildModuleCard(PermissionModule module) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          _getIconData(module.icon),
          color: theme.primaryColor,
        ),
        title: Text(
          module.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: module.description != null
            ? Text(
                module.description!,
                style: const TextStyle(fontSize: 12),
              )
            : null,
        children: module.actions.map((action) {
          return _buildPermissionTile(module.key, action);
        }).toList(),
      ),
    );
  }

  /// Tile de un permiso individual
  Widget _buildPermissionTile(String moduleKey, PermissionAction action) {
    final hasOverride = _hasOverride(moduleKey, action.key);

    // Valores base del rol
    final baseValue = action.type == PermissionActionType.boolean
        ? _roleBasePermissions?.dynamicHelper.can(moduleKey, action.key) ??
            false
        : null;
    final baseScope = action.type == PermissionActionType.scoped
        ? _roleBasePermissions?.dynamicHelper.getScope(moduleKey, action.key) ??
            PermissionScope.none
        : null;

    // Valores efectivos (con overrides aplicados)
    final effectiveValue = action.type == PermissionActionType.boolean
        ? _getEffectiveBooleanValue(moduleKey, action.key)
        : null;
    final effectiveScope = action.type == PermissionActionType.scoped
        ? _getEffectiveScope(moduleKey, action.key)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: hasOverride ? Colors.orange.withOpacity(0.05) : null,
        border: hasOverride
            ? const Border(
                left: BorderSide(
                  color: Colors.orange,
                  width: 3,
                ),
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                action.displayName,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (hasOverride)
              const Icon(
                Icons.edit,
                size: 16,
                color: Colors.orange,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (action.description != null)
              Text(
                action.description!,
                style: const TextStyle(fontSize: 11),
              ),
            if (hasOverride)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildOverrideIndicator(
                  action.type,
                  baseValue,
                  effectiveValue,
                  baseScope,
                  effectiveScope,
                ),
              ),
          ],
        ),
        trailing: action.type == PermissionActionType.boolean
            ? _buildBooleanControl(moduleKey, action.key, effectiveValue!)
            : _buildScopeControl(moduleKey, action.key, effectiveScope!),
      ),
    );
  }

  /// Indicador visual de cambio respecto al rol base
  Widget _buildOverrideIndicator(
    PermissionActionType type,
    bool? baseValue,
    bool? effectiveValue,
    PermissionScope? baseScope,
    PermissionScope? effectiveScope,
  ) {
    final l10n = AppLocalizations.of(context)!;

    String text = '';
    Color color = Colors.orange;

    if (type == PermissionActionType.boolean) {
      if (baseValue == true && effectiveValue == false) {
        text = l10n.roleAllowsButUserDenied;
        color = Colors.red;
      } else if (baseValue == false && effectiveValue == true) {
        text = l10n.roleDeniesButUserAllowed;
        color = Colors.green;
      }
    } else if (type == PermissionActionType.scoped) {
      text =
          '${l10n.roleScope}: ${_getScopeDisplayName(baseScope!)} ${_getScopeDisplayName(effectiveScope!)}';

      if (_isScopeUpgrade(baseScope, effectiveScope)) {
        color = Colors.green;
      } else if (_isScopeDowngrade(baseScope, effectiveScope)) {
        color = Colors.red;
      }
    }

    return Row(
      children: [
        Icon(Icons.info_outline, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Control para permisos booleanos
  Widget _buildBooleanControl(
      String moduleKey, String actionKey, bool currentValue) {
    return Switch(
      value: currentValue,
      onChanged: (value) =>
          _toggleBooleanPermission(moduleKey, actionKey, value),
      activeColor: Colors.green,
    );
  }

  /// Control para permisos con scope
  Widget _buildScopeControl(
      String moduleKey, String actionKey, PermissionScope currentScope) {
    return DropdownButton<PermissionScope>(
      value: currentScope,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: PermissionScope.values.map((scope) {
        return DropdownMenuItem<PermissionScope>(
          value: scope,
          child: Text(
            _getScopeDisplayName(scope),
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: (newScope) {
        if (newScope != null) {
          _changeScopePermission(moduleKey, actionKey, newScope);
        }
      },
    );
  }

  /// Obtener nombre display del scope
  String _getScopeDisplayName(PermissionScope scope) {
    final l10n = AppLocalizations.of(context)!;
    switch (scope) {
      case PermissionScope.none:
        return l10n.scopeNone;
      case PermissionScope.assigned:
        return l10n.scopeAssigned;
      case PermissionScope.all:
        return l10n.scopeAll;
    }
  }

  /// Verificar si un cambio de scope es una mejora
  bool _isScopeUpgrade(PermissionScope base, PermissionScope effective) {
    if (base == PermissionScope.none && effective != PermissionScope.none)
      return true;
    if (base == PermissionScope.assigned && effective == PermissionScope.all)
      return true;
    return false;
  }

  /// Verificar si un cambio de scope es una restricciÃƒÂ³n
  bool _isScopeDowngrade(PermissionScope base, PermissionScope effective) {
    if (base == PermissionScope.all && effective != PermissionScope.all)
      return true;
    if (base == PermissionScope.assigned && effective == PermissionScope.none)
      return true;
    return false;
  }

  /// Helper para convertir string de icono a IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'view_kanban':
        return Icons.view_kanban;
      case 'linear_scale':
        return Icons.linear_scale;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'category':
        return Icons.category;
      case 'folder':
        return Icons.folder;
      case 'people':
        return Icons.people;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'chat':
        return Icons.chat;
      case 'business':
        return Icons.business;
      case 'assessment':
        return Icons.assessment;
      default:
        return Icons.settings;
    }
  }
}
