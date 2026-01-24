import 'package:flutter/material.dart';
import 'package:gestion_produccion/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../models/status_transition_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/organization_member_model.dart';
import '../../services/organization_member_service.dart';
import '../../l10n/app_localizations.dart';

class MultiApprovalDialog extends StatefulWidget {
  final StatusTransitionModel transition;
  final BatchProductModel product;

  const MultiApprovalDialog({
    Key? key,
    required this.transition,
    required this.product,
  }) : super(key: key);

  @override
  State<MultiApprovalDialog> createState() => _MultiApprovalDialogState();
}

class _MultiApprovalDialogState extends State<MultiApprovalDialog> {
  final Set<String> _selectedApprovers = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final memberService = Provider.of<OrganizationMemberService>(context);
    final config = widget.transition.validationConfig;
    final minApprovals = config.minApprovals ?? 1;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.people,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.multiApprovalRequired)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info del producto
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(widget.transition.fromStatusName,
                          style: const TextStyle(fontSize: 12)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 14),
                      ),
                      Text(
                        widget.transition.toStatusName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Requisitos
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.minApprovalsRequired}: $minApprovals',
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

            // Lista de posibles aprobadores
            Text(
              l10n.selectApprovers,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Flexible(
              child: FutureBuilder<List<OrganizationMemberWithUser>>(
                future: memberService.getMembers(
                  user.organizationId!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('${l10n.error}: ${snapshot.error}'),
                    );
                  }

                  final members = snapshot.data ?? [];
                  
                  // Filtrar solo miembros con roles permitidos para aprobar
                  final eligibleMembers = members.where((member) {
                    return widget.transition.allowedRoles.contains(member.roleId);
                  }).toList();

                  if (eligibleMembers.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noEligibleApprovers,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: eligibleMembers.length,
                    itemBuilder: (context, index) {
                      final member = eligibleMembers[index];
                      final isSelected = _selectedApprovers.contains(member.userId);

                      return CheckboxListTile(
                        title: Text(member.userName),
                        subtitle: Text(
                          member.roleName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          child: Text(
                            (member.userName)[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedApprovers.add(member.userId);
                            } else {
                              _selectedApprovers.remove(member.userId);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Contador de aprobadores seleccionados
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_selectedApprovers.length} / $minApprovals',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedApprovers.length >= minApprovals
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.approversSelected,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _canSubmit() ? _handleSubmit : null,
          icon: const Icon(Icons.check),
          label: Text(l10n.confirm),
        ),
      ],
    );
  }

  bool _canSubmit() {
    final minApprovals = widget.transition.validationConfig.minApprovals ?? 1;
    return _selectedApprovers.length >= minApprovals;
  }

  void _handleSubmit() {
    if (!_canSubmit()) return;

    final validationData = ValidationDataModel(
      approvedBy: _selectedApprovers.toList(),
      timestamp: DateTime.now(),
    );

    Navigator.pop(context, validationData);
  }
}