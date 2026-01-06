// lib/widgets/management/client_folder_card.dart

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
    final user = authService.currentUserData!;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isExpanded
              ? theme.colorScheme.primary.withOpacity(0.3)
              : Colors.grey.shade200,
          width: _isExpanded ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: StreamBuilder<List<ProjectModel>>(
          stream: Provider.of<ProjectService>(context, listen: false)
              .watchClientProjects(user.organizationId!, widget.client.id),
          builder: (context, projectSnapshot) {
            final projects = projectSnapshot.data ?? [];
            
            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              onExpansionChanged: (expanded) {
                setState(() => _isExpanded = expanded);
              },
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  widget.client.initials,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.client.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.client.company,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.urgentProductsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 14,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.urgentProductsCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _buildStat(
                      icon: Icons.folder_outlined,
                      value: '${projects.length}',
                      label: l10n.projects,
                    ),
                    const SizedBox(width: 16),
                    _buildStat(
                      icon: Icons.widgets_outlined,
                      value: '${widget.totalProductsCount}',
                      label: l10n.products,
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientDetailScreen(
                            client: widget.client,
                          ),
                        ),
                      );
                    },
                    tooltip: l10n.viewDetailsTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  if (user.canManageProduction)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditClientScreen(
                              client: widget.client,
                            ),
                          ),
                        );
                      },
                      tooltip: l10n.edit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 24,
                  ),
                ],
              ),
              children: [
                if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noProjectsForClient,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (user.canManageProduction) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateProjectScreen(
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.createProject),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ...projects.map((project) => ProjectFolderCard(
                        project: project,
                        client: widget.client,
                      )),
              ],
            );
          }
        ),
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
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}