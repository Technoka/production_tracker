import 'package:cloud_firestore/cloud_firestore.dart';

// Enum para estados del proyecto
enum ProjectStatus {
  preparation('preparation', 'En Preparación'),
  production('production', 'En Producción'),
  completed('completed', 'Completado'),
  delivered('delivered', 'Entregado');

  final String value;
  final String displayName;
  const ProjectStatus(this.value, this.displayName);

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.preparation,
    );
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String clientId; // ID del cliente
  final String organizationId; // Organización propietaria
  final String status;
  final DateTime startDate;
  final DateTime estimatedEndDate;
  final DateTime? actualEndDate;
  final List<String> assignedMembers; // UIDs de miembros asignados
  final String createdBy; // UID del usuario que lo creó
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // NUEVOS CAMPOS PARA SLA Y ALERTAS (FASE 5)
  final int? totalSlaHours;
  final DateTime? expectedCompletionDate;
  final bool isDelayed;
  final double delayHours;
  
  // NUEVOS CAMPOS PARA KANBAN (FASE 6)
  final int priority;                    // 1-5 (1=máxima)
  final String urgencyLevel;             // "low", "medium", "high", "critical"
  final List<String>? tags;
  
  // NUEVOS CAMPOS PARA FACTURACIÓN (FASE 10)
  final String invoiceStatus;            // "pending", "issued", "paid", "overdue"
  final String? invoiceId;               // ID de Holded
  final double totalAmount;
  final double paidAmount;
  final DateTime? paymentDueDate;
  
  // NUEVOS CAMPOS PARA MÉTRICAS (FASE 13)
  final DateTime? startedAt;
  final DateTime? actualCompletionDate;
  final double? leadTimeHours;
  
  final int batchCount; // Contador de lotes asociados

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.clientId,
    required this.organizationId,
    required this.status,
    required this.startDate,
    required this.estimatedEndDate,
    this.actualEndDate,
    required this.assignedMembers,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.totalSlaHours,
    this.expectedCompletionDate,
    this.isDelayed = false,
    this.delayHours = 0,
    this.priority = 3,
    this.urgencyLevel = 'medium',
    this.tags,
    this.invoiceStatus = 'pending',
    this.invoiceId,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.paymentDueDate,
    this.startedAt,
    this.actualCompletionDate,
    this.leadTimeHours,
    this.batchCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'clientId': clientId,
      'organizationId': organizationId,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'estimatedEndDate': Timestamp.fromDate(estimatedEndDate),
      'actualEndDate': actualEndDate != null ? Timestamp.fromDate(actualEndDate!) : null,
      'assignedMembers': assignedMembers,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'totalSlaHours': totalSlaHours,
      'expectedCompletionDate': expectedCompletionDate != null ? Timestamp.fromDate(expectedCompletionDate!) : null,
      'isDelayed': isDelayed,
      'delayHours': delayHours,
      'priority': priority,
      'urgencyLevel': urgencyLevel,
      'tags': tags,
      'invoiceStatus': invoiceStatus,
      'invoiceId': invoiceId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentDueDate': paymentDueDate != null ? Timestamp.fromDate(paymentDueDate!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'actualCompletionDate': actualCompletionDate != null ? Timestamp.fromDate(actualCompletionDate!) : null,
      'leadTimeHours': leadTimeHours,
      'batchCount': batchCount,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      clientId: map['clientId'] as String,
      organizationId: map['organizationId'] as String,
      status: map['status'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      estimatedEndDate: (map['estimatedEndDate'] as Timestamp).toDate(),
      actualEndDate: map['actualEndDate'] != null
          ? (map['actualEndDate'] as Timestamp).toDate()
          : null,
      assignedMembers: List<String>.from(map['assignedMembers'] as List),
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
            totalSlaHours: map['totalSlaHours'],
      expectedCompletionDate: map['expectedCompletionDate'] != null
          ? (map['expectedCompletionDate'] as Timestamp).toDate()
          : null,
      isDelayed: map['isDelayed'] ?? false,
      delayHours: (map['delayHours'] ?? 0).toDouble(),
      priority: map['priority'] ?? 3,
      urgencyLevel: map['urgencyLevel'] ?? 'medium',
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      invoiceStatus: map['invoiceStatus'] ?? 'pending',
      invoiceId: map['invoiceId'],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      paymentDueDate: map['paymentDueDate'] != null
          ? (map['paymentDueDate'] as Timestamp).toDate()
          : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      actualCompletionDate: map['actualCompletionDate'] != null
          ? (map['actualCompletionDate'] as Timestamp).toDate()
          : null,
      leadTimeHours: map['leadTimeHours'] != null 
          ? (map['leadTimeHours'] as num).toDouble()
          : null,
      batchCount: map['batchCount'] as int? ?? 0,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? clientId,
    String? organizationId,
    String? status,
    DateTime? startDate,
    DateTime? estimatedEndDate,
    DateTime? actualEndDate,
    List<String>? assignedMembers,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? totalSlaHours,
    DateTime? expectedCompletionDate,
    bool? isDelayed,
    double? delayHours,
    int? priority,
    String? urgencyLevel,
    List<String>? tags,
    String? invoiceStatus,
    String? invoiceId,
    double? totalAmount,
    double? paidAmount,
    DateTime? paymentDueDate,
    DateTime? startedAt,
    DateTime? actualCompletionDate,
    double? leadTimeHours
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      organizationId: organizationId ?? this.organizationId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      estimatedEndDate: estimatedEndDate ?? this.estimatedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      assignedMembers: assignedMembers ?? this.assignedMembers,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      totalSlaHours: totalSlaHours ?? this.totalSlaHours,
      expectedCompletionDate: expectedCompletionDate ?? this.expectedCompletionDate,
      isDelayed: isDelayed ?? this.isDelayed,
      delayHours: delayHours ?? this.delayHours,
      priority: priority ?? this.priority,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      tags: tags ?? this.tags,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      invoiceId: invoiceId ?? this.invoiceId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      startedAt: startedAt ?? this.startedAt,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      leadTimeHours: leadTimeHours ?? this.leadTimeHours,
    );
  }

  // Getters útiles
  ProjectStatus get statusEnum => ProjectStatus.fromString(status);
  String get statusDisplayName => statusEnum.displayName;

  bool get isAssigned => assignedMembers.isNotEmpty;
  int get memberCount => assignedMembers.length;

  bool isAssignedTo(String userId) => assignedMembers.contains(userId);

  // Verificar si está atrasado
  bool get isOverdue {
    if (actualEndDate != null) return false; // Ya está completado
    return DateTime.now().isAfter(estimatedEndDate);
  }

  // Días restantes (negativo si está atrasado)
  int get daysRemaining {
    if (actualEndDate != null) return 0;
    return estimatedEndDate.difference(DateTime.now()).inDays;
  }

  // Duración total estimada en días
  int get estimatedDuration => estimatedEndDate.difference(startDate).inDays;

  // Duración real (si está completado)
  int? get actualDuration {
    if (actualEndDate == null) return null;
    return actualEndDate!.difference(startDate).inDays;
  }

  // Progreso estimado (0.0 a 1.0)
  double get estimatedProgress {
    if (actualEndDate != null) return 1.0;
    final total = estimatedEndDate.difference(startDate).inDays;
    final elapsed = DateTime.now().difference(startDate).inDays;
    if (elapsed < 0) return 0.0;
    if (elapsed > total) return 1.0;
    return elapsed / total;
  }
}