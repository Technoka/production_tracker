import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/project_product_model.dart';
import '../../models/user_model.dart';
import '../../services/project_product_service.dart';
import '../../utils/role_utils.dart';

class ProjectProductDetailScreen extends StatefulWidget {
  final String projectId;
  final String productId;
  final UserModel currentUser;

  const ProjectProductDetailScreen({
    super.key,
    required this.projectId,
    required this.productId,
    required this.currentUser,
  });

  @override
  State<ProjectProductDetailScreen> createState() =>
      _ProjectProductDetailScreenState();
}

class _ProjectProductDetailScreenState
    extends State<ProjectProductDetailScreen> {
  final ProjectProductService _productService = ProjectProductService();
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isLoading = false;
  
  // Controladores para edición
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _colorController;
  late TextEditingController _materialController;
  late TextEditingController _finishController;
  late TextEditingController _specialDetailsController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _depthController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _quantityController = TextEditingController();
    _unitPriceController = TextEditingController();
    _colorController = TextEditingController();
    _materialController = TextEditingController();
    _finishController = TextEditingController();
    _specialDetailsController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _depthController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _populateControllers(ProjectProductModel product) {
    _quantityController.text = product.quantity.toString();
    _unitPriceController.text = product.unitPrice.toStringAsFixed(2);
    _colorController.text = product.customization.color ?? '';
    _materialController.text = product.customization.material ?? '';
    _finishController.text = product.customization.finish ?? '';
    _specialDetailsController.text = product.customization.specialDetails ?? '';
    _widthController.text = product.customization.dimensions?.width?.toString() ?? '';
    _heightController.text = product.customization.dimensions?.height?.toString() ?? '';
    _depthController.text = product.customization.dimensions?.depth?.toString() ?? '';
    _notesController.text = product.notes ?? '';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _finishController.dispose();
    _specialDetailsController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _canEdit() {
    return RoleUtils.canManageProjects(widget.currentUser.role);
  }

  bool _canViewPrices() {
    return RoleUtils.canViewFinancials(widget.currentUser.role);
  }

  bool _canDelete() {
    return RoleUtils.canManageProjects(widget.currentUser.role);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProjectProductModel?>(
      stream: _productService
          .watchProjectProducts(widget.projectId)
          .map((products) => products.firstWhere(
                (p) => p.id == widget.productId,
                orElse: () => products.first, // Fallback temporal
              )),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del Producto')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del Producto')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Producto no encontrado'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final product = snapshot.data!;
        
        // Poblar controladores si estamos editando y aún no se han llenado
        if (_isEditing && _quantityController.text.isEmpty) {
          _populateControllers(product);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del Producto'),
            actions: [
              if (_canEdit() && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _populateControllers(product);
                    });
                  },
                ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                ),
              if (_canDelete() && !_isEditing)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          const Icon(Icons.content_copy, size: 20),
                          const SizedBox(width: 8),
                          const Text('Duplicar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'duplicate') {
                      await _duplicateProduct(product);
                    } else if (value == 'delete') {
                      await _deleteProduct(product);
                    }
                  },
                ),
            ],
          ),
          body: _isEditing
              ? _buildEditForm(product)
              : _buildDetailView(product),
          floatingActionButton: _isEditing
              ? FloatingActionButton.extended(
                  onPressed: _isLoading ? null : () => _saveChanges(product),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Guardar'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDetailView(ProjectProductModel product) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información del producto del catálogo
          _buildSectionTitle(context, 'Producto del Catálogo'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.catalogProductName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Referencia', product.catalogProductReference,
                      monospace: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estado y cantidad
          _buildSectionTitle(context, 'Estado y Cantidad'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Estado'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.statusDisplayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(product.status),
                      ),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.numbers),
                  title: const Text('Cantidad'),
                  trailing: Text(
                    '${product.quantity} unidades',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_canViewPrices()) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.euro),
                    title: const Text('Precio unitario'),
                    trailing: Text(
                      '€${product.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Precio total'),
                    trailing: Text(
                      '€${product.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Personalización
          if (product.customization.hasCustomizations) ...[
            _buildSectionTitle(context, 'Personalización'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...product.customization
                        .getCustomizationSummary()
                        .map((custom) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 20, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(custom)),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notas
          if (product.notes != null && product.notes!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Notas'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(product.notes!),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Acciones rápidas (cambiar estado)
          if (_canEdit()) ...[
            _buildSectionTitle(context, 'Cambiar Estado'),
            Wrap(
              spacing: 8,
              children: ProjectProductStatus.values
                  .map((status) => FilterChip(
                        label: Text(status.displayName),
                        selected: product.status == status.value,
                        onSelected: (selected) async {
                          if (selected) {
                            await _updateStatus(product, status.value);
                          }
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Información del sistema
          _buildSectionTitle(context, 'Información del Sistema'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Creado'),
                  subtitle: Text(dateFormat.format(product.createdAt)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('Última actualización'),
                  subtitle: Text(dateFormat.format(product.updatedAt)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEditForm(ProjectProductModel product) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, 'Cantidad y Precio'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad *',
                    border: OutlineInputBorder(),
                    suffixText: 'uds',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Cantidad inválida';
                    }
                    return null;
                  },
                ),
              ),
              if (_canViewPrices()) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio unitario',
                      border: OutlineInputBorder(),
                      prefixText: '€ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Personalización'),
          TextFormField(
            controller: _colorController,
            decoration: const InputDecoration(
              labelText: 'Color',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _materialController,
            decoration: const InputDecoration(
              labelText: 'Material',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _finishController,
            decoration: const InputDecoration(
              labelText: 'Acabado',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Dimensiones (cm)'),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Detalles y Notas'),
          TextFormField(
            controller: _specialDetailsController,
            decoration: const InputDecoration(
              labelText: 'Detalles especiales',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notas',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _saveChanges(ProjectProductModel product) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customization = ProductCustomization(
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        material: _materialController.text.trim().isNotEmpty
            ? _materialController.text.trim()
            : null,
        finish: _finishController.text.trim().isNotEmpty
            ? _finishController.text.trim()
            : null,
        specialDetails: _specialDetailsController.text.trim().isNotEmpty
            ? _specialDetailsController.text.trim()
            : null,
        dimensions: _buildCustomDimensions(),
      );

      final success = await _productService.updateProjectProduct(
        projectId: widget.projectId,
        productId: widget.productId,
        updatedBy: widget.currentUser.uid,
        quantity: int.parse(_quantityController.text),
        unitPrice: _canViewPrices()
            ? double.tryParse(_unitPriceController.text)
            : null,
        customization: customization,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar producto'),
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

  CustomDimensions? _buildCustomDimensions() {
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);
    final depth = double.tryParse(_depthController.text);

    if (width == null && height == null && depth == null) return null;

    return CustomDimensions(
      width: width,
      height: height,
      depth: depth,
      unit: 'cm',
    );
  }

  Future<void> _updateStatus(ProjectProductModel product, String newStatus) async {
    final success = await _productService.updateProductStatus(
      projectId: widget.projectId,
      productId: widget.productId,
      status: newStatus,
      updatedBy: widget.currentUser.uid,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Estado actualizado correctamente'
                : 'Error al actualizar estado',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _duplicateProduct(ProjectProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar producto'),
        content: const Text(
            '¿Deseas crear una copia de este producto en el proyecto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final newId = await _productService.duplicateProduct(
      projectId: widget.projectId,
      productId: widget.productId,
      createdBy: widget.currentUser.uid,
    );

    if (mounted) {
      if (newId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto duplicado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al duplicar producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(ProjectProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${product.catalogProductName}" del proyecto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _productService.removeProductFromProject(
      projectId: widget.projectId,
      productId: widget.productId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
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

  Widget _buildInfoRow(String label, String value, {bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: monospace ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'en_produccion':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}