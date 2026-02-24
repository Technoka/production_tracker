import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product_catalog_model.dart';
import '../../models/user_model.dart';
import '../../services/product_catalog_service.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import 'package:provider/provider.dart';

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
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategories();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _referenceController =
        TextEditingController(text: widget.product.reference);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _categoryController =
        TextEditingController(text: widget.product.category ?? '');
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

    _secondaryMaterials =
        List.from(widget.product.materialInfo?.secondaryMaterials ?? []);
    _tags = List.from(widget.product.tags);
    _imageUrls = List.from(widget.product.imageUrls);

    _isPublic = widget.product.isPublic;
    _selectedClientId = widget.product.clientId;

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
    final catalogService =
        Provider.of<ProductCatalogService>(context, listen: false);
    final categories = await catalogService
        .getOrganizationCategories(widget.product.organizationId);
    if (mounted) {
      setState(() {
        _availableCategories = categories;
      });
    }
  }

  Future<void> _saveChanges(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final catalogService =
        Provider.of<ProductCatalogService>(context, listen: false);

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

      await catalogService.updateProduct(
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
        clientId: _isPublic ? null : _selectedClientId,
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productEditedSuccess(_selectedClientName ?? '')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  Future<bool> _onWillPop(AppLocalizations l10n) async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clientService = Provider.of<ClientService>(context, listen: false);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(l10n);
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: AppScaffold(
        currentIndex: AppNavIndex.management,
        title: l10n.editProductTitle,
        actions: [
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.unsavedChanges,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(l10n.basicInfo),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.productNameLabel,
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
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _categoryController.text),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _availableCategories;
                  }
                  return _availableCategories.where((category) => category
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  _categoryController.text = selection;
                  _markAsChanged();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text != _categoryController.text) {
                    controller.text = _categoryController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: l10n.categoryLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
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
              _buildSectionTitle(l10n.availabilityTitle),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: Text(
                          _isPublic ? l10n.publicProduct : l10n.privateProduct),
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
                          _hasChanges = true;
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

              if (!_isPublic) ...[
                StreamBuilder<List<ClientModel>>(
                  stream: clientService.watchClients(widget.organizationId),
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
                          _hasChanges = true;
                          _selectedClientName =
                              clients.firstWhere((c) => c.id == clientId).name;
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.blue[700]),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(l10n.materialTitle),
              TextFormField(
                controller: _primaryMaterialController,
                decoration: InputDecoration(
                  labelText: l10n.primaryMaterialLabel,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _markAsChanged(),
              ),
              const SizedBox(height: 16),
              _buildListField(
                title: l10n.secondaryMaterialsLabel,
                items: _secondaryMaterials,
                hintText: l10n.secondaryMaterialsHint,
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
                      decoration: InputDecoration(
                        labelText: l10n.finishLabel,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: l10n.colorLabel,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => _markAsChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _markAsChanged(),
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
                decoration: InputDecoration(
                  labelText: l10n.notesLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _markAsChanged(),
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isLoading || !_hasChanges
                    ? null
                    : () => _saveChanges(l10n),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveChangesButton),
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
