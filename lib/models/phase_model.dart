import 'package:cloud_firestore/cloud_firestore.dart';

enum PhaseStatus {
  pending,
  inProgress,
  completed;

  String get displayName {
    switch (this) {
      case PhaseStatus.pending:
        return 'Pendiente';
      case PhaseStatus.inProgress:
        return 'En Proceso';
      case PhaseStatus.completed:
        return 'Completado';
    }
  }

  static PhaseStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PhaseStatus.pending;
      case 'inprogress':
      case 'in_progress':
        return PhaseStatus.inProgress;
      case 'completed':
        return PhaseStatus.completed;
      default:
        return PhaseStatus.pending;
    }
  }

  String toFirestore() {
    return toString().split('.').last;
  }
}

class ProductionPhase {
  final String id;
  final String name;
  final int order;
  final bool isActive;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductionPhase({
    required this.id,
    required this.name,
    required this.order,
    this.isActive = true,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductionPhase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductionPhase(
      id: doc.id,
      name: data['name'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'order': order,
      'isActive': isActive,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ProductionPhase copyWith({
    String? id,
    String? name,
    int? order,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductionPhase(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<ProductionPhase> getDefaultPhases() {
    final now = DateTime.now();
    return [
      ProductionPhase(
        id: 'cut',
        name: 'Corte de piel',
        order: 1,
        isActive: true,
        createdAt: now,
      ),
      ProductionPhase(
        id: 'preparation',
        name: 'Preparación de piezas',
        order: 2,
        isActive: true,
        createdAt: now,
      ),
      ProductionPhase(
        id: 'sewing',
        name: 'Costura',
        order: 3,
        isActive: true,
        createdAt: now,
      ),
      ProductionPhase(
        id: 'assembly',
        name: 'Montaje',
        order: 4,
        isActive: true,
        createdAt: now,
      ),
      ProductionPhase(
        id: 'hardware',
        name: 'Herrajes y accesorios',
        order: 5,
        isActive: true,
        createdAt: now,
      ),
      ProductionPhase(
        id: 'quality',
        name: 'Control de calidad',
        order: 6,
        isActive: true,
        createdAt: now,
      ),
      ProductionPhase(
        id: 'finishing',
        name: 'Acabado final',
        order: 7,
        isActive: true,
        createdAt: now,
      ),
      ProductionPhase(
        id: 'packaging',
        name: 'Empaquetado',
        order: 8,
        isActive: true,
        createdAt: now,
      ),
    ];
  }
}

class ProductPhaseProgress {
  final String id;
  final String productId;
  final String phaseId;
  final String phaseName;
  final int phaseOrder;
  final PhaseStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? startedByUserId;
  final String? startedByUserName;
  final String? completedByUserId;
  final String? completedByUserName;
  final String? notes;

  ProductPhaseProgress({
    required this.id,
    required this.productId,
    required this.phaseId,
    required this.phaseName,
    required this.phaseOrder,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.startedByUserId,
    this.startedByUserName,
    this.completedByUserId,
    this.completedByUserName,
    this.notes,
  });

  factory ProductPhaseProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductPhaseProgress(
      id: doc.id,
      productId: data['productId'] ?? '',
      phaseId: data['phaseId'] ?? '',
      phaseName: data['phaseName'] ?? '',
      phaseOrder: data['phaseOrder'] ?? 0,
      status: PhaseStatus.fromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      startedByUserId: data['startedByUserId'],
      startedByUserName: data['startedByUserName'],
      completedByUserId: data['completedByUserId'],
      completedByUserName: data['completedByUserName'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'phaseId': phaseId,
      'phaseName': phaseName,
      'phaseOrder': phaseOrder,
      'status': status.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'startedByUserId': startedByUserId,
      'startedByUserName': startedByUserName,
      'completedByUserId': completedByUserId,
      'completedByUserName': completedByUserName,
      'notes': notes,
    };
  }

  ProductPhaseProgress copyWith({
    String? id,
    String? productId,
    String? phaseId,
    String? phaseName,
    int? phaseOrder,
    PhaseStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? startedByUserId,
    String? startedByUserName,
    String? completedByUserId,
    String? completedByUserName,
    String? notes,
  }) {
    return ProductPhaseProgress(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      phaseId: phaseId ?? this.phaseId,
      phaseName: phaseName ?? this.phaseName,
      phaseOrder: phaseOrder ?? this.phaseOrder,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      startedByUserId: startedByUserId ?? this.startedByUserId,
      startedByUserName: startedByUserName ?? this.startedByUserName,
      completedByUserId: completedByUserId ?? this.completedByUserId,
      completedByUserName: completedByUserName ?? this.completedByUserName,
      notes: notes ?? this.notes,
    );
  }

  double get progressPercentage {
    switch (status) {
      case PhaseStatus.pending:
        return 0.0;
      case PhaseStatus.inProgress:
        return 0.5;
      case PhaseStatus.completed:
        return 1.0;
    }
  }

  bool get isPending => status == PhaseStatus.pending;
  bool get isInProgress => status == PhaseStatus.inProgress;
  bool get isCompleted => status == PhaseStatus.completed;
}