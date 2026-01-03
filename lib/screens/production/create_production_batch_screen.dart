import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/client_service.dart';
import '../../services/production_batch_service.dart';
import '../../models/production_batch_model.dart';
import 'package:flutter/services.dart';

// Imports añadidos para la gestión de productos
import '../../models/product_catalog_model.dart';
import '../../services/product_catalog_service.dart';
import '../../services/phase_service.dart';

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
  final _prefixController = TextEditingController();
  final ValueNotifier<String> _batchNumberPreview = ValueNotifier<String>('___2601');

  // --- VARIABLES PARA GESTIÓN DE PRODUCTOS ---
  final List<Map<String, dynamic>> _productsToAdd = []; // Lista de productos a añadir
  ProductCatalogModel? _selectedCatalogProduct;
  final _productQuantityController = TextEditingController(text: '1');
  // -------------------------------------------

  @override
  void initState() {
    super.initState();
    // Si viene con un projectId, cargar ese proyecto
    if (widget.projectId != null) {
      _loadProject();
    }
    _prefixController.addListener(_updateBatchNumberPreview);
    _updateBatchNumberPreview();
  }

  void _updateBatchNumberPreview() {
    _batchNumberPreview.value = BatchNumberHelper.previewBatchNumber(
      _prefixController.text,
    );
  }

  @override
  void dispose() {
    _prefixController.removeListener(_updateBatchNumberPreview);
    _prefixController.dispose();
    _notesController.dispose();
    _batchNumberPreview.dispose();
    _productQuantityController.dispose(); // No olvidar dispose
    super.dispose();
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

  // --- MÉTODOS PARA GESTIÓN DE PRODUCTOS ---
  void _addProductToList() {
    if (_selectedCatalogProduct == null) return;
    
    // Validar límite de 10 productos
    if (_productsToAdd.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 10 productos por lote')),
      );
      return;
    }

    final quantity = int.tryParse(_productQuantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
      );
      return;
    }

    setState(() {
      _productsToAdd.add({
        'product': _selectedCatalogProduct,
        'quantity': quantity,
      });
      // Resetear selección para permitir añadir otro (incluso el mismo)
      _selectedCatalogProduct = null;
      _productQuantityController.text = '1';
    });
  }

  void _removeProductFromList(int index) {
    setState(() {
      _productsToAdd.removeAt(index);
    });
  }
  // -----------------------------------------

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
                    const SizedBox(height: 16),
                    
                    // Campo de prefijo
                    TextFormField(
                      controller: _prefixController,
                      decoration: InputDecoration(
                        labelText: 'Prefijo del Lote *',
                        hintText: 'Ej: FL1, ABC, X99',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.tag),
                        helperText: '3 caracteres alfanuméricos',
                        counterText: '${_prefixController.text.length}/3',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(3),
                        UpperCaseTextFormatter(), // Convertir a mayúsculas
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El prefijo es obligatorio';
                        }
                        if (!BatchNumberHelper.isValidPrefix(value)) {
                          return 'Debe tener exactamente 3 caracteres alfanuméricos';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Preview del número de lote
                    ValueListenableBuilder<String>(
                      valueListenable: _batchNumberPreview,
                      builder: (context, preview, _) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.preview, size: 18, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Preview del número de lote:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preview,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                  letterSpacing: 2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Formato: Prefijo (3) + Año (2) + Semana (2)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                          selectedColor: Colors.green,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _urgencyLevel = 'low');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Media'),
                          selected: _urgencyLevel == 'medium',
                          selectedColor: Colors.amber,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _urgencyLevel = 'medium');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Alta'),
                          selected: _urgencyLevel == 'high',
                          selectedColor: Colors.red[500],
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _urgencyLevel = 'high');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Crítica'),
                          selected: _urgencyLevel == 'critical',
                          selectedColor: Colors.red[900],
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
            // --- SECCIÓN: PRODUCTOS DEL LOTE (NUEVO) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Productos del Lote',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '${_productsToAdd.length}/10',
                          style: TextStyle(
                            color: _productsToAdd.length >= 10 ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Añade productos para inicializar el lote (Opcional)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    // Selector de Producto
                    _buildProductSelector(),
                    const SizedBox(height: 12),
                    
                    // Cantidad y Botón Añadir
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _productQuantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Cant.',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: _selectedCatalogProduct == null ? null : _addProductToList,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Añadir al Lote'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Lista de productos añadidos
                    if (_productsToAdd.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'No hay productos seleccionados',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _productsToAdd.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _productsToAdd[index];
                          final product = item['product'] as ProductCatalogModel;
                          final quantity = item['quantity'] as int;
                          final sequence = index + 1; // Número secuencial

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                '#$sequence',
                                style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(product.name),
                            subtitle: Text('SKU: ${product.reference}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('x$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeProductFromList(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ---------------------------------------------

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


            // Botón Crear Lote
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
                backgroundColor: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget selector de producto (Dropdown simplificado)
  Widget _buildProductSelector() {
    return StreamBuilder<List<ProductCatalogModel>>(
      stream: Provider.of<ProductCatalogService>(context, listen: false)
          .getOrganizationProductsStream(widget.organizationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        
        final products = snapshot.data ?? [];
        
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Seleccionar producto del catálogo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          value: _selectedCatalogProduct?.id,
          isExpanded: true,
          items: products.map((product) {
            return DropdownMenuItem(
              value: product.id,
              child: Text(
                '${product.name} (SKU: ${product.reference})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (productId) {
            if (productId == null) return;
            setState(() {
              _selectedCatalogProduct = products.firstWhere((p) => p.id == productId);
            });
          },
        );
      },
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
    final phaseService = Provider.of<PhaseService>(context, listen: false); // Servicio de fases

    try {
      final client = await clientService.getClient(
        widget.organizationId,
        _selectedProject!.clientId,
      );

      if (client == null) {
        throw Exception('No se pudo obtener la información del cliente');
      }

      // 1. Crear el Lote
      final batchId = await batchService.createProductionBatch(
        organizationId: widget.organizationId,
        projectId: _selectedProject!.id,
        projectName: _selectedProject!.name,
        clientId: client.id,
        clientName: client.name,
        createdBy: authService.currentUser!.uid,
        batchPrefix: _prefixController.text.toUpperCase(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        urgencyLevel: _urgencyLevel,
        expectedCompletionDate: _expectedCompletionDate,
      );

      if (batchId == null) {
        throw Exception(batchService.error ?? 'Error desconocido al crear lote');
      }

      // 2. Si hay productos en la lista, añadirlos secuencialmente
      if (_productsToAdd.isNotEmpty) {
        // Obtener fases de la organización (necesarias para crear productos)
        final phases = await phaseService.getOrganizationPhases(widget.organizationId);
        if (phases.isEmpty) {
          // Si no hay fases, no podemos crear productos, pero el lote ya está creado.
          // Podríamos lanzar error, pero mejor avisar.
          debugPrint('Advertencia: No hay fases configuradas, no se pudieron añadir productos.');
        } else {
          phases.sort((a, b) => a.order.compareTo(b.order));

          // Iterar y añadir productos
          for (int i = 0; i < _productsToAdd.length; i++) {
            final item = _productsToAdd[i];
            final product = item['product'] as ProductCatalogModel;
            final quantity = item['quantity'] as int;

            // Añadimos el producto al lote
            await batchService.addProductToBatch(
              organizationId: widget.organizationId,
              batchId: batchId,
              productCatalogId: product.id,
              productName: product.name,
              productReference: product.reference,
              description: product.description,
              quantity: quantity,
              phases: phases,
              unitPrice: product.basePrice,
              // Aquí podrías pasar un identificador especial en 'specialDetails' si lo necesitas
              // specialDetails: "Seq #${i+1}", 
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lote ${_batchNumberPreview.value} creado con ${_productsToAdd.length} productos.'),
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

/// Text formatter para convertir a mayúsculas
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}