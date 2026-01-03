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

// REEMPLAZAR el método _buildBatchCard para incluir las barras dobles:

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

            // NUEVO: Progreso Doble
            FutureBuilder<Map<String, double>>(
              future: _calculateProgressStats(user.organizationId!, batch),
              builder: (context, statsSnapshot) {
                final stats = statsSnapshot.data ?? {
                  'phaseProgress': 0.0,
                  'statusProgress': 0.0,
                  'phaseCompleted': 0,
                  'phaseTotal': 0,
                  'statusCompleted': 0,
                  'statusTotal': 0,
                };

                return Column(
                  children: [
                    // Barra 1: Fases
                    Row(
                      children: [
                        Icon(Icons.precision_manufacturing, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(
                              'Producción: ${stats['phaseCompleted']?.toInt() ?? 0} / ${stats['phaseTotal']?.toInt() ?? 0} en Studio',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        const Spacer(),
                        Text(
                          '${(stats['phaseProgress']! * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: stats['phaseProgress'],
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        stats['phaseProgress'] == 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Barra 2: Estados
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 6),
                            Text(
                              'Estado: ${stats['statusCompleted']?.toInt() ?? 0} / ${stats['statusTotal']?.toInt() ?? 0} en OK',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        const Spacer(),
                        Text(
                          '${(stats['statusProgress']! * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: stats['statusProgress'],
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        stats['statusProgress'] == 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                );
              },
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
            if (batch.isDelayed || batch.urgencyNumericValue <= 2) ...[
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
                  if (batch.urgencyNumericValue <= 2)
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

// AÑADIR método helper para calcular progreso del lote:
Future<Map<String, double>> _calculateBatchProgress(
  ProductionBatchModel batch,
  String organizationId,
) async {
  final batchService = Provider.of<ProductionBatchService>(context, listen: false);

  try {
    final products = await batchService
        .watchBatchProducts(organizationId, batch.id)
        .first
        .timeout(const Duration(seconds: 2));

    if (products.isEmpty) {
      return {'phaseProgress': 0.0, 'statusProgress': 0.0};
    }

    final inStudio = products.where((p) => p.isInStudio).length;
    final okStatus = products.where((p) => p.isOK).length;

    return {
      'phaseProgress': inStudio / products.length,
      'statusProgress': okStatus / products.length,
    };
  } catch (e) {
    return {'phaseProgress': 0.0, 'statusProgress': 0.0};
  }
}

// AÑADIR este método helper para calcular estadísticas:
Future<Map<String, double>> _calculateProgressStats(String organizationId, ProductionBatchModel batch) async {
  final batchService = Provider.of<ProductionBatchService>(context, listen: false);
  
  try {
    final products = await batchService
        .watchBatchProducts(organizationId, batch.id)
        .first;

    if (products.isEmpty) {
      return {
        'phaseProgress': 0.0,
        'statusProgress': 0.0,
        'phaseCompleted': 0.0,
        'phaseTotal': 0.0,
        'statusCompleted': 0.0,
        'statusTotal': 0.0,
      };
    }

    // Contar productos en Studio (fase completada)
    final inStudio = products.where((p) => p.isInStudio).length;
    final phaseProgress = inStudio / products.length;

    // Contar productos en estado OK
    final okStatus = products.where((p) => p.isOK).length;
    final statusProgress = okStatus / products.length;

    return {
      'phaseProgress': phaseProgress,
      'statusProgress': statusProgress,
      'phaseCompleted': inStudio.toDouble(),
      'phaseTotal': products.length.toDouble(),
      'statusCompleted': okStatus.toDouble(),
      'statusTotal': products.length.toDouble(),
    };
  } catch (e) {
    return {
      'phaseProgress': 0.0,
      'statusProgress': 0.0,
      'phaseCompleted': 0.0,
      'phaseTotal': 0.0,
      'statusCompleted': 0.0,
      'statusTotal': 0.0,
    };
  }
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