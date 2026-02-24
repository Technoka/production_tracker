import 'package:flutter/material.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../services/auth_service.dart';
import '../../providers/production_data_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/management_view_types.dart';
import '../../utils/filter_utils.dart';
import 'management_folders_view.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({Key? key}) : super(key: key);

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  ManagementFilters _filters = const ManagementFilters();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return AppScaffold(
        title: l10n.management,
        currentIndex: AppNavIndex.management,
        body: Center(child: Text(l10n.noOrganizationAssigned)),
      );
    }

    return AppScaffold(
      title: l10n.management,
      currentIndex: AppNavIndex.production,
      body: Consumer<ProductionDataProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ OPTIMIZACIÓN: Usar datos del provider en lugar de StreamBuilder
          final clients = provider.filterClients(
            searchQuery: _filters.searchQuery,
          );

          return Column(
            children: [
              _buildFilters(user!, l10n, clients),
              Expanded(
                child: ManagementFoldersView(
                  clients: clients, // ✅ Pasar lista pre-cargada
                  filters: _filters,
                  onAddClient: () => _navigateToCreateClient(user),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(
    UserModel user,
    AppLocalizations l10n,
    List<ClientModel> clients,
  ) {
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
            controller: _searchController,
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
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                            child:
                                Text(c.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _filters = _filters.copyWith(clientId: val);
                    });
                  },
                ),
                if (_filters.hasActiveFilters)
                  FilterUtils.buildClearFiltersButton(
                    context: context,
                    onPressed: () {
                      setState(() {
                        _filters = _filters.clear();
                        _searchController.clear();
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
  }

  void _navigateToCreateClient(UserModel user) {
    // TODO: que coño hace esta funcion??  eliminarla.
  }
}
