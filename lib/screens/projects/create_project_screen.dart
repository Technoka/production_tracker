import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/client_service.dart';
import '../../services/organization_service.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ClientModel? _selectedClient;
  DateTime _startDate = DateTime.now();
  DateTime _estimatedEndDate = DateTime.now().add(const Duration(days: 30));
  List<String> _selectedMembers = [];
  String? _selectedClientId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _estimatedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_estimatedEndDate.isBefore(_startDate)) {
            _estimatedEndDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _estimatedEndDate = picked;
        }
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un cliente'), backgroundColor: Colors.red),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final projectService = Provider.of<ProjectService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null || user.organizationId == null) return;

    final projectId = await projectService.createProject(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      clientId: _selectedClientId!,
      organizationId: user.organizationId!,
      startDate: _startDate,
      estimatedEndDate: _estimatedEndDate,
      assignedMembers: _selectedMembers,
      createdBy: user.uid,
    );

    if (mounted) {
      if (projectId != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto creado exitosamente'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(projectService.error ?? 'Error al crear proyecto'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final projectService = Provider.of<ProjectService>(context);
    final clientService = Provider.of<ClientService>(context);
    final organizationService = Provider.of<OrganizationService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return const Scaffold(body: Center(child: Text('Debes pertenecer a una organización')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Proyecto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Información Básica', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre del proyecto *', prefixIcon: Icon(Icons.work_outline), border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa el nombre' : value.length < 3 ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción *', prefixIcon: Icon(Icons.description), border: OutlineInputBorder(), alignLabelWithHint: true),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa la descripción' : null,
                ),
                const SizedBox(height: 16),
StreamBuilder<List<ClientModel>>(
  stream: clientService.watchClients(user!.organizationId!),
  builder: (context, snapshot) {
    final clients = snapshot.data ?? [];
    
    // Cambiamos el tipo de ClientModel a String aquí:
    return DropdownButtonFormField<String>( 
      decoration: const InputDecoration(
        labelText: 'Cliente *',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      value: _selectedClientId,
      // Ahora el valor del item (String) coincide con el del Dropdown (String)
      items: clients.map((client) => DropdownMenuItem<String>(
        value: client.id, 
        child: Text('${client.name} - ${client.company}'),
      )).toList(),
      onChanged: (id) => setState(() => _selectedClientId = id),
      validator: (value) => value == null ? 'Selecciona un cliente' : null,
    );
  },
),
                const SizedBox(height: 24),
                Text('Fechas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.calendar_today),
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inicio', style: TextStyle(fontSize: 11)),
                            Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.event),
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Entrega', style: TextStyle(fontSize: 11)),
                            Text('${_estimatedEndDate.day}/${_estimatedEndDate.month}/${_estimatedEndDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Asignar Miembros', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StreamBuilder<List<UserModel>>(
                  stream: organizationService.watchOrganizationMembers(user.organizationId!),
                  builder: (context, snapshot) {
                    final members = snapshot.data ?? [];
                    return Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: members.map((member) {
                          final isSelected = _selectedMembers.contains(member.uid);
                          return CheckboxListTile(
                            title: Text(member.name),
                            subtitle: Text(member.roleDisplayName),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedMembers.add(member.uid);
                                } else {
                                  _selectedMembers.remove(member.uid);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: projectService.isLoading ? null : _handleCreate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: projectService.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Crear Proyecto', style: TextStyle(fontSize: 16)),
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