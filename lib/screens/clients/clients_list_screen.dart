import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../models/client_model.dart';
import 'create_client_screen.dart';
import 'client_detail_screen.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final clientService = Provider.of<ClientService>(context);
    final user = authService.currentUserData;

    if (user == null || user.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clientes')),
        body: const Center(
          child: Text('Debes pertenecer a una organización'),
        ),
      );
    }

    final canCreate = user.canManageProduction;
    final canEdit = user.canManageProduction;
    final canDelete = user.hasAdminAccess;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateClientScreen(),
                  ),
                );
              },
              tooltip: 'Nuevo cliente',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: clientService.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          clientService.clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                clientService.setSearchQuery(value);
              },
            ),
          ),

          // Lista de clientes
          Expanded(
            child: StreamBuilder<List<ClientModel>>(
              stream: clientService.watchClients(user.organizationId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                print("Snapshot data: ${snapshot.data}");

                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(Icons.people_outline,
                      size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay clientes registrados',
                      style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey[600]),
                    ),
                    ],
                  ),
                  );
                }

                if (snapshot.hasError) {
                  print("🔥🔥 ERROR CRÍTICO EN CLIENTES: ${snapshot.error}");
                  print("StackTrace: ${snapshot.stackTrace}");
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar clientes',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final allClients = snapshot.data ?? [];
                // final clients = clientService.searchClients(user.organizationId, clientService.searchQuery);
                final query = clientService.searchQuery.toLowerCase().trim();
              
              List<ClientModel> clients;
              
              if (query.isEmpty) {
                clients = allClients;
              } else {
                // Filtramos localmente (es mucho más rápido y fluido)
                clients = allClients.where((client) {
                  final nameMatch = client.name.toLowerCase().contains(query);
                  // Asegúrate de que tu modelo tenga estos campos o ajustalos
                  final emailMatch = client.email?.toLowerCase().contains(query) ?? false;
                  final companyMatch = client.company?.toLowerCase().contains(query) ?? false;
                  
                  return nameMatch || emailMatch || companyMatch;
                }).toList();
              }

                if (allClients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay clientes registrados',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        if (canCreate) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Toca el botón + para agregar uno',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                if (clients.isEmpty && clientService.searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'para "${clientService.searchQuery}"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return _ClientCard(
                      client: client,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ClientDetailScreen(client: client),
                          ),
                        );
                      },
                      canEdit: canEdit,
                      canDelete: canDelete,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateClientScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTap;
  final bool canEdit;
  final bool canDelete;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar con iniciales
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  client.initials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                        color: Colors.grey[600],
                      ),
                    ),
                    if (client.hasPhone || client.city != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (client.hasPhone)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  client.phone!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          if (client.city != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  client.city!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Icono
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}