import 'package:flutter/material.dart';
import 'package:gestion_produccion/helpers/approval_helper.dart';
import 'package:gestion_produccion/models/pending_object_model.dart';
import 'package:gestion_produccion/services/notification_service.dart';
import 'package:gestion_produccion/services/organization_member_service.dart';
import 'package:gestion_produccion/services/pending_object_service.dart';
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

/// Pantalla unificada para crear y editar productos del catálogo
/// 
/// Modo CREAR: product == null
/// Modo EDITAR: product != null
class ProductCatalogFormScreen extends StatefulWidget {
  final ProductCatalogModel? product; // null = crear, no-null = editar
  final String? initialClientId;
  final String? initialProjectId;
  final String? initialFamily;
  final bool createNewFamily;

  const ProductCatalogFormScreen({
    super.key,
    this.product,
    this.initialClientId,
    this.initialProjectId,
    this.initialFamily,
    this.createNewFamily = false,
  });

  @override
  State<ProductCatalogFormScreen> createState() =>
      _ProductCatalogFormScreenState();
}

class _ProductCatalogFormScreenState extends State<ProductCatalogFormScreen> {
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

  // Getters de modo
  bool get isEditMode => widget.product != null;
  bool get isCreateMode => widget.product == null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (isEditMode) {
      // MODO EDICIÓN: Cargar datos del producto existente
      final product = widget.product!;
      _nameController.text = product.name;
      _referenceController.text = product.reference;
      _descriptionController.text = product.description;
      _notesController.text = product.notes ?? '';
      _selectedClientId = product.clientId;
      _selectedFamily = product.family;
      
      // Cargar projectId desde la lista de proyectos del producto
      if (product.projects.isNotEmpty) {
        _selectedProjectId = product.projects.first;
      }
    } else {
      // MODO CREACIÓN: Pre-seleccionar valores iniciales si existen
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
      // Si cancela en modo creación, volver atrás
      if (mounted && isCreateMode) {
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

  Future<void> _handleSubmit() async {
    // if (!_formKey.currentState!.validate()) return;

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
      if (isCreateMode) {
        await _handleCreate();
      } else {
        await _handleUpdate();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCreate() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final catalogService = Provider.of<ProductCatalogService>(context, listen: false);
    final memberService = Provider.of<OrganizationMemberService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final pendingService = Provider.of<PendingObjectService>(context, listen: false);
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    if (user == null || user.organizationId == null) return;

    // Verificar si requiere aprobación
    final userIsClient = memberService.currentMember?.roleId == 'client';
    final requiresApproval = userIsClient;

    String? resultId;

    if (requiresApproval) {
      // FLUJO CON APROBACIÓN
      resultId = await ApprovalHelper.createOrRequestApproval(
        organizationId: user.organizationId!,
        objectType: PendingObjectType.productCatalog,
        collectionRoute: 'product_catalog',
        modelData: {
          'name': _nameController.text.trim(),
          'reference': _referenceController.text.trim(),
          'description': _descriptionController.text.trim(),
          'family': _selectedFamily!,
          'clientId': _selectedClientId!,
          'projects': [_selectedProjectId!],
          'notes': _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          'organizationId': user.organizationId!,
          'createdBy': user.uid,
          'isActive': true,
          'isPublic': true,
          'tags': [],
          'imageUrls': [],
          'specifications': {},
          'usageCount': 0,
          'approvalStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        createdBy: user.uid,
        createdByName: user.name,
        requiresApproval: true,
        userIsClient: true,
        pendingService: pendingService,
        notificationService: notificationService,
        organizationMemberService: memberService,
        clientId: _selectedClientId,
      );

      if (mounted && resultId != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productCreationPendingApproval),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // FLUJO DIRECTO (SIN APROBACIÓN)
      resultId = await catalogService.createProduct(
        organizationId: user.organizationId!,
        name: _nameController.text.trim(),
        reference: _referenceController.text.trim(),
        description: _descriptionController.text.trim(),
        family: _selectedFamily!,
        clientId: _selectedClientId!,
        projects: [_selectedProjectId!],
        createdBy: user.uid,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        if (resultId != null) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al crear producto',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleUpdate() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final catalogService = Provider.of<ProductCatalogService>(context, listen: false);
    final user = authService.currentUserData;
    final l10n = AppLocalizations.of(context)!;

    if (user == null || widget.product == null) return;

    // TODO: En el futuro, verificar si requiere aprobación según el rol
    // Por ahora, actualización directa sin flujo de aprobación

    final success = await catalogService.updateProduct(
      organizationId: widget.product!.organizationId,
      productId: widget.product!.id,
      updatedBy: user.uid,
      name: _nameController.text.trim(),
      reference: _referenceController.text.trim(),
      description: _descriptionController.text.trim(),
      family: _selectedFamily,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      // clientId y projects no se actualizan (readonly en edición)
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productEditedSuccess('')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar producto',
            ),
            backgroundColor: Colors.red,
          ),
        );
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
        appBar: AppBar(
          title: Text(isCreateMode ? 'Nuevo Producto' : 'Editar Producto'),
        ),
        body: const Center(
          child: Text('Debes pertenecer a una organización'),
        ),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isCreateMode 
                ? 'Nuevo Producto' 
                : 'Editar: ${widget.product!.name}',
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Información Básica
                      _buildBasicInfoCard(context, l10n),
                      const SizedBox(height: 16),

                      // Seleccionar Cliente y Proyecto
                      if (isCreateMode) ...[
                        _buildClientCard(context, user!, l10n),
                        const SizedBox(height: 16),
                        _buildProjectCard(context, user, l10n),
                        const SizedBox(height: 16),
                      ] else ...[
                        // En modo edición, mostrar cliente y proyecto readonly
                        _buildReadOnlyClientProjectCard(context, l10n),
                        const SizedBox(height: 16),
                      ],

                      // Seleccionar Familia
                      _buildFamilyCard(context, user, l10n),
                      const SizedBox(height: 16),

                      // Notas (opcional)
                      _buildNotesCard(context, l10n),
                    ],
                  ),
                ),
              ),
            ),

            // Botón de acción (fijo abajo)
            _buildBottomBar(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, AppLocalizations l10n) {
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
            const SizedBox(height: 16),
            
            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.productName,
                hintText: 'Ej: Bolso bandolera premium',
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.nameRequired;
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // SKU/Referencia
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: l10n.skuLabel,
                hintText: 'Ej: BOL-BAND-001',
                prefixIcon: const Icon(Icons.qr_code),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La referencia es obligatoria';
                }
                if (value.trim().length < 2) {
                  return 'La referencia debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                hintText: 'Describe las características del producto...',
                prefixIcon: const Icon(Icons.description_outlined),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }
                if (value.trim().length < 10) {
                  return 'La descripción debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, user, AppLocalizations l10n) {
    final clientService = Provider.of<ClientService>(context, listen: false);

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
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cliente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ClientModel>>(
              stream: clientService.watchClients(user.organizationId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildDropdownSkeleton('Cliente');
                }

                final clients = snapshot.data ?? [];

                if (clients.isEmpty) {
                  return _buildNoClientsMessage(context);
                }

                return FilterUtils.buildFullWidthDropdown<String>(
                  context: context,
                  label: 'Seleccionar Cliente',
                  value: _selectedClientId,
                  icon: Icons.business,
                  isRequired: true,
                  items: clients.map((client) {
                    return DropdownMenuItem<String>(
                      value: client.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            client.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            client.company,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                      _selectedProjectId = null; // Reset proyecto
                      _markAsChanged();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona un cliente';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, user, AppLocalizations l10n) {
    if (_selectedClientId == null) {
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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.project,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selecciona primero un cliente para ver sus proyectos',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final projectService = Provider.of<ProjectService>(context, listen: false);

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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.project,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ProjectModel>?>(
              future: projectService.getClientProjects(
                user.organizationId!,
                _selectedClientId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildDropdownSkeleton(l10n.project);
                }

                final projects = snapshot.data ?? [];

                if (projects.isEmpty) {
                  return _buildNoProjectsMessage(context);
                }

                return FilterUtils.buildFullWidthDropdown<String>(
                  context: context,
                  label: l10n.selectProject,
                  value: _selectedProjectId,
                  icon: Icons.folder,
                  isRequired: true,
                  items: projects.map((project) {
                    return DropdownMenuItem<String>(
                      value: project.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (project.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              project.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                      _markAsChanged();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona un proyecto';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyClientProjectCard(BuildContext context, AppLocalizations l10n) {
    final clientService = Provider.of<ClientService>(context, listen: false);
    final projectService = Provider.of<ProjectService>(context, listen: false);
    final product = widget.product!;

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
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cliente y Proyecto (no editables)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cliente (readonly)
            FutureBuilder<ClientModel?>(
              future: clientService.getClient(product.organizationId, product.clientId!),
              builder: (context, snapshot) {
                final client = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              client?.name ?? 'Cargando...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (client != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                client.company,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Proyecto (readonly)
            if (product.projects.isNotEmpty)
              FutureBuilder<ProjectModel?>(
                future: projectService.getProject(
                  product.organizationId,
                  product.projects.first,
                ),
                builder: (context, snapshot) {
                  final project = snapshot.data;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Proyecto',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                project?.name ?? 'Cargando...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (project != null && project.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  project.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
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
    );
  }

  Widget _buildFamilyCard(BuildContext context, user, AppLocalizations l10n) {
    if (_selectedProjectId == null && isCreateMode) {
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.family,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selecciona primero un proyecto para ver las familias',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final catalogService = Provider.of<ProductCatalogService>(context);

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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.family,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ProductCatalogModel>>(
              stream: catalogService.getProjectProductsStream(
                user.organizationId!,
                isEditMode ? widget.product!.projects.first : _selectedProjectId!,
                user.clientId,
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

                // Opción 1: Crear nueva familia (solo en modo creación)
                if (isCreateMode) {
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
                }

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
            ),
          ],
        ),
      ),
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

  Widget _buildNoClientsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber, size: 40, color: Colors.orange.shade700),
          const SizedBox(height: 8),
          Text(
            'No hay clientes disponibles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Debes crear un cliente antes de crear un producto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProjectsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber, size: 40, color: Colors.orange.shade700),
          const SizedBox(height: 8),
          Text(
            'No hay proyectos para este cliente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea un proyecto para este cliente antes de añadir productos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
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
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isCreateMode 
                        ? l10n.createProduct 
                        : l10n.saveChangesButton,
                  ),
          ),
        ),
      ),
    );
  }
}