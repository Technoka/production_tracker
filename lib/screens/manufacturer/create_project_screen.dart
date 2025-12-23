import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class CreateProjectScreen extends StatefulWidget {
  final String manufacturerId;

  const CreateProjectScreen({super.key, required this.manufacturerId});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _clients = [];
  Map<String, dynamic>? _selectedClient;
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchClients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _clients = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _firestoreService.searchClients(query);

    if (mounted) {
      setState(() {
        _clients = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final projectId = await _firestoreService.createProject(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      manufacturerId: widget.manufacturerId,
      clientId: _selectedClient!['uid'],
    );

    if (mounted) {
      setState(() {
        _isCreating = false;
      });

      if (projectId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proyecto creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el proyecto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Proyecto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del proyecto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del proyecto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Asignar cliente',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar cliente',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  _searchClients(value);
                },
              ),
              const SizedBox(height: 8),
              if (_selectedClient != null)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(_selectedClient!['name']),
                    subtitle: Text(_selectedClient!['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedClient = null;
                        });
                      },
                    ),
                  ),
                )
              else if (_clients.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(client['name']),
                        subtitle: Text(client['email']),
                        onTap: () {
                          setState(() {
                            _selectedClient = client;
                            _clients = [];
                            _searchController.clear();
                          });
                        },
                      );
                    },
                  ),
                )
              else if (_searchController.text.isNotEmpty && !_isSearching)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No se encontraron clientes',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isCreating ? null : _createProject,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Crear Proyecto',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}