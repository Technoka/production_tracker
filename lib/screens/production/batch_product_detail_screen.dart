import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/batch_product_model.dart';
import '../../models/phase_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/production_batch_service.dart';
import '../../services/phase_service.dart';
import '../../models/production_batch_model.dart';
import 'production_batch_detail_screen.dart';

class BatchProductDetailScreen extends StatefulWidget {
  final String organizationId;
  final String batchId;
  final String productId;

  const BatchProductDetailScreen({
    super.key,
    required this.organizationId,
    required this.batchId,
    required this.productId,
  });

  @override
  State<BatchProductDetailScreen> createState() => _BatchProductDetailScreenState();
}

class _BatchProductDetailScreenState extends State<BatchProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserData;

    return StreamBuilder<List<BatchProductModel>>(
  stream: Provider.of<ProductionBatchService>(context, listen: false)
      .watchBatchProducts(widget.organizationId, widget.batchId),
  builder: (context, productSnapshot) {
    if (productSnapshot.connectionState == ConnectionState.waiting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (productSnapshot.hasError || !productSnapshot.hasData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error al cargar el producto: ${productSnapshot.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    // Buscar el producto específico en la lista
    final products = productSnapshot.data!;
    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => products.first, // Fallback si no se encuentra
    );

        return Scaffold(
          appBar: AppBar(
            title: Text(product.productName),
            actions: [
  if (user?.canManageProduction ?? false)
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleAction(value, product),
      itemBuilder: (context) => [
        const PopupMenuDivider(),
        
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Información del producto
                _buildProductInfoCard(product, user),
                const SizedBox(height: 16),
                
                _buildProductStatusCard(product, user),
                const SizedBox(height: 16),

                // Progreso por fases
                _buildPhasesCard(product, user),
                const SizedBox(height: 16),

                // Personalización
                if (product.color != null ||
                    product.material != null ||
                    product.specialDetails != null)
                  _buildCustomizationCard(product),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfoCard(BatchProductModel product, UserModel? user) {
    

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text(
                  'Información del Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Nombre
            Text(
              product.productName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Referencia
            if (product.productReference != null) ...[
              Text(
                'SKU: ${product.productReference}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
// Lote (Obtenido asíncronamente)
            if (user?.organizationId != null)
              FutureBuilder<ProductionBatchModel?>(
                future: Provider.of<ProductionBatchService>(context, listen: false)
                    .getBatch(user!.organizationId!, product.batchId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Cargando lote...',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                     // Si falla o no encuentra el lote, mostramos el ID o un texto genérico
                    return Text(
                      'Lote no disponible',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    );
                  }

                  final batch = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lote: ${batch.batchNumber} (Producto #${product.productNumber} / ${batch.totalProducts})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32, // Altura reducida para botón pequeño
                        child: OutlinedButton(
                          onPressed: () {
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Ver lote'),
                        ),
                      ),
                      ],
                  );
                },
              ),
            const SizedBox(height: 8),

            // Descripción
            if (product.description != null) ...[
              Text(
                'Descripción: ${product.description!}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Urgencia
              Text(
                'Urgencia: ${product.urgencyLevel}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              
            // Notas
            if (product.productNotes != null) ...[
              Text(
                'Notas: ${product.productNotes!}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(),
            const SizedBox(height: 8),

            // Cantidad
            _buildInfoRow(
              Icons.numbers,
              'Cantidad',
              '${product.quantity} unidades',
            ),
            const SizedBox(height: 8),

            // Precio (solo para roles autorizados)
            if ((user!.canViewFinancials) && product.unitPrice != null) ...[
              _buildInfoRow(
                Icons.euro,
                'Precio unitario',
                '${product.unitPrice!.toStringAsFixed(2)} €',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.account_balance_wallet,
                'Precio total',
                '${product.totalPrice?.toStringAsFixed(2) ?? "0.00"} €',
                isBold: true,
              ),
              const SizedBox(height: 8),
            ],

            // Progreso general
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progreso General',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${product.progressPercentage}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: product.totalProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          product.isCompleted ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.completedPhasesCount} de ${product.totalPhasesCount} fases completadas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Estado actual
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Fase actual: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    product.currentPhaseName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// ================= NUEVO CÓDIGO PARA ESTADOS DEL PRODUCTO =================
Widget _buildProductStatusCard(BatchProductModel product, UserModel? user) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(product.productStatus),
                color: product.statusColor,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Estado del Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Estado actual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: product.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: product.statusColor, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(product.productStatus),
                  color: product.statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.statusDisplayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: product.statusColor,
                        ),
                      ),
                      Text(
                        _getStatusDescription(product.productStatus),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Información adicional según estado
          const SizedBox(height: 16),

          if (product.hasBeenSent) ...[
            _buildInfoRow(
              Icons.send,
              'Enviado al cliente',
              _formatDateTime(product.sentToClientAt!),
            ),
            const SizedBox(height: 8),
          ],

          if (product.hasBeenEvaluated) ...[
            _buildInfoRow(
              Icons.rate_review,
              'Evaluado',
              _formatDateTime(product.evaluatedAt!),
            ),
            const SizedBox(height: 8),
          ],

          if (product.isCAO || product.isControl) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Devoluciones',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.assignment_return,
              'Devueltos',
              '${product.returnedCount} unidades',
            ),
            if (product.returnReason != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.comment,
                'Motivo',
                product.returnReason!,
              ),
            ],
            
            // NUEVO: Mostrar estado de clasificación en Control
            if (product.isControl) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Clasificación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 8),
              
              if (product.isReturnBalanced) ...[
                // Ya está clasificado
                _buildInfoRow(
                  Icons.build,
                  'Reparados',
                  '${product.repairedCount} unidades',
                ),
                const SizedBox(height: 4),
                _buildInfoRow(
                  Icons.delete_forever,
                  'Descartados',
                  '${product.discardedCount} unidades',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Clasificación completa. Listo para aprobar.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Pendiente de clasificar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pendiente de clasificar (Reparados/Basura)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (product.isCAO) ...[
              // En CAO, aún no está en Control
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esperando recepción de productos devueltos',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _buildProductStatusActions(product, user),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _buildProductStatusActions(BatchProductModel product, UserModel? user) {
    // Si no tiene permisos, no mostramos nada (ni siquiera el título)
    if (user?.canManageProduction != true) return const SizedBox.shrink();

    // 1. Preparamos la lista de acciones disponibles
    final List<Widget> actions = [];

    // FLUJO: Studio + Pending → OK directo o CAO
    if (product.isInStudio && product.isPending) {
      actions.add(_buildActionButton(
        icon: Icons.check_circle,
        label: 'Todo Correcto (→ OK)',
        color: Colors.green,
        onPressed: () => _handleAction('approve_directly', product),
      ));
      // Añadimos un pequeño espacio entre botones si hay varios
      if (actions.isNotEmpty) actions.add(const SizedBox(height: 8)); 
      
      actions.add(_buildActionButton(
        icon: Icons.cancel,
        label: 'Hay Defectos (→ CAO)',
        color: Colors.red,
        onPressed: () => _handleAction('reject_directly', product),
      ));
    }
    // Añadimos un pequeño espacio entre botones si hay varios
    if (actions.isNotEmpty) actions.add(const SizedBox(height: 8)); 

    // FLUJO: CAO → Control (sin clasificar)
    if (product.isCAO && !product.isControl) {
      actions.add(_buildActionButton(
        icon: Icons.verified,
        label: 'Recibir y Evaluar (→ Control)',
        color: Colors.blue,
        onPressed: () => _handleAction('move_to_control', product),
      ));
    }
    // Añadimos un pequeño espacio entre botones si hay varios
    if (actions.isNotEmpty) actions.add(const SizedBox(height: 8)); 
    
    // FLUJO: Control sin clasificar → Clasificar
    if (product.isControl && !product.isReturnBalanced) {
      actions.add(_buildActionButton(
        icon: Icons.category,
        label: 'Clasificar Devoluciones',
        color: Colors.orange,
        onPressed: () => _handleAction('classify_returns', product),
      ));
    }
    // Añadimos un pequeño espacio entre botones si hay varios
    if (actions.isNotEmpty) actions.add(const SizedBox(height: 8));
    
    // FLUJO: Control clasificado → OK
    if (product.isControl && product.isReturnBalanced) {
      actions.add(_buildActionButton(
        icon: Icons.check_circle,
        label: 'Finalizar (→ OK)',
        color: Colors.green,
        onPressed: () => _handleAction('approve', product),
      ));
    }
    // Añadimos un pequeño espacio entre botones si hay varios
    if (actions.isNotEmpty) actions.add(const SizedBox(height: 8)); 
    
      // FLUJO: Hold → OK o CAO
    if (product.isHold) {
      actions.add(_buildActionButton(
        icon: Icons.check_circle,
        label: 'Aprobar (→ OK)',
        color: Colors.green,
        onPressed: () => _handleAction('approve', product),
      ));
      // Añadimos un pequeño espacio entre botones si hay varios
      if (actions.isNotEmpty) actions.add(const SizedBox(height: 8)); 
      
      actions.add(_buildActionButton(
        icon: Icons.cancel,
        label: 'Rechazar (→ CAO)',
        color: Colors.red,
        onPressed: () => _handleAction('reject', product),
      ));
    }
    // Añadimos un pequeño espacio entre botones si hay varios
    if (actions.isNotEmpty) actions.add(const SizedBox(height: 8));

    // 2. Construimos la UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // 3. Lógica para mostrar acciones o el mensaje de vacío
        if (actions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No hay acciones disponibles',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...actions,
      ],
    );
  }

  // Helper para crear los botones de la lista con estilo uniforme
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity, // Ocupa todo el ancho disponible
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          label: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            side: BorderSide(color: color.withOpacity(0.5)),
            alignment: Alignment.centerLeft, // Alinea contenido a la izquierda como una lista
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhasesCard(BatchProductModel product, UserModel? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt),
                SizedBox(width: 8),
                Text(
                  'Fases de Producción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            FutureBuilder<List<ProductionPhase>>(
              future: Provider.of<PhaseService>(context, listen: false)
                  .getOrganizationPhases(widget.organizationId),
              builder: (context, phasesSnapshot) {
                if (phasesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (phasesSnapshot.hasError) {
                  return Text('Error: ${phasesSnapshot.error}');
                }

                final allPhases = phasesSnapshot.data ?? [];
                allPhases.sort((a, b) => a.order.compareTo(b.order));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allPhases.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final phase = allPhases[index];
                    final phaseProgress = product.phaseProgress[phase.id];
                    final isCurrentPhase = product.currentPhase == phase.id;

                    return _buildPhaseItem(
                      phase,
                      phaseProgress,
                      isCurrentPhase,
                      user,
                      product,
                      allPhases,
                      index,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

Widget _buildPhaseItem(
  ProductionPhase phase,
  PhaseProgressData? progress,
  bool isCurrentPhase,
  UserModel? user,
  BatchProductModel product,
  List<ProductionPhase> allPhases,
  int currentIndex,
) {
  final isInProgress = progress?.isInProgress ?? false;
  final isCompleted = progress?.isCompleted ?? false;

  Color backgroundColor;
  Color borderColor;
  IconData icon;

  if (isCompleted) {
    backgroundColor = Colors.green[50]!;
    borderColor = Colors.green;
    icon = Icons.check_circle;
  } else if (isInProgress || isCurrentPhase) {
    backgroundColor = Colors.blue[50]!;
    borderColor = Colors.blue;
    icon = Icons.play_circle;
  } else {
    backgroundColor = Colors.grey[100]!;
    borderColor = Colors.grey;
    icon = Icons.radio_button_unchecked;
  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: borderColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                    Text(
                      phase.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            
            // Botones de acción
            if (user?.canManageProduction ?? false) ...[
              // Retroceder (solo admin)
              if ((user?.isAdmin ?? false) && (isCompleted)) ...[
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.orange),
                    onPressed: () => _showRollbackDialog(
                      product,
                      allPhases[currentIndex],
                      user!,
                    ),
                    tooltip: 'Retroceder fase',
                  ),
                ],
            ],
              
              // Avanzar
              if (isCurrentPhase && currentIndex < allPhases.length - 1) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _showAdvancePhaseDialog(
                    product,
                    allPhases[currentIndex + 1],
                    user!,
                  ),
                  tooltip: 'Avanzar fase',
                ),
              ],
            ],
          
        ),
          // Detalles de la fase
          if (progress != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            if (progress.startedAt != null)
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Iniciado: ${_formatDateTime(progress.startedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

            if (progress.completedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Completado: ${_formatDateTime(progress.completedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            if (progress.completedByName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Por: ${progress.completedByName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            if (progress.notes != null && progress.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notas: ${progress.notes}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showRollbackDialog(
  BatchProductModel product,
  ProductionPhase previousPhase,
  UserModel user,
) {
  final reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Retroceder Fase'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Retroceder a "${previousPhase.name}"?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta acción solo debe realizarse en casos excepcionales.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo del retroceso *',
              border: OutlineInputBorder(),
              hintText: 'Explica por qué se retrocede...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debes indicar el motivo')),
              );
              return;
            }

            final batchService = Provider.of<ProductionBatchService>(
              context,
              listen: false,
            );

            Navigator.pop(context);

            final success = await batchService.updateProductPhaseWithRollback(
              organizationId: widget.organizationId,
              batchId: widget.batchId,
              productId: widget.productId,
              newPhaseId: previousPhase.id,
              newPhaseName: previousPhase.name,
              userId: user.uid,
              userName: user.name,
              isRollback: true,
              notes: reasonController.text.trim(),
            );

            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Retrocedido a: ${previousPhase.name}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Retroceder'),
        ),
      ],
    ),
  );
}

  Widget _buildCustomizationCard(BatchProductModel product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                const Text(
                  'Personalización',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (product.color != null) ...[
              _buildInfoRow(Icons.color_lens, 'Color', product.color!),
              const SizedBox(height: 8),
            ],

            if (product.material != null) ...[
              _buildInfoRow(Icons.texture, 'Material', product.material!),
              const SizedBox(height: 8),
            ],

            if (product.specialDetails != null) ...[
              _buildInfoRow(Icons.notes, 'Detalles especiales', product.specialDetails!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAdvancePhaseDialog(
    BatchProductModel product,
    ProductionPhase nextPhase,
    UserModel user,
  ) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avanzar Fase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Completar fase actual y avanzar a "${nextPhase.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Añade observaciones...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final batchService = Provider.of<ProductionBatchService>(
                context,
                listen: false,
              );

              Navigator.pop(context); // Cerrar diálogo

              final success = await batchService.updateProductPhase(
                organizationId: widget.organizationId,
                batchId: widget.batchId,
                productId: widget.productId,
                newPhaseId: nextPhase.id,
                newPhaseName: nextPhase.name,
                userId: user.uid,
                userName: user.name,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Avanzado a fase: ${nextPhase.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al avanzar fase'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Avanzar'),
          ),
        ],
      ),
    );
  }

Future<void> _handleAction(
  String action,
  BatchProductModel product
) async {
  final batchService = Provider.of<ProductionBatchService>(context, listen: false);

  switch (action) {
    case 'approve_directly':
      final confirm = await _showConfirmDialog(
        'Aprobar Producto',
        '¿Confirmar que el producto está correcto?\n\nPasará directamente a OK.',
      );
      if (confirm == true) {
        final success = await batchService.approveProductDirectly(
          organizationId: widget.organizationId,
          batchId: widget.batchId,
          productId: widget.productId,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto aprobado'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted && batchService.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(batchService.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      break;

    case 'reject_directly':
      _showRejectDirectlyDialog(product);
      break;

    case 'move_to_control':
      final confirm = await _showConfirmDialog(
        'Mover a Control',
        '¿Confirmar que se han recibido los productos devueltos?\n\nSe moverán a Control para evaluación.',
      );
      if (confirm == true) {
        final success = await batchService.moveToControl(
          organizationId: widget.organizationId,
          batchId: widget.batchId,
          productId: widget.productId,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movido a Control'),
              backgroundColor: Colors.blue,
            ),
          );
        } else if (mounted && batchService.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(batchService.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      break;

    case 'classify_returns':
      _showClassifyReturnsDialog(product);
      break;

    case 'approve':
      final confirm = await _showConfirmDialog(
        'Aprobar Producto',
        '¿Aprobar este producto?\n\nEl estado cambiará a OK.',
      );
      if (confirm == true) {
        final success = await batchService.approveProduct(
          organizationId: widget.organizationId,
          batchId: widget.batchId,
          productId: widget.productId,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto aprobado'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted && batchService.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(batchService.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      break;

    case 'reject':
      _showRejectDialog(product);
      break;

    case 'delete':
      _showDeleteConfirmation(product);
      break;
  }
}

// AÑADIR nuevo diálogo para rechazo directo desde Studio:

void _showRejectDirectlyDialog(BatchProductModel product) {
  final returnedController = TextEditingController();
  final reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final returned = int.tryParse(returnedController.text) ?? 0;
        final isValidQuantity = returned >= 1 && returned <= product.quantity;

        return AlertDialog(
          title: const Text('Rechazar Producto (CAO)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'El producto será marcado como CAO (no conforme).',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total de productos: ${product.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: returnedController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Unidades con defectos *',
                    border: const OutlineInputBorder(),
                    helperText: 'Entre 1 y ${product.quantity}',
                    errorText: returned > 0 && !isValidQuantity
                        ? 'Debe ser entre 1 y ${product.quantity}'
                        : null,
                    suffixIcon: returned > 0
                        ? Icon(
                            isValidQuantity ? Icons.check_circle : Icons.error,
                            color: isValidQuantity ? Colors.green : Colors.red,
                          )
                        : null,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del rechazo *',
                    border: OutlineInputBorder(),
                    hintText: 'Describe los defectos...',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: !isValidQuantity || reasonController.text.trim().isEmpty
                  ? null
                  : () async {
                      final batchService = Provider.of<ProductionBatchService>(
                        context,
                        listen: false,
                      );

                      Navigator.pop(context);

                      final success = await batchService.rejectProductDirectly(
                        organizationId: widget.organizationId,
                        batchId: widget.batchId,
                        productId: widget.productId,
                        returnedCount: returned,
                        returnReason: reasonController.text.trim(),
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Producto rechazado (CAO)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    ),
  );
}

void _showRejectDialog(BatchProductModel product) {
  final returnedController = TextEditingController();
  final reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final returned = int.tryParse(returnedController.text) ?? 0;
        final isValidQuantity = returned >= 1 && returned <= product.quantity;

        return AlertDialog(
          title: const Text('Rechazar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total de productos: ${product.quantity}'),
                const SizedBox(height: 16),
                TextField(
                  controller: returnedController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Unidades devueltas *',
                    border: const OutlineInputBorder(),
                    helperText: 'Entre 1 y ${product.quantity}',
                    errorText: returned > 0 && !isValidQuantity
                        ? 'Debe ser entre 1 y ${product.quantity}'
                        : null,
                    suffixIcon: returned > 0
                        ? Icon(
                            isValidQuantity ? Icons.check_circle : Icons.error,
                            color: isValidQuantity ? Colors.green : Colors.red,
                          )
                        : null,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del rechazo *',
                    border: OutlineInputBorder(),
                    hintText: 'Describe los defectos encontrados...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: !isValidQuantity || reasonController.text.trim().isEmpty
                  ? null
                  : () async {
                      final batchService = Provider.of<ProductionBatchService>(
                        context,
                        listen: false,
                      );

                      Navigator.pop(context);

                      final success = await batchService.rejectProduct(
                        organizationId: widget.organizationId,
                        batchId: widget.batchId,
                        productId: widget.productId,
                        returnedCount: returned,
                        returnReason: reasonController.text.trim(),
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Producto rechazado (CAO)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        // No hace falta setState, el Stream se actualiza automáticamente
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    ),
  );
}
// AÑADIR diálogo para clasificar devoluciones:

void _showClassifyReturnsDialog(BatchProductModel product) {
  final repairedController = TextEditingController();
  final discardedController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final repaired = int.tryParse(repairedController.text) ?? 0;
        final discarded = int.tryParse(discardedController.text) ?? 0;
        final total = repaired + discarded;
        final isValid = total == product.returnedCount;

        return AlertDialog(
          title: const Text('Clasificar Devoluciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total devueltos: ${product.returnedCount} unidades'),
              const SizedBox(height: 16),
              TextField(
                controller: repairedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reparados',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discardedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Descartados (basura)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.delete_forever),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isValid ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total: $total / ${product.returnedCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isValid ? Colors.green[900] : Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: !isValid
                  ? null
                  : () async {
                      final batchService = Provider.of<ProductionBatchService>(
                        context,
                        listen: false,
                      );

                      Navigator.pop(context);

                      final success = await batchService.classifyReturns(
                        organizationId: widget.organizationId,
                        batchId: widget.batchId,
                        productId: widget.productId,
                        repairedCount: repaired,
                        discardedCount: discarded,
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Devoluciones clasificadas'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
}

// AÑADIR helpers:

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.schedule;
    case 'cao':
      return Icons.error;
    case 'hold':
      return Icons.pause_circle;
    case 'control':
      return Icons.verified;
    case 'ok':
      return Icons.check_circle;
    default:
      return Icons.help_outline;
  }
}

String _getStatusDescription(String status) {
  switch (status) {
    case 'pending':
      return 'En proceso de fabricación';
    case 'cao':
      return 'No conforme - Devuelto por el cliente';
    case 'hold':
      return 'Enviado - Pendiente de evaluación del cliente';
    case 'control':
      return 'En evaluación - Clasificando devoluciones';
    case 'ok':
      return 'Aprobado por el cliente';
    default:
      return status;
  }
}

Future<bool?> _showConfirmDialog(String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}

  void _showDeleteConfirmation(BatchProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de eliminar "${product.productName}" del lote?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final batchService = Provider.of<ProductionBatchService>(
                context,
                listen: false,
              );

              Navigator.pop(context); // Cerrar diálogo

              final success = await batchService.deleteProductFromBatch(
                widget.organizationId,
                widget.batchId,
                widget.productId,
              );

              if (success && mounted) {
                Navigator.pop(context); // Volver a detalle del lote
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  
}