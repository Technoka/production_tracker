// lib/screens/management/management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/project_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/management_view_types.dart';
import '../../utils/filter_utils.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import 'management_list_view.dart';
import 'management_folders_view.dart';
import '../clients/create_client_screen.dart';
import '../projects/create_project_screen.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({Key? key}) : super(key: key);

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  ManagementViewMode _viewMode = ManagementViewMode.folders;
  ManagementFilters _filters = const ManagementFilters();
  
  // Tabs dinámicos para vista lista
  final List<ManagementTab> _tabs = [ManagementTab.general()];
  int _currentTabIndex = 0;

  void _addTab(ManagementTab tab) {
    setState(() {
      // Evitar duplicados
      final existingIndex = _tabs.indexWhere((t) => t.id == tab.id);
      if (existingIndex != -1) {
        _currentTabIndex = existingIndex;
        return;
      }

      _tabs.add(tab);
      _currentTabIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    if (index == 0) return; // No cerrar el tab general
    
    setState(() {
      _tabs.removeAt(index);
      _currentTabIndex = index > 0 ? index - 1 : 0;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.management)),
        body: Center(child: Text(l10n.noOrganizationAssigned)),
        bottomNavigationBar: BottomNavBarWidget(currentIndex: 2, user: user!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.management),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              _buildBreadcrumbBar(l10n),
              _buildViewModeToggle(l10n),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(user!, l10n),
          Expanded(
            child: _viewMode == ManagementViewMode.folders
                ? ManagementFoldersView(
                    filters: _filters,
                    onAddClient: () => _navigateToCreateClient(user),
                  )
                : ManagementListView(
                    currentTab: _tabs[_currentTabIndex],
                    filters: _filters,
                    onOpenClientTab: (client) => _addTab(
                      ManagementTab.client(
                        clientId: client.id,
                        clientName: client.name,
                      ),
                    ),
                    onOpenProjectTab: (project, clientId) => _addTab(
                      ManagementTab.project(
                        projectId: project.id,
                        projectName: project.name,
                        clientId: clientId,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(user, l10n),
      bottomNavigationBar: BottomNavBarWidget(currentIndex: 2, user: user),
    );
  }

  Widget _buildBreadcrumbBar(AppLocalizations l10n) {
    final theme = Theme.of(context);
    
    // En vista folders, solo mostrar "General"
    if (_viewMode == ManagementViewMode.folders) {
      return Container(
        height: 50,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: theme.colorScheme.surface,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.general,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // En vista lista, mostrar breadcrumb dinámico
    final currentTab = _tabs[_currentTabIndex];
    
    return Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          // General
          InkWell(
            onTap: () => _navigateToTab(0),
            child: Text(
              l10n.general,
              style: TextStyle(
                fontSize: 16,
                fontWeight: _currentTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                color: _currentTabIndex == 0 
                    ? theme.colorScheme.primary 
                    : Colors.grey.shade600,
              ),
            ),
          ),
          
          // Cliente (si existe)
          if (currentTab.type == ManagementTabType.client || 
              currentTab.type == ManagementTabType.project) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ),
            InkWell(
              onTap: () {
                // Encontrar el tab del cliente
                final clientTabIndex = _tabs.indexWhere(
                  (t) => t.type == ManagementTabType.client && 
                         t.clientId == currentTab.clientId
                );
                if (clientTabIndex != -1) {
                  _navigateToTab(clientTabIndex);
                }
              },
              child: Text(
                _getClientName(currentTab),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: currentTab.type == ManagementTabType.client 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  color: currentTab.type == ManagementTabType.client
                      ? theme.colorScheme.primary
                      : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Proyecto (si existe)
          if (currentTab.type == ManagementTabType.project) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ),
            Expanded(
              child: Text(
                currentTab.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Botón cerrar tab (si no es General)
          if (_currentTabIndex > 0) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _closeTab(_currentTabIndex),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getClientName(ManagementTab tab) {
    if (tab.type == ManagementTabType.client) {
      return tab.title;
    } else if (tab.type == ManagementTabType.project) {
      // Buscar el nombre del cliente en los tabs
      final clientTab = _tabs.firstWhere(
        (t) => t.type == ManagementTabType.client && t.clientId == tab.clientId,
        orElse: () => ManagementTab.general(),
      );
      return clientTab.title;
    }
    return '';
  }

  Widget _buildViewModeToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ManagementViewMode>(
        segments: [
          ButtonSegment(
            value: ManagementViewMode.list,
            label: Text(l10n.listView),
            icon: const Icon(Icons.list, size: 18),
          ),
          ButtonSegment(
            value: ManagementViewMode.folders,
            label: Text(l10n.foldersView),
            icon: const Icon(Icons.folder_open, size: 18),
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: (Set<ManagementViewMode> newSelection) {
          setState(() => _viewMode = newSelection.first);
        },
      ),
    );
  }

  Widget _buildFilters(UserModel user, AppLocalizations l10n) {
    return StreamBuilder<List<ClientModel>>(
      stream: Provider.of<ClientService>(context, listen: false)
          .watchClients(user.organizationId!),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              FilterUtils.buildSearchField(
                hintText: '${l10n.search}...',
                searchQuery: _filters.searchQuery,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(searchQuery: value);
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: [
                    FilterUtils.buildFilterOption<String>(
                      context: context,
                      label: l10n.client,
                      value: _filters.clientId,
                      icon: Icons.person_outline,
                      allLabel: l10n.allClients,
                      items: clients
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _filters = _filters.copyWith(clientId: val);
                        });
                      },
                    ),
                    FilterUtils.buildUrgencyFilterChip(
                      context: context,
                      isUrgentOnly: _filters.onlyUrgent,
                      onToggle: () {
                        setState(() {
                          _filters = _filters.copyWith(
                            onlyUrgent: !_filters.onlyUrgent,
                          );
                        });
                      },
                    ),
                    if (_filters.hasActiveFilters)
                      FilterUtils.buildClearFiltersButton(
                        context: context,
                        onPressed: () {
                          setState(() {
                            _filters = _filters.clear();
                          });
                        },
                        hasActiveFilters: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildFAB(UserModel user, AppLocalizations l10n) {
    if (!user.canManageProduction) return null;

    final currentTab = _tabs[_currentTabIndex];

    if (currentTab.type == ManagementTabType.general) {
      return SizedBox(
        height: 40,
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToCreateClient(user),
          icon: const Icon(Icons.add, size: 20),
          label: Text(l10n.createClient, style: const TextStyle(fontSize: 13)),
        ),
      );
    } else if (currentTab.type == ManagementTabType.client) {
      return SizedBox(
        height: 40,
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToCreateProject(user, currentTab.clientId),
          icon: const Icon(Icons.add, size: 20),
          label: Text(l10n.createProject, style: const TextStyle(fontSize: 13)),
        ),
      );
    }

    return null;
  }

  void _navigateToCreateClient(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateClientScreen(
        ),
      ),
    );
  }

  void _navigateToCreateProject(UserModel user, String? clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectScreen(
        ),
      ),
    );
  }
}