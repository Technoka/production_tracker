import '../models/message_model.dart';
import '../services/message_service.dart';

/// Helper para crear eventos automáticos del sistema en el chat
/// Se llama desde otros servicios cuando ocurren cambios importantes
class MessageEventsHelper {
  static final MessageService _messageService = MessageService();

  /// Evento: Lote creado
  static Future<void> onBatchCreated({
    required String organizationId,
    required String batchId,
    required String batchName,
    required String createdBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.batchCreated,
      eventData: {
        'batchName': batchName,
        'createdBy': createdBy,
      },
      isInternal: false, // Visible para todos incluido cliente
    );
  }

  /// Evento: Estado del lote cambiado
  static Future<void> onBatchStatusChanged({
    required String organizationId,
    required String batchId,
    required String oldStatus,
    required String newStatus,
    required String changedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.batchStatusChanged,
      eventData: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'changedBy': changedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Lote iniciado
  static Future<void> onBatchStarted({
    required String organizationId,
    required String batchId,
    required String startedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.batchStarted,
      eventData: {
        'startedBy': startedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Lote completado
  static Future<void> onBatchCompleted({
    required String organizationId,
    required String batchId,
    required String completedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.batchCompleted,
      eventData: {
        'completedBy': completedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Fase completada
  static Future<void> onPhaseCompleted({
    required String organizationId,
    required String batchId,
    required String productId,
    required String phaseName,
    required String completedBy,
    String? productName,
    int? productNumber,
    String? productCode,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.phaseCompleted,
      eventData: {
        'phaseName': phaseName,
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'completedBy': completedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Producto movido a nueva fase
  static Future<void> onProductMoved({
    required String organizationId,
    required String batchId,
    required String productId,
    required String productName,
    required String oldPhase,
    required String newPhase,
    required String movedBy,
    int? productNumber,
    String? productCode,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch_product',
      entityId: productId,
      parentId: batchId,
      eventType: SystemEventType.productMoved,
      eventData: {
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'oldPhase': oldPhase,
        'newPhase': newPhase,
        'movedBy': movedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Producto añadido al lote
  static Future<void> onProductAddedToBatch({
    required String organizationId,
    required String batchId,
    required String productId,
    required String productName,
    int? productNumber,
    String? productCode,
    required String addedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.productAdded,
      eventData: {
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'addedBy': addedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Producto eliminado del lote
  static Future<void> onProductRemoved({
    required String organizationId,
    required String batchId,
    required String productId,
    required String productName,
    int? productNumber,
    String? productCode,
    required String removedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.productRemoved,
      eventData: {
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'removedBy': removedBy,
      },
      isInternal: true, // Interno
    );
  }

  /// Evento: Estado del producto cambiado
  static Future<void> onProductStatusChanged({
    required String organizationId,
    required String batchId,
    required String productId,
    required String productName,
    int? productNumber,
    String? productCode,
    required String oldStatus,
    required String newStatus,
    required String changedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.productStatusChanged,
      eventData: {
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'changedBy': changedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Cambio de urgencia del producto
  static Future<void> onProductUrgencyChanged({
    required String organizationId,
    required String batchId,
    required String productId,
    required String productName,
    int? productNumber,
    String? productCode,
    required String oldUrgency,
    required String newUrgency,
    required String changedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch_product',
      entityId: productId,
      parentId: batchId,
      eventData: {
        'batchId': batchId,
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'oldUrgency': oldUrgency,
        'newUrgency': newUrgency,
        'changedBy': changedBy,
      },
      eventType: SystemEventType.productUrgencyChanged,
      isInternal: false, // Visible para cliente
    );
  }

  /// Evento: Cambio de fase del producto (mejorado con info de validación)
  static Future<void> onProductPhaseChanged({
    required String organizationId,
    required String batchId,
    required String productId,
    required String productName,
    int? productNumber,
    String? productCode,
    required String oldPhaseName,
    required String newPhaseName,
    required String changedBy,
    Map<String, dynamic>? validationData,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'product',
      entityId: productId,
      eventData: {
        'batchId': batchId,
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'oldPhaseName': oldPhaseName,
        'newPhaseName': newPhaseName,
        'changedBy': changedBy,
        'validationData': validationData,
      },
      eventType: SystemEventType.productPhaseChanged,
      isInternal: false,
    );
  }

  /// Evento: Cambio de estado del producto V2 (mejorado con info de validación)
  static Future<void> onProductStatusChangedV2({
    required String organizationId,
    required String batchId,
    required String productId,
    required String productName,
    int? productNumber,
    String? productCode,
    required String oldStatusName,
    required String newStatusName,
    required String changedBy,
    Map<String, dynamic>? validationData,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch_product',
      entityId: productId,
      parentId: batchId,
      eventData: {
        'batchId': batchId,
        'productId': productId,
        'productName': productName,
        'productNumber': productNumber,
        'productCode': productCode,
        'oldStatusName': oldStatusName,
        'newStatusName': newStatusName,
        'changedBy': changedBy,
        'validationData': validationData,
      },
      eventType: SystemEventType.productStatusChangedV2,
      isInternal: false,
    );
  }

  /// Evento: Retraso detectado
  static Future<void> onDelayDetected({
    required String organizationId,
    required String batchId,
    required String productId,
    String? productName,
    required int delayHours,
    String? phaseName,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.delayDetected,
      eventData: {
        'productId': productId,
        'productName': productName,
        'delayHours': delayHours,
        'phaseName': phaseName,
      },
      isInternal: true, // Solo interno
    );
  }

  /// Evento: Miembro asignado al lote
  static Future<void> onMemberAssigned({
    required String organizationId,
    required String batchId,
    required String memberId,
    required String memberName,
    required String assignedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.memberAssigned,
      eventData: {
        'memberId': memberId,
        'memberName': memberName,
        'assignedBy': assignedBy,
      },
      isInternal: true,
    );
  }

  /// Evento: Miembro removido del lote
  static Future<void> onMemberRemoved({
    required String organizationId,
    required String batchId,
    required String memberId,
    required String memberName,
    required String removedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.memberRemoved,
      eventData: {
        'memberId': memberId,
        'memberName': memberName,
        'removedBy': removedBy,
      },
      isInternal: true,
    );
  }

  /// Evento: Archivo subido
  static Future<void> onFileUploaded({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String fileName,
    required String uploadedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: entityType,
      entityId: entityId,
      eventType: SystemEventType.fileUploaded,
      eventData: {
        'fileName': fileName,
        'uploadedBy': uploadedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Nota añadida
  static Future<void> onNoteAdded({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String noteTitle,
    required String addedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: entityType,
      entityId: entityId,
      eventType: SystemEventType.noteAdded,
      eventData: {
        'noteTitle': noteTitle,
        'addedBy': addedBy,
      },
      isInternal: true,
    );
  }

  /// Evento: Factura emitida (FASE 10 - Futuro)
  static Future<void> onInvoiceIssued({
    required String organizationId,
    required String batchId,
    required String invoiceNumber,
    required double amount,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.invoiceIssued,
      eventData: {
        'invoiceNumber': invoiceNumber,
        'amount': amount,
      },
      isInternal: false,
    );
  }

  /// Evento: Pago recibido (FASE 11 - Futuro)
  static Future<void> onPaymentReceived({
    required String organizationId,
    required String batchId,
    required double amount,
    required String paymentMethod,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'batch',
      entityId: batchId,
      eventType: SystemEventType.paymentReceived,
      eventData: {
        'amount': amount,
        'paymentMethod': paymentMethod,
      },
      isInternal: false,
    );
  }

  // =================================================================
  // EVENTOS PARA PROYECTOS (PREPARACIÓN FASE FUTURA)
  // =================================================================

  /// Evento: Proyecto creado
  static Future<void> onProjectCreated({
    required String organizationId,
    required String projectId,
    required String projectName,
    required String createdBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'project',
      entityId: projectId,
      eventType: 'project_created',
      eventData: {
        'projectName': projectName,
        'createdBy': createdBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Estado del proyecto cambiado
  static Future<void> onProjectStatusChanged({
    required String organizationId,
    required String projectId,
    required String oldStatus,
    required String newStatus,
    required String changedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'project',
      entityId: projectId,
      eventType: 'project_status_changed',
      eventData: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'changedBy': changedBy,
      },
      isInternal: false,
    );
  }

  // =================================================================
  // EVENTOS PARA PRODUCTOS (PREPARACIÓN FASE FUTURA)
  // =================================================================

  /// Evento: Producto añadido al proyecto
  static Future<void> onProductAddedToProject({
    required String organizationId,
    required String projectId,
    required String productId,
    required String productName,
    required String addedBy,
  }) async {
    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'project',
      entityId: projectId,
      eventType: 'product_added',
      eventData: {
        'productId': productId,
        'productName': productName,
        'addedBy': addedBy,
      },
      isInternal: false,
    );
  }

  /// Evento: Fase del producto completada (dentro de proyecto)
  static Future<void> onProductPhaseCompleted({
    required String organizationId,
    required String projectId,
    required String productId,
    required String phaseName,
    required String completedBy,
  }) async {
    // Para producto: entityId debe ser "projectId/products/productId"
    final productEntityId = '$projectId/products/$productId';

    await _messageService.createSystemEvent(
      organizationId: organizationId,
      entityType: 'product',
      entityId: productEntityId,
      eventType: SystemEventType.phaseCompleted,
      eventData: {
        'phaseName': phaseName,
        'completedBy': completedBy,
      },
      isInternal: false,
    );
  }
}