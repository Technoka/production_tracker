import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product_catalog_model.dart';
import '../../models/batch_product_model.dart';
import '../../models/production_batch_model.dart';
import '../../services/product_catalog_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/phase_service.dart';
import '../../utils/filter_utils.dart';
import '../../services/organization_member_service.dart';
import '../../models/organization_member_model.dart';
import '../../services/auth_service.dart';

// TODO: comprobar que se usa scope y assignedMembers correctamente

class AddProductToBatchScreen extends StatefulWidget {
  final String organizationId;
  final String batchId;
  final String clientName;
  final String projectName;

  const AddProductToBatchScreen({
    super.key,
    required this.organizationId,
    required this.batchId,
    required this.clientName,
    required this.projectName,
  });

  @override
  State<AddProductToBatchScreen> createState() =>
      _AddProductToBatchScreenState();
}

class _AddProductToBatchScreenState extends State<AddProductToBatchScreen> {

  // Controladores
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _productNotesController = TextEditingController();

  // Estado del formulario
  ProductCatalogModel? _selectedProduct;
  bool _isLoading = false;
  String _productSearchQuery = '';
  String _productUrgencyLevel = 'medium';
  DateTime? _productExpectedDelivery;

  // NUEVO: Variable para familia seleccionada
  String? _selectedFamily;

  // Datos del lote
  String? _batchClientId;
  String? _batchProjectId;
  ProductionBatchModel? _batchData;
  late Stream<List<BatchProductModel>> _existingProductsStream;

  // NUEVO: Lista de productos pendientes de guardar
  final List<Map<String, dynamic>> _pendingProducts = [];

  //RBAC
  OrganizationMemberWithUser? _currentMember;

  @override
  void initState() {
    super.initState();
    _loadCurrentMember();
    _loadBatchInfo();
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData!;

    // Inicializar fecha por defecto
    _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));

    // Inicializar Stream aquí para evitar recargas al hacer setState
    _existingProductsStream =
        Provider.of<ProductionBatchService>(context, listen: false)
            .watchBatchProducts(widget.organizationId, widget.batchId, user.uid);

    _productSearchController.addListener(() {
      setState(() {
        _productSearchQuery = _productSearchController.text;
      });
    });
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

  void _removeProductFromList(int index) {
    setState(() {
      _pendingProducts.removeAt(index);
    });
  }

  Future<void> _loadBatchInfo() async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final batch =
        await batchService.getBatchById(widget.organizationId, widget.batchId);

    if (batch != null && mounted) {
      setState(() {
        _batchData = batch;
        _batchClientId = batch.clientId;
        _batchProjectId = batch.projectId;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _productSearchController.dispose();
    _productNotesController.dispose();
    super.dispose();
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

  // --- LÓGICA DE LISTA PENDIENTE ---

  void _addProductToPendingList() {
    // if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un producto')),
      );
      return;
    }

    // Validar límite total (Existentes + Pendientes)
    final currentTotal =
        (_batchData?.totalProducts ?? 0) + _pendingProducts.length;
    if (currentTotal >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El límite es de 100 productos por lote')),
      );
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final unitPrice = _unitPriceController.text.isNotEmpty
        ? double.tryParse(_unitPriceController.text)
        : _selectedProduct!.basePrice;

    setState(() {
      _pendingProducts.add({
        'product': _selectedProduct,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'expectedDeliveryDate': _productExpectedDelivery,
        'urgencyLevel': _productUrgencyLevel,
        'notes': _productNotesController.text.trim(),
        'family': _selectedFamily,
      });

      // Resetear formulario
      _selectedProduct = null;
      _quantityController.text = '1';
      _unitPriceController.clear();
      _productNotesController.clear();
      _productUrgencyLevel = 'medium';
      _productExpectedDelivery = DateTime.now().add(const Duration(days: 21));
      // No limpiamos el buscador para facilitar añadir productos similares si se desea
    });
  }

  Future<void> _saveAllProducts() async {
    if (_pendingProducts.isEmpty) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final phaseService = Provider.of<PhaseService>(context, listen: false);

    try {
      // Obtener fases de la organización
      final phases =
          await phaseService.getOrganizationPhases(widget.organizationId);
      if (phases.isEmpty) {
        throw Exception('No hay fases configuradas');
      }
      phases.sort((a, b) => a.order.compareTo(b.order));

      // ✅ CONSTRUIR LISTA DE BatchProductModel
      final List<BatchProductModel> batchProducts = [];

      // 1. Cambiamos a un bucle con índice 'i'
    for (int i = 0; i < _pendingProducts.length; i++) {
      final item = _pendingProducts[i];
      final product = item['product'] as ProductCatalogModel;

      // 2. Calculamos la variable productCount
      // (Contador actual del lote + índice actual + 1 para que sea secuencial)
      final int productNumber = _batchData!.totalProducts + i + 1;

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
        id: '', 
        batchId: widget.batchId,
        productCatalogId: product.id,
        productName: product.name,
        productReference: product.reference,
        family: item['family'],
        description: product.description,
        quantity: item['quantity'],
        currentPhase: phases.first.id,
        currentPhaseName: phases.first.name,
        phaseProgress: phaseProgress,
        productNumber: productNumber, 
        productCode: '', 
        unitPrice: item['unitPrice'],
        totalPrice: item['unitPrice'] != null
            ? item['unitPrice'] * item['quantity']
            : null,
        expectedDeliveryDate: item['expectedDeliveryDate'],
        urgencyLevel: item['urgencyLevel'],
        productNotes: item['notes'].isNotEmpty ? item['notes'] : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      batchProducts.add(batchProduct);
    }

      // ✅ LLAMAR A addProductsToBatch CON LA LISTA
      final success = await batchService.addProductsToBatch(
        organizationId: widget.organizationId,
        batchId: widget.batchId,
        products: batchProducts,
        userId: authService.currentUser!.uid,
        userName: authService.currentUser!.displayName ?? 'Usuario',
      );

      if (!success) {
        throw Exception('Error al añadir productos: ${batchService.error}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_pendingProducts.length} productos añadidos exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_batchData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Añadir Producto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Añadir Producto al Lote'),
            Text(
              _batchData!.batchNumber,
              style: const TextStyle(
                  fontSize: 14), // Tamaño más pequeño para el subtítulo
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProjectInformationCard(),
          const SizedBox(height: 12),

          // 1. Productos Existentes
          _buildExistingProductsSection(),
          const SizedBox(height: 12),

          // 2. Formulario Nuevo Producto
          _buildAddProductsSection(),

          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: _pendingProducts.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2))
                ],
              ),
              child: FilledButton(
                onPressed: (_isLoading || _currentMember == null)
                    ? null
                    : _saveAllProducts,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar productos'),
              ),
            )
          : null,
    );
  }

  // Se usa el Stream inicializado en initState para evitar recargas
  Widget _buildExistingProductsSection() {
    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Productos en el Lote',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_batchData!.totalProducts} guardados',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),

          StreamBuilder<List<BatchProductModel>>(
            stream: _existingProductsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()));
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay productos guardados.',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    EdgeInsets.zero, // Padding eliminado para reducir espacio
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];

                  final urgency = product.urgencyLevel as String? ?? 'medium';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. LEADING: Avatar con número
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              product.urgencyColor.withOpacity(0.2),
                          child: Text(
                            '#${product.productNumber}',
                            style: TextStyle(
                              color: product.urgencyColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 2. CENTRO: Información del producto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${product.productReference}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (product.expectedDeliveryDate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Entrega: ${_formatDate(product.expectedDeliveryDate!)}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                              if (product.productNotes != null &&
                                  product.productNotes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Notas: ${product.productNotes}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[800],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 3. DERECHA: Chip arriba, Acciones abajo
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ARRIBA: Chip de urgencia
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: product.urgencyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        product.urgencyColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                UrgencyLevel.fromString(urgency).displayName,
                                style: TextStyle(
                                  color: product.urgencyColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12), // Espacio en medio

                            // ABAJO: Cantidad y Borrar
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    'x${product.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          // Pequeño espacio final opcional
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildProjectInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Lote',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 12),
            Text(
              'Cliente: ${widget.clientName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Proyecto: ${widget.projectName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductsSection() {
    return Card(
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${_pendingProducts.length}/10',
                  style: TextStyle(
                      color: _pendingProducts.length >= 10
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
              stream: Provider.of<ProductCatalogService>(context, listen: false)
                  .getOrganizationProductsStream(widget.organizationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Obtenemos todos los productos
                final allProducts = snapshot.data ?? [];

                // Filtramos productos relevantes para este cliente/proyecto si es necesario
                // (Por ahora mostramos todos los de la organización que coincidan en familia,
                // pero podríamos filtrar por clientId si _selectedProject está definido)
                var relevantProducts = allProducts;
                if (_batchProjectId != null) {
                  // Opcional: filtrar solo productos de este cliente o públicos
                  relevantProducts = allProducts
                      .where((p) => p.clientId == _batchClientId || p.isPublic)
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
                    if (_batchProjectId == null)
                      Opacity(
                        opacity: 0.5,
                        child: IgnorePointer(
                          child: FilterUtils.buildFullWidthDropdown<String>(
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
                      if (_selectedFamily == null || _batchProjectId == null) {
                        return Opacity(
                          opacity: 0.5,
                          child: IgnorePointer(
                            child: FilterUtils.buildFullWidthDropdown<String>(
                              context: context,
                              label: 'Producto',
                              value: null,
                              icon: Icons.inventory,
                              hintText: 'Selecciona una familia primero',
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
                      final List<DropdownMenuItem<String>> dropdownItems = [];
// TODO: si el usuario tiene permiso para crear productos
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
                      dropdownItems
                          .addAll(familyProducts.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('SKU: ${p.reference}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )));

                      // Validar selección actual
                      final isSelectionValid = _selectedProduct != null &&
                          familyProducts
                              .any((p) => p.id == _selectedProduct!.id);
                      final currentValue =
                          isSelectionValid ? _selectedProduct!.id : null;

                      return FilterUtils.buildFullWidthDropdown<String>(
                        context: context,
                        label: 'Producto',
                        value: currentValue,
                        icon: Icons.inventory,
                        hintText: 'Seleccionar producto...',
                        items: dropdownItems,
                        onChanged: (value) {
                          if (value == '__CREATE_NEW__') {
                            _showQuickCreateProductDialog(_selectedFamily!);
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
              urgencyLevel: UrgencyLevel.fromString(_productUrgencyLevel),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
                hintText: 'Añade detalles específicos de este producto...',
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
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Cant.',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: _selectedProduct == null
                        ? null
                        : _addProductToPendingList,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Añadir al Lote'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de productos añadidos
            if (_pendingProducts.isEmpty)
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
                itemCount: _pendingProducts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _pendingProducts[index];
                  final product = item['product'] as ProductCatalogModel;
                  final quantity = item['quantity'] as int;
                  final deliveryDate =
                      item['expectedDeliveryDate'] as DateTime?;
                  final urgency = item['urgencyLevel'] as String? ??
                      UrgencyLevel.medium.value;
                  final notes = item['notes'] as String?;
                  final sequence = index + 1;

                  final urgencyLevel = UrgencyLevel.fromString(urgency);

                  return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade200)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 1. LEADING: Avatar con número
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      UrgencyLevel.fromString(urgency)
                                          .color
                                          .withOpacity(0.2),
                                  child: Text(
                                    '#$sequence',
                                    style: TextStyle(
                                      color: UrgencyLevel.fromString(urgency)
                                          .color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 2. CENTRO: Información del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'SKU: ${product.reference}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (deliveryDate != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Entrega: ${_formatDate(deliveryDate)}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                      if (notes != null &&
                                          notes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Notas: $notes',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue[800],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 3. DERECHA: Chip arriba, Acciones abajo
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // ARRIBA: Chip de urgencia
                                    if (UrgencyLevel.fromString(urgency)
                                            .value ==
                                        UrgencyLevel.urgent.value)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              UrgencyLevel.fromString(urgency)
                                                  .color
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: UrgencyLevel.fromString(
                                                      urgency)
                                                  .color
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          UrgencyLevel.fromString(urgency)
                                              .displayName,
                                          style: TextStyle(
                                            color:
                                                UrgencyLevel.fromString(urgency)
                                                    .color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                    const SizedBox(
                                        height: 12), // Espacio en medio

                                    // ABAJO: Cantidad y Borrar
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Text(
                                            'x$quantity',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () =>
                                              _removeProductFromList(index),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Icon(Icons.delete_outline,
                                                color: Colors.red, size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                },
              ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Método para mostrar popup de crear producto rápido
  Future<void> _showQuickCreateProductDialog(String familyName) async {
    final skuController = TextEditingController();
    final notesController = TextEditingController();

    if (_batchProjectId == null) {
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

      final createdId = await catalogService.createProduct(
        organizationId: widget.organizationId,
        name: family.capitalize, // Nombre auto-generado
        reference: sku,
        description: notes,
        family: family, // Asignamos la familia
        clientId: _batchClientId, // Cliente del proyecto
        createdBy: authService.currentUser!.uid,
        isPublic: false, // Por defecto privado para este cliente
        projects: [_batchProjectId!],
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

  Widget _buildProductSelector() {
    if (_batchClientId == null) return const LinearProgressIndicator();

    return StreamBuilder<List<ProductCatalogModel>>(
      stream: Provider.of<ProductCatalogService>(context, listen: false)
          .getOrganizationProductsStream(widget.organizationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
              height: 50, child: Center(child: LinearProgressIndicator()));

        var allProducts = snapshot.data ?? [];

        // 1. Filtrar por cliente
        var products = allProducts
            .where((p) => p.isPublic || p.clientId == _batchClientId)
            .toList();

        // 2. Filtrar por búsqueda
        if (_productSearchQuery.isNotEmpty) {
          final query = _productSearchQuery.toLowerCase();
          products = products
              .where((p) =>
                  p.name.toLowerCase().contains(query) ||
                  (p.reference?.toLowerCase().contains(query) ?? false))
              .toList();
        }

        // --- SOLUCIÓN ERROR "BAD STATE" ---
        // Verificamos si la selección actual sigue siendo válida en la lista filtrada
        final isSelectionValid = _selectedProduct != null &&
            products.any((p) => p.id == _selectedProduct!.id);

        // Si no es válida, pasamos null al dropdown (visual), pero mantenemos el estado si queremos
        // O según tu petición: "se elimine el producto seleccionado"
        final dropdownValue = isSelectionValid ? _selectedProduct!.id : null;

        return FilterUtils.buildFullWidthDropdown<String>(
          context: context,
          label: 'Producto',
          value: dropdownValue,
          icon: Icons.inventory,
          hintText: products.isEmpty ? 'Sin coincidencias' : 'Seleccionar...',
          items: products.map((product) {
            return DropdownMenuItem(
              value: product.id,
              child: Text(
                '${product.name} (SKU: ${product.reference ?? "-"})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (productId) {
            if (productId == null) return;
            setState(() {
              _selectedProduct = products.firstWhere((p) => p.id == productId);
              if (_selectedProduct!.basePrice != null) {
                _unitPriceController.text =
                    _selectedProduct!.basePrice!.toStringAsFixed(2);
              }
            });
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
