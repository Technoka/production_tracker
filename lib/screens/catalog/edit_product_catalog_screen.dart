import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';

class EditProductCatalogScreen extends StatefulWidget {
  final String organizationId;
  final ProductCatalogModel product;
  final UserModel currentUser;

  const EditProductCatalogScreen({
    super.key,
    required this.product,
    required this.currentUser,
    required this.organizationId,
  });

  @override
  State<EditProductCatalogScreen> createState() =>
      _EditProductCatalogScreenState();
}

class _EditProductCatalogScreenState extends State<EditProductCatalogScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductCatalogService _catalogService = ProductCatalogService();

  // Controladores
  late final TextEditingController _nameController;
  late final TextEditingController _referenceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _weightController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _depthController;
  late final TextEditingController _primaryMaterialController;
  late final TextEditingController _finishController;
  late final TextEditingController _colorController;

  late List<String> _secondaryMaterials;
  late List<String> _tags;
  late List<String> _imageUrls;

  bool _isLoading = false;
  bool _hasChanges = false;
  List<String> _availableCategories = [];

  String? _selectedClientId;
  String? _selectedClientName;
  bool _isPublic = true; // Por defecto, el producto es público

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategories();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _referenceController = TextEditingController(text: widget.product.reference);
    _descriptionController = TextEditingController(text: widget.product.description);
    _categoryController = TextEditingController(text: widget.product.category ?? '');
    _notesController = TextEditingController(text: widget.product.notes ?? '');
    _basePriceController = TextEditingController(
      text: widget.product.basePrice?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.product.estimatedWeight?.toString() ?? '',
    );
    _widthController = TextEditingController(
      text: widget.product.dimensions?.width?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.product.dimensions?.height?.toString() ?? '',
    );
    _depthController = TextEditingController(
      text: widget.product.dimensions?.depth?.toString() ?? '',
    );
    _primaryMaterialController = TextEditingController(
      text: widget.product.materialInfo?.primaryMaterial ?? '',
    );
    _finishController = TextEditingController(
      text: widget.product.materialInfo?.finish ?? '',
    );
    _colorController = TextEditingController(
      text: widget.product.materialInfo?.color ?? '',
    );

    _secondaryMaterials = List.from(widget.product.materialInfo?.secondaryMaterials ?? []);
    _tags = List.from(widget.product.tags);
    _imageUrls = List.from(widget.product.imageUrls);

    // Detectar cambios
    _nameController.addListener(_markAsChanged);
    _referenceController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _categoryController.addListener(_markAsChanged);
    _notesController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _basePriceController.dispose();
    _weightController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _primaryMaterialController.dispose();
    _finishController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories =
        await _catalogService.getOrganizationCategories(widget.product.organizationId);
    if (mounted) {
      setState(() {
        _availableCategories = categories;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Construir MaterialInfo
      MaterialInfo? materialInfo;
      if (_primaryMaterialController.text.isNotEmpty) {
        materialInfo = MaterialInfo(
          primaryMaterial: _primaryMaterialController.text.trim(),
          secondaryMaterials: _secondaryMaterials,
          finish: _finishController.text.trim().isNotEmpty
              ? _finishController.text.trim()
              : null,
          color: _colorController.text.trim().isNotEmpty
              ? _colorController.text.trim()
              : null,
        );
      }

      // Construir DimensionsInfo
      DimensionsInfo? dimensions;
      final width = double.tryParse(_widthController.text);
      final height = double.tryParse(_heightController.text);
      final depth = double.tryParse(_depthController.text);

      if (width != null || height != null || depth != null) {
        dimensions = DimensionsInfo(
          width: width,
          height: height,
          depth: depth,
          unit: 'cm',
        );
      }

      final success = await _catalogService.updateProduct(
        organizationId: widget.product.organizationId,
        productId: widget.product.id,
        updatedBy: widget.currentUser.uid,
        name: _nameController.text.trim(),
        reference: _referenceController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        imageUrls: _imageUrls,
        tags: _tags,
        materialInfo: materialInfo,
        dimensions: dimensions,
        estimatedWeight: double.tryParse(_weightController.text),
        basePrice: double.tryParse(_basePriceController.text),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        // NUEVOS PARÁMETROS:
        clientId: _isPublic ? null : _selectedClientId,
        isPublic: _isPublic,
      );

    if (mounted) {
      if (widget.product.id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto editado para $_selectedClientName'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al actualizar el producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('¿Deseas descartar los cambios realizados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Producto'),
          actions: [
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Sin guardar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Información Básica'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Referencia/SKU *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La referencia es obligatoria';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _categoryController.text),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _availableCategories;
                  }
                  return _availableCategories.where((category) =>
                      category.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  _categoryController.text = selection;
                  _markAsChanged();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text != _categoryController.text) {
                    controller.text = _categoryController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onChanged: (value) {
                      _categoryController.text = value;
                      _markAsChanged();
                    },
                    textCapitalization: TextCapitalization.words,
                  );
                },
              ),
              const SizedBox(height: 24),

// Cliente asociado
_buildSectionTitle('Disponibilidad'),
Row(
  children: [
    Expanded(
      child: SwitchListTile(
        title: Text(
          _isPublic 
              ? 'Producto público' 
              : 'Producto privado'),
        subtitle: Text(
          _isPublic 
              ? 'Disponible para todos los clientes' 
              : 'Solo para cliente específico',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        value: _isPublic,
        onChanged: (value) {
          setState(() {
            _isPublic = value;
            _hasChanges = true;
            if (value) {
              // Si se hace público, limpiar cliente seleccionado
              _selectedClientId = null;
              _selectedClientName = null;
            }
          });
        },
      ),
    ),
  ],
),
const SizedBox(height: 12),

// Selector de cliente (solo si no es público)
if (!_isPublic) ...[
  StreamBuilder<List<ClientModel>>(
    stream: ClientService().watchClients(widget.organizationId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LinearProgressIndicator();
      }

      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      final clients = snapshot.data ?? [];

      if (clients.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'No hay clientes disponibles. Crea un cliente primero.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }

      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Cliente específico *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
          helperText: 'Este producto solo estará disponible para este cliente',
        ),
        value: _selectedClientId,
        isExpanded: true,
        items: clients.map((client) {
          return DropdownMenuItem(
            value: client.id,
            child: Text(
              client.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (clientId) {
          setState(() {
            _selectedClientId = clientId;
            _hasChanges = true;
            // Guardar el nombre del cliente también
            _selectedClientName = clients
                .firstWhere((c) => c.id == clientId)
                .name;
          });
        },
        validator: (value) {
          if (!_isPublic && (value == null || value.isEmpty)) {
            return 'Debes seleccionar un cliente';
          }
          return null;
        },
      );
    },
  ),
  const SizedBox(height: 16),
  
  // Información adicional
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Solo este cliente podrá añadir este producto a sus lotes de producción.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[900],
            ),
          ),
        ),
      ],
    ),
  ),
],

const SizedBox(height: 24),     

              _buildSectionTitle('Dimensiones (cm)'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: const InputDecoration(
                        labelText: 'Ancho',
                        border: OutlineInputBorder(),
                        suffixText: 'cm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Alto',
                        border: OutlineInputBorder(),
                        suffixText: 'cm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _depthController,
                      decoration: const InputDecoration(
                        labelText: 'Fondo',
                        border: OutlineInputBorder(),
                        suffixText: 'cm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Material'),
              TextFormField(
                controller: _primaryMaterialController,
                decoration: const InputDecoration(
                  labelText: 'Material principal',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _markAsChanged(),
              ),
              const SizedBox(height: 16),
              _buildListField(
                title: 'Materiales secundarios',
                items: _secondaryMaterials,
                hintText: 'Ej: Acero inoxidable',
                onAdd: (value) {
                  setState(() {
                    _secondaryMaterials.add(value);
                    _hasChanges = true;
                  });
                },
                onRemove: (index) {
                  setState(() {
                    _secondaryMaterials.removeAt(index);
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _finishController,
                      decoration: const InputDecoration(
                        labelText: 'Acabado',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Datos Adicionales'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Peso estimado',
                        border: OutlineInputBorder(),
                        suffixText: 'kg',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio base',
                        border: OutlineInputBorder(),
                        prefixText: '€ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildListField(
                title: 'Etiquetas',
                items: _tags,
                hintText: 'Ej: Premium',
                onAdd: (value) {
                  setState(() {
                    _tags.add(value);
                    _hasChanges = true;
                  });
                },
                onRemove: (index) {
                  setState(() {
                    _tags.removeAt(index);
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _markAsChanged(),
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isLoading || !_hasChanges ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar Cambios'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListField({
    required String title,
    required List<String> items,
    required String hintText,
    required Function(String) onAdd,
    required Function(int) onRemove,
  }) {
    final controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    onAdd(value.trim());
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                  controller.clear();
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => onRemove(entry.key),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}