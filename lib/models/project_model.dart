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