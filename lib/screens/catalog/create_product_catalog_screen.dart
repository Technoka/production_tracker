import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/product_catalog_service.dart';
import '../../services/client_service.dart';
import '../../services/project_service.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../models/product_catalog_model.dart';
import '../../utils/filter_utils.dart';
import '../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProductCatalogScreen extends StatefulWidget {
  final String? initialClientId;
  final String? initialProjectId;
  final String? initialFamily;
  final bool createNewFamily;

  const CreateProductCatalogScreen({
    super.key,
    this.initialClientId,
    this.initialProjectId,
    this.initialFamily,
    this.createNewFamily = false,
  });

  @override
  State<CreateProductCatalogScreen> createState() =>
      _CreateProductCatalogScreenState();
}

class _CreateProductCatalogScreenState
    extends State<CreateProductCatalogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedClientId;
  String? _selectedProjectId;
  String? _selectedFamily;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  String? _pendingNewFamily;

  @override
  void initState() {
    super.initState();
    
    // Pre-seleccionar valores iniciales
    if (widget.initialClientId != null) {
      _selectedClientId = widget.initialClientId;
    }
    if (widget.initialProjectId != null) {
      _selectedProjectId = widget.initialProjectId;
    }
    if (widget.initialFamily != null) {
      _selectedFamily = widget.initialFamily;
    }

    // Mostrar diálogo de crear familia si viene el parámetro
    if (widget.createNewFamily) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateFamilyDialog();
      });
    }

    // Detectar cambios en los campos
    _nameController.addListener(_markAsChanged);
    _referenceController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _notesController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _showCreateFamilyDialog() async {
    final familyController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Nueva Familia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa el nombre de la nueva familia de productos. Deberás crear al menos un producto para que la familia se registre.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: familyController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la familia',
                  hintText: 'Ej: Bolsos de mano',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: familyController,
              builder: (context, value, child) {
                final isValid = value.text.trim().isNotEmpty;
                return FilledButton(
                  onPressed: isValid
                      ? () => Navigator.pop(context, value.text.trim())
                      : null,
                  child: const Text('Continuar'),
                );
              },
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _pendingNewFamily = result;
        _selectedFamily = result;
      });
    } else {
      // Si cancela, volver atrás
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text(
          '¿Estás seguro que quieres salir? Los cambios no guardados se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleCreate() async {
  if (!_formKey.currentState!.validate()) return;

  if (_selectedClientId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor selecciona un cliente'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_selectedProjectId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor selecciona un proyecto'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_selectedFamily == null || _selectedFamily!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor selecciona o crea una familia'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final catalogService = Provider.of<ProductCatalogService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null || user.organizationId == null) return;

    // 1. Crear el producto en el catálogo
    final productId = await catalogService.createProduct(
      organizationId: user.organizationId!,
      name: _nameController.text.trim(),
      reference: _referenceController.text.trim(),
      description: _descriptionController.text.trim(),
      family: _selectedFamily,
      clientId: _selectedClientId,
      createdBy: user.uid,
      isPublic: false,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      projects: [_selectedProjectId!],
    );

    if (productId != null) {

      if (mounted) {
        _hasUnsavedChanges = false; // Evitar el diálogo al salir
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pendingNewFamily != null
                  ? 'Familia "$_pendingNewFamily" y producto creados exitosamente'
                  : 'Producto creado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear el producto'),
          backgroundColor: Colors.red,
        ),
      );
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
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.newProduct)),
        body: const Center(
          child: Text('Debes pertenecer a una organización'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.newProduct),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildBasicInfoCard(context, user!, l10n),
                    const SizedBox(height: 16),
                    _buildNotesCard(context, l10n),
                  ],
                ),
              ),
              _buildBottomBar(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(
    BuildContext context,
    dynamic user,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.basicInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Nombre del producto
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${l10n.productName} *',
                hintText: 'Ej: Bolso de mano clásico',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
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
            
            // Referencia (SKU)
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: '${l10n.reference} (SKU) *',
                hintText: 'Ej: BLS-001',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
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
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '${l10n.description} *',
                hintText: 'Describe las características del producto',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
                alignLabelWithHint: true,
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
            const SizedBox(height: 20),
            
            // Cliente
            _buildClientDropdown(context, user, l10n),
            const SizedBox(height: 16),
            
            // Proyecto
            _buildProjectDropdown(context, user, l10n),
            const SizedBox(height: 16),
            
            // Familia
            _buildFamilyDropdown(context, user, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDropdown(
    BuildContext context,
    dynamic user,
    AppLocalizations l10n,
  ) {
    final clientService = Provider.of<ClientService>(context);

    return StreamBuilder<List<ClientModel>>(
      stream: clientService.watchClients(user.organizationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDropdownSkeleton(l10n.client);
        }

        final clients = snapshot.data ?? [];

        if (clients.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay clientes registrados',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return FilterUtils.buildFullWidthDropdown<String>(
          context: context,
          label: l10n.client,
          value: _selectedClientId,
          icon: Icons.business,
          isRequired: true,
          hintText: l10n.selectClient,
          items: clients.map((client) {
            return DropdownMenuItem(
              value: client.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (client.company.isNotEmpty)
                    Text(
                      client.company,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClientId = value;
              _selectedProjectId = null; // Reset proyecto
              _selectedFamily = null; // Reset familia
              _markAsChanged();
            });
          },
        );
      },
    );
  }

  Widget _buildProjectDropdown(
    BuildContext context,
    dynamic user,
    AppLocalizations l10n,
  ) {
    if (_selectedClientId == null) {
      return Opacity(
        opacity: 0.5,
        child: IgnorePointer(
          child: FilterUtils.buildFullWidthDropdown<String>(
            context: context,
            label: l10n.project,
            value: null,
            icon: Icons.folder,
            isRequired: true,
            hintText: 'Selecciona un cliente primero',
            items: const [],
            onChanged: (_) {},
          ),
        ),
      );
    }

    final projectService = Provider.of<ProjectService>(context);

    return StreamBuilder<List<ProjectModel>>(
      stream: projectService.watchClientProjects(
        _selectedClientId!,
        user.organizationId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDropdownSkeleton(l10n.project);
        }

        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay proyectos para este cliente',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return FilterUtils.buildFullWidthDropdown<String>(
          context: context,
          label: l10n.project,
          value: _selectedProjectId,
          icon: Icons.folder,
          isRequired: true,
          hintText: l10n.selectProject,
          items: projects.map((project) {
            return DropdownMenuItem(
              value: project.id,
              child: Text(
                project.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProjectId = value;
              _selectedFamily = null; // Reset familia
              _markAsChanged();
            });
          },
        );
      },
    );
  }

  Widget _buildFamilyDropdown(
    BuildContext context,
    dynamic user,
    AppLocalizations l10n,
  ) {
    if (_selectedProjectId == null) {
      return Opacity(
        opacity: 0.5,
        child: IgnorePointer(
          child: FilterUtils.buildFullWidthDropdown<String>(
            context: context,
            label: l10n.family,
            value: null,
            icon: Icons.category,
            isRequired: true,
            hintText: 'Selecciona un proyecto primero',
            items: const [],
            onChanged: (_) {},
          ),
        ),
      );
    }

    final catalogService = Provider.of<ProductCatalogService>(context);

    return StreamBuilder<List<ProductCatalogModel>>(
      stream: catalogService.getProjectProductsStream(
        user.organizationId!,
        _selectedProjectId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDropdownSkeleton(l10n.family);
        }

        final allProducts = snapshot.data ?? [];
        
        // Extraer familias únicas
        final families = allProducts
            .map((p) => p.family)
            .where((f) => f != null && f.isNotEmpty)
            .toSet()
            .toList();
        families.sort();

        // Preparar items del dropdown
        final List<DropdownMenuItem<String>> dropdownItems = [];

        // Opción 1: Crear nueva familia
        dropdownItems.add(
          const DropdownMenuItem(
            value: '__CREATE_NEW__',
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Crear nueva familia',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

        // Si hay una familia pendiente de crear que no está en la lista, agregarla
        if (_pendingNewFamily != null && !families.contains(_pendingNewFamily)) {
          dropdownItems.add(
            DropdownMenuItem(
              value: _pendingNewFamily,
              child: Row(
                children: [
                  Icon(Icons.new_label, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_pendingNewFamily (nueva)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Opciones: Familias existentes
        dropdownItems.addAll(
          families.map((family) => DropdownMenuItem(
            value: family,
            child: Text(
              family!,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          )),
        );

        // Validar que el valor seleccionado esté en los items
        final validValue = _selectedFamily != null &&
            (families.contains(_selectedFamily) || 
             _selectedFamily == _pendingNewFamily ||
             _selectedFamily == '__CREATE_NEW__')
            ? _selectedFamily
            : null;

        return FilterUtils.buildFullWidthDropdown<String>(
          context: context,
          label: l10n.family,
          value: validValue,
          icon: Icons.category,
          isRequired: true,
          hintText: families.isEmpty
              ? 'No hay familias, crea una nueva'
              : l10n.selectFamily,
          items: dropdownItems,
          onChanged: (value) async {
            if (value == '__CREATE_NEW__') {
              await _showCreateFamilyDialog();
            } else {
              setState(() {
                _selectedFamily = value;
                _markAsChanged();
              });
            }
          },
        );
      },
    );
  }

  Widget _buildNotesCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notes_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.notes,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${l10n.optional})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Agrega notas adicionales sobre el producto...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSkeleton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleCreate,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.createProduct),
          ),
        ),
      ),
    );
  }
}