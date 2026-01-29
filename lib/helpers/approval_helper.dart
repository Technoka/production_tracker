import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pending_object_model.dart';
import '../models/notification_model.dart';
import '../models/batch_product_model.dart';
import '../models/phase_model.dart';
import '../services/pending_object_service.dart';
import '../services/notification_service.dart';
import '../services/organization_member_service.dart';
import '../services/production_batch_service.dart';
import '../services/project_service.dart';
import '../services/product_catalog_service.dart';
import '../services/phase_service.dart';

class ApprovalHelper {
  static Future<String?> createApprovalRequest({
    required String organizationId,
    required PendingObjectType objectType,
    required String collectionRoute,
    required Map<String, dynamic> modelData,
    required String createdBy,
    required String createdByName,
    required String? clientId,
    required PendingObjectService pendingService,
    required NotificationService notificationService,
    required OrganizationMemberService organizationMemberService,
    String? parentBatchId,
  }) async {
    // 1. Crear pending object
    final pendingId = await pendingService.createPendingObject(
      organizationId: organizationId,
      objectType: objectType,
      collectionRoute: collectionRoute,
      modelData: modelData,
      createdBy: createdBy,
      createdByName: createdByName,
      clientId: clientId,
      parentBatchId: parentBatchId,
    );

    if (pendingId == null) return null;

    // 2. Buscar usuarios con permiso approveClientRequests
    final approvers = await organizationMemberService.getUsersWithPermission(
      organizationId,
      'organization',
      'approveClientRequests',
    );

    if (approvers.isEmpty) {
      // AUTO-APROBAR: No hay aprobadores
      await pendingService.approvePendingObject(
        organizationId,
        pendingId,
        'system',
        'Sistema (Auto-aprobado)',
      );

      // Notificar al cliente que fue auto-aprobado
      final objectName = modelData['name'] as String? ?? 'Sin nombre';
      await notificationService.createNotification(
        organizationId: organizationId,
        type: NotificationType.approvalResponse,
        destinationUserIds: [createdBy],
        title: 'Solicitud aprobada automáticamente ✓',
        message: 'Tu ${objectType.label} "$objectName" fue aprobado automáticamente',
        metadata: {
          'approved': true,
          'approvedBy': 'system',
          'approvedByName': 'Sistema',
          'objectType': objectType.value,
          'objectName': objectName,
          'autoApproved': true,
          'pendingObjectId': pendingId,
        },
        priority: NotificationPriority.medium,
      );

      return pendingId; // Retornar para que el flujo continúe
    }

    // 3. Crear notificación para aprobadores
    final objectName = modelData['name'] as String? ?? 'Sin nombre';
    final notifId = await notificationService.createNotification(
      organizationId: organizationId,
      type: NotificationType.approvalRequest,
      destinationUserIds: approvers.map((u) => u.uid).toList(),
      title: 'Solicitud de aprobación',
      message: '$createdByName quiere crear un ${objectType.label}: "$objectName"',
      metadata: {
        'requestType': '${objectType.value}_create',
        'pendingObjectId': pendingId,
        'requestedBy': createdBy,
        'requestedByName': createdByName,
        'clientId': clientId,
        'objectName': objectName,
      },
      actions: [
        const NotificationAction(type: 'approve', label: 'Aprobar'),
        const NotificationAction(type: 'reject', label: 'Rechazar'),
      ],
      priority: NotificationPriority.high,
    );

    if (notifId != null) {
      // 4. Vincular notificación a pending object
      await pendingService.linkNotification(
        organizationId,
        pendingId,
        notifId,
      );
    }

    return pendingId;
  }

  /// Aprobar solicitud y crear objeto real
  static Future<bool> approveRequest({
    required String organizationId,
    required String pendingObjectId,
    required String approvedBy,
    required String approvedByName,
    required String notificationId,
    required PendingObjectService pendingService,
    required NotificationService notificationService,
    // Servicios para crear objetos reales
    ProductionBatchService? batchService,
    ProjectService? projectService,
    ProductCatalogService? catalogService,
    PhaseService? phaseService,
  }) async {
    // 1. Obtener pending object
    final pendingObject = await pendingService.getPendingObject(
      organizationId,
      pendingObjectId,
    );

    if (pendingObject == null) return false;

    // 2. Aprobar pending object
    final success = await pendingService.approvePendingObject(
      organizationId,
      pendingObjectId,
      approvedBy,
      approvedByName,
    );

    if (!success) return false;

    // 3. CREAR OBJETO REAL
    String? createdObjectId;
    try {
      createdObjectId = await _createApprovedObject(
        organizationId: organizationId,
        pendingObject: pendingObject,
        batchService: batchService,
        projectService: projectService,
        catalogService: catalogService,
        phaseService: phaseService,
      );
    } catch (e) {
      debugPrint('Error creating approved object: $e');
      // Continuar con notificaciones aunque falle la creación
    }

    // 4. Resolver notificación de aprobadores
    await notificationService.resolveNotification(
      organizationId,
      notificationId,
    );

    // 5. Crear notificación de respuesta para el solicitante
    await notificationService.createNotification(
      organizationId: organizationId,
      type: NotificationType.approvalResponse,
      destinationUserIds: [pendingObject.createdBy],
      title: 'Solicitud aprobada ✓',
      message: 'Tu ${pendingObject.objectType.label} "${pendingObject.objectName}" ha sido aprobado',
      metadata: {
        'approved': true,
        'approvedBy': approvedBy,
        'approvedByName': approvedByName,
        'objectType': pendingObject.objectType.value,
        'objectName': pendingObject.objectName,
        'originalNotificationId': notificationId,
        'createdObjectId': createdObjectId,
      },
      priority: NotificationPriority.medium,
    );

    return true;
  }

  /// Rechazar solicitud
  static Future<bool> rejectRequest({
    required String organizationId,
    required String pendingObjectId,
    required String rejectedBy,
    required String rejectedByName,
    required String rejectionReason,
    required String notificationId,
    required PendingObjectService pendingService,
    required NotificationService notificationService,
  }) async {
    // 1. Obtener pending object
    final pendingObject = await pendingService.getPendingObject(
      organizationId,
      pendingObjectId,
    );

    if (pendingObject == null) return false;

    // 2. Rechazar pending object
    final success = await pendingService.rejectPendingObject(
      organizationId,
      pendingObjectId,
      rejectedBy,
      rejectedByName,
      rejectionReason,
    );

    if (!success) return false;

    // 3. Resolver notificación de aprobadores
    await notificationService.resolveNotification(
      organizationId,
      notificationId,
    );

    // 4. Crear notificación de respuesta para el solicitante
    await notificationService.createNotification(
      organizationId: organizationId,
      type: NotificationType.approvalResponse,
      destinationUserIds: [pendingObject.createdBy],
      title: 'Solicitud rechazada',
      message: 'Tu ${pendingObject.objectType.label} "${pendingObject.objectName}" ha sido rechazado',
      metadata: {
        'approved': false,
        'rejectedBy': rejectedBy,
        'rejectedByName': rejectedByName,
        'rejectionReason': rejectionReason,
        'objectType': pendingObject.objectType.value,
        'objectName': pendingObject.objectName,
        'originalNotificationId': notificationId,
      },
      priority: NotificationPriority.medium,
    );

    return true;
  }

  /// Método unificado para crear objetos con o sin aprobación
  static Future<String?> createOrRequestApproval({
    required String organizationId,
    required PendingObjectType objectType,
    required String collectionRoute,
    required Map<String, dynamic> modelData,
    required String createdBy,
    required String createdByName,
    required bool requiresApproval,
    required bool userIsClient,
    required PendingObjectService pendingService,
    required NotificationService notificationService,
    required OrganizationMemberService organizationMemberService,
    String? clientId,
    String? parentBatchId,
  }) async {
    // Si requiere aprobación Y el usuario es cliente
    if (requiresApproval && userIsClient) {
      return await createApprovalRequest(
        organizationId: organizationId,
        objectType: objectType,
        collectionRoute: collectionRoute,
        modelData: modelData,
        createdBy: createdBy,
        createdByName: createdByName,
        clientId: clientId,
        pendingService: pendingService,
        notificationService: notificationService,
        organizationMemberService: organizationMemberService,
        parentBatchId: parentBatchId,
      );
    }
    
    // Si no requiere aprobación, retornar null
    // (el flujo normal creará el objeto directamente)
    return null;
  }

  // ==================== MÉTODO PRIVADO ====================

  /// Crear objeto real desde pending object aprobado
  static Future<String?> _createApprovedObject({
    required String organizationId,
    required PendingObjectModel pendingObject,
    ProductionBatchService? batchService,
    ProjectService? projectService,
    ProductCatalogService? catalogService,
    PhaseService? phaseService,
  }) async {
    final data = pendingObject.modelData;

    switch (pendingObject.objectType) {
      // ============ BATCH CON PRODUCTOS ============
      case PendingObjectType.batch:
        if (batchService == null) {
          throw Exception('BatchService required for creating batch');
        }

        // 1. Crear el batch
        final batchId = await batchService.createBatch(
          organizationId: organizationId,
          userId: data['createdBy'] as String,
          projectId: data['projectId'] as String,
          projectName: data['projectName'] as String,
          clientId: data['clientId'] as String,
          clientName: data['clientName'] as String,
          createdBy: data['createdBy'] as String,
          batchPrefix: data['batchPrefix'] as String,
          batchNumber: data['batchNumber'] as String,
          assignedMembers: List<String>.from(data['assignedMembers'] ?? []),
          notes: data['notes'] as String?,
        );

        if (batchId == null) {
          throw Exception('Failed to create batch: ${batchService.error}');
        }

        // 2. Crear productos si existen
        final productsData = data['products'] as List?;
        if (productsData != null && productsData.isNotEmpty) {
          if (phaseService == null) {
            debugPrint('Warning: PhaseService not provided, skipping products');
            return batchId;
          }

          // Obtener fases
          final phases = await phaseService.getOrganizationPhases(organizationId);
          if (phases.isEmpty) {
            debugPrint('Warning: No phases configured, skipping products');
            return batchId;
          }

          phases.sort((a, b) => a.order.compareTo(b.order));

          // Convertir productos de Map a BatchProductModel
          final List<BatchProductModel> batchProducts = [];

          for (int i = 0; i < productsData.length; i++) {
            final prodData = productsData[i] as Map<String, dynamic>;

            // Reconstruir phaseProgress
            final Map<String, PhaseProgressData> phaseProgress = {};
            final phaseProgressData = prodData['phaseProgress'] as Map<String, dynamic>?;
            
            if (phaseProgressData != null) {
              phaseProgressData.forEach((phaseId, progressData) {
                final progressMap = progressData as Map<String, dynamic>;
                phaseProgress[phaseId] = PhaseProgressData(
                  status: progressMap['status'] as String,
                  startedAt: progressMap['startedAt'] != null
                      ? (progressMap['startedAt'] as Timestamp).toDate()
                      : null,
                  completedAt: progressMap['completedAt'] != null
                      ? (progressMap['completedAt'] as Timestamp).toDate()
                      : null,
                );
              });
            }

            final batchProduct = BatchProductModel(
              id: '',
              batchId: batchId,
              productCatalogId: prodData['productCatalogId'] as String,
              productName: prodData['productName'] as String,
              productReference: prodData['productReference'] as String,
              family: prodData['family'] as String?,
              description: prodData['description'] as String?,
              quantity: prodData['quantity'] as int,
              currentPhase: prodData['currentPhase'] as String,
              currentPhaseName: prodData['currentPhaseName'] as String,
              phaseProgress: phaseProgress,
              productNumber: prodData['productNumber'] as int,
              productCode: '',
              unitPrice: prodData['unitPrice'] as double?,
              totalPrice: prodData['totalPrice'] as double?,
              expectedDeliveryDate: prodData['expectedDeliveryDate'] != null
                  ? (prodData['expectedDeliveryDate'] as Timestamp).toDate()
                  : null,
              urgencyLevel: prodData['urgencyLevel'] as String? ?? 'medium',
              productNotes: prodData['productNotes'] as String?,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            batchProducts.add(batchProduct);
          }

          // Añadir productos al batch
          final success = await batchService.addProductsToBatch(
            organizationId: organizationId,
            batchId: batchId,
            products: batchProducts,
            userId: data['createdBy'] as String,
            userName: pendingObject.createdByName,
          );

          if (!success) {
            debugPrint('Warning: Failed to add products: ${batchService.error}');
          }
        }

        return batchId;

      // ============ PROJECT ============
      case PendingObjectType.project:
        if (projectService == null) {
          throw Exception('ProjectService required for creating project');
        }

        final projectId = await projectService.createProject(
          name: data['name'] as String,
          description: data['description'] as String,
          clientId: data['clientId'] as String,
          organizationId: organizationId,
          startDate: data['startDate'] != null
              ? (data['startDate'] as Timestamp).toDate()
              : DateTime.now(),
          estimatedEndDate: data['estimatedEndDate'] != null
              ? (data['estimatedEndDate'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(days: 30)),
          assignedMembers: List<String>.from(data['assignedMembers'] ?? []),
          createdBy: data['createdBy'] as String,
        );

        return projectId;

      // ============ PRODUCT CATALOG ============
      case PendingObjectType.productCatalog:
        if (catalogService == null) {
          throw Exception('CatalogService required for creating product');
        }

        final productId = await catalogService.createProduct(
          organizationId: organizationId,
          name: data['name'] as String,
          reference: data['reference'] as String,
          description: data['description'] as String,
          family: data['family'] as String?,
          clientId: data['clientId'] as String?,
          createdBy: data['createdBy'] as String,
          isPublic: data['isPublic'] as bool? ?? false,
          notes: data['notes'] as String?,
          projects: List<String>.from(data['projects'] ?? []),
        );

        return productId;

      default:
        throw Exception('Unsupported object type: ${pendingObject.objectType}');
    }
  }
}