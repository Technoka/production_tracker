import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/production_batch_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import 'create_production_batch_screen.dart';
import 'production_batch_detail_screen.dart';

class ProductionBatchesListScreen extends StatefulWidget {
  const ProductionBatchesListScreen({super.key});

  @override
  State<ProductionBatchesListScreen> createState() => _ProductionBatchesListScreenState();
}

class _ProductionBatchesListScreenState extends State<ProductionBatchesListScreen> {
  String _selectedFilter = 'all'; // all, pending, in_progress, completed

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final batchService = Provider.of<ProductionBatchService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lotes de Producción')),
        body: const Center(
          child: Text('No tienes una organización asignada'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotes de Producción'),
        actions: [
          // Filtros
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _selectedFilter,
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pendientes'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('En Producción'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completados'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ProductionBatchModel>>(
        stream: batchService.watchBatches(user!.organizationId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final allBatches = snapshot.data ?? [];
          
          // Aplicar filtro
          final filteredBatches = _selectedFilter == 'all'
              ? allBatches
              : allBatches.where((batch) => batch.status == _selectedFilter).toList();

          if (filteredBatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'all'
                        ? 'No hay lotes de producción'
                        : 'No hay lotes con este estado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_selectedFilter == 'all') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Crea el primer lote usando el botón +',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredBatches.length,
              itemBuilder: (context, index) {
                final batch = filteredBatches[index];
                return _buildBatchCard(context, batch, user);
              },
            ),
          );
        },
      ),
      floatingActionButton: user.canManageProduction
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateProductionBatchScreen(
                      organizationId: user.organizationId!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Lote'),
            )
          : null,
    );
  }

  Widget _buildBatchCard(
    BuildContext context,
    ProductionBatchModel batch,
    UserModel user,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductionBatchDetailScreen(
                organizationId: user.organizationId!,
                batchId: batch.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Número de lote + Estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batch.batchNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(batch.status),
                ],
              ),
              const SizedBox(height: 8),

              // Proyecto y Cliente
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      batch.projectName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      batch.clientName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progreso
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${batch.completedProducts}/${batch.totalProducts} productos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: batch.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            batch.isComplete
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${batch.progressPercentage}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Fecha de creación
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado: ${_formatDate(batch.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Indicadores adicionales
              if (batch.isDelayed || batch.priority <= 2) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (batch.isDelayed)
                      Chip(
                        label: const Text('Retrasado'),
                        avatar: const Icon(Icons.warning, size: 16),
                        backgroundColor: Colors.orange[100],
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    if (batch.priority <= 2)
                      Chip(
                        label: const Text('Alta Prioridad'),
                        avatar: const Icon(Icons.priority_high, size: 16),
                        backgroundColor: Colors.red[100],
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.red[900],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = 'Pendiente';
        break;
      case 'in_progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        label = 'En Producción';
        break;
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        label = 'Completado';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}