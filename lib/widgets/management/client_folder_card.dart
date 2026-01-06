import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../l10n/app_localizations.dart';
import 'project_folder_card.dart';
import '../../screens/clients/client_detail_screen.dart';
import '../../screens/clients/edit_client_screen.dart';
import '../../screens/projects/create_project_screen.dart';

class ClientFolderCard extends StatefulWidget {
  final ClientModel client;
  final int urgentProductsCount;
  final int totalProductsCount;

  const ClientFolderCard({
    Key? key,
    required this.client,
    required this.urgentProductsCount,
    required this.totalProductsCount,
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
        // Fondo con opacidad reducida del color del tema
        color: theme.primaryColor.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1), // Borde sutil del mismo color
        ),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Avatar centrado verticalmente
                children: [
                  // 1. Avatar (Izquierda)
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Text(
                      widget.client.initials,
                      style: TextStyle(
                        fontSize: 16,
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
                      mainAxisSize: MainAxisSize.min, // Ajuste para el centrado vertical
                      children: [
                        // FILA 1: Nombre + Iconos + Flecha
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.client.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            // Badge Urgente
                            if (widget.urgentProductsCount > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.urgentProductsCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Botones de acción (Ver / Editar) - Siempre visibles
                            const SizedBox(width: 4),
                            _buildActionButton(
                              icon: Icons.visibility_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClientDetailScreen(client: widget.client),
                                  ),
                                );
                              },
                              theme: theme,
                              tooltip: l10n.viewDetailsTooltip,
                            ),
                            _buildActionButton(
                              icon: Icons.edit_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditClientScreen(client: widget.client),
                                  ),
                                );
                              },
                              theme: theme,
                              tooltip: l10n.edit,
                            ),

                            // Flecha de expansión
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                          ],
                        ),
                        
                        // FILA 2: Empresa
                        if (widget.client.company.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.client.company,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // FILA 3: Estadísticas (Proyectos y Productos)
                        const SizedBox(height: 6),
                        FutureBuilder<List<ProjectModel>>(
                          future: Provider.of<ProjectService>(context, listen: false)
                              .watchClientProjects(
                                authService.currentUserData!.organizationId!, 
                                widget.client.id
                              ).first,
                          builder: (context, snapshot) {
                            final count = snapshot.hasData ? snapshot.data!.length : 0;
                            return Row(
                              children: [
                                Flexible(
                                  child: _buildStat(
                                    icon: Icons.folder_outlined,
                                    value: '$count',
                                    label: l10n.projects,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: _buildStat(
                                    icon: Icons.widgets_outlined,
                                    value: '${widget.totalProductsCount}',
                                    label: l10n.products,
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === CONTENIDO EXPANDIBLE (Lista de proyectos) ===
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(
              children: [
                Divider(height: 1, indent: 16, endIndent: 16, color: theme.primaryColor.withOpacity(0.1)),
                FutureBuilder<List<ProjectModel>>(
                  future: Provider.of<ProjectService>(context, listen: false)
                      .watchClientProjects(
                        authService.currentUserData!.organizationId!,
                        widget.client.id
                      ).first,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }

                    final projects = snapshot.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Lista de Proyectos
                        if (projects.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    l10n.projectsCount(0),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CreateProjectScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text(l10n.createProject, style: const TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide(color: theme.primaryColor.withOpacity(0.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...projects.map((project) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ProjectFolderCard(
                                  project: project,
                                  client: widget.client,
                                ),
                          )),
                         
                        const SizedBox(height: 8),
                      ],
                    );
                  }
                ),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para botones de acción compactos
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
        icon: Icon(icon, size: 20, color: theme.primaryColor.withOpacity(0.7)),
        tooltip: tooltip,
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }

  // Widget auxiliar para estadísticas pequeñas
  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
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