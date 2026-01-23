import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/status_transition_model.dart';
import '../../models/validation_config_model.dart';
import '../../models/role_model.dart';
import '../../services/role_service.dart';
import '../../l10n/app_localizations.dart';

class ConditionalLogicBuilder extends StatefulWidget {
  final ValidationType validationType;
  final ConditionalLogic? logic;
  final String organizationId;
  final Function(ConditionalLogic?) onLogicChanged;

  const ConditionalLogicBuilder({
    Key? key,
    required this.validationType,
    this.logic,
    required this.organizationId,
    required this.onLogicChanged,
  }) : super(key: key);

  @override
  State<ConditionalLogicBuilder> createState() =>
      _ConditionalLogicBuilderState();
}

class _ConditionalLogicBuilderState extends State<ConditionalLogicBuilder> {
  String _field = 'quantity';
  ConditionOperator _operator = ConditionOperator.greaterThan;
  final TextEditingController _valueController = TextEditingController();
  ConditionalActionType _actionType = ConditionalActionType.showWarning;
  final TextEditingController _messageController = TextEditingController();
  List<String> _selectedRoles = [];

  @override
  void initState() {
    super.initState();
    _loadFromLogic();
  }

  void _loadFromLogic() {
    if (widget.logic != null) {
      _field = widget.logic!.field;
      _operator = widget.logic!.operator;
      _valueController.text = widget.logic!.value.toString();
      _actionType = widget.logic!.action.type;

      final params = widget.logic!.action.parameters;
      if (params != null) {
        _messageController.text = params['message']?.toString() ?? '';
        _selectedRoles = (params['requiredRoles'] as List?)?.cast<String>() ?? [];
      }
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.condition,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Campo a evaluar
            DropdownButtonFormField<String>(
              value: _field,
              decoration: InputDecoration(
                labelText: l10n.field,
                border: const OutlineInputBorder(),
              ),
              items: _getAvailableFields(l10n).map((field) {
                return DropdownMenuItem(
                  value: field['value'],
                  child: Text(field['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _field = value ?? 'quantity';
                });
                _updateLogic();
              },
            ),
            const SizedBox(height: 16),

            // Operador
            DropdownButtonFormField<ConditionOperator>(
              isExpanded: true,
              value: _operator,
              decoration: InputDecoration(
                labelText: l10n.operator,
                border: const OutlineInputBorder(),
              ),
              items: ConditionOperator.values.map((op) {
                return DropdownMenuItem(
                  value: op,
                  child: Text(_getOperatorLabel(op, l10n), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _operator = value ?? ConditionOperator.greaterThan;
                });
                _updateLogic();
              },
            ),
            const SizedBox(height: 16),

            // Valor
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.value,
                hintText: l10n.valueHint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: _field == 'quantity'
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: _field == 'quantity'
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              onChanged: (_) => _updateLogic(),
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),

            Text(
              l10n.action,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Tipo de acción
            DropdownButtonFormField<ConditionalActionType>(
              isExpanded: true,
              value: _actionType,
              decoration: InputDecoration(
                labelText: l10n.actionType,
                border: const OutlineInputBorder(),
              ),
              items: ConditionalActionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getActionTypeLabel(type, l10n), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _actionType = value ?? ConditionalActionType.showWarning;
                  _selectedRoles.clear();
                  _messageController.clear();
                });
                _updateLogic();
              },
            ),
            const SizedBox(height: 16),

            // Parámetros según tipo de acción
            if (_actionType == ConditionalActionType.showWarning ||
                _actionType == ConditionalActionType.blockTransition)
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: l10n.message,
                  hintText: l10n.messageHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (_) => _updateLogic(),
              ),

            if (_actionType == ConditionalActionType.requireApproval ||
                _actionType == ConditionalActionType.notifyRoles)
              _buildRolesSelector(l10n),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRolesSelector(AppLocalizations l10n) {
    return FutureBuilder<List<RoleModel>>(
      future: Provider.of<RoleService>(context, listen: false)
          .getAllRoles(widget.organizationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final roles = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _actionType == ConditionalActionType.requireApproval
                  ? l10n.selectApprovers
                  : l10n.selectRolesToNotify,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((role) {
                final isSelected = _selectedRoles.contains(role.id);

                return FilterChip(
                  selected: isSelected,
                  label: Text(role.name),
                  avatar: Icon(
                    _getIconData(role.icon),
                    size: 18,
                    color: isSelected ? Colors.white : _getColorFromHex(role.color),
                  ),
                  selectedColor: _getColorFromHex(role.color),
                  backgroundColor: _getColorFromHex(role.color).withOpacity(0.1),
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedRoles.add(role.id);
                      } else {
                        _selectedRoles.remove(role.id);
                      }
                    });
                    _updateLogic();
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, String>> _getAvailableFields(AppLocalizations l10n) {
    switch (widget.validationType) {
      case ValidationType.quantityAndText:
        return [
          {'value': 'quantity', 'label': l10n.quantity},
          {'value': 'textLength', 'label': l10n.textLength},
        ];
      case ValidationType.textRequired:
      case ValidationType.textOptional:
        return [
          {'value': 'textLength', 'label': l10n.textLength},
        ];
      case ValidationType.photoRequired:
        return [
          {'value': 'photoCount', 'label': l10n.photoCount},
        ];
      case ValidationType.multiApproval:
        return [
          {'value': 'approvalCount', 'label': l10n.approvalCount},
        ];
      default:
        return [
          {'value': 'quantity', 'label': l10n.quantity},
        ];
    }
  }

  String _getOperatorLabel(ConditionOperator op, AppLocalizations l10n) {
    switch (op) {
      case ConditionOperator.greaterThan:
        return l10n.greaterThan;
      case ConditionOperator.greaterThanOrEqual:
        return l10n.greaterThanOrEqual;
      case ConditionOperator.lessThan:
        return l10n.lessThan;
      case ConditionOperator.lessThanOrEqual:
        return l10n.lessThanOrEqual;
      case ConditionOperator.equals:
        return l10n.equals;
      case ConditionOperator.notEquals:
        return l10n.notEquals;
      case ConditionOperator.contains:
        return l10n.contains;
    }
  }

  String _getActionTypeLabel(ConditionalActionType type, AppLocalizations l10n) {
    switch (type) {
      case ConditionalActionType.requireApproval:
        return l10n.requireApproval;
      case ConditionalActionType.showWarning:
        return l10n.showWarning;
      case ConditionalActionType.blockTransition:
        return l10n.blockTransition;
      case ConditionalActionType.requireAdditionalField:
        return l10n.requireAdditionalField;
      case ConditionalActionType.notifyRoles:
        return l10n.notifyRoles;
    }
  }

  void _updateLogic() {
    if (_valueController.text.isEmpty) {
      widget.onLogicChanged(null);
      return;
    }

    // Parsear valor según tipo de campo
    dynamic value;
    if (_field == 'quantity' ||
        _field == 'textLength' ||
        _field == 'photoCount' ||
        _field == 'approvalCount') {
      value = int.tryParse(_valueController.text) ?? 0;
    } else {
      value = _valueController.text;
    }

    // Construir parámetros de acción
    Map<String, dynamic>? parameters;
    if (_actionType == ConditionalActionType.requireApproval ||
        _actionType == ConditionalActionType.notifyRoles) {
      parameters = {
        'requiredRoles': _selectedRoles,
      };
    } else if (_actionType == ConditionalActionType.showWarning) {
      parameters = {
        'message': _messageController.text,
      };
    } else if (_actionType == ConditionalActionType.blockTransition) {
      parameters = {
        'reason': _messageController.text,
      };
    }

    final logic = ConditionalLogic(
      field: _field,
      operator: _operator,
      value: value,
      action: ConditionalAction(
        type: _actionType,
        parameters: parameters,
      ),
    );

    widget.onLogicChanged(logic);
  }

  IconData _getIconData(String iconName) {
    try {
      final codePoint = int.tryParse(iconName);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
      return Icons.person;
    } catch (e) {
      return Icons.person;
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}