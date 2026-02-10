import 'package:flutter/material.dart';
import 'package:gestion_produccion/providers/production_data_provider.dart';
import 'package:gestion_produccion/utils/ui_constants.dart';
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

import '../../services/status_transition_service.dart';
import '../../models/status_transition_model.dart';
import '../../models/role_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/validation_dialogs/validation_dialog_manager.dart';
import '../../models/validation_config_model.dart';
import '../../utils/filter_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/message_events_helper.dart';

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
  bool _isHistoryExpanded = false; // Historial comprimido por defecto

  final MessageService _messageService = MessageService();

  RoleModel? _currentRole; // ← NUEVO

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

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
      final transitions =
          await transitionService.getAvailableTransitionsFromStatus(
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
          .watchBatchProducts(widget.organizationId, widget.batchId, user!.uid),
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

        BatchProductModel? product;
        try {
          product = products.firstWhere((p) => p.id == widget.productId);
        } catch (e) {
          product = null;
        }

        // Si el producto no se encuentra (porque se acaba de eliminar),
        // cerrar la pantalla automáticamente
        if (product == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
                    onSelected: (value) => _handleAction(value, product!),
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
                      _buildProductInfoCard(product!, user),
                      const SizedBox(height: 16),
                      _buildProductStatusCard(product, user),
                      const SizedBox(height: 16),
                      _buildStatusHistoryCard(product),
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
                  padding:
                      const EdgeInsets.all(24), // Un poco más de margen en web
                  child: Column(
                    children: [
                      // FILA 1: Info y Estado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _buildProductInfoCard(product!, user)),
                          const SizedBox(width: 24),
                          Expanded(
                              child: _buildProductStatusCard(product, user)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // FILA 2: Fases y Chat
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildStatusHistoryCard(product)),
                          const SizedBox(width: 24),
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
    // Obtener el icono desde statusIcon si existe, sino usar el statusId

    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    final statusIconValue = dataProvider.getStatusById(product.statusId!)!.icon;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  UIConstants.getIcon(statusIconValue),
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
            if (product.urgencyLevel == UrgencyLevel.urgent.value) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: product.urgencyColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  product.urgencyDisplayName,
                  style: TextStyle(
                    color: product.urgencyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const Divider(height: 24),

            // Estado actual
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: product.effectiveStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: product.effectiveStatusColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    UIConstants.getIcon(statusIconValue),
                    color: product.effectiveStatusColor,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.effectiveStatusName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: product.effectiveStatusColor,
                          ),
                        ),
                        if (product.statusName != null)
                          Text(
                            product.statusName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          )
                        else
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
            const Divider(
              height: 24,
              thickness: 3,
            ),
            _buildProductStatusActions(product, user),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryCard(BatchProductModel product) {
    final hasHistory = product.statusHistory.isNotEmpty;

    return Card(
      // 1. Envolver en StatefulBuilder para aislar el renderizado
      child: StatefulBuilder(
        builder: (context, setStateLocal) {
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Historial de Cambios de Estado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(
                  _isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () {
                  // 2. Usar setStateLocal en lugar de setState global
                  setStateLocal(() {
                    _isHistoryExpanded = !_isHistoryExpanded;
                  });
                },
              ),
              if (_isHistoryExpanded) ...[
                const Divider(height: 1),
                if (!hasHistory)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No hay historial de cambios',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: product.statusHistory.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final entry = product.statusHistory[index];
                      return _buildHistoryEntry(entry);
                    },
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryEntry(StatusHistoryEntry entry) {
    // Parsear color desde hex string
    Color statusColor;
    try {
      statusColor = Color(
        int.parse(entry.statusColor.replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      statusColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Estado y fecha
        Row(
          children: [
            // Icono del estado
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                UIConstants.getIcon(entry.statusIcon),
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del estado
                  Text(
                    entry.statusName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Fecha y usuario
                  Text(
                    '${_formatDateTime(entry.timestamp)} • ${entry.userName}',
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

        // Notas si existen
        if (entry.notes != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Datos de validación si existen y tienen algo más que solo el timestamp
        if (entry.validationData != null &&
            entry.validationData!.keys.any((k) => k != 'timestamp')) ...[
          const SizedBox(height: 8),
          _buildValidationDataSection(entry.validationData!),
        ],
      ],
    );
  }

  Widget _buildValidationDataSection(Map<String, dynamic> validationData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                'Datos de validación',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cantidad
          if (validationData['quantity'] != null)
            _buildValidationDataRow(
              'Cantidad',
              '${validationData['quantity']}',
            ),

          // Texto
          if (validationData['text'] != null)
            _buildValidationDataRow(
              'Descripción',
              validationData['text'] as String,
            ),

          // Checklist
          if (validationData['checklistAnswers'] != null)
            ...() {
              // Aquí SÍ puedes declarar variables porque es una función
              final answers =
                  validationData['checklistAnswers'] as Map<String, dynamic>;
              final completed = answers.values.where((v) => v == true).length;

              // Retornas la lista de widgets
              return [
                _buildValidationDataRow(
                  'Checklist',
                  '$completed/${answers.length} completados',
                ),
              ];
            }(), // <--- Nota los paréntesis aquí para ejecutar la función

          // Fotos
          if (validationData['photoUrls'] != null)
            ...() {
              final photos = validationData['photoUrls'] as List;
              if (photos.isNotEmpty) {
                return [
                  _buildValidationDataRow(
                    'Fotos',
                    '${photos.length} adjuntas',
                  ),
                ];
              }
              return <Widget>[];
            }(),

          // Aprobadores
          if (validationData['approvedBy'] != null)
            ...() {
              final approvers = validationData['approvedBy'] as List;
              if (approvers.isNotEmpty) {
                return [
                  _buildValidationDataRow(
                    'Aprobado por',
                    '${approvers.length} usuarios',
                  ),
                ];
              }
              return <Widget>[];
            }(),

          // Custom Parameters
          if (validationData['customParametersData'] != null)
            ...() {
              final params = validationData['customParametersData']
                  as Map<String, dynamic>;
              return params.entries.map((entry) {
                return _buildValidationDataRow(
                  entry.key,
                  entry.value.toString(),
                );
              }).toList();
            }(),

          // Modo de texto
          if (validationData['textMode'] != null)
            _buildValidationDataRow(
              'Modo',
              validationData['textMode'] == 'single'
                  ? 'Descripción general'
                  : 'Descripciones individuales',
            ),

          // Defectos individuales
          if (validationData['individualDefects'] != null)
            ...() {
              final defects =
                  validationData['individualDefects'] as Map<String, dynamic>;
              return [
                const SizedBox(height: 4),
                Text(
                  'Descripciones individuales:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                // Aquí expandimos los widgets del mapa dentro de la lista que retornamos
                ...defects.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      '${int.parse(entry.key) + 1}. ${entry.value}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }),
              ];
            }(),
        ],
      ),
    );
  }

  Widget _buildValidationDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
    final phaseService = Provider.of<PhaseService>(context, listen: false);

    return FutureBuilder<bool>(
      future: memberService.can('batch_products', 'changeStatus'),
      builder: (context, permSnapshot) {
        final canChangeStatus = permSnapshot.data ?? false;

        if (!canChangeStatus) return const SizedBox.shrink();

        // Verificar si está en la última fase
        return FutureBuilder<List<ProductionPhase>>(
          future: phaseService.getActivePhases(widget.organizationId),
          builder: (context, phasesSnapshot) {
            if (phasesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (phasesSnapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar fases: ${phasesSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final phases = phasesSnapshot.data ?? [];

            // Encontrar la última fase (mayor order)
            ProductionPhase? lastPhase;
            if (phases.isNotEmpty) {
              lastPhase = phases.reduce((a, b) => a.order > b.order ? a : b);
            }

            // Verificar si el producto está en la última fase
            final isInLastPhase =
                lastPhase != null && product.currentPhase == lastPhase.id;

            if (!isInLastPhase) {
              // No está en la última fase, no mostrar acciones
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Las acciones de estado están disponibles solo cuando el producto llegue a la última fase de producción (${lastPhase?.name ?? "desconocida"})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Está en la última fase, cargar transiciones disponibles
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
      },
    );
  }

  /// Construir botón para una transición específica
  Widget _buildTransitionButton({
    required StatusTransitionModel transition,
    required BatchProductModel product,
  }) {
    final dataProvider =
        Provider.of<ProductionDataProvider>(context, listen: false);
    final status = dataProvider.getStatusById(transition.toStatusId)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleTransitionAction(transition, product),
        icon: Icon(UIConstants.getIcon(status.icon), color: status.colorValue),
        label: Row(
          children: [
            Expanded(
              child: Text(
                'Cambiar a: ${transition.toStatusName}',
                style: TextStyle(
                  color: status.colorValue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Badge con tipo de validación
            if (transition.validationType != ValidationType.simpleApproval)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status.colorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: status.colorValue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      transition.validationType.icon,
                      size: 12,
                      color: status.colorValue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getValidationLabel(transition.validationType),
                      style: TextStyle(
                        fontSize: 10,
                        color: status.colorValue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: status.colorValue, width: 2),
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
          content: Text(
              'Error: el producto debe estar en Studio antes de cambiar de estado'),
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

  Widget _buildPhasesCard(BatchProductModel product, UserModel? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          // ✅ CAMBIADO: Usar StatefulBuilder
          builder: (context, setStateLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con botón de expandir/contraer
                InkWell(
                  onTap: () {
                    setStateLocal(() {
                      // ✅ CAMBIADO: usar setStateLocal en vez de setState
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
                    if (phasesSnapshot.connectionState ==
                        ConnectionState.waiting) {
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
                      final phaseProgress =
                          product.phaseProgress[currentPhase.id];
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
    IconData icon = UIConstants.getIcon(phase.icon);

    if (isCompleted) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green;
    } else if (isInProgress || isCurrentPhase) {
      backgroundColor = Colors.blue[50]!;
      borderColor = Colors.blue;
    } else {
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.grey;
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
                      phase.description,
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
    return '${date.day}/${date.month}/${date.year}';
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
                Navigator.pop(context); // Cerrar diálogo

                // Generar evento de cambio de fase
                await MessageEventsHelper.onProductPhaseChanged(
                  organizationId: widget.organizationId,
                  batchId: product.batchId,
                  productId: product.id,
                  productName: product.productName,
                  productNumber: product.productNumber,
                  productCode: product.productCode,
                  oldPhaseName: product.currentPhaseName,
                  newPhaseName: nextPhase.name,
                  changedBy: user.name,
                  validationData:
                      null, // Sin validación en movimientos simples de Kanban
                );

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
      case 'delete':
        _showDeleteConfirmation(product);
        break;

      case 'edit':
        _showEditProductDialog(product);
        break;
    }
  }

  Future<void> _showEditProductDialog(BatchProductModel product) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final quantityController =
        TextEditingController(text: product.quantity.toString());
    final notesController =
        TextEditingController(text: product.productNotes ?? '');
    DateTime? selectedDate = product.expectedDeliveryDate;
    UrgencyLevel selectedUrgency =
        UrgencyLevel.fromString(product.urgencyLevel);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgencia
                  const Text(
                    'Urgencia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilterUtils.buildUrgencyBinaryToggle(
                    context: context,
                    urgencyLevel: selectedUrgency,
                    onChanged: (newLevel) {
                      setState(() {
                        selectedUrgency = UrgencyLevel.fromString(newLevel);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fecha
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha de entrega'),
                    subtitle: Text(
                      selectedDate != null
                          ? _formatDateTime(selectedDate!)
                          : 'Sin fecha',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cantidad
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Notas
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text);
                  if (quantity == null || quantity < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cantidad inválida'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'quantity': quantity,
                    'notes': notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    'dueDate': selectedDate,
                    'urgencyLevel': selectedUrgency.value,
                  });
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    // Si la urgencia ha cambiado
    final urgencyChanged = product.urgencyLevel != selectedUrgency.value;
    final oldUrgency = product.urgencyLevel;

    if (result != null) {
      // Actualizar producto en Firestore
      try {
        await FirebaseFirestore.instance
            .collection('organizations')
            .doc(widget.organizationId)
            .collection('production_batches')
            .doc(widget.batchId)
            .collection('batch_products')
            .doc(product.id)
            .update({
          'quantity': result['quantity'],
          'productNotes': result['notes'],
          'dueDate': result['dueDate'] != null
              ? Timestamp.fromDate(result['dueDate'])
              : null,
          'urgencyLevel': result['urgencyLevel'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        //Si la urgencia ha cambiado, generar mensaje de evento
        if (urgencyChanged) {
          // 🆕 Generar evento de cambio de urgencia
          await MessageEventsHelper.onProductUrgencyChanged(
            organizationId: widget.organizationId,
            batchId: product.batchId,
            productId: product.id,
            productName: product.productName,
            productNumber: product.productNumber,
            productCode: product.productCode,
            oldUrgency: oldUrgency,
            newUrgency: selectedUrgency.value,
            changedBy: authService.currentUserData!.name,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado'),
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
    final l10n = AppLocalizations.of(context)!;

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
          l10n: l10n);

      if (!mounted) return;

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

  void _showDeleteConfirmation(BatchProductModel product) {
    final batchService =
        Provider.of<ProductionBatchService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserData;

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
                await batchService.removeBatchProduct(
                    organizationId: widget.organizationId,
                    batchId: product.batchId,
                    productId: product.id,
                    userId: user!.uid);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Volver a la pantalla anterior
                }
              } catch (e) {
                if (context.mounted) {
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

    return InkWell(
      // ✅ CAMBIADO: Envolver Card en InkWell
      onTap: () => _openChat(product), // ✅ AÑADIDO: Al hacer tap abre el chat
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
