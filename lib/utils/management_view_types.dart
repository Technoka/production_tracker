// lib/utils/management_view_types.dart

/// Tipo de vista en la pantalla de gestión
enum ManagementViewMode {
  list,
  folders;

  String get displayKey {
    switch (this) {
      case ManagementViewMode.list:
        return 'listView';
      case ManagementViewMode.folders:
        return 'foldersView';
    }
  }
}

/// Tipo de tab activo en la vista de lista
enum ManagementTabType {
  general,
  client,
  project;
}

/// Información de un tab dinámico
class ManagementTab {
  final String id;
  final ManagementTabType type;
  final String title;
  final String? clientId;
  final String? projectId;

  const ManagementTab({
    required this.id,
    required this.type,
    required this.title,
    this.clientId,
    this.projectId,
  });

  factory ManagementTab.general() {
    return const ManagementTab(
      id: 'general',
      type: ManagementTabType.general,
      title: 'general',
    );
  }

  factory ManagementTab.client({
    required String clientId,
    required String clientName,
  }) {
    return ManagementTab(
      id: 'client_$clientId',
      type: ManagementTabType.client,
      title: clientName,
      clientId: clientId,
    );
  }

  factory ManagementTab.project({
    required String projectId,
    required String projectName,
    required String clientId,
  }) {
    return ManagementTab(
      id: 'project_$projectId',
      type: ManagementTabType.project,
      title: projectName,
      projectId: projectId,
      clientId: clientId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagementTab &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Filtros para la vista de gestión
class ManagementFilters {
  final String? clientId;
  final String? projectId;
  final String? statusFilter;
  final String searchQuery;
  final bool onlyUrgent;

  const ManagementFilters({
    this.clientId,
    this.projectId,
    this.statusFilter,
    this.searchQuery = '',
    this.onlyUrgent = false,
  });

  ManagementFilters copyWith({
    String? clientId,
    String? projectId,
    String? statusFilter,
    String? searchQuery,
    bool? onlyUrgent,
  }) {
    return ManagementFilters(
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      onlyUrgent: onlyUrgent ?? this.onlyUrgent,
    );
  }

  bool get hasActiveFilters =>
      clientId != null ||
      projectId != null ||
      statusFilter != null ||
      searchQuery.isNotEmpty ||
      onlyUrgent;

  ManagementFilters clear() {
    return const ManagementFilters();
  }
}