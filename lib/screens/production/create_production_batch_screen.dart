import 'package:flex_color_picker/flex_color_picker.dart';
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
import '../../services/organization_member_service.dart';
import '../../utils/filter_utils.dart';
import '../../models/batch_product_model.dart';
import '../../models/organization_member_model.dart';

class CreateProductionBatchScreen extends StatefulWidget {
  final String organizationId;
  final String? projectId;

  const CreateProductionBatchScreen({
    super.key,
    required this.organizationId,
    this.projectId,
  });

  @override
  State<CreateProductionBatchScreen> createState() =>
      _CreateProductionBatchScreenState();
}

class _CreateProductionBatchScreenState
    extends State<CreateProductionBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  ProjectModel? _selectedProject;
  final String _urgencyLevel = UrgencyLevel.medium.value;
  DateTime? _expectedCompletionDate;
  bool _isLoading = false;
  final _prefixController = TextEditingController();
  final ValueNotifier<String> _batchNumberPreview =
      ValueNotifier<String>('___2601');

  // --- VARIABLES PARA GESTIÓN DE PRODUCTOS ---
  final List<Map<String, dynamic>> _productsToAdd = [];
  ProductCatalogModel? _selectedProduct;
  final _productQuantityController = TextEditingController(text: '1');

  // NUEVO: Variable para familia seleccionada
  String? _selectedFamily;

  DateTime? _productExpectedDelivery;
  String _productUrgencyLevel = UrgencyLevel.medium.value;
  final _productNotesController = TextEditingController();

  // RBAC
  OrganizationMemberWithUser? _currentMember;
  // -------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadCurrentMember();
    if (widget.projectId != null) {
      _loadProject();
    }
    _prefixController.addListener(_updateBatchNumberPreview);
    _updateBatchNumberPreview();

    _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));
  }

  Future<void> _loadCurrentMember() async {
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final member = await memberService.getCurrentMember(
      widget.organizationId,
      authService.currentUser!.uid,
    );

    if (mounted) {
      setState(() {
        _currentMember = member;
      });
    }
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
    _productQuantityController.dispose();
    _productNotesController.dispose();
    super.dispose();
  }

Future<void> _loadProject() async {
  final projectService = Provider.of<ProjectService>(context, listen: false);
  final authService = Provider.of<AuthService>(context, listen: false);
  
  // TODO: falta añadir canWithScope ('projects', 'view')

  final project = await projectService.getProject(
    widget.organizationId,
    widget.projectId!,
  );
  
  if (project != null && mounted) {
    setState(() {
      _selectedProject = project;
    });
  }
}

  // --- MÉTODOS PARA GESTIÓN DE PRODUCTOS ---
  void _addProductToList() {
    if (_selectedProduct == null) return;

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
        'product': _selectedProduct,
        'quantity': quantity,
        'expectedDeliveryDate': _productExpectedDelivery,
        'urgencyLevel': _productUrgencyLevel,
        'notes': _productNotesController.text.trim().isEmpty
            ? null
            : _productNotesController.text.trim(),
      });
      // Resetear selección
      _selectedProduct = null;
      _productQuantityController.text = '1';
      // MANTENEMOS la familia seleccionada para facilitar añadir más del mismo tipo
      // _selectedFamily = null;
      _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));
      _productUrgencyLevel = UrgencyLevel.medium.value;
      _productNotesController.clear();
    });
  }

  void _removeProductFromList(int index) {
    setState(() {
      _productsToAdd.removeAt(index);
    });
  }

  Future<void> _selectProductDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _productExpectedDelivery ??
          DateTime.now().add(const Duration(days: 21)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha de entrega del producto',
    );

    if (picked != null) {
      setState(() {
        _productExpectedDelivery = picked;
      });
    }
  }

  // NUEVO: Método para mostrar popup de crear producto rápido
  Future<void> _showQuickCreateProductDialog(String familyName) async {
    final skuController = TextEditingController();
    final notesController = TextEditingController();

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Debes seleccionar un proyecto primero')),
      );
      return;
    }

    final String familyNameCapitalized = familyName.isNotEmpty
        ? '${familyName[0].toUpperCase()}${familyName.substring(1)}'
        : familyName;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Crear producto en "$familyNameCapitalized"', // Asegúrate que esta variable exista o pásala
          style: const TextStyle(fontSize: 14),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skuController,
              decoration: const InputDecoration(
                labelText: 'SKU',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          // Usamos ValueListenableBuilder para escuchar cambios en el controlador
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: skuController,
            builder: (context, value, child) {
              // Verificamos si hay texto (quitando espacios en blanco)
              final bool isValid = value.text.trim().isNotEmpty;

              return FilledButton(
                // Si no es válido, onPressed es null (lo que deshabilita/pone en gris el botón)
                onPressed: isValid ? () => Navigator.pop(context, true) : null,
                child: const Text('Crear Producto'),
              );
            },
          ),
        ],
      ),
    );

    if (result == true && skuController.text.isNotEmpty) {
      await _createQuickProduct(
        sku: skuController.text.trim(),
        notes: notesController.text.trim(),
        family: familyName,
      );
    }
  }

  Future<void> _createQuickProduct({
    required String sku,
    required String notes,
    required String family,
  }) async {
    try {
      setState(() => _isLoading = true);

      final catalogService =
          Provider.of<ProductCatalogService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // IMPORTANTE: Asumimos que el servicio tiene un método addProduct o createProduct.
      // Si no existe tal cual, deberás adaptarlo a tu servicio real.
      final createdId = await catalogService.createProduct(
        organizationId: widget.organizationId,
        name: '${family.capitalize}', // Nombre auto-generado
        reference: sku,
        description: notes,
        family: family, // Asignamos la familia
        clientId: _selectedProject!.clientId, // Cliente del proyecto
        createdBy: authService.currentUser!.uid,
        isPublic: false, // Por defecto privado para este cliente
      );

      if (createdId != null) {
        // Recargar para que aparezca en el dropdown y seleccionarlo
        // Al usar StreamBuilder en el build, la UI se actualizará sola,
        // pero necesitamos seleccionar el ID nuevo.

        // Pequeño delay para asegurar que Firestore propague el cambio localmente
        await Future.delayed(const Duration(milliseconds: 300));

        final newProduct = await catalogService.getProductById(
            widget.organizationId, createdId);

        setState(() {
          // Asignamos el producto recién creado
          // Nota: Necesitamos reconstruir el objeto completo con el ID real para asignarlo a _selectedProduct
          _selectedProduct = newProduct!.copyWith(id: createdId);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto creado y seleccionado')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear producto: $e')),
        );
      }
    }
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
            // ... (Información del lote y Proyecto se mantienen igual)
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
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(3),
                        UpperCaseTextFormatter(),
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
                                  Icon(Icons.preview,
                                      size: 18, color: Colors.blue[700]),
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

            // Notas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas del lote (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Añade notas sobre este lote...',
                        hintStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- SECCIÓN: PRODUCTOS DEL LOTE (MODIFICADA) ---
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
                            Icon(Icons.inventory_2_outlined,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Añadir Productos',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '${_productsToAdd.length}/10',
                          style: TextStyle(
                              color: _productsToAdd.length >= 10
                                  ? Colors.red
                                  : Colors.grey,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'También puedes añadir productos al lote después de crearlo.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    // Usamos un StreamBuilder común para obtener todos los productos
                    // y luego filtrar familias y productos en memoria para los dropdowns
                    StreamBuilder<List<ProductCatalogModel>>(
                      stream: Provider.of<ProductCatalogService>(context,
                              listen: false)
                          .getOrganizationProductsStream(widget.organizationId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());

                        // Obtenemos todos los productos
                        final allProducts = snapshot.data ?? [];

                        // Filtramos productos relevantes para este cliente/proyecto si es necesario
                        // (Por ahora mostramos todos los de la organización que coincidan en familia,
                        // pero podríamos filtrar por clientId si _selectedProject está definido)
                        var relevantProducts = allProducts;
                        if (_selectedProject != null) {
                          // Opcional: filtrar solo productos de este cliente o públicos
                          relevantProducts = allProducts
                              .where((p) =>
                                  p.clientId == _selectedProject!.clientId ||
                                  p.isPublic)
                              .toList();
                        }

                        // 1. Extraer Familias Únicas
                        final families = relevantProducts
                            .map((p) => p.family)
                            .where((f) => f != null && f.isNotEmpty)
                            .toSet()
                            .toList();
                        families.sort();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- SELECTOR DE FAMILIA ---

                            // Si no hay proyecto seleccionado, no se puede seleccionar familia
                            if (_selectedProject == null)
                              Opacity(
                                opacity: 0.5,
                                child: IgnorePointer(
                                  child: FilterUtils.buildFullWidthDropdown<
                                      String>(
                                    context: context,
                                    label: 'Familia',
                                    value: null,
                                    icon: Icons.category_outlined,
                                    hintText: 'Selecciona un proyecto primero',
                                    items: [],
                                    onChanged: (_) {},
                                  ),
                                ),
                              )
                            else
                              FilterUtils.buildFullWidthDropdown<String>(
                                context: context,
                                label: 'Familia de Productos',
                                value: _selectedFamily,
                                icon: Icons.category_outlined,
                                hintText: families.isEmpty
                                    ? 'No hay familias definidas'
                                    : 'Seleccionar familia...',
                                items: families.map((f) {
                                  // Lógica segura para capitalizar la primera letra solo visualmente
                                  final String text = f ?? '';
                                  final String displayName = text.isNotEmpty
                                      ? '${text[0].toUpperCase()}${text.substring(1)}'
                                      : text;

                                  return DropdownMenuItem(
                                    value:
                                        f, // ⚠️ IMPORTANTE: Mantener 'f' original para que el filtro funcione
                                    child: Text(
                                        displayName), // Aquí mostramos la versión con mayúscula
                                  );
                                }).toList(),
                                // ------------------------

                                onChanged: (val) {
                                  setState(() {
                                    _selectedFamily = val;
                                    _selectedProduct = null;
                                  });
                                },
                              ),

                            const SizedBox(height: 12),

                            // --- SELECTOR DE PRODUCTO (Filtrado por Familia) ---
                            Builder(builder: (context) {
                              // Si no hay familia seleccionada
                              if (_selectedFamily == null ||
                                  _selectedProject == null) {
                                return Opacity(
                                  opacity: 0.5,
                                  child: IgnorePointer(
                                    child: FilterUtils.buildFullWidthDropdown<
                                        String>(
                                      context: context,
                                      label: 'Producto',
                                      value: null,
                                      icon: Icons.inventory,
                                      hintText:
                                          'Selecciona una familia primero',
                                      items: [],
                                      onChanged: (_) {},
                                    ),
                                  ),
                                );
                              }

                              // Filtrar productos por la familia seleccionada
                              final familyProducts = relevantProducts
                                  .where((p) => p.family == _selectedFamily)
                                  .toList();

                              // Preparamos los items del dropdown
                              final List<DropdownMenuItem<String>>
                                  dropdownItems = [];

                              // OPCIÓN 1: Crear nuevo producto
                              dropdownItems.add(
                                const DropdownMenuItem(
                                  value: '__CREATE_NEW__',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline,
                                          color: Colors.blue, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Crear nuevo producto',
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Divider(
                                        height: 1,
                                      ),
                                      SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              );

                              // OPCIONES: Productos existentes
                              dropdownItems.addAll(
                                  familyProducts.map((p) => DropdownMenuItem(
                                        value: p.id,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('SKU: ${p.reference}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      )));

                              // Validar selección actual
                              final isSelectionValid = _selectedProduct !=
                                      null &&
                                  familyProducts
                                      .any((p) => p.id == _selectedProduct!.id);
                              final currentValue = isSelectionValid
                                  ? _selectedProduct!.id
                                  : null;

                              return FilterUtils.buildFullWidthDropdown<String>(
                                context: context,
                                label: 'Producto',
                                value: currentValue,
                                icon: Icons.inventory,
                                hintText: 'Seleccionar producto...',
                                items: dropdownItems,
                                onChanged: (value) {
                                  if (value == '__CREATE_NEW__') {
                                    _showQuickCreateProductDialog(
                                        _selectedFamily!);
                                  } else if (value != null) {
                                    setState(() {
                                      _selectedProduct = familyProducts
                                          .firstWhere((p) => p.id == value);
                                    });
                                  }
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Urgencia del producto
                    FilterUtils.buildUrgencyBinaryToggle(
                      context: context,
                      urgencyLevel:
                          UrgencyLevel.fromString(_productUrgencyLevel),
                      onChanged: (newUrgency) {
                        setState(() {
                          _productUrgencyLevel = newUrgency;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Fecha de entrega
                    InkWell(
                      onTap: _selectProductDeliveryDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Fecha de entrega estimada',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(_productExpectedDelivery!),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Notas del producto
                    TextFormField(
                      controller: _productNotesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notas del producto (opcional)',
                        labelStyle: TextStyle(fontSize: 14),
                        hintText:
                            'Añade detalles específicos de este producto...',
                        hintStyle: TextStyle(fontSize: 12),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.notes),
                        alignLabelWithHint: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),

                    const SizedBox(height: 12),

                    // Cantidad y Botón Añadir
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _productQuantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Cant.',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: _selectedProduct == null
                                ? null
                                : _addProductToList,
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
                          final product =
                              item['product'] as ProductCatalogModel;
                          final quantity = item['quantity'] as int;
                          final deliveryDate =
                              item['expectedDeliveryDate'] as DateTime?;
                          final urgency = item['urgencyLevel'] as String? ??
                              UrgencyLevel.medium.value;
                          final notes = item['notes'] as String?;
                          final sequence = index + 1;

                          final urgencyLevel = UrgencyLevel.fromString(urgency);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  urgencyLevel.color.withOpacity(0.2),
                              child: Text(
                                '#$sequence',
                                style: TextStyle(
                                    color: urgencyLevel.color,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text('SKU: ${product.reference}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (deliveryDate != null)
                                  Text(
                                    'Entrega: ${_formatDate(deliveryDate)}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                if (notes != null)
                                  Text(
                                    'Notas: $notes',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontStyle: FontStyle.italic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('x$quantity',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _removeProductFromList(index),
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

  // ... (Resto de métodos auxiliares: _buildSelectedProjectCard, _buildProjectSelector, _createBatch, _formatDate, UpperCaseTextFormatter se mantienen igual)

  // Incluyo los métodos mínimos necesarios para que el archivo sea funcional al copiar
  Widget _buildSelectedProjectCard() {
    // ... (Igual que en tu archivo original)
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
                        .getClientStream(
                            widget.organizationId, _selectedProject!.clientId),
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
          .watchProjectsWithScope(widget.organizationId, _currentMember!.userId),
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

        // Cargar información de clientes para mostrar en el dropdown
        return StreamBuilder<List<ClientModel>>(
          stream: Provider.of<ClientService>(context, listen: false)
              .watchClients(widget.organizationId),
          builder: (context, clientSnapshot) {
            final clients = clientSnapshot.data ?? [];
            final clientMap = {for (var c in clients) c.id: c};

            return FilterUtils.buildFullWidthDropdown<String>(
              context: context,
              label: 'Proyecto',
              value: _selectedProject?.id,
              icon: Icons.folder_outlined,
              hintText: 'Seleccionar proyecto...',
              isRequired: true,
              items: projects.map((project) {
                final client = clientMap[project.clientId];
                return DropdownMenuItem(
                  value: project.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        project.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (client != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Cliente: ${client.name}',
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (projectId) {
                if (projectId == null) return;
                setState(() {
                  _selectedProject =
                      projects.firstWhere((p) => p.id == projectId);
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
  final phaseService = Provider.of<PhaseService>(context, listen: false);

  try {
    final client = await clientService.getClient(
      widget.organizationId,
      _selectedProject!.clientId,
    );

    if (client == null) {
      throw Exception('No se pudo obtener la información del cliente');
    }

    // 1. Crear el Lote
    final batchId = await batchService.createBatch(
      organizationId: widget.organizationId,
      userId: authService.currentUser!.uid,
      projectId: _selectedProject!.id,
      projectName: _selectedProject!.name,
      clientId: client.id,
      clientName: client.name,
      createdBy: authService.currentUser!.uid,
      batchPrefix: _prefixController.text.toUpperCase(),
      batchNumber: _batchNumberPreview.value,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (batchId == null) {
      throw Exception(batchService.error ?? 'Error desconocido al crear lote');
    }

    // 2. Si hay productos en la lista, añadirlos en batch
    if (_productsToAdd.isNotEmpty) {
      // Obtener fases de la organización (necesarias para crear productos)
      final phases = await phaseService.getOrganizationPhases(widget.organizationId);
      
      if (phases.isEmpty) {
        debugPrint('Advertencia: No hay fases configuradas, no se pudieron añadir productos.');
      } else {
        phases.sort((a, b) => a.order.compareTo(b.order));

        // ✅ CONSTRUIR LISTA DE BatchProductModel
        final List<BatchProductModel> batchProducts = [];
        
        for (int i = 0; i < _productsToAdd.length; i++) {
          final item = _productsToAdd[i];
          final product = item['product'] as ProductCatalogModel;
          final quantity = item['quantity'] as int;
          final deliveryDate = item['expectedDeliveryDate'] as DateTime?;
          final urgency = item['urgencyLevel'] as String? ?? 'medium';
          final notes = item['notes'] as String?;
          final family = item['family'];

          // Crear progreso de fases inicial
          final Map<String, PhaseProgressData> phaseProgress = {};
          for (var phase in phases) {
            phaseProgress[phase.id] = PhaseProgressData(
              status: phase.id == phases.first.id ? 'in_progress' : 'pending',
              startedAt: phase.id == phases.first.id ? DateTime.now() : null,
            );
          }

          // Construir BatchProductModel
          final batchProduct = BatchProductModel(
            id: '', // Se asignará en el servicio
            batchId: batchId,
            productCatalogId: product.id,
            productName: product.name,
            productReference: product.reference,
            family: family,
            description: product.description,
            quantity: quantity,
            currentPhase: phases.first.id,
            currentPhaseName: phases.first.name,
            phaseProgress: phaseProgress,
            productNumber: 0, // Se asignará en el servicio (secuencial)
            productCode: '', // Se generará en el servicio
            unitPrice: product.basePrice,
            totalPrice: product.basePrice != null ? product.basePrice! * quantity : null,
            expectedDeliveryDate: deliveryDate,
            urgencyLevel: urgency,
            productNotes: notes,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          batchProducts.add(batchProduct);
        }

        // ✅ LLAMAR A addProductsToBatch CON LA LISTA
        final success = await batchService.addProductsToBatch(
          organizationId: widget.organizationId,
          batchId: batchId,
          products: batchProducts,
          userId: authService.currentUser!.uid,
          userName: authService.currentUser!.displayName ?? 'Usuario',
        );

        if (!success) {
          throw Exception('Error al añadir productos: ${batchService.error}');
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
