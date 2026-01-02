import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/client_service.dart';
import '../../services/production_batch_service.dart';

class CreateProductionBatchScreen extends StatefulWidget {
  final String organizationId;
  final String? projectId; // Opcional: si viene desde un proyecto específico

  const CreateProductionBatchScreen({
    super.key,
    required this.organizationId,
    this.projectId,
  });

  @override
  State<CreateProductionBatchScreen> createState() => _CreateProductionBatchScreenState();
}

class _CreateProductionBatchScreenState extends State<CreateProductionBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  ProjectModel? _selectedProject;
  int _priority = 3;
  String _urgencyLevel = 'medium';
  DateTime? _expectedCompletionDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si viene con un projectId, cargar ese proyecto
    if (widget.projectId != null) {
      _loadProject();
    }
  }

  Future<void> _loadProject() async {
    final projectService = Provider.of<ProjectService>(context, listen: false);
    final project = await projectService.getProject(
      widget.organizationId,
      widget.projectId!,
    );
    if (project != null) {
      setState(() {
        _selectedProject = project;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Lote de Producción'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información del lote
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Información del Lote',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El número de lote se generará automáticamente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Seleccionar Proyecto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proyecto *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedProject != null)
                      _buildSelectedProjectCard()
                    else
                      _buildProjectSelector(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prioridad y Urgencia
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prioridad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nivel: $_priority',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Slider(
                                value: _priority.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: _priority.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _priority = value.toInt();
                                  });
                                },
                              ),
                              Text(
                                '1 = Máxima, 5 = Baja',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Urgencia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Baja'),
                          selected: _urgencyLevel == 'low',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _urgencyLevel = 'low');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Media'),
                          selected: _urgencyLevel == 'medium',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _urgencyLevel = 'medium');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Alta'),
                          selected: _urgencyLevel == 'high',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _urgencyLevel = 'high');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Crítica'),
                          selected: _urgencyLevel == 'critical',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _urgencyLevel = 'critical');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fecha de entrega esperada
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de entrega esperada'),
                subtitle: _expectedCompletionDate != null
                    ? Text(_formatDate(_expectedCompletionDate!))
                    : const Text('Opcional'),
                trailing: _expectedCompletionDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _expectedCompletionDate = null;
                          });
                        },
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

            // Notas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Añade notas sobre este lote...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón Crear
            FilledButton.icon(
              onPressed: _isLoading ? null : _createBatch,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'Creando...' : 'Crear Lote'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProjectCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedProject!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<ClientModel?>(
                    stream: Provider.of<ClientService>(context, listen: false)
                        .getClientStream(widget.organizationId, _selectedProject!.clientId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          'Cliente: ${snapshot.data!.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            if (widget.projectId == null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _selectedProject = null;
                  });
                },
                tooltip: 'Cambiar proyecto',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSelector() {
    return StreamBuilder<List<ProjectModel>>(
      stream: Provider.of<ProjectService>(context, listen: false)
          .watchProjects(widget.organizationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          return Column(
            children: [
              Text(
                'No hay proyectos disponibles',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Crear proyecto primero'),
              ),
            ],
          );
        }

        return DropdownButtonFormField<ProjectModel>(
          decoration: const InputDecoration(
            labelText: 'Seleccionar proyecto',
            border: OutlineInputBorder(),
          ),
          value: _selectedProject,
          items: projects.map((project) {
            return DropdownMenuItem(
              value: project,
              child: Text(project.name),
            );
          }).toList(),
          onChanged: (project) {
            setState(() {
              _selectedProject = project;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Debes seleccionar un proyecto';
            }
            return null;
          },
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedCompletionDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Seleccionar fecha de entrega',
    );

    if (picked != null) {
      setState(() {
        _expectedCompletionDate = picked;
      });
    }
  }

  Future<void> _createBatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un proyecto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final clientService = Provider.of<ClientService>(context, listen: false);

    try {
      // Obtener información del cliente
      final client = await clientService.getClient(
        widget.organizationId,
        _selectedProject!.clientId,
      );

      if (client == null) {
        throw Exception('No se pudo obtener la información del cliente');
      }

      final batchId = await batchService.createProductionBatch(
        organizationId: widget.organizationId,
        projectId: _selectedProject!.id,
        projectName: _selectedProject!.name,
        clientId: client.id,
        clientName: client.name,
        createdBy: authService.currentUser!.uid,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        priority: _priority,
        urgencyLevel: _urgencyLevel,
        expectedCompletionDate: _expectedCompletionDate,
      );

      if (batchId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lote de producción creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, batchId);
      } else if (mounted) {
        throw Exception(batchService.error ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear lote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}