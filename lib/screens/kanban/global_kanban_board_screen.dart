import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/production_batch_model.dart';
import '../../models/user_model.dart';
import '../../services/kanban_service.dart';
import '../../services/phase_service.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../widgets/draggable_product_card.dart';
import '../production/batch_product_detail_screen.dart';

class GlobalKanbanBoardScreen extends StatefulWidget {
  const GlobalKanbanBoardScreen({Key? key}) : super(key: key);

  @override
  State<GlobalKanbanBoardScreen> createState() => _GlobalKanbanBoardScreenState();
}

class _GlobalKanbanBoardScreenState extends State<GlobalKanbanBoardScreen> {
  final KanbanService _kanbanService = KanbanService();
  final PhaseService _phaseService = PhaseService();
  final AuthService _authService = AuthService();

  String? _searchQuery;
  String? _batchFilter;
  String? _productFilter;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    if (user?.organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tablero Kanban')),
        body: const Center(child: Text('No tienes una organización asignada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero Kanban Global'),
        actions: [
          StreamBuilder<Map<String, dynamic>>(
            stream: _getStatsStream(user!.organizationId!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final stats = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.inventory_2,
                      value: stats['totalProducts'].toString(),
                      color: Colors.blue,
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
          _buildFiltersBar(user!),
          Expanded(
            child: StreamBuilder<List<ProductionPhase>>(
              stream: _phaseService.getOrganizationPhasesStream(user.organizationId!),
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
                
                return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                  future: _getAllProductsGroupedByPhase(user.organizationId!, phases),
                  builder: (context, productsSnapshot) {
                    if (productsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final productsByPhase = productsSnapshot.data ?? {};
                    
                    return _buildKanbanBoard(phases, productsByPhase, user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Búsqueda por nombre/referencia
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar por nombre o referencia',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = null),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.isEmpty ? null : value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Filtro por lote
              Expanded(
                child: StreamBuilder<List<ProductionBatchModel>>(
                  stream: Provider.of<ProductionBatchService>(context, listen: false)
                      .watchBatches(user.organizationId!),
                  builder: (context, snapshot) {
                    final batches = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Lote',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _batchFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...batches.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.batchNumber, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (value) => setState(() => _batchFilter = value),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getAllProductsGroupedByPhase(
    String organizationId,
    List<ProductionPhase> phases,
  ) async {
    final batchService = Provider.of<ProductionBatchService>(context, listen: false);
    final Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    // Inicializar con fases vacías
    for (final phase in phases) {
      groupedProducts[phase.id] = [];
    }

    try {
      final batches = await batchService.watchBatches(organizationId).first;

      for (final batch in batches) {
        final products = await batchService
            .watchBatchProducts(organizationId, batch.id)
            .first;

        for (final product in products) {
          // Aplicar filtros
          bool passesFilter = true;

          if (_searchQuery != null && _searchQuery!.isNotEmpty) {
            final query = _searchQuery!.toLowerCase();
            passesFilter = product.productName.toLowerCase().contains(query) ||
                          (product.productReference?.toLowerCase().contains(query) ?? false);
          }

          if (_batchFilter != null && batch.id != _batchFilter) {
            passesFilter = false;
          }

          if (passesFilter) {
            final phaseId = product.currentPhase;
            if (groupedProducts.containsKey(phaseId)) {
              groupedProducts[phaseId]!.add({
                'product': product,
                'batch': batch,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error cargando productos: $e');
    }

    return groupedProducts;
  }

  Widget _buildKanbanBoard(
    List<ProductionPhase> phases,
    Map<String, List<Map<String, dynamic>>> productsByPhase,
    UserModel user,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: phases.length,
      itemBuilder: (context, index) {
        final phase = phases[index];
        final productsData = productsByPhase[phase.id] ?? [];
        final isAtWipLimit = productsData.length >= phase.wipLimit;
        
        return DragTarget<Map<String, dynamic>>(
          onWillAccept: (data) {
            if (data == null || _currentUser == null) return false;
            
            if (!_kanbanService.canUserMoveToPhase(
              user: _currentUser!,
              phaseId: phase.id,
            )) {
              return false;
            }
            
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
          onAccept: (data) => _handleProductDrop(data, phase),
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
              child: _buildKanbanColumn(phase, productsData, phases, isAtWipLimit),
            );
          },
        );
      },
    );
  }

  Widget _buildKanbanColumn(
    ProductionPhase phase,
    List<Map<String, dynamic>> productsData,
    List<ProductionPhase> allPhases,
    bool isAtWipLimit,
  ) {
    final color = _parseColor(phase.color);
    
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAtWipLimit ? Colors.orange : Colors.grey.shade300,
          width: isAtWipLimit ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumnHeader(phase, color, productsData.length, isAtWipLimit),
          const Divider(height: 1),
          Expanded(
            child: productsData.isEmpty
                ? _buildEmptyColumnState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: productsData.length,
                    itemBuilder: (context, index) {
                      final product = productsData[index]['product'] as BatchProductModel;
                      final batch = productsData[index]['batch'] as ProductionBatchModel;
                      
                      return DraggableProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        allPhases: allPhases,
                        batchNumber: batch.batchNumber,
                        onTap: () => _handleProductTap(product, batch),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(ProductionPhase phase, Color color, int count, bool isAtWipLimit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getPhaseIcon(phase.icon),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? "producto" : "productos"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAtWipLimit) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Límite de productos para esta fase alcanzado.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyColumnState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin productos',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
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

  Widget _buildStatChip({
    required IconData icon,
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

  Stream<Map<String, dynamic>> _getStatsStream(String organizationId) {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final batchService = Provider.of<ProductionBatchService>(context, listen: false);
      
      try {
        final batches = await batchService.watchBatches(organizationId).first;
        int totalProducts = 0;

        for (final batch in batches) {
          final products = await batchService
              .watchBatchProducts(organizationId, batch.id)
              .first;
          totalProducts += products.length;
        }

        return {
          'totalProducts': totalProducts,
        };
      } catch (e) {
        return {
          'totalProducts': 0,
        };
      }
    });
  }

  Future<void> _handleProductDrop(
    Map<String, dynamic> data,
    ProductionPhase toPhase,
  ) async {
    try {
      final product = data['product'] as BatchProductModel;
      final fromPhaseId = product.currentPhase;
      
      if (fromPhaseId == toPhase.id) return;
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moviendo producto...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      final batchService = Provider.of<ProductionBatchService>(context, listen: false);
      
      await batchService.updateProductPhase(
        organizationId: _currentUser!.organizationId!,
        batchId: product.batchId,
        productId: product.id,
        newPhaseId: toPhase.id,
        newPhaseName: toPhase.name,
        userId: _currentUser!.uid,
        userName: _currentUser!.name,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto movido a ${toPhase.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      setState(() {}); // Recargar datos
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

  void _handleProductTap(BatchProductModel product, ProductionBatchModel batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchProductDetailScreen(
          organizationId: batch.organizationId,
          batchId: batch.id,
          productId: product.id,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getPhaseIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'planned':
        return Icons.calendar_today;
      case 'cutting':
        return Icons.content_cut;
      case 'skiving':
        return Icons.layers;
      case 'assembly':
        return Icons.construction;
      case 'studio':
        return Icons.brush;
      default:
        return Icons.work;
    }
  }
}