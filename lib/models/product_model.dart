import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final int quantity;
  final String currentStage;
  final String batchNumber;
  final List<StageModel> stages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.currentStage,
    required this.batchNumber,
    required this.stages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'currentStage': currentStage,
      'batchNumber': batchNumber,
      'stages': stages.map((s) => s.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      quantity: map['quantity'] as int,
      currentStage: map['currentStage'] as String,
      batchNumber: map['batchNumber'] as String,
      stages: (map['stages'] as List)
          .map((s) => StageModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    int? quantity,
    String? currentStage,
    String? batchNumber,
    List<StageModel>? stages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      currentStage: currentStage ?? this.currentStage,
      batchNumber: batchNumber ?? this.batchNumber,
      stages: stages ?? this.stages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StageModel {
  final String name;
  final String status; // 'En proceso', 'Completado'
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? notes;

  StageModel({
    required this.name,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
    };
  }

  factory StageModel.fromMap(Map<String, dynamic> map) {
    return StageModel(
      name: map['name'] as String,
      status: map['status'] as String,
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      notes: map['notes'] as String?,
    );
  }

  StageModel copyWith({
    String? name,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return StageModel(
      name: name ?? this.name,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}