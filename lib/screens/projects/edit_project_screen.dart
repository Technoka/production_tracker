import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../services/organization_service.dart';
import '../../services/auth_service.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class EditProjectScreen extends StatefulWidget {
  final ProjectModel project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _estimatedEndDate;
  late List<String> _selectedMembers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
    _startDate = widget.project.startDate;
    _estimatedEndDate = widget.project.estimatedEndDate;
    _selectedMembers = List.from(widget.project.assignedMembers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _estimatedEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _estimatedEndDate = picked);
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final projectService = Provider.of<ProjectService>(context, listen: false);
    final success = await projectService.updateProject(
      projectId: widget.project.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      estimatedEndDate: _estimatedEndDate,
      assignedMembers: _selectedMembers,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proyecto actualizado'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(projectService.error ?? 'Error'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectService = Provider.of<ProjectService>(context);
    final organizationService = Provider.of<OrganizationService>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Proyecto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre *', prefixIcon: Icon(Icons.work_outline), border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción *', prefixIcon: Icon(Icons.description), border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text('Inicio\n${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.event),
                      label: Text('Entrega\n${_estimatedEndDate.day}/${_estimatedEndDate.month}/${_estimatedEndDate.year}'),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
             StreamBuilder<List<UserModel>>(
  stream: organizationService.watchOrganizationMembers(widget.project.organizationId),
  builder: (context, snapshot) {
    final members = snapshot.data ?? [];

    // ORDENAR: Te pones a ti mismo al principio de la lista
    // members.sort((a, b) => a.uid == user?.uid ? -1 : 1);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: members.map((m) {
          final isMe = m.uid == user?.uid;
          final isSelected = _selectedMembers.contains(m.uid);

          return CheckboxListTile(
            // Identificador visual "TÚ"
            title: Row(
              children: [
                Text(m.name),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'TÚ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(m.roleDisplayName),
            secondary: isMe ? const Icon(Icons.person_pin, color: Colors.blue) : null,
            value: isSelected,
            activeColor: Colors.blue,
            // Fondo sutil si eres tú para diferenciar la fila
            tileColor: isMe ? Colors.blue.withOpacity(0.05) : null,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selectedMembers.add(m.uid);
              } else {
                _selectedMembers.remove(m.uid);
              }
            }),
          );
        }).toList(),
      ),
    );
  },
),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: projectService.isLoading ? null : _handleUpdate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: projectService.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}