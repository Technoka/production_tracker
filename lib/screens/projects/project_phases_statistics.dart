import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/phase_service.dart';
import '../../services/project_product_service.dart';
import '../../models/project_product_model.dart';
import '../../widgets/phase_progress_indicator.dart';
import '../../screens/products/product_phases_screen.dart';

class ProjectPhasesStatisticsScreen extends StatelessWidget {
  final String organizationId;
  final String projectId;
  final String projectName;
  final UserModel currentUser;

  const ProjectPhasesStatisticsScreen({
    Key? key,
    required this.organizationId,
    required this.projectId,
    required this.projectName,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phaseService = PhaseService();
    final productService = ProjectProductService();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estadísticas de Producción'),
            Text(
              projectName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // El stream se actualizará automáticamente
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: phaseService.getProjectPhaseStatistics(
            organizationId,
            projectId,
          ),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (statsSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${statsSnapshot.error}'),
                  ],
                ),
              );
            }

            final stats = statsSnapshot.data ?? {};

            return StreamBuilder<List<ProjectProductModel>>(
              stream: productService.watchProjectProducts(organizationId, projectId),
              builder: (context, productsSnapshot) {
                final products = productsSnapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Resumen general
                    _buildOverallProgressCard(stats),
                    const SizedBox(height: 16),

                    // Estadísticas por estado
                    _buildPhaseStatusCards(stats),
                    const SizedBox(height: 24),

                    // Lista de productos con su progreso
                    _buildSectionTitle('Progreso por Producto'),
                    const SizedBox(height: 8),
                    if (products.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No hay productos en este proyecto'),
                          ),
                        ),
                      )
                    else
                      ...products.map((product) => _buildProductCard(
                            context,
                            product,
                          )),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOverallProgressCard(Map<String, dynamic> stats) {
    final totalPhases = stats['totalPhases'] ?? 0;
    final completedPhases = stats['completedPhases'] ?? 0;
    final overallProgress = stats['overallProgress'] ?? 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Progreso General del Proyecto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: totalPhases > 0 ? completedPhases / totalPhases : 0,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(overallProgress / 100),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${overallProgress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(overallProgress / 100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedPhases/$totalPhases',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$completedPhases de $totalPhases fases completadas',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseStatusCards(Map<String, dynamic> stats) {
    final completed = stats['completedPhases'] ?? 0;
    final inProgress = stats['inProgressPhases'] ?? 0;
    final pending = stats['pendingPhases'] ?? 0;
    final totalProducts = stats['totalProducts'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Completadas',
                completed.toString(),
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'En Proceso',
                inProgress.toString(),
                Colors.orange,
                Icons.access_time,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pendientes',
                pending.toString(),
                Colors.grey,
                Icons.radio_button_unchecked,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Productos',
                totalProducts.toString(),
                Colors.blue,
                Icons.inventory_2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProjectProductModel product,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: PhaseProgressIndicator(
          organizationId: organizationId,
          projectId: projectId,
          productId: product.id,
          size: 40,
          showLabel: false,
        ),
        title: Text(
          product.catalogProductName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${product.quantity} unidades · ${product.catalogProductReference}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductPhasesScreen(
                organizationId: organizationId,
                projectId: projectId,
                productId: product.id,
                productName: product.catalogProductName,
                currentUser: currentUser,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.33) return Colors.red;
    if (progress < 0.66) return Colors.orange;
    if (progress < 1.0) return Colors.blue;
    return Colors.green;
  }
}