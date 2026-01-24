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
import '../../widgets/chat/chat_button.dart';
import '../../services/message_service.dart';
import '../../screens/chat/chat_screen.dart';
import '../../services/organization_member_service.dart';
import '../../models/organization_member_model.dart';

import '../../services/product_status_service.dart';
import '../../services/status_transition_service.dart';
import '../../models/product_status_model.dart';
import '../../models/status_transition_model.dart';
import '../../models/role_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/validation_dialogs/validation_dialog_manager.dart';
import '../../models/validation_config_model.dart';

// TODO: comprobar que se usa scope y assignedMembers correctamente


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
  State<BatchProductDetailScreen> createState() =>
      _BatchProductDetailScreenState();
}

class _BatchProductDetailScreenState extends State<BatchProductDetailScreen> {
  OrganizationMemberWithUser? _currentMember;
  bool _isLoadingPermissions = true;
  bool _isPhasesExpanded = false; // Comprimido por defecto

  final MessageService _messageService = MessageService();

  RoleModel? _currentRole; // ← NUEVO
  List<ProductStatusModel> _availableStatuses = []; // ← NUEVO
  List<StatusTransitionModel> _availableTransitions = []; // ← NUEVO

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  // ✅ AÑADIR MÉTODO completo
  Future<void> _loadPermissions() async {
    final memberService =
        Provider.of<OrganizationMemberService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final member = await memberService.getCurrentMember(
      widget.organizationId,
      authService.currentUser!.uid,
    );

    // Cargar rol completo para validaciones
    RoleModel? role;
    if (member != null) {
      try {
        final roleDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(widget.organizationId)
            .collection('roles')
            .doc(member.member.roleId)
            .get();

        if (roleDoc.exists) {
          role = RoleModel.fromMap(roleDoc.data()!, docId: roleDoc.id);
        }
      } catch (e) {
        debugPrint('Error loading role: $e');
      }
    }

    if (mounted) {
      setState(() {
        _currentMember = member;
        _currentRole = role;
        _isLoadingPermissions = false;
      });
    }
  }

  /// Cargar transiciones disponibles desde el estado actual del producto
Future<List<StatusTransitionModel>> _loadAvailableTransitions(
  String currentStatusId,
) async {
  if (_currentRole == null) return [];

  final transitionService = Provider.of<StatusTransitionService>(
    context,
    listen: false,
  );

  try {
    // Obtener todas las transiciones desde el estado actual
    final transitions = await transitionService.getAvailableTransitions(
      organizationId: widget.organizationId,
      fromStatusId: currentStatusId,
      userRoleId: _currentRole!.id,
    );

    // Filtrar solo las activas
    return transitions.where((t) => t.isActive).toList();
  } catch (e) {
    debugPrint('Error loading transitions: $e');
    return [];
  }
}

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final memberService = Provider.of<OrganizationMemberService>(context);
    final user = authService.currentUserData;

    // ✅ Mostrar loading mientras cargan permisos
    if (_isLoadingPermissions) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              // Botón de chat en el AppBar con badge
              if (user != null)
                ChatButton(
                    organizationId: widget.organizationId,
                    entityType: 'batch_product',
                    entityId: product.id,
                    parentId: product.batchId,
                    entityName:
                        '${product.productName} - ${product.productReference}',
                    user: user,
                    showInAppBar: true),

              FutureBuilder<bool>(
                future: memberService.can('batch_products', 'edit'),
                builder: (context, snapshot) {
                  final canEdit = snapshot.data ?? false;

                  if (!canEdit) return const SizedBox.shrink();

                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleAction(value, product),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar Producto'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {},
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Definimos el breakpoint para "Escritorio" (ej: 900px)
                final isDesktop = constraints.maxWidth > 900;

                // Si es móvil, mantenemos el ListView original (1 columna)
                if (!isDesktop) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProductInfoCard(product, user),
                      const SizedBox(height: 16),
                      _buildProductStatusCard(product, user),
                      const SizedBox(height: 16),
                      _buildPhasesCard(product, user),
                      const SizedBox(height: 16),
                      _buildChatSection(product, user), // Ver helper abajo
                      if (product.color != null ||
                          product.material != null ||
                          product.specialDetails != null) ...[
                        const SizedBox(height: 16),
                        _buildCustomizationCard(product),
                      ],
                    ],
                  );
                }

                // Si es Escritorio, usamos ScrollView con Filas
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24), // Un poco más de margen en web
                  child: Column(
                    children: [
                      // FILA 1: Info y Estado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildProductInfoCard(product, user)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildProductStatusCard(product, user)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // FILA 2: Fases y Chat
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPhasesCard(product, user)),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildChatSection(product, user),
                                // Si hay personalización, la ponemos debajo del chat para equilibrar
                                if (product.color != null ||
                                    product.material != null ||
                                    product.specialDetails != null) ...[
                                  const SizedBox(height: 24),
                                  _buildCustomizationCard(product),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
                future:
                    Provider.of<ProductionBatchService>(context, listen: false)
                        .getBatchById(user!.organizationId!, product.batchId),
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
                                builder: (context) =>
                                    ProductionBatchDetailScreen(
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
          ],
        ),
      ),
    );
  }

// ================= NUEVO CÃ“DIGO PARA ESTADOS DEL PRODUCTO =================
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
                  _getStatusIcon(product.statusName!),
                  color: product.effectiveStatusColor,
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
                color: product.effectiveStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: product.effectiveStatusColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(product.statusName!),
                    color: product.effectiveStatusColor,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.statusName!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: product.effectiveStatusColor,
                          ),
                        ),
                        Text(
                          _getStatusDescription(product.statusName!),
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
            
            const SizedBox(height: 16),
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

            // Información adicional según estado

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
                          'Esperando recepciÃ³n de productos devueltos',
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
            const Divider(height: 24, thickness: 3,),
            _buildProductStatusActions(product, user),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStatusActions(
  BatchProductModel product,
  UserModel? user,
) {
  // Si no tiene permisos, no mostramos nada
  final memberService = Provider.of<OrganizationMemberService>(
    context,
    listen: false,
  );

  return FutureBuilder<bool>(
    future: memberService.can('batch_products', 'changeStatus'),
    builder: (context, permSnapshot) {
      final canChangeStatus = permSnapshot.data ?? false;

      if (!canChangeStatus) return const SizedBox.shrink();

      // Cargar transiciones disponibles desde el estado actual
      final currentStatusId = product.statusId ?? 'pending';

      return FutureBuilder<List<StatusTransitionModel>>(
        future: _loadAvailableTransitions(currentStatusId),
        builder: (context, transSnapshot) {
          if (transSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (transSnapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar transiciones: ${transSnapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final transitions = transSnapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Acciones Disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (transitions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No hay transiciones disponibles desde este estado',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...transitions.map((transition) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildTransitionButton(
                      transition: transition,
                      product: product,
                    ),
                  );
                }).toList(),
            ],
          );
        },
      );
    },
  );
}

/// Construir botón para una transición específica
Widget _buildTransitionButton({
  required StatusTransitionModel transition,
  required BatchProductModel product,
}) {
  // Determinar color e icono según el estado destino
  Color buttonColor = _getColorForStatus(transition.toStatusId);
  IconData buttonIcon = _getIconForStatus(transition.toStatusId);

  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => _handleTransitionAction(transition, product),
      icon: Icon(buttonIcon, color: buttonColor),
      label: Row(
        children: [
          Expanded(
            child: Text(
              'Cambiar a: ${transition.toStatusName}',
              style: TextStyle(
                color: buttonColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Badge con tipo de validación
          if (transition.validationType != ValidationType.simpleApproval)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: buttonColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getValidationIcon(transition.validationType),
                    size: 12,
                    color: buttonColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getValidationLabel(transition.validationType),
                    style: TextStyle(
                      fontSize: 10,
                      color: buttonColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: buttonColor, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
  );
}

/// Manejar acción de transición usando ValidationDialogManager
Future<void> _handleTransitionAction(
  StatusTransitionModel transition,
  BatchProductModel product,
) async {
  final authService = Provider.of<AuthService>(context, listen: false);
  final user = authService.currentUserData;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error: Usuario no autenticado'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (product.currentPhase != 'studio') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error: el producto debe estar en Studio antes de cambiar de estado'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Mostrar el diálogo de validación apropiado
  final validationData = await ValidationDialogManager.showValidationDialog(
    context: context,
    transition: transition,
    product: product,
  );

  // Si el usuario canceló, salir
  if (validationData == null) {
    return;
  }

  // Ejecutar el cambio de estado con los datos validados
  await _executeStatusChangeWithValidation(
    product: product,
    toStatusId: transition.toStatusId,
    validationData: validationData.toMap(),
  );
}

/// Helpers para colores e iconos según estado
Color _getColorForStatus(String statusId) {
  switch (statusId) {
    case 'ok':
      return Colors.green;
    case 'cao':
      return Colors.red;
    case 'control':
      return Colors.orange;
    case 'hold':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

IconData _getIconForStatus(String statusId) {
  switch (statusId) {
    case 'ok':
      return Icons.check_circle;
    case 'cao':
      return Icons.cancel;
    case 'control':
      return Icons.verified;
    case 'hold':
      return Icons.pause_circle;
    default:
      return Icons.circle;
  }
}

IconData _getValidationIcon(ValidationType type) {
  switch (type) {
    case ValidationType.textRequired:
    case ValidationType.textOptional:
      return Icons.edit;
    case ValidationType.quantityAndText:
      return Icons.format_list_numbered;
    case ValidationType.checklist:
      return Icons.checklist;
    case ValidationType.photoRequired:
      return Icons.camera_alt;
    case ValidationType.multiApproval:
      return Icons.people;
    default:
      return Icons.check_circle;
  }
}

String _getValidationLabel(ValidationType type) {
  switch (type) {
    case ValidationType.textRequired:
      return 'Texto';
    case ValidationType.quantityAndText:
      return 'Cantidad';
    case ValidationType.checklist:
      return 'Checklist';
    case ValidationType.photoRequired:
      return 'Foto';
    case ValidationType.multiApproval:
      return 'Aprobación';
    default:
      return '';
  }
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
            alignment: Alignment
                .centerLeft, // Alinea contenido a la izquierda como una lista
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
        child: StatefulBuilder(  // ✅ CAMBIADO: Usar StatefulBuilder
          builder: (context, setStateLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con botón de expandir/contraer
                InkWell(
                  onTap: () {
                    setStateLocal(() {  // ✅ CAMBIADO: usar setStateLocal en vez de setState
                      _isPhasesExpanded = !_isPhasesExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Fases de Producción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _isPhasesExpanded 
                            ? Icons.expand_less 
                            : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
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

                    // Si está comprimido, mostrar solo la fase actual
                    if (!_isPhasesExpanded) {
                      final currentPhase = allPhases.firstWhere(
                        (phase) => phase.id == product.currentPhase,
                        orElse: () => allPhases.first,
                      );
                      final phaseProgress = product.phaseProgress[currentPhase.id];
                      final currentIndex = allPhases.indexOf(currentPhase);

                      return _buildPhaseItem(
                        currentPhase,
                        phaseProgress,
                        true, // Es la fase actual
                        user,
                        product,
                        allPhases,
                        currentIndex,
                      );
                    }

                    // Si está expandido, mostrar todas las fases
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allPhases.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
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
            );
          },
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

// TODO: cambiar toda la logica de cambio de estados por el nuevo sistema con validaciones y estados en la organizacion.

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

              try {
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(widget.organizationId)
                    .collection('production_batches')
                    .doc(widget.batchId)
                    .collection('batch_products')
                    .doc(widget.productId)
                    .update({
                  'currentPhase': previousPhase.id,
                  'currentPhaseName': previousPhase.name,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'phaseProgress.${product.currentPhase}.status': 'pending',
                  'phaseProgress.${previousPhase.id}.status': 'in_progress',
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Retrocedido a: ${previousPhase.name}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
            const Row(
              children: [
                Icon(Icons.palette),
                SizedBox(width: 8),
                Text(
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
              _buildInfoRow(
                  Icons.notes, 'Detalles especiales', product.specialDetails!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isBold = false}) {
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
              Navigator.pop(context); // Cerrar diálogo

              try {
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(widget.organizationId)
                    .collection('production_batches')
                    .doc(widget.batchId)
                    .collection('batch_products')
                    .doc(widget.productId)
                    .update({
                  'currentPhase': nextPhase.id,
                  'currentPhaseName': nextPhase.name,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'phaseProgress.${product.currentPhase}.status': 'completed',
                  'phaseProgress.${product.currentPhase}.completedAt':
                      FieldValue.serverTimestamp(),
                  'phaseProgress.${product.currentPhase}.completedBy': user.uid,
                  'phaseProgress.${product.currentPhase}.completedByName':
                      user.name,
                  'phaseProgress.${nextPhase.id}.status': 'in_progress',
                  'phaseProgress.${nextPhase.id}.startedAt':
                      FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Avanzado a: ${nextPhase.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Avanzar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, BatchProductModel product) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null || _currentRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo verificar los permisos del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    switch (action) {
      case 'approve_directly':
        // HOLD → OK
        print("approve directly llamada -------------------");
        await _handleStatusChange(
          product: product,
          fromStatusId: 'hold',
          toStatusId: 'ok',
          actionName: 'Aprobar Producto',
          confirmMessage:
              '¿Confirmar que el producto está correcto?\n\nPasará directamente a OK.',
        );
        break;

      case 'reject_directly':
        print("reject_directly llamada -------------------");
        // HOLD → CAO
        await _handleStatusChange(
          product: product,
          fromStatusId: 'hold',
          toStatusId: 'cao',
          actionName: 'Rechazar Producto',
          confirmMessage: 'Indica la cantidad defectuosa y descripción',
          requiresValidation: true,
        );
        break;

      case 'move_to_control':
        print("move_to_control llamada -------------------");
        // CAO → CONTROL
        await _handleStatusChange(
          product: product,
          fromStatusId: 'cao',
          toStatusId: 'control',
          actionName: 'Mover a Control',
          confirmMessage:
              '¿Confirmar que se han recibido los productos devueltos?\n\nSe moverán a Control para evaluación.',
        );
        break;

      case 'classify_returns':
        print("classify_returns llamada -------------------");
        // CONTROL → OK (con posible clasificación)
        await _handleStatusChange(
          product: product,
          fromStatusId: 'control',
          toStatusId: 'ok',
          actionName: 'Clasificar Devoluciones',
          confirmMessage: 'Clasifica los productos devueltos',
          requiresValidation: false,
        );
        break;

      case 'approve':
        print("approve llamada -------------------");
        // PENDING → OK
        await _handleStatusChange(
          product: product,
          fromStatusId: product.statusId ?? 'pending',
          toStatusId: 'ok',
          actionName: 'Aprobar Producto',
          confirmMessage: '¿Aprobar este producto?\n\nEl estado cambiará a OK.',
        );
        break;

      case 'reject':
        print("reject llamada -------------------");
        // ANY → CAO o similar (según configuración)
        await _handleStatusChange(
          product: product,
          fromStatusId: product.statusId ?? 'pending',
          toStatusId: 'cao',
          actionName: 'Rechazar Producto',
          confirmMessage: 'Indica la razón del rechazo',
          requiresValidation: true,
        );
        break;

      case 'delete':
        print("delete llamada -------------------");
        _showDeleteConfirmation(product);
        break;
    }
  }

  Future<void> _handleStatusChange({
  required BatchProductModel product,
  required String fromStatusId,
  required String toStatusId,
  required String actionName,
  required String confirmMessage,
  bool requiresValidation = false,
}) async {
  final transitionService = Provider.of<StatusTransitionService>(
    context,
    listen: false,
  );

  // Obtener la transición configurada
  final transition = await transitionService.getTransitionBetweenStatuses(
    organizationId: widget.organizationId,
    fromStatusId: fromStatusId,
    toStatusId: toStatusId,
  );

  if (transition == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hay transición configurada entre estos estados'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Usar el nuevo método unificado
  await _handleTransitionAction(transition, product);
}

  Future<void> _showValidationDialog({
    required BatchProductModel product,
    required String fromStatusId,
    required String toStatusId,
    required String actionName,
    required Map<String, dynamic> validationResult,
  }) async {
    final validationType = validationResult['validationType'];
    final validationConfig = validationResult['validationConfig'];

    final quantityController = TextEditingController();
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionName),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Campo de cantidad si es requerido
                if (validationType == 'quantity_and_text' ||
                    validationType == 'quantity_required') ...[
                  TextFormField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: validationConfig['quantityLabel'] ??
                          'Cantidad Defectuosa',
                      hintText:
                          validationConfig['quantityPlaceholder'] ?? 'Ej: 3',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty < 1) {
                        return 'Cantidad inválida';
                      }
                      final min = validationConfig['quantityMin'] ?? 1;
                      if (qty < min) {
                        return 'Mínimo $min unidades';
                      }
                      if (qty > product.quantity) {
                        return 'Máximo ${product.quantity} unidades';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Campo de texto si es requerido
                if (validationType == 'quantity_and_text' ||
                    validationType == 'text_required') ...[
                  TextFormField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: validationConfig['textLabel'] ?? 'Descripción',
                      hintText: validationConfig['textPlaceholder'] ??
                          'Describe el problema',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final minLength = validationConfig['textMinLength'] ?? 10;
                      if (value.length < minLength) {
                        return 'Mínimo $minLength caracteres';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final validationData = <String, dynamic>{};
                if (quantityController.text.isNotEmpty) {
                  validationData['quantity'] =
                      int.parse(quantityController.text);
                }
                if (textController.text.isNotEmpty) {
                  validationData['text'] = textController.text;
                }
                Navigator.pop(context, validationData);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Ejecutar cambio de estado con datos de validación
      await _executeStatusChangeWithValidation(
        product: product,
        toStatusId: toStatusId,
        validationData: result,
      );
    }
  }

  Future<void> _executeStatusChangeWithValidation({
    required BatchProductModel product,
    required String toStatusId,
    required Map<String, dynamic> validationData,
  }) async {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null || _currentRole == null || _currentMember == null) {
      return;
    }

    try {
      final success = await batchService.changeProductStatus(
        organizationId: widget.organizationId,
        batchId: widget.batchId,
        productId: widget.productId,
        toStatusId: toStatusId,
        userId: user.uid,
        userName: user.name,
        validationData: validationData,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado cambiado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(batchService.error ?? 'Error al cambiar estado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              Navigator.pop(context); // Cerrar diálogo

              try {
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(widget.organizationId)
                    .collection('production_batches')
                    .doc(widget.batchId)
                    .collection('batch_products')
                    .doc(widget.productId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context); // Volver a la pantalla anterior
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

// Helper para mostrar el chat condicionalmente
  Widget _buildChatSection(BatchProductModel product, UserModel? user) {
    return FutureBuilder<bool>(
      future: Provider.of<OrganizationMemberService>(context, listen: false)
          .can('chat', 'view'),
      builder: (context, snapshot) {
        final canViewChat = snapshot.data ?? false;
        if (!canViewChat) return const SizedBox.shrink();

        return _buildChatPreviewCard(product, user);
      },
    );
  }

/// Vista previa de chat (solo lectura, últimos 10 mensajes)
  Widget _buildChatPreviewCard(BatchProductModel product, UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    return InkWell(  // ✅ CAMBIADO: Envolver Card en InkWell
      onTap: () => _openChat(product),  // ✅ AÑADIDO: Al hacer tap abre el chat
      child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.chat_bubble_outline),
                SizedBox(width: 8),
                Text(
                  'Chat del Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vista rápida de los últimos mensajes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 24),

            // Stream de los últimos 10 mensajes
            StreamBuilder(
              stream: _messageService.getMessages(
                organizationId: widget.organizationId,
                entityType: 'batch_product',
                entityId: product.id,
                parentId: product.batchId,
                limit: 10,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error al cargar mensajes: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay mensajes aún',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Mostrar los mensajes (read-only)
                return Column(
                  children: [
                    // Lista de mensajes (sin scroll, máximo 10)
                    ...messages.reversed.map((message) {
                      final isSystemMessage = message.isSystemGenerated;
                      final isCurrentUser = message.authorId == user.uid;

                      // Mensaje del sistema (centrado)
                      if (isSystemMessage) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                // Header del mensaje
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sistema',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatMessageTime(message.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Contenido del mensaje
                                Text(
                                  message.content,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Mensaje de usuario (derecha) o de otro (izquierda)
                      return Align(
                        alignment: isCurrentUser 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: isCurrentUser ? 40 : 0,
                            right: isCurrentUser ? 0 : 40,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentUser 
                                  ? Colors.green[50] 
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrentUser 
                                    ? Colors.green[200]! 
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header del mensaje
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isCurrentUser
                                          ? '${message.authorName ?? 'Usuario'} (Tú)'
                                          : (message.authorName ?? 'Usuario'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatMessageTime(message.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Contenido del mensaje
                                Text(
                                  message.content,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 12),

                    // Botón "Ver chat completo"
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openChat(product),
                        icon: const Icon(Icons.chat),
                        label: const Text('Ver chat completo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
    );
  }

  /// Formatear tiempo del mensaje
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Abrir pantalla de chat
  void _openChat(BatchProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          organizationId: widget.organizationId,
          entityType: 'batch_product',
          entityId: product.id,
          parentId: product.batchId,
          entityName: '${product.productName} - ${product.productReference}',
          showInternalMessages:
              true, // Mostrar mensajes internos para el equipo
        ),
      ),
    );
  }
}