import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product_status_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/product_status_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/status/status_preview_card.dart';

class CreateEditStatusDialog extends StatefulWidget {
  final String organizationId;
  final ProductStatusModel? status; // Null = crear, non-null = editar

  const CreateEditStatusDialog({
    Key? key,
    required this.organizationId,
    this.status,
  }) : super(key: key);

  @override
  State<CreateEditStatusDialog> createState() =>
      _CreateEditStatusDialogState();
}

class _CreateEditStatusDialogState extends State<CreateEditStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late Color _selectedColor;
  late IconData _selectedIcon;
  
  bool _isLoading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    
    if (widget.status != null) {
      // Modo edición - cargar datos existentes
      _nameController.text = widget.status!.name;
      _descriptionController.text = widget.status!.description;
      _selectedColor = widget.status!.colorValue;
      _selectedIcon = _getIconData(widget.status!.icon);
    } else {
      // Modo creación - valores por defecto
      _selectedColor = Colors.blue;
      _selectedIcon = Icons.label;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.status != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit : Icons.add_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? l10n.editStatus : l10n.createStatus,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Vista previa del estado
                  Card(
                    color: _selectedColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.statusPreview,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StatusPreviewCard(
                            name: _nameController.text.isEmpty
                                ? l10n.statusName
                                : _nameController.text,
                            description: _descriptionController.text.isEmpty
                                ? l10n.statusDescription
                                : _descriptionController.text,
                            color: _selectedColor,
                            icon: _selectedIcon,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre del estado
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.statusName,
                      hintText: l10n.statusNameHint,
                      prefixIcon: const Icon(Icons.title),
                      border: const OutlineInputBorder(),
                      errorText: _nameError,
                    ),
                    maxLength: 50,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.statusNameRequired;
                      }
                      if (value.trim().length < 3) {
                        return l10n.statusNameTooShort;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _nameError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.statusDescription,
                      hintText: l10n.statusDescriptionHint,
                      prefixIcon: const Icon(Icons.description),
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 200,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.statusDescriptionRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Color
                  Card(
                    child: InkWell(
                      onTap: () => _showColorPicker(context, l10n),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.palette),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.statusColor,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _colorToHex(_selectedColor),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Icono
                  Card(
                    child: InkWell(
                      onTap: () => _showIconPicker(context, l10n),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_symbols),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.statusIcon,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.tapToSelectIcon,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _selectedColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _selectedIcon,
                                color: _selectedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSubmit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(isEditing ? Icons.save : Icons.add),
                        label: Text(isEditing ? l10n.save : l10n.create),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Limpiar error previo
    setState(() {
      _nameError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final statusService = Provider.of<ProductStatusService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Verificar que el nombre no existe (excepto si es el mismo estado que estamos editando)
    final nameExists = await statusService.statusNameExists(
      widget.organizationId,
      _nameController.text.trim(),
      excludeStatusId: widget.status?.id,
    );

    if (nameExists) {
      setState(() {
        _nameError = l10n.statusNameExists;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final colorHex = _colorToHex(_selectedColor);
    final iconCode = _selectedIcon.codePoint.toString();

    bool success;
    if (widget.status != null) {
      // Modo edición
      success = await statusService.updateStatus(
        organizationId: widget.organizationId,
        statusId: widget.status!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: colorHex,
        icon: iconCode,
      );
    } else {
      // Modo creación
      // Obtener el siguiente orden
      final statuses = await statusService.getAllStatuses(widget.organizationId);
      final maxOrder = statuses.isEmpty
          ? 0
          : statuses.map((s) => s.order).reduce((a, b) => a > b ? a : b);

      final statusId = await statusService.createStatus(
        organizationId: widget.organizationId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: colorHex,
        icon: iconCode,
        order: maxOrder + 1,
        createdBy: authService.currentUser!.uid,
      );

      success = statusId != null;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.status != null
                ? l10n.statusUpdated
                : l10n.statusCreated,
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.status != null
                ? l10n.errorUpdatingStatus
                : l10n.errorCreatingStatus,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showColorPicker(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectColor),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getColorPalette().map((color) {
              final isSelected = color.value == _selectedColor.value;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showIconPicker(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectIcon),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _getIconList().length,
            itemBuilder: (context, index) {
              final icon = _getIconList()[index];
              final isSelected = icon.codePoint == _selectedIcon.codePoint;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor.withOpacity(0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? _selectedColor : Colors.grey.shade700,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  IconData _getIconData(String iconName) {
    try {
      final codePoint = int.tryParse(iconName);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
      return Icons.label;
    } catch (e) {
      return Icons.label;
    }
  }

  List<Color> _getColorPalette() {
    return [
      // Rojos
      Colors.red.shade400,
      Colors.red.shade700,
      Colors.pink.shade400,
      Colors.pink.shade700,
      // Naranjas
      Colors.orange.shade400,
      Colors.orange.shade700,
      Colors.deepOrange.shade400,
      Colors.deepOrange.shade700,
      // Amarillos
      Colors.amber.shade400,
      Colors.amber.shade700,
      Colors.yellow.shade700,
      Colors.lime.shade700,
      // Verdes
      Colors.green.shade400,
      Colors.green.shade700,
      Colors.lightGreen.shade700,
      Colors.teal.shade400,
      Colors.teal.shade700,
      // Azules
      Colors.blue.shade400,
      Colors.blue.shade700,
      Colors.lightBlue.shade400,
      Colors.lightBlue.shade700,
      Colors.cyan.shade400,
      Colors.cyan.shade700,
      // Morados
      Colors.indigo.shade400,
      Colors.indigo.shade700,
      Colors.purple.shade400,
      Colors.purple.shade700,
      Colors.deepPurple.shade400,
      Colors.deepPurple.shade700,
      // Marrones y grises
      Colors.brown.shade400,
      Colors.brown.shade700,
      Colors.grey.shade600,
      Colors.grey.shade800,
      Colors.blueGrey.shade400,
      Colors.blueGrey.shade700,
    ];
  }

  List<IconData> _getIconList() {
    return [
      Icons.label,
      Icons.label_important,
      Icons.bookmark,
      Icons.flag,
      Icons.star,
      Icons.circle,
      Icons.square,
      Icons.pentagon,
      Icons.hexagon,
      Icons.favorite,
      Icons.check_circle,
      Icons.cancel,
      Icons.error,
      Icons.warning,
      Icons.info,
      Icons.help,
      Icons.lightbulb,
      Icons.schedule,
      Icons.hourglass_empty,
      Icons.timer,
      Icons.alarm,
      Icons.event,
      Icons.today,
      Icons.date_range,
      Icons.update,
      Icons.sync,
      Icons.cached,
      Icons.autorenew,
      Icons.refresh,
      Icons.loop,
      Icons.done,
      Icons.done_all,
      Icons.close,
      Icons.block,
      Icons.not_interested,
      Icons.pause_circle,
      Icons.play_circle,
      Icons.stop_circle,
      Icons.replay_circle_filled,
      Icons.arrow_forward,
      Icons.arrow_back,
      Icons.arrow_upward,
      Icons.arrow_downward,
      Icons.trending_up,
      Icons.trending_down,
      Icons.trending_flat,
      Icons.insights,
      Icons.analytics,
      Icons.assessment,
      Icons.bar_chart,
      Icons.pie_chart,
      Icons.show_chart,
      Icons.notification_important,
      Icons.notifications,
      Icons.notifications_active,
      Icons.notifications_off,
      Icons.priority_high,
      Icons.new_releases,
      Icons.fiber_new,
      Icons.build,
      Icons.settings,
      Icons.tune,
      Icons.engineering,
      Icons.construction,
      Icons.handyman,
      Icons.verified,
      Icons.verified_user,
      Icons.security,
      Icons.lock,
      Icons.lock_open,
      Icons.vpn_key,
      Icons.key,
      Icons.fingerprint,
      Icons.visibility,
      Icons.visibility_off,
      Icons.remove_red_eye,
      Icons.preview,
      Icons.search,
      Icons.zoom_in,
      Icons.zoom_out,
      Icons.filter_alt,
      Icons.sort,
      Icons.list,
      Icons.view_list,
      Icons.view_module,
      Icons.view_column,
      Icons.view_agenda,
      Icons.view_array,
      Icons.dashboard,
      Icons.space_dashboard,
      Icons.category,
      Icons.class_,
      Icons.folder,
      Icons.folder_open,
      Icons.description,
      Icons.article,
      Icons.note,
      Icons.sticky_note_2,
      Icons.task,
      Icons.assignment,
      Icons.fact_check,
      Icons.checklist,
      Icons.rule,
      Icons.gavel,
    ];
  }
}