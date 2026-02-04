import 'package:flutter/material.dart';
import 'package:gestion_produccion/helpers/approval_helper.dart';
import 'package:gestion_produccion/models/pending_object_model.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/services/notification_service.dart';
import 'package:gestion_produccion/services/organization_member_service.dart';
import 'package:gestion_produccion/services/pending_object_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/client_service.dart';
import '../../services/organization_service.dart';
import '../../services/permission_service.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../models/organization_member_model.dart';
import '../../models/permission_model.dart';
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

  bool _hasLoadedCounts = false; // ✅ NUEVA BANDERA
  bool _hasPreselectedCurrentUser = false; // ✅ NUEVA BANDERA

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
      setState(() => _isLoadingProjectCounts = true);
    }

    final projectService = Provider.of<ProjectService>(context, listen: false);

    try {
      for (final client in clients) {
        try {
          final projects = await projectService.getClientProjects(
                  organizationId, client.id) ??
              [];

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
      // Si hay error, permitir reintentar
      _hasLoadedCounts = false; // ✅ Resetear bandera para permitir reintento
    }

    if (mounted) {
      setState(() => _isLoadingProjectCounts = false);
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
    final productionProvider = Provider.of<ProductionDataProvider>(context, listen: false);

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
      String clientName = productionProvider.getClientById(_selectedClientId!)!.name;

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

  Future<bool> _checkCreatePermission(
      String userId, String organizationId) async {
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);

    // Cargar permisos del usuario actual
    await permissionService.loadCurrentUserPermissions(
      userId: userId,
      organizationId: organizationId,
    );

    // Verificar permiso
    return permissionService.effectivePermissions?.canCreateProjects ?? false;
  }

  Future<Color> _getMemberRoleColor(
      String organizationId, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        final roleColor = doc.data()?['roleColor'] as String?;
        if (roleColor != null) {
          return _parseColor(roleColor);
        }
      }
    } catch (e) {
      debugPrint('Error getting role color: $e');
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuevo Proyecto')),
        body: const Center(
          child: Text('Debes pertenecer a una organización'),
        ),
      );
    }

    // Verificar permisos para crear proyectos
    return FutureBuilder<bool>(
      future: _checkCreatePermission(user!.uid, user.organizationId!),
      builder: (context, permissionSnapshot) {
        if (permissionSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Nuevo Proyecto')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final canCreate = permissionSnapshot.data ?? false;

        if (!canCreate) {
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
                      'No tienes permisos para crear proyectos. Contacta con un administrador.',
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

        return _buildForm(context, user);
      },
    );
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
            StreamBuilder<List<ClientModel>>(
              stream: clientService.watchClients(user.organizationId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildClientDropdownSkeleton();
                }

                final clients = snapshot.data ?? [];

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
                                '$projectCount',
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

  Widget _buildClientDropdownSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 150,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
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
    final organizationService =
        Provider.of<OrganizationService>(context, listen: false);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);

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
                    Icons.security_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control de Acceso al Proyecto',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecciona quiénes podrán ver y trabajar con este proyecto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Miembros con acceso automático
            FutureBuilder<List<OrganizationMemberWithUser>>(
              future: _getMembersWithAutoAccess(
                organizationService,
                permissionService,
                user.organizationId!,
              ),
              builder: (context, autoAccessSnapshot) {
                if (autoAccessSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _buildAutoAccessSkeleton();
                }

                final autoAccessMembers = autoAccessSnapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (autoAccessMembers.isNotEmpty) ...[
                      _buildAutoAccessSection(context, autoAccessMembers),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                    ],

                    // Asignar miembros manualmente
                    _buildMemberSelectionSection(
                      context,
                      user,
                      organizationService,
                      autoAccessMembers,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoAccessSection(
    BuildContext context,
    List<OrganizationMemberWithUser> autoAccessMembers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Acceso automático (no necesitan asignación)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            children: autoAccessMembers.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              final isLast = index == autoAccessMembers.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              _parseColor(member.roleColor).withOpacity(0.2),
                          child: Text(
                            member.initials,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _parseColor(member.roleColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nombre
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.userName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member.userEmail,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Badge de rol
                        _buildRoleBadge(
                          member.roleName,
                          _parseColor(member.roleColor),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.blue.shade100,
                      indent: 52,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoAccessSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSelectionSection(
    BuildContext context,
    UserModel user,
    OrganizationService organizationService,
    List<OrganizationMemberWithUser> autoAccessMembers,
  ) {
    final autoAccessIds = autoAccessMembers.map((m) => m.userId).toSet();

    return StreamBuilder<List<UserModel>>(
      stream:
          organizationService.watchOrganizationMembers(user.organizationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMemberSelectionSkeleton();
        }

        // Filtrar miembros que NO tienen acceso automático
        final selectableMembers = (snapshot.data ?? [])
            .where((m) => !autoAccessIds.contains(m.uid))
            .toList();

        if (selectableMembers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Todos los miembros tienen acceso automático',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        // Pre-seleccionar al usuario actual si no tiene acceso automático
        // SOLO ejecutar si NO se ha pre-seleccionado antes
        if (!_hasPreselectedCurrentUser &&
            !autoAccessIds.contains(user.uid) &&
            !_selectedMembers.contains(user.uid)) {
          _hasPreselectedCurrentUser = true; // ✅ Marcar como ejecutado
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedMembers.add(user.uid);
              });
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Asignar miembros adicionales',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: selectableMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final isMe = member.uid == user.uid;
                  final isSelected = _selectedMembers.contains(member.uid);
                  final isLast = index == selectableMembers.length - 1;

                  return Column(
                    children: [
                      CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedMembers.add(member.uid);
                            } else {
                              _selectedMembers.remove(member.uid);
                            }
                          });
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Tú',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FutureBuilder<Color>(
                              future: _getMemberRoleColor(
                                  user.organizationId!, member.uid),
                              builder: (context, colorSnapshot) {
                                final color = colorSnapshot.data ?? Colors.blue;
                                return _buildRoleBadge(
                                  member.roleDisplayName,
                                  color,
                                  compact: true,
                                );
                              },
                            ),
                          ],
                        ),
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor: isMe
                              ? Colors.blue.shade100
                              : _parseColor(
                                      '#2196F3') // TODO: color del badge real
                                  .withOpacity(0.2),
                          child: Icon(
                            isMe ? Icons.account_circle : Icons.person,
                            color: isMe
                                ? Colors.blue.shade700
                                : _parseColor(
                                    '#2196F3'), // TODO: color del badge real
                            size: 20,
                          ),
                        ),
                        activeColor: Theme.of(context).primaryColor,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                          indent: 68,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberSelectionSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 180,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRoleBadge(String roleName, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        roleName,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  /// Obtener miembros con acceso automático (owner, admin, scope all en projects)
  Future<List<OrganizationMemberWithUser>> _getMembersWithAutoAccess(
    OrganizationService organizationService,
    PermissionService permissionService,
    String organizationId,
  ) async {
    try {
      // Obtener organización para saber quién es el owner
      final org = await organizationService.getOrganization(organizationId);
      if (org == null) return [];

      // Obtener todos los miembros
      final allMembers = await organizationService
          .watchOrganizationMembers(organizationId)
          .first;

      final autoAccessMembers = <OrganizationMemberWithUser>[];

      for (final member in allMembers) {
        // Owner siempre tiene acceso
        if (member.uid == org.ownerId) {
          final memberData = await permissionService.getMemberWithRole(
            organizationId,
            member.uid,
          );
          if (memberData != null) {
            autoAccessMembers.add(memberData);
            continue;
          }
        }

        // Verificar si es admin o tiene scope all en projects
        final memberData = await permissionService.getMemberWithRole(
          organizationId,
          member.uid,
        );

        if (memberData != null) {
          // Obtener el rol separadamente
          final roleDoc = await FirebaseFirestore.instance
              .collection('organizations')
              .doc(organizationId)
              .collection('roles')
              .doc(memberData.member.roleId)
              .get();

          if (!roleDoc.exists) continue;

          final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);
          final permissions = memberData.member.getEffectivePermissions(role);

          // Admin o Production Manager con scope all
          if (memberData.member.roleId == 'admin' ||
              permissions.viewProjectsScope == PermissionScope.all) {
            autoAccessMembers.add(memberData);
          }
        }
      }

      return autoAccessMembers;
    } catch (e) {
      debugPrint('Error getting auto-access members: $e');
      return [];
    }
  }
}

/// Extensión para obtener miembro con rol desde PermissionService
extension PermissionServiceExtension on PermissionService {
  Future<OrganizationMemberWithUser?> getMemberWithRole(
    String organizationId,
    String userId,
  ) async {
    try {
      final memberDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) return null;

      final member = OrganizationMemberModel.fromMap(
        memberDoc.data()!,
        docId: memberDoc.id,
      );

      final roleDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('roles')
          .doc(member.roleId)
          .get();

      if (!roleDoc.exists) return null;

      final role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      final user = UserModel.fromMap(userDoc.data()!);

      return OrganizationMemberWithUser(
        member: member,
        userName: user.name,
        userEmail: user.email,
        userPhotoUrl: user.photoURL,
      );
    } catch (e) {
      return null;
    }
  }
}
