import 'package:flutter/material.dart';
import 'package:gestion_produccion/helpers/approval_helper.dart';
import 'package:gestion_produccion/models/pending_object_model.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/services/notification_service.dart';
import 'package:gestion_produccion/services/organization_member_service.dart';
import 'package:gestion_produccion/services/pending_object_service.dart';
import 'package:gestion_produccion/widgets/access_control_widget.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/permission_service.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';
import '../../utils/filter_utils.dart';
import '../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProjectScreen extends StatefulWidget {
  final String? clientId; // Parámetro opcional para preseleccionar cliente

  const CreateProjectScreen({
    super.key,
    this.clientId,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedClientId;
  List<String> _selectedMembers = [];

  // Cache para contar proyectos por cliente
  final Map<String, int> _clientProjectCounts = {};
  bool _isLoadingProjectCounts = false;

  bool _hasLoadedCounts = false;

  @override
  void initState() {
    super.initState();
    // Preseleccionar cliente si se proporcionó
    if (widget.clientId != null) {
      _selectedClientId = widget.clientId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Cargar cantidad de proyectos activos por cliente
  Future<void> _loadClientProjectCounts(
      String organizationId, List<ClientModel> clients) async {
    if (_isLoadingProjectCounts) return;

    if (mounted) {
      // setState(() => _isLoadingProjectCounts = true);
    }

    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);

    try {
      for (final client in clients) {
        try {
          // CAMBIAR: Usar filterProjects del provider en lugar de query
          final projects = dataProvider.filterProjects(clientId: client.id);

          final activeProjects = projects
              .where((p) => p.status != 'completed' && p.status != 'cancelled')
              .length;

          _clientProjectCounts[client.id] = activeProjects;
        } catch (e) {
          _clientProjectCounts[client.id] = 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading client project counts: $e');
      _hasLoadedCounts = false;
    }

    if (mounted) {
      // setState(() => _isLoadingProjectCounts = false);
    }
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
    final projectService = Provider.of<ProjectService>(context, listen: false);
    final productionProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);

    setState(() => projectService.isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final projectService =
          Provider.of<ProjectService>(context, listen: false);
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      final pendingService =
          Provider.of<PendingObjectService>(context, listen: false);
      final user = authService.currentUserData;
      final l10n = AppLocalizations.of(context)!;

      if (user == null || user.organizationId == null) return;

      // Asegurar que el creador esté en la lista
      if (!_selectedMembers.contains(user.uid)) {
        _selectedMembers.add(user.uid);
      }

      // Verificar si requiere aprobación
      final userIsClient = memberService.currentMember?.roleId == 'client';
      final requiresApproval =
          userIsClient; // Clientes siempre requieren aprobación

      String? resultId;
      String clientName =
          productionProvider.getClientById(_selectedClientId!)!.name;

      if (requiresApproval) {
        // FLUJO CON APROBACIÓN
        resultId = await ApprovalHelper.createOrRequestApproval(
          organizationId: user.organizationId!,
          objectType: PendingObjectType.project,
          collectionRoute: 'projects',
          modelData: {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'clientId': _selectedClientId!,
            'clientName': clientName,
            'organizationId': user.organizationId!,
            'startDate': Timestamp.fromDate(DateTime.now()),
            'estimatedEndDate': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 30)),
            ),
            'assignedMembers': _selectedMembers,
            'createdBy': user.uid,
            'status': 'active',
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
              content: Text(l10n.projectCreationPendingApproval),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // FLUJO DIRECTO (SIN APROBACIÓN)
        resultId = await projectService.createProject(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          clientId: _selectedClientId!,
          organizationId: user.organizationId!,
          startDate: DateTime.now(),
          estimatedEndDate: DateTime.now().add(const Duration(days: 30)),
          assignedMembers: _selectedMembers,
          createdBy: user.uid,
        );

        if (mounted) {
          if (resultId != null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Proyecto creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(projectService.error ?? 'Error al crear proyecto'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
        setState(() => projectService.isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuevo Proyecto')),
        body: const Center(
          child: Text('Debes pertenecer a una organización'),
        ),
      );
    }

    final canCreateProjects = permissionService.canCreateProjects;

    if (!canCreateProjects) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.orange.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'No tienes permisos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No tienes permisos para crear proyectos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildForm(context, user!);
  }

  Widget _buildForm(BuildContext context, UserModel user) {
    final projectService = Provider.of<ProjectService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Proyecto'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Información Básica
                _buildBasicInfoCard(context),
                const SizedBox(height: 16),

                // Seleccionar Cliente
                _buildClientCard(context, user),
                const SizedBox(height: 16),

                // Control de Acceso
                _buildAccessControlCard(context, user),
                const SizedBox(height: 32),

                // Botón Crear
                FilledButton(
                  onPressed: projectService.isLoading ? null : _handleCreate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: projectService.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text(
                              'Crear Proyecto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context) {
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información Básica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nombre del Proyecto
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del proyecto *',
                hintText: 'Ej: Colección Primavera 2025',
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el nombre del proyecto';
                }
                if (value.length < 3) {
                  return 'Mínimo 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción *',
                hintText: 'Describe los detalles del proyecto...',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context)!;

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
                    Icons.person_outline,
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
            Consumer<ProductionDataProvider>(
              builder: (context, dataProvider, _) {
                final clients = dataProvider.clients;

                if (clients.isEmpty) {
                  return _buildNoClientsMessage(context);
                }

                // SOLO ejecutar si NO se ha cargado antes
                if (!_hasLoadedCounts && !_isLoadingProjectCounts) {
                  _hasLoadedCounts =
                      true; // ✅ Marcar como ejecutado INMEDIATAMENTE
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadClientProjectCounts(user.organizationId!, clients);
                  });
                }

                return FilterUtils.buildFullWidthDropdown<String>(
                  context: context,
                  label: 'Seleccionar Cliente',
                  value: _selectedClientId,
                  icon: Icons.business,
                  isRequired: true,
                  items: clients.map((client) {
                    final projectCount = _clientProjectCounts[client.id] ?? 0;

                    return DropdownMenuItem<String>(
                      value: client.id,
                      child: Row(
                        children: [
                          Expanded(
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
                          ),
                          const SizedBox(width: 8),
                          // Badge con número de proyectos
                          if (projectCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '$projectCount ${projectCount == 1 ? l10n.project : l10n.projects}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedClientId = value);
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
          Icon(
            Icons.person_off_outlined,
            size: 48,
            color: Colors.orange.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay clientes registrados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Debes crear un cliente antes de crear un proyecto',
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

  Widget _buildAccessControlCard(BuildContext context, UserModel user) {
    final memberService = Provider.of<OrganizationMemberService>(context, listen: false);
    // Si no hay cliente seleccionado, no mostrar nada
    if (_selectedClientId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          // CAMBIAR: Usar StatefulBuilder
          builder: (BuildContext context, StateSetter setStateLocal) {
            return AccessControlWidget(
              organizationId: user.organizationId!,
              currentUserId: user.uid,
              clientId: _selectedClientId!,
              selectedMembers: _selectedMembers,
              onMembersChanged: (members) {
                setStateLocal(() {
                  _selectedMembers = members;
                });
              },
              readOnly: memberService.currentMember?.clientId != null,
              showTitle: true,
              resourceType: 'project',
              customTitle: 'Control de Acceso al Proyecto',
              customDescription:
                  'Selecciona quiénes podrán ver y trabajar con este proyecto',
            );
          },
        ),
      ),
    );
  }
}
