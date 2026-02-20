import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/services/organization_member_service.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../services/auth_service.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../services/permission_service.dart';
import '../../models/client_model.dart';
import '../../widgets/access_control_widget.dart';
import '../../l10n/app_localizations.dart';

class EditProjectScreen extends StatefulWidget {
  final ProjectModel project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late List<String> _selectedMembers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController =
        TextEditingController(text: widget.project.description);
    _selectedMembers = List.from(widget.project.assignedMembers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final projectService = Provider.of<ProjectService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null) return;

    // Asegurar que el usuario actual esté incluido si no tiene scope "all"
    if (!_selectedMembers.contains(user.uid)) {
      _selectedMembers.add(user.uid);
    }

    final success = await projectService.updateProject(
      organizationId: widget.project.organizationId,
      projectId: widget.project.id,
      userId: user.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      assignedMembers: _selectedMembers,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.projectUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectService.error ?? l10n.projectUpdateError),
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
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editProjectTitle)),
        body: Center(
          child: Text(l10n.noOrganizationAssigned),
        ),
      );
    }

    final canEditProjects = permissionService.canEditProjects;

    // Verificar si el proyecto está completado o cancelado
    final isCompleted = widget.project.status == 'completed';
    final isCancelled = widget.project.status == 'cancelled';

    if (!canEditProjects || isCompleted || isCancelled) {
      return _buildAccessDeniedScreen(
        context,
        l10n,
        canEdit: canEditProjects,
        isCompleted: isCompleted,
        isCancelled: isCancelled,
      );
    }

    return _buildForm(context, l10n, user!);
  }

  Widget _buildAccessDeniedScreen(
    BuildContext context,
    AppLocalizations l10n, {
    required bool canEdit,
    required bool isCompleted,
    required bool isCancelled,
  }) {
    String title;
    IconData icon;

    if (isCompleted) {
      title = l10n.projectIsCompleted;
      icon = Icons.check_circle_outline;
    } else if (isCancelled) {
      title = l10n.projectIsCancelled;
      icon = Icons.cancel_outlined;
    } else {
      title = l10n.cannotEditProject;
      icon = Icons.lock_outline;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProjectTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.back),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context, AppLocalizations l10n, UserModel user) {
    final projectService = Provider.of<ProjectService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProjectTitle),
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
                _buildBasicInfoCard(context, l10n),
                const SizedBox(height: 16),

                // Información del Cliente (Read-Only)
                _buildClientInfoCard(context, l10n),
                const SizedBox(height: 16),

                // Control de Acceso
                _buildAccessControlCard(context, l10n, user),
                const SizedBox(height: 32),

                // Botón Guardar
                FilledButton(
                  onPressed: projectService.isLoading ? null : _handleUpdate,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_outlined),
                            const SizedBox(width: 8),
                            Text(
                              l10n.save,
                              style: const TextStyle(
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

  Widget _buildClientInfoCard(BuildContext context, AppLocalizations l10n) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.clientInformation,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clientCannotBeChanged,
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
            const SizedBox(height: 16),
            Consumer<ProductionDataProvider>(
              builder: (context, dataProvider, _) {
                final client =
                    dataProvider.getClientById(widget.project.clientId);

                if (client == null) {
                  return _buildClientNotFound(l10n);
                }

                return _buildClientInfo(context, l10n, client);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientNotFound(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_outlined, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.clientNotFound,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo(
    BuildContext context,
    AppLocalizations l10n,
    ClientModel client,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.purple.shade200,
            child: Text(
              client.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade800,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  client.company,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        client.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                  l10n.projectInformation,
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
                labelText: '${l10n.projectName} *',
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.required;
                }
                if (value.length < 3) {
                  return l10n.nameMinLengthError;
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
                labelText: '${l10n.description} *',
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
                  return l10n.required;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessControlCard(
    BuildContext context,
    AppLocalizations l10n,
    UserModel user,
  ) {
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);

    if (memberService.currentMember?.clientId != null) {
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
              organizationId: widget.project.organizationId,
              currentUserId: user.uid,
              clientId: widget.project.clientId,
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
                  'Gestiona quiénes pueden ver y trabajar con este proyecto',
            );
          },
        ),
      ),
    );
  }
}
