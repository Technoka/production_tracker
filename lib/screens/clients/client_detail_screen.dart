import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_produccion/models/project_model.dart';
import 'package:gestion_produccion/screens/projects/project_detail_screen.dart';
import 'package:gestion_produccion/services/project_service.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/organization_member_service.dart';
import '../../models/client_model.dart';
import '../../utils/ui_constants.dart';
import '../../widgets/client_color_picker.dart';
import '../../widgets/client_permissions_selector.dart';
import '../../widgets/client_associated_members.dart';
import '../../widgets/common_refresh.dart';
import 'client_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final ClientModel client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientDetailScreen> {
  // 1. Definimos variables de estado para los permisos
  bool _canEdit = false;
  bool _canDelete = false;
  bool _isLoadingPermissions = true; // Para mostrar carga mientras verificamos

  @override
  void initState() {
    super.initState();
    // 2. Cargamos los permisos al iniciar la pantalla
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    // Nota: En initState usamos listen: false porque solo leemos una vez
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final user = authService.currentUserData;
    if (user?.organizationId == null) return;

    // Verificamos permisos
    final canEdit = await memberService.can('clients', 'edit');
    final canDelete = await memberService.can('clients', 'delete');

    // Actualizamos el estado si el widget sigue vivo (mounted)
    if (mounted) {
      setState(() {
        _canEdit = canEdit;
        _canDelete = canDelete;
        _isLoadingPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    // clientService se puede mantener aquí si es para datos reactivos
    final clientService = context.watch<ClientService>();
    final l10n = AppLocalizations.of(context)!;

    final user = authService.currentUserData;
    final organizationId = user?.organizationId;

    // 3. Verificamos si faltan datos o si estamos cargando permisos
    if (user == null || organizationId == null || _isLoadingPermissions) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Future<void> handleRefresh() async {
      // Forzar rebuild del widget obteniendo nuevo snapshot
      // El StreamBuilder de miembros se refrescará automáticamente
      setState(() {}); // Forzar rebuild del cliente

      // Refrescar cliente del servicio
      await clientService.getClient(organizationId, widget.client.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientDetailTitle),
        actions: [
          if (_canEdit || _canDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    if (_canEdit) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClientFormScreen(client: widget.client),
                        ),
                      );
                    }
                    break;
                  case 'duplicate':
                    if (_canEdit) {
                      await _handleDuplicate(
                          context, clientService, user, l10n);
                    }
                    break;
                  case 'delete':
                    if (_canDelete) {
                      await _showDeleteDialog(
                        context,
                        clientService,
                        organizationId,
                        l10n,
                      );
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                if (_canEdit)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined),
                        const SizedBox(width: 12),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                if (_canEdit)
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        const Icon(Icons.content_copy),
                        const SizedBox(width: 12),
                        Text(l10n.duplicate),
                      ],
                    ),
                  ),
                if (_canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: CommonRefresh(
        onRefresh: handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header con avatar
              _buildHeader(context, widget.client),

              // Contenido con cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información básica
                    _buildCard(
                      context,
                      title: l10n.basicInfoSection,
                      icon: Icons.info_outline,
                      iconColor: Colors.blue,
                      children: [
                        _buildInfoTile(
                          context,
                          icon: Icons.person_outline,
                          label: l10n.contactNameLabel,
                          value: widget.client.name,
                        ),
                        const Divider(height: 24),
                        _buildInfoTile(
                          context,
                          icon: Icons.business,
                          label: l10n.companyLabel,
                          value: widget.client.company,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Información de contacto
                    _buildCard(
                      context,
                      title: l10n.contactInfo,
                      icon: Icons.phone_outlined,
                      iconColor: Colors.green,
                      children: [
                        _buildInfoTile(
                          context,
                          icon: Icons.email_outlined,
                          label: l10n.emailLabel,
                          value: widget.client.email,
                          onTap: () => _copyToClipboard(
                            context,
                            widget.client.email,
                            l10n.emailLabel,
                          ),
                        ),
                        if (widget.client.hasPhone) ...[
                          const Divider(height: 24),
                          _buildInfoTile(
                            context,
                            icon: Icons.phone_outlined,
                            label: l10n.phoneLabel,
                            value: widget.client.phone!,
                            onTap: () => _copyToClipboard(
                              context,
                              widget.client.phone!,
                              l10n.phoneLabel,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dirección (si existe)
                    if (widget.client.hasAddress ||
                        widget.client.hasCity ||
                        widget.client.hasCountry)
                      _buildCard(
                        context,
                        title: l10n.addressLabel,
                        icon: Icons.location_on_outlined,
                        iconColor: Colors.red,
                        children: [
                          if (widget.client.hasAddress)
                            _buildInfoTile(
                              context,
                              icon: Icons.location_on_outlined,
                              label: l10n.addressLabel,
                              value: widget.client.address!,
                            ),
                          if (widget.client.hasCity ||
                              widget.client.hasPostalCode) ...[
                            if (widget.client.hasAddress)
                              const Divider(height: 24),
                            _buildInfoTile(
                              context,
                              icon: Icons.location_city,
                              label: l10n.cityLabel,
                              value: widget.client.hasPostalCode
                                  ? '${widget.client.city ?? ''}, ${widget.client.postalCode}'
                                  : widget.client.city ?? '',
                            ),
                          ],
                          if (widget.client.hasCountry) ...[
                            const Divider(height: 24),
                            _buildInfoTile(
                              context,
                              icon: Icons.flag,
                              label: l10n.countryLabel,
                              value: widget.client.country!,
                            ),
                          ],
                        ],
                      ),

                    if (widget.client.hasAddress ||
                        widget.client.hasCity ||
                        widget.client.hasCountry)
                      const SizedBox(height: 16),

                    // Color
                    if (widget.client.color != null)
                      _buildCard(
                        context,
                        title: l10n.clientColorLabel,
                        icon: Icons.palette_outlined,
                        iconColor: Colors.purple,
                        children: [
                          Row(
                            children: [
                              ClientColorIndicator(
                                color: widget.client.color,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                UIConstants.getColorName(widget.client.color!),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    if (widget.client.color != null) const SizedBox(height: 16),

                    // Notas (si existen)
                    if (widget.client.hasNotes)
                      _buildCard(
                        context,
                        title: l10n.notesSection,
                        icon: Icons.note_outlined,
                        iconColor: Colors.orange,
                        children: [
                          Text(
                            widget.client.notes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),

                    if (widget.client.hasNotes) const SizedBox(height: 16),

                    // Proyectos del cliente
                    _buildClientProjects(
                        context, organizationId, widget.client.id),

                    const SizedBox(height: 16),

                    // Permisos especiales
                    if (widget.client.hasSpecialPermissions)
                      _buildCard(
                        context,
                        title: l10n.clientSpecialPermissions,
                        icon: Icons.security_outlined,
                        iconColor: Colors.deepPurple,
                        children: [
                          ClientPermissionsSelector(
                            initialPermissions: widget.client.clientPermissions,
                            readOnly: true, // Solo lectura en detail screen
                          ),
                        ],
                      ),

                    if (widget.client.hasSpecialPermissions)
                      const SizedBox(height: 16),

                    // Miembros asociados
                    ClientAssociatedMembers(
                      organizationId: organizationId,
                      clientId: widget.client.id,
                      showTitle: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ClientModel client) {
    final colorValue =
        client.colorValue ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorValue,
            colorValue.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              client.initials,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorValue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            client.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            client.company,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.copy,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

// TODO: mostrar solo si tiene permiso projects.view
  Widget _buildClientProjects(
    BuildContext context,
    String organizationId,
    String clientId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final projectService = Provider.of<ProjectService>(context, listen: false);

    return FutureBuilder<List<ProjectModel>?>(
      future: projectService.getClientProjects(organizationId, clientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final projects = snapshot.data!;

        if (projects.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildCard(
          context,
          title: l10n.projects,
          icon: Icons.folder_outlined,
          iconColor: widget.client.colorValue,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                // CORRECCIÓN 1: No castear a Map, es un ProjectModel
                final project = projects[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  // CORRECCIÓN 2: Acceder con punto (.) en vez de corchetes ['']
                  title: Text(project.name),
                  subtitle: project.description != null &&
                          project.description!.isNotEmpty
                      ? Text(
                          project.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailScreen(
                          projectId: project.id, // CORRECCIÓN 3: .id
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDuplicate(
    BuildContext context,
    ClientService clientService,
    dynamic user,
    AppLocalizations l10n,
  ) async {
    final success = await clientService.createClient(
      organizationId: user.organizationId!,
      name: '${widget.client.name} (${l10n.copy})',
      company: widget.client.company,
      email: widget.client.email,
      phone: widget.client.phone,
      address: widget.client.address,
      city: widget.client.city,
      postalCode: widget.client.postalCode,
      country: widget.client.country,
      notes: widget.client.notes,
      createdBy: user.uid,
      color: widget.client.color,
      clientPermissions: widget.client.clientPermissions,
    );

    if (context.mounted) {
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clientDuplicatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(clientService.error ?? l10n.duplicateClientError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    ClientService clientService,
    String organizationId,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteClientConfirmTitle),
        content: Text(l10n.deleteClientConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await clientService.deleteClient(
        organizationId,
        widget.client.id,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clientDeleted),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(clientService.error ?? l10n.deleteClientError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
