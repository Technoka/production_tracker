import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';

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
  
  String? _selectedClientId;
  String? _selectedClientName;
  bool _isPublic = true;

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

  Future<void> _saveProduct(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
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
        clientId: _isPublic ? null : _selectedClientId,
        isPublic: _isPublic,
      );

      if (mounted) {
        if (productId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isPublic 
                    ? l10n.productCreatedPublicSuccess
                    : l10n.productCreatedPrivateSuccess(_selectedClientName ?? ''),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.createProductError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newProduct),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información básica
            _buildSectionTitle(l10n.basicInfo),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.productNameLabel,
                hintText: l10n.productNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.nameRequired;
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: l10n.referenceLabel,
                hintText: l10n.referenceHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.referenceRequired;
                }
                return null;
              },
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                hintText: l10n.descriptionHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.descriptionRequired;
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
                if (controller.text != _categoryController.text) {
                  controller.text = _categoryController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: l10n.categoryLabel,
                    hintText: l10n.categoryHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  onChanged: (value) {
                    _categoryController.text = value;
                  },
                  textCapitalization: TextCapitalization.words,
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Cliente asociado
            _buildSectionTitle(l10n.availabilityTitle),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text(
                      _isPublic 
                          ? l10n.publicProduct
                          : l10n.privateProduct),
                    subtitle: Text(
                      _isPublic 
                          ? l10n.publicProductSubtitle 
                          : l10n.privateProductSubtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                        if (value) {
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

            // Selector de cliente
            if (!_isPublic) ...[
              StreamBuilder<List<ClientModel>>(
                stream: ClientService().watchClients(widget.organizationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('${l10n.error}: ${snapshot.error}');
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
                          Expanded(
                            child: Text(
                              l10n.noClientsAvailable,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.specificClientLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      helperText: l10n.specificClientHelper,
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
                        _selectedClientName = clients
                            .firstWhere((c) => c.id == clientId)
                            .name;
                      });
                    },
                    validator: (value) {
                      if (!_isPublic && (value == null || value.isEmpty)) {
                        return l10n.selectClientError;
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
                        l10n.privateProductInfo,
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

            // Dimensiones
            _buildSectionTitle(l10n.dimensionsLabel('cm')),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _widthController,
                    decoration: InputDecoration(
                      labelText: l10n.widthLabel,
                      border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: l10n.heightLabel,
                      border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: l10n.depthLabel,
                      border: const OutlineInputBorder(),
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
            _buildSectionTitle(l10n.materialTitle),
            TextFormField(
              controller: _primaryMaterialController,
              decoration: InputDecoration(
                labelText: l10n.primaryMaterialLabel,
                hintText: l10n.primaryMaterialHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _buildListField(
              title: l10n.secondaryMaterialsLabel,
              items: _secondaryMaterials,
              hintText: l10n.secondaryMaterialsHint,
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
                    decoration: InputDecoration(
                      labelText: l10n.finishLabel,
                      hintText: l10n.finishHint,
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: InputDecoration(
                      labelText: l10n.colorLabel,
                      hintText: l10n.colorHint,
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Datos adicionales
            _buildSectionTitle(l10n.additionalDataTitle),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: l10n.estimatedWeightLabel,
                      border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: l10n.basePriceLabel,
                      border: const OutlineInputBorder(),
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
              title: l10n.tagsLabel,
              items: _tags,
              hintText: l10n.tagsHint,
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
              decoration: InputDecoration(
                labelText: l10n.notesLabel,
                hintText: l10n.notesHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Botón guardar
            FilledButton(
              onPressed: _isLoading ? null : () => _saveProduct(l10n),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.createProductBtn), // Asegurar que exista o usar genérico
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