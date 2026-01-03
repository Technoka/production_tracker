import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/production_batch_model.dart';
import '../../models/user_model.dart';
import '../../services/kanban_service.dart';
import '../../services/phase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/kanban_column_widget.dart';
import '../../widgets/kanban_filter_bar.dart';
import '../production/batch_product_detail_screen.dart';

class KanbanBoardScreen extends StatefulWidget {
  final ProductionBatchModel batch;

  const KanbanBoardScreen({
    Key? key,
    required this.batch,
  }) : super(key: key);

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final KanbanService _kanbanService = KanbanService();
  final PhaseService _phaseService = PhaseService();
  final AuthService _authService = AuthService();

  String? _searchQuery;
  bool _showOnlyBlocked = false;
  UserModel? _currentUser;
  Map<String, int> _productCounts = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadProductCounts();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final user = await _authService.getUserById(userId);
        if (mounted) {
          setState(() => _currentUser = user);
        }
      }
    } catch (e) {
      print('Error cargando usuario: $e');
    }
  }

  Future<void> _loadProductCounts() async {
    try {
      final counts = await _kanbanService.getProductCountByPhase(
        organizationId: widget.batch.organizationId,
        projectId: widget.batch.projectId,
        batchId: widget.batch.id,
      );
      if (mounted) {
        setState(() => _productCounts = counts);
      }
    } catch (e) {
      print('Error cargando contadores: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tablero Kanban'),
            Text(
              '${widget.batch.batchNumber} - ${widget.batch.projectName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Estadísticas rápidas
          StreamBuilder<Map<String, dynamic>>(
            stream: _getStatsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final stats = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.inventory_2,
                      label: 'Activos',
                      value: stats['activeProducts'].toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    if (stats['blockedProducts'] > 0)
                      _buildStatChip(
                        icon: Icons.block,
                        label: 'Bloqueados',
                        value: stats['blockedProducts'].toString(),
                        color: Colors.red,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtros
          KanbanFilterBar(
            searchQuery: _searchQuery,
            showOnlyBlocked: _showOnlyBlocked,
            onSearchChanged: (query) => setState(() => _searchQuery = query),
            onBlockedFilterChanged: (value) => setState(() => _showOnlyBlocked = value),
            onClearFilters: () => setState(() {
              _searchQuery = null;
              _showOnlyBlocked = false;
            }),
          ),
          
          // Tablero Kanban
          Expanded(
            child: StreamBuilder<List<ProductionPhase>>(
              stream: _phaseService.getOrganizationPhasesStream(widget.batch.organizationId),
              builder: (context, phasesSnapshot) {
                if (phasesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!phasesSnapshot.hasData || phasesSnapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final phases = phasesSnapshot.data!
                    .where((p) => p.isActive)
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));
                
                return StreamBuilder<Map<String, List<BatchProductModel>>>(
                  stream: _kanbanService.getKanbanProductsStream(
                    organizationId: widget.batch.organizationId,
                    projectId: widget.batch.projectId,
                    batchId: widget.batch.id,
                    searchQuery: _searchQuery,
                    onlyBlocked: _showOnlyBlocked,
                  ),
                  builder: (context, productsSnapshot) {
                    if (!productsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final productsByPhase = productsSnapshot.data!;
                    
                    return _buildKanbanBoard(phases, productsByPhase);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard(
    List<ProductionPhase> phases,
    Map<String, List<BatchProductModel>> productsByPhase,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: phases.length,
      itemBuilder: (context, index) {
        final phase = phases[index];
        final products = productsByPhase[phase.id] ?? [];
        final isAtWipLimit = products.length >= phase.wipLimit;
        
        return DragTarget<Map<String, dynamic>>(
          onWillAccept: (data) {
            if (data == null) return false;
            if (_currentUser == null) return false;
            
            // Verificar permisos
            if (!_kanbanService.canUserMoveToPhase(
              user: _currentUser!,
              phaseId: phase.id,
            )) {
              return false;
            }
            
            // Verificar WIP limit
            final productData = data['product'] as BatchProductModel;
            if (productData.currentPhase != phase.id && isAtWipLimit) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Límite WIP alcanzado en ${phase.name}'),
                  backgroundColor: Colors.orange,
                ),
              );
              return false;
            }
            
            return true;
          },
          onAccept: (data) => _handleProductDrop(data, phase, products.length),
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: isHovering
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: KanbanColumnWidget(
                phase: phase,
                products: products,
                allPhases: phases,
                isAtWipLimit: isAtWipLimit,
                onProductTap: _handleProductTap,
                onProductBlock: _handleProductBlock,
                onReorder: (product, newIndex) {
                  _handleReorder(product, phase, newIndex);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_kanban, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay fases configuradas',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Configura las fases de producción primero',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>> _getStatsStream() {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return await _kanbanService.getKanbanStats(
        organizationId: widget.batch.organizationId,
        projectId: widget.batch.projectId,
        batchId: widget.batch.id,
      );
    });
  }

  Future<void> _handleProductDrop(
    Map<String, dynamic> data,
    ProductionPhase toPhase,
    int newPosition,
  ) async {
    try {
      final product = data['product'] as BatchProductModel;
      final fromPhaseId = product.currentPhase;
      
      if (fromPhaseId == toPhase.id) return; // Misma columna
      
      // Mostrar loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moviendo producto...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Mover producto
      await _kanbanService.moveProductToPhase(
        organizationId: widget.batch.organizationId,
        projectId: widget.batch.projectId,
        batchId: widget.batch.id,
        productId: product.id,
        fromPhaseId: fromPhaseId,
        toPhaseId: toPhase.id,
        toPhaseName: toPhase.name,
        newPosition: newPosition,
        userId: _currentUser!.uid,
        userName: _currentUser!.name,
      );
      
      // Actualizar contadores
      await _loadProductCounts();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto movido a ${toPhase.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReorder(
    BatchProductModel product,
    ProductionPhase phase,
    int newPosition,
  ) async {
    try {
      await _kanbanService.moveProductToPhase(
        organizationId: widget.batch.organizationId,
        projectId: widget.batch.projectId,
        batchId: widget.batch.id,
        productId: product.id,
        fromPhaseId: phase.id,
        toPhaseId: phase.id,
        toPhaseName: phase.name,
        newPosition: newPosition,
        userId: _currentUser!.uid,
        userName: _currentUser!.name,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reordenar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleProductTap(BatchProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchProductDetailScreen(
          organizationId: widget.batch.organizationId,
          batchId: widget.batch.id,
          productId: product.id,
        ),
      ),
    );
  }

  Future<void> _handleProductBlock(BatchProductModel product) async {
    if (product.isBlocked) {
      // Desbloquear directamente
      await _toggleBlock(product, false, null);
    } else {
      // Mostrar diálogo para bloquear
      final reason = await _showBlockDialog();
      if (reason != null) {
        await _toggleBlock(product, true, reason);
      }
    }
  }

  Future<void> _toggleBlock(
    BatchProductModel product,
    bool isBlocked,
    String? reason,
  ) async {
    try {
      await _kanbanService.toggleProductBlock(
        organizationId: widget.batch.organizationId,
        projectId: widget.batch.projectId,
        batchId: widget.batch.id,
        productId: product.id,
        isBlocked: isBlocked,
        blockReason: reason,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBlocked ? 'Producto bloqueado' : 'Producto desbloqueado'),
          backgroundColor: isBlocked ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showBlockDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear Producto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motivo del bloqueo',
            hintText: 'Ej: Falta de material, problema de calidad...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debes especificar un motivo')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
  }
}