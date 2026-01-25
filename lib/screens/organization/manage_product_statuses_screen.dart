import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_status_model.dart';
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

                // Banner de reordenamiento
                if (_isReordering)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.drag_handle, color: Colors.orange.shade800),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.reorderingStatusesMessage,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Todos los estados juntos
                if (_isReordering)
                  _buildReorderableList(
                    _statuses,
                    l10n,
                    memberService,
                    statusService,
                  )
                else
                  ..._statuses.map((status) {
                    return _buildStatusCard(
                      status,
                      l10n,
                      memberService,
                      statusService,
                    );
                  }).toList(),
                  
                const SizedBox(height: 100),
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
    ProductStatusService statusService,
  ) {
    // Color más oscuro para estados inactivos
    final cardColor = status.isActive 
        ? null 
        : Colors.grey.shade300;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              _getIconData(status.icon),
              color: status.isActive ? status.colorValue : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            // Color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: status.isActive ? status.colorValue : Colors.grey.shade600,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                status.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status.isActive ? null : Colors.grey.shade700,
                ),
              ),
            ),
            // Badge de sistema
            if (status.isSystem)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Text(
                  'SYSTEM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            // Badge de inactivo
            if (!status.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: Text(
                  'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status.description,
              style: TextStyle(
                color: status.isActive ? null : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Order: ${status.order}',
              style: TextStyle(
                fontSize: 11,
                color: status.isActive ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: FutureBuilder<bool>(
          future: memberService.can('organization', 'manageProductStatuses'),
          builder: (context, snapshot) {
            if (snapshot.data != true) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    if (status.isActive) {
                      _showEditDialog(context, status);
                    }
                    break;
                  case 'toggle':
                    _toggleStatusActive(statusService, status, l10n);
                    break;
                  case 'delete':
                    if (!status.isSystem) {
                      _confirmDelete(statusService, status, l10n);
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                    if (status.isActive)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
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
                      const SizedBox(width: 8),
                      Text(
                        status.isActive
                            ? l10n.deactivate
                            : l10n.activate,
                      ),
                    ],
                  ),
                ),
                if (!status.isSystem)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
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
        // Color más oscuro para estados inactivos en modo reordenamiento
        final cardColor = status.isActive 
            ? null 
            : Colors.grey.shade300;
            
        return Card(
          key: ValueKey(status.id),
          margin: const EdgeInsets.only(bottom: 8),
          color: cardColor,
          child: ListTile(
            leading: Icon(Icons.drag_handle, color: Colors.grey.shade600),
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.isActive ? status.colorValue : Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  _getIconData(status.icon), 
                  color: status.isActive ? status.colorValue : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: status.isActive ? null : Colors.grey.shade700,
                    ),
                  ),
                ),
                // Badge de sistema
                if (status.isSystem)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      'SYSTEM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                // Badge de inactivo
                if (!status.isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade600),
                    ),
                    child: Text(
                      'INACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              status.description,
              style: TextStyle(
                color: status.isActive ? null : Colors.grey.shade600,
              ),
            ),
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