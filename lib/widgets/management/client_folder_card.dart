import 'package:flutter/material.dart';
import 'package:gestion_produccion/models/production_batch_model.dart';
import 'package:gestion_produccion/models/user_model.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../services/organization_member_service.dart';
import '../../l10n/app_localizations.dart';
import 'project_folder_card.dart';
import '../../screens/clients/client_detail_screen.dart';
import '../../screens/clients/client_form_screen.dart';
import '../../screens/projects/create_project_screen.dart';

class ClientFolderCard extends StatefulWidget {
  final ClientModel client;
  final int urgentProductsCount;
  final int totalProductsCount;
  final int projectsCount;

  const ClientFolderCard({
    Key? key,
    required this.client,
    required this.urgentProductsCount,
    required this.totalProductsCount,
    required this.projectsCount,
  }) : super(key: key);

  @override
  State<ClientFolderCard> createState() => _ClientFolderCardState();
}

class _ClientFolderCardState extends State<ClientFolderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // === HEADER DEL CLIENTE ===
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12), bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FutureBuilder<bool>(
                    future:
                        _canEditClients(context, authService.currentUserData!),
                    builder: (context, permissionSnapshot) {
                      final canEditClients = permissionSnapshot.data ?? false;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Avatar (Izquierda)
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                theme.primaryColor.withOpacity(0.1),
                            child: Text(
                              widget.client.initials,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 2. Columna Central (Info + Stats)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FILA 1: Nombre + Iconos + Flecha
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.client.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Badge Urgente
                                    if (widget.urgentProductsCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: UrgencyLevel.urgent.color
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.warning_amber_rounded,
                                                size: 10,
                                                color: Colors.red),
                                            const SizedBox(width: 2),
                                            Text(
                                              widget.urgentProductsCount
                                                  .toString(),
                                              style: TextStyle(
                                                color:
                                                    UrgencyLevel.urgent.color,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Botones de acción (Ver / Editar)
                                    const SizedBox(width: 4),
                                    _buildActionButton(
                                      icon: Icons.visibility_outlined,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ClientDetailScreen(
                                                    client: widget.client),
                                          ),
                                        );
                                      },
                                      theme: theme,
                                      tooltip: l10n.viewDetailsTooltip,
                                    ),
                                    if (canEditClients)
                                      _buildActionButton(
                                        icon: Icons.edit_outlined,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ClientFormScreen(
                                                      client: widget.client),
                                            ),
                                          );
                                        },
                                        theme: theme,
                                        tooltip: l10n.edit,
                                      ),

                                    // Flecha de expansión
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.7),
                                      size: 18,
                                    ),
                                  ],
                                ),

                                // FILA 2: Empresa
                                if (widget.client.company.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.client.company,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                // FILA 3: Estadísticas (Proyectos y Productos)
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Proyectos
                                    Flexible(
                                      child: _buildStat(
                                        icon: Icons.folder_outlined,
                                        value: '${widget.projectsCount}',
                                        label: l10n.projects,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Productos
                                    Flexible(
                                      child: _buildStat(
                                        icon: Icons.widgets_outlined,
                                        value: '${widget.totalProductsCount}',
                                        label: l10n.products,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                
              
            ),
          ),

          // === CONTENIDO EXPANDIBLE ===
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(
              children: [
                const Divider(height: 1, indent: 16, endIndent: 16),
                FutureBuilder<List<ProjectModel>?>(
                    future: Provider.of<ProjectService>(context, listen: false)
                        .getClientProjectsWithScope(
                            organizationId:
                                authService.currentUserData!.organizationId!,
                            clientId: widget.client.id,
                            userId: authService.currentUserData!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                              child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                        );
                      }

                      final projects = snapshot.data ?? [];

                      return FutureBuilder<bool>(
                        future: _canCreateProjects(
                            context, authService.currentUserData!),
                        builder: (context, permissionSnapshot) {
                          final canCreateProjects =
                              permissionSnapshot.data ?? false;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // Botón de crear proyecto (al inicio si tiene permisos)
                              if (canCreateProjects)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CreateProjectScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      label: Text(l10n.createProject,
                                          style: const TextStyle(fontSize: 14)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        side: BorderSide(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Lista de Proyectos
                              if (projects.isEmpty && !canCreateProjects)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      l10n.projectsCount(0),
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13),
                                    ),
                                  ),
                                )
                              else if (projects.isNotEmpty)
                                ...projects.map((project) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: ProjectFolderCard(
                                        project: project,
                                        client: widget.client,
                                      ),
                                    )),

                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      );
                    }),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Future<bool> _canCreateProjects(BuildContext context, UserModel user) async {
    try {
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);
      await memberService.getCurrentMember(user.organizationId!, user.uid);
      final canCreateProjects = await memberService.can('projects', 'create');

      return canCreateProjects;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _canEditClients(BuildContext context, UserModel user) async {
    try {
      final memberService =
          Provider.of<OrganizationMemberService>(context, listen: false);
      await memberService.getCurrentMember(user.organizationId!, user.uid);
      final canCreateProjects = await memberService.can('clients', 'edit');

      return canCreateProjects;
    } catch (e) {
      return false;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required String tooltip,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon,
            size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
        tooltip: tooltip,
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$value $label',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
