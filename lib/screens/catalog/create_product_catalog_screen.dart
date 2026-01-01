import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';

class CreateProductCatalogScreen extends StatefulWidget {
  final String organizationId;
  final UserModel currentUser;

  const CreateProductCatalogScreen({
    super.key,
    required this.organizationId,
    required this.currentUser,
  });

  @override
  State<CreateProductCatalogScreen> createState() =>
      _CreateProductCatalogScreenState();
}

class _CreateProductCatalogScreenState
    extends State<CreateProductCatalogScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductCatalogService _catalogService = ProductCatalogService();

  // Controladores de campos básicos
  final _nameController = TextEditingController();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  // Controladores de especificaciones
  final _basePriceController = TextEditingController();
  final _weightController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _depthController = TextEditingController();

  // Controladores de material
  final _primaryMaterialController = TextEditingController();
  final _finishController = TextEditingController();
  final _colorController = TextEditingController();

  List<String> _secondaryMaterials = [];
  List<String> _tags = [];
  List<String> _imageUrls = [];
  Map<String, dynamic> _specifications = {};

  bool _isLoading = false;
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
        await _catalogService.getOrganizationCategories(widget.organizationId);
    if (mounted) {
      setState(() {
        _availableCategories = categories;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Construir MaterialInfo si hay datos
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

      // Construir DimensionsInfo si hay datos
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

      final productId = await _catalogService.createProduct(
        organizationId: widget.organizationId,
        name: _nameController.text.trim(),
        reference: _referenceController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: widget.currentUser.uid,
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        imageUrls: _imageUrls,
        specifications: _specifications,
        tags: _tags,
        materialInfo: materialInfo,
        dimensions: dimensions,
        estimatedWeight: double.tryParse(_weightController.text),
        basePrice: double.tryParse(_basePriceController.text),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        if (productId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al crear el producto'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información básica
            _buildSectionTitle('Información Básica'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto *',
                hintText: 'Ej: Mesa de comedor rústica',
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
                hintText: 'Ej: MESA-001',
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
                hintText: 'Describe el producto...',
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
            
            // Categoría con autocompletado
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _availableCategories;
                }
                return _availableCategories.where((category) =>
                    category.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (selection) {
                _categoryController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Sincronizar con nuestro controlador
                if (controller.text != _categoryController.text) {
                  controller.text = _categoryController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    hintText: 'Ej: Muebles',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  onChanged: (value) {
                    _categoryController.text = value;
                  },
                  textCapitalization: TextCapitalization.words,
                );
              },
            ),
            const SizedBox(height: 24),

            // Dimensiones
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Material
            _buildSectionTitle('Material'),
            TextFormField(
              controller: _primaryMaterialController,
              decoration: const InputDecoration(
                labelText: 'Material principal',
                hintText: 'Ej: Madera de roble',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _buildListField(
              title: 'Materiales secundarios',
              items: _secondaryMaterials,
              hintText: 'Ej: Acero inoxidable',
              onAdd: (value) {
                setState(() {
                  _secondaryMaterials.add(value);
                });
              },
              onRemove: (index) {
                setState(() {
                  _secondaryMaterials.removeAt(index);
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
                      hintText: 'Ej: Barnizado',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      hintText: 'Ej: Nogal',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Datos adicionales
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildListField(
              title: 'Etiquetas',
              items: _tags,
              hintText: 'Ej: Premium, Moderno',
              onAdd: (value) {
                setState(() {
                  _tags.add(value);
                });
              },
              onRemove: (index) {
                setState(() {
                  _tags.removeAt(index);
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                hintText: 'Información adicional...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Botón guardar
            FilledButton(
              onPressed: _isLoading ? null : _saveProduct,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear Producto'),
            ),
            const SizedBox(height: 16),
          ],
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