// lib/widgets/management/client_folder_card.dart
// ✅ OPTIMIZADO: Usa ProductionDataProvider para estadísticas Y proyectos

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import '../../providers/production_data_provider.dart';
import '../../l10n/app_localizations.dart';
import 'project_folder_card.dart';
import '../../screens/clients/client_detail_screen.dart';
import '../../screens/clients/client_form_screen.dart';
import '../../screens/projects/create_project_screen.dart';

class ClientFolderCard extends StatefulWidget {
  final ClientModel client;

  const ClientFolderCard({
    Key? key,
    required this.client,
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
    final permissionService = Provider.of<PermissionService>(context);

    // ✅ OPTIMIZACIÓN: Obtener estadísticas del provider
    final productionProvider = Provider.of<ProductionDataProvider>(context);
    final stats = productionProvider.getClientStats(widget.client.id);
    final projectsCount = stats['projectsCount'] ?? 0;
    final productsCount = stats['catalogProductsCount'] ?? 0;

    // ✅ OPTIMIZACIÓN: Obtener proyectos del provider (sin query adicional)
    final clientProjects = productionProvider.getProjectsByClientId(widget.client.id);

    // ✅ OPTIMIZACIÓN: Usar permisos cacheados
    final canEditClients = permissionService.canEditClients;
    final canCreateProjects = permissionService.canCreateProjects;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.client.isActive 
            ? widget.client.colorValue.withAlpha(10) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.client.isActive 
              ? widget.client.colorValue.withAlpha(120) 
              : Colors.grey.shade100
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
              top: Radius.circular(12),
              bottom: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Avatar (Izquierda)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: widget.client.isActive 
                        ? widget.client.colorValue.withAlpha(200) 
                        : Colors.grey.shade100,
                    child: Text(
                      widget.client.initials,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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

                            // Botones de acción (Ver / Editar)
                            const SizedBox(width: 4),
                            _buildActionButton(
                              icon: Icons.visibility_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ClientDetailScreen(client: widget.client),
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
                                          ClientFormScreen(client: widget.client),
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
                              color: theme.colorScheme.primary.withOpacity(0.7),
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
                                value: '$projectsCount',
                                label: l10n.projects,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Productos de catálogo
                            Flexible(
                              child: _buildStat(
                                icon: Icons.widgets_outlined,
                                value: '$productsCount',
                                label: l10n.products,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === LISTA DE PROYECTOS EXPANDIBLE ===
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                // ✅ OPTIMIZACIÓN: Usar datos del provider (sin StreamBuilder)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Botón de crear proyecto (al inicio si tiene permisos)
                    if (canCreateProjects)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CreateProjectScreen(clientId: widget.client.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              l10n.createProject,
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Lista de Proyectos
                    if (clientProjects.isEmpty && !canCreateProjects)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            l10n.projectsCount(0),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else if (clientProjects.isNotEmpty)
                      ...clientProjects.map(
                        (project) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ProjectFolderCard(
                            project: project,
                            client: widget.client,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                  ],
                ),
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
        icon: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
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