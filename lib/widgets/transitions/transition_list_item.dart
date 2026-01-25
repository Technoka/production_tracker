import 'package:flutter/material.dart';
import '../../models/status_transition_model.dart';
import '../../models/validation_config_model.dart';
import '../../l10n/app_localizations.dart';

class TransitionListItem extends StatefulWidget {
  final StatusTransitionModel transition;
  final String organizationId;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  const TransitionListItem({
    Key? key,
    required this.transition,
    required this.organizationId,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
  }) : super(key: key);

  @override
  State<TransitionListItem> createState() => _TransitionListItemState();
}

class _TransitionListItemState extends State<TransitionListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transition = widget.transition;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: _isExpanded ? 4 : 1,
      child: Column(
        children: [
          // Vista compacta
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icono expandir/contraer
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),

                  // Transición
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                transition.fromStatusName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                transition.toStatusName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Badge de tipo de validación
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: transition.validationType.color
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: transition.validationType.color,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    transition.validationType.icon,
                                    size: 12,
                                    color: transition.validationType.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    transition.validationType.displayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: transition.validationType.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Badge de lógica condicional
                            if (transition.hasConditionalLogic)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.rule,
                                      size: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.conditionalLogic,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Estado activo/inactivo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: transition.isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: transition.isActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transition.isActive ? l10n.active : l10n.inactive,
                          style: TextStyle(
                            fontSize: 11,
                            color: transition.isActive
                                ? Colors.green.shade900
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menú de acciones
                  if (widget.canEdit)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            widget.onEdit?.call();
                            break;
                          case 'toggle':
                            widget.onToggleActive?.call();
                            break;
                          case 'delete':
                            widget.onDelete?.call();
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
                                transition.isActive
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                transition.isActive
                                    ? l10n.deactivate
                                    : l10n.activate,
                              ),
                            ],
                          ),
                        ),
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
                    ),
                ],
              ),
            ),
          ),

          // Vista expandida
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Roles permitidos
                  _buildDetailSection(
                    l10n.allowedRoles,
                    Icons.people,
                    Colors.blue,
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: transition.allowedRoles.map((roleId) {
                        return Chip(
                          label: Text(
                            _getRoleDisplayName(roleId),
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Configuración de validación
                  if (transition.validationType != ValidationType.simpleApproval)
                    _buildDetailSection(
                      l10n.validationConfiguration,
                      Icons.settings,
                      Colors.purple,
                      _buildValidationConfigDetails(transition, l10n),
                    ),

                  // Lógica condicional
                  if (transition.hasConditionalLogic) ...[
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      l10n.conditionalLogic,
                      Icons.rule,
                      Colors.amber,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transition.conditionalLogic!.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${l10n.action}: ${transition.conditionalLogic!.action.description}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildValidationConfigDetails(
    StatusTransitionModel transition,
    AppLocalizations l10n,
  ) {
    final config = transition.validationConfig;

    switch (transition.validationType) {
      case ValidationType.textRequired:
      case ValidationType.textOptional:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigRow(
              l10n.label,
              config.textLabel ?? l10n.text,
            ),
            _buildConfigRow(
              l10n.minLength,
              '${config.textMinLength ?? 0}',
            ),
            _buildConfigRow(
              l10n.maxLength,
              '${config.textMaxLength ?? 500}',
            ),
          ],
        );

      case ValidationType.quantityAndText:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigRow(
              l10n.quantityLabel,
              config.quantityLabel ?? l10n.quantity,
            ),
            _buildConfigRow(
              l10n.quantityRange,
              '${config.quantityMin ?? 0} - ${config.quantityMax ?? 999}',
            ),
            _buildConfigRow(
              l10n.text,
              config.textLabel ?? l10n.text,
            ),
          ],
        );

      case ValidationType.checklist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigRow(
              l10n.items,
              '${config.checklistItems?.length ?? 0}',
            ),
            _buildConfigRow(
              l10n.allItemsRequired,
              config.checklistAllRequired == true ? l10n.yes : l10n.no,
            ),
            if (config.checklistItems != null &&
                config.checklistItems!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...config.checklistItems!.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.required
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        );

      case ValidationType.photoRequired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigRow(
              l10n.minPhotos,
              '${config.minPhotos ?? 1}',
            ),
          ],
        );

      case ValidationType.multiApproval:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigRow(
              l10n.minApprovals,
              '${config.minApprovals ?? 1}',
            ),
          ],
        );

      default:
        return Text(
          l10n.noConfigurationRequired,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String roleId) {
    // Mapeo de IDs de roles comunes a nombres en español
    final roleNames = {
      'owner': 'Propietario',
      'admin': 'Administrador',
      'manager': 'Gerente',
      'production_manager': 'Gerente de Producción',
      'operator': 'Operario',
      'quality_control': 'Control de Calidad',
      'client': 'Cliente',
    };

    return roleNames[roleId] ?? roleId;
  }
}