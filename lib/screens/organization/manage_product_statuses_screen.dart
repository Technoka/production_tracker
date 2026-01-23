import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_status_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/product_status_service.dart';
import '../../services/organization_member_service.dart';
import '../../l10n/app_localizations.dart';
import 'create_edit_status_dialog.dart';
import '../../widgets/status/status_preview_card.dart';

class ManageProductStatusesScreen extends StatefulWidget {
  final String organizationId;

  const ManageProductStatusesScreen({
    Key? key,
    required this.organizationId,
  }) : super(key: key);

  @override
  State<ManageProductStatusesScreen> createState() =>
      _ManageProductStatusesScreenState();
}

class _ManageProductStatusesScreenState
    extends State<ManageProductStatusesScreen> {
  bool _isReordering = false;
  List<ProductStatusModel> _statuses = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final statusService = Provider.of<ProductStatusService>(context);
    final memberService = Provider.of<OrganizationMemberService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.manageProductStatuses)),
        body: Center(child: Text(l10n.noOrganizationTitle)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageProductStatuses),
        actions: [
          // Botón para alternar modo reordenamiento
          IconButton(
            icon: Icon(_isReordering ? Icons.check : Icons.sort),
            tooltip: _isReordering ? l10n.done : l10n.reorderStatuses,
            onPressed: () {
              setState(() {
                _isReordering = !_isReordering;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductStatusModel>>(
        stream: statusService.watchStatuses(widget.organizationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.error}: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          _statuses = snapshot.data ?? [];

          if (_statuses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.label_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noStatusesFound,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createFirstStatus,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Separar estados del sistema y personalizados
          final systemStatuses =
              _statuses.where((s) => s.isSystem).toList();
          final customStatuses =
              _statuses.where((s) => !s.isSystem).toList();

          return RefreshIndicator(
            onRefresh: () async {
              // El stream se actualiza automáticamente
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Descripción
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.statusesDescription,
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Estados del sistema (no editables)
                if (systemStatuses.isNotEmpty) ...[
                  Text(
                    l10n.systemStatuses,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...systemStatuses.map((status) {
                    return _buildStatusCard(
                      status,
                      l10n,
                      memberService,
                      statusService,
                      isSystem: true,
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],

                // Estados personalizados (editables)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.customStatuses,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (_isReordering && customStatuses.isNotEmpty)
                      Text(
                        l10n.dragToReorder,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (customStatuses.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.noCustomStatuses,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else if (_isReordering)
                  _buildReorderableList(
                    customStatuses,
                    l10n,
                    memberService,
                    statusService,
                  )
                else
                  ...customStatuses.map((status) {
                    return _buildStatusCard(
                      status,
                      l10n,
                      memberService,
                      statusService,
                      isSystem: false,
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: memberService.can('organization', 'manageProductStatuses'),
        builder: (context, snapshot) {
          if (snapshot.data != true) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.createStatus),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
    ProductStatusModel status,
    AppLocalizations l10n,
    OrganizationMemberService memberService,
    ProductStatusService statusService, {
    required bool isSystem,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              _getIconData(status.icon),
              color: status.colorValue,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                status.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isSystem)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.systemStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(status.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: status.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  status.isActive ? l10n.activeStatus : l10n.inactiveStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: status.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: FutureBuilder<bool>(
                future:
                    memberService.can('organization', 'manageProductStatuses'),
                builder: (context, snapshot) {
                  if (snapshot.data != true) return const SizedBox.shrink();

                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(context, status);
                          break;
                        case 'toggle':
                          _toggleStatusActive(
                            statusService,
                            status,
                            l10n,
                          );
                          break;
                        case 'delete':
                          _confirmDelete(
                            statusService,
                            status,
                            l10n,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              status.isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              status.isActive
                                  ? l10n.deactivate
                                  : l10n.activate,
                            ),
                          ],
                        ),
                      ),
                      if (!isSystem) // Los estados del sistema no se pueden eliminar
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            Text(
                              l10n.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildReorderableList(
    List<ProductStatusModel> statuses,
    AppLocalizations l10n,
    OrganizationMemberService memberService,
    ProductStatusService statusService,
  ) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        _handleReorder(oldIndex, newIndex, statuses, statusService, l10n);
      },
      children: statuses.map((status) {
        return Card(
          key: ValueKey(status.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.drag_handle, color: Colors.grey.shade600),
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.colorValue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(_getIconData(status.icon), color: status.colorValue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Text(status.description),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleReorder(
    int oldIndex,
    int newIndex,
    List<ProductStatusModel> statuses,
    ProductStatusService statusService,
    AppLocalizations l10n,
  ) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedStatuses = List<ProductStatusModel>.from(statuses);
    final item = reorderedStatuses.removeAt(oldIndex);
    reorderedStatuses.insert(newIndex, item);

    // Crear lista de IDs en el nuevo orden
    final orderedIds = reorderedStatuses.map((s) => s.id).toList();

    final success = await statusService.reorderStatuses(
      widget.organizationId,
      orderedIds,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.statusesReordered),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorReorderingStatuses),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateEditStatusDialog(
        organizationId: widget.organizationId,
      ),
    );
  }

  void _showEditDialog(BuildContext context, ProductStatusModel status) {
    showDialog(
      context: context,
      builder: (context) => CreateEditStatusDialog(
        organizationId: widget.organizationId,
        status: status,
      ),
    );
  }

  Future<void> _toggleStatusActive(
    ProductStatusService statusService,
    ProductStatusModel status,
    AppLocalizations l10n,
  ) async {
    final success = await statusService.toggleStatusActive(
      widget.organizationId,
      status.id,
      !status.isActive,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isActive ? l10n.statusDeactivated : l10n.statusActivated,
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorUpdatingStatus),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    ProductStatusService statusService,
    ProductStatusModel status,
    AppLocalizations l10n,
  ) async {
    // Primero verificar si se puede eliminar
    final canDelete = await statusService.canDeleteStatus(
      widget.organizationId,
      status.id,
    );

    if (!mounted) return;

    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.statusInUseCannotDelete),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteStatusConfirm),
            const SizedBox(height: 16),
            StatusPreviewCard(
              name: status.name,
              description: status.description,
              color: status.colorValue,
              icon: _getIconData(status.icon),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.deleteStatusWarning,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await statusService.deleteStatus(
      widget.organizationId,
      status.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.statusDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorDeletingStatus),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getIconData(String iconName) {
    try {
      // Intentar parsear como código numérico
      final codePoint = int.tryParse(iconName);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
      // Si no es numérico, usar icono por defecto
      return Icons.label;
    } catch (e) {
      return Icons.label;
    }
  }
}