import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/status_transition_model.dart';
import '../../models/product_status_model.dart';
import '../../services/auth_service.dart';
import '../../services/status_transition_service.dart';
import '../../services/product_status_service.dart';
import '../../services/organization_member_service.dart';
import '../../l10n/app_localizations.dart';
import 'create_edit_transition_dialog.dart';
import '../../widgets/transitions/transition_list_item.dart';

class ManageStatusTransitionsScreen extends StatefulWidget {
  final String organizationId;

  const ManageStatusTransitionsScreen({
    Key? key,
    required this.organizationId,
  }) : super(key: key);

  @override
  State<ManageStatusTransitionsScreen> createState() =>
      _ManageStatusTransitionsScreenState();
}

class _ManageStatusTransitionsScreenState
    extends State<ManageStatusTransitionsScreen> {
  String? _filterByFromStatus;
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final transitionService = Provider.of<StatusTransitionService>(context);
    final statusService = Provider.of<ProductStatusService>(context);
    final memberService = Provider.of<OrganizationMemberService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.manageStatusTransitions)),
        body: Center(child: Text(l10n.noOrganizationTitle)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageStatusTransitions),
        actions: [
          // Toggle mostrar inactivos
          IconButton(
            icon: Icon(
              _showInactive ? Icons.visibility : Icons.visibility_off,
              color: _showInactive ? Colors.amber : null,
            ),
            tooltip: _showInactive
                ? l10n.hideInactiveTransitions
                : l10n.showInactiveTransitions,
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltersSection(l10n, statusService),

          // Lista de transiciones
          Expanded(
            child: StreamBuilder<List<StatusTransitionModel>>(
              stream: transitionService.watchTransitions(widget.organizationId),
              builder: (context, transitionSnapshot) {
                if (transitionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (transitionSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.error}: ${transitionSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                var transitions = transitionSnapshot.data ?? [];

                // Aplicar filtro de estado origen
                if (_filterByFromStatus != null) {
                  transitions = transitions
                      .where((t) => t.fromStatusId == _filterByFromStatus)
                      .toList();
                }

                // Aplicar filtro de activos/inactivos
                if (!_showInactive) {
                  transitions =
                      transitions.where((t) => t.isActive).toList();
                }

                if (transitions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _filterByFromStatus != null
                              ? l10n.noTransitionsForStatus
                              : l10n.noTransitionsFound,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.createFirstTransition,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transitions.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<bool>(
                        future: memberService.can(
                            'organization', 'manageStatusTransitions'),
                        builder: (context, permSnapshot) {
                          final canManage = permSnapshot.data ?? false;

                          return TransitionListItem(
                            transition: transitions[index],
                            organizationId: widget.organizationId,
                            canEdit: canManage,
                            onEdit: () =>
                                _showEditDialog(context, transitions[index]),
                            onDelete: () => _confirmDelete(
                              context,
                              transitionService,
                              transitions[index],
                              l10n,
                            ),
                            onToggleActive: () => _toggleTransitionActive(
                              context,
                              transitionService,
                              transitions[index],
                              l10n,
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: memberService.can('organization', 'manageStatusTransitions'),
        builder: (context, snapshot) {
          if (snapshot.data != true) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.createTransition),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection(
    AppLocalizations l10n,
    ProductStatusService statusService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.transitionsDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtro por estado origen
          StreamBuilder<List<ProductStatusModel>>(
            stream: statusService.watchActiveStatuses(widget.organizationId),
            builder: (context, snapshot) {
              final statuses = snapshot.data ?? [];

              return Row(
                children: [
                  Icon(Icons.filter_alt, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _filterByFromStatus,
                      decoration: InputDecoration(
                        labelText: l10n.filterByFromStatus,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.allStatuses),
                        ),
                        ...statuses.map((status) {
                          return DropdownMenuItem<String?>(
                            value: status.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: status.colorValue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterByFromStatus = value;
                        });
                      },
                    ),
                  ),
                  if (_filterByFromStatus != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.clearFilter,
                      onPressed: () {
                        setState(() {
                          _filterByFromStatus = null;
                        });
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateEditTransitionDialog(
        organizationId: widget.organizationId,
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, StatusTransitionModel transition) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateEditTransitionDialog(
        organizationId: widget.organizationId,
        transition: transition,
      ),
    );
  }

  Future<void> _toggleTransitionActive(
    BuildContext context,
    StatusTransitionService transitionService,
    StatusTransitionModel transition,
    AppLocalizations l10n,
  ) async {
    final success = await transitionService.updateTransition(
      organizationId: widget.organizationId,
      transitionId: transition.id,
      isActive: !transition.isActive,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transition.isActive
                ? l10n.transitionDeactivated
                : l10n.transitionActivated,
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorUpdatingTransition),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StatusTransitionService transitionService,
    StatusTransitionModel transition,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTransition),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteTransitionConfirm),
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${transition.fromStatusName} → ${transition.toStatusName}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.deleteTransitionWarning,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    final success = await transitionService.deleteTransition(
      widget.organizationId,
      transition.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transitionDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorDeletingTransition),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}