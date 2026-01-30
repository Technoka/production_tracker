import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para solicitudes de código de activación de organizaciones
/// 
/// Cuando un usuario quiere crear una organización, primero solicita
/// un código de activación. Esta solicitud se guarda en Firestore para
/// que el admin pueda revisarla y aprobarla.
class ActivationRequestModel {
  final String id;
  final String companyName;
  final String contactEmail;
  final String contactName;
  final String contactPhone;
  final String? message;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? activationCodeId; // Referencia al código generado si se aprueba

  ActivationRequestModel({
    required this.id,
    required this.companyName,
    required this.contactEmail,
    required this.contactName,
    required this.contactPhone,
    this.message,
    required this.requestedAt,
    required this.status,
    this.reviewedAt,
    this.reviewedBy,
    this.activationCodeId,
  });

  /// Crear desde Map (Firestore)
  factory ActivationRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivationRequestModel(
      id: id,
      companyName: map['companyName'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactName: map['contactName'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      message: map['message'],
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'],
      activationCodeId: map['activationCodeId'],
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'contactEmail': contactEmail,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'message': message,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'activationCodeId': activationCodeId,
    };
  }

  /// Verificar si está pendiente
  bool get isPending => status == 'pending';

  /// Verificar si fue aprobada
  bool get isApproved => status == 'approved';

  /// Verificar si fue rechazada
  bool get isRejected => status == 'rejected';

  /// Copiar con nuevos valores
  ActivationRequestModel copyWith({
    String? id,
    String? companyName,
    String? contactEmail,
    String? contactName,
    String? contactPhone,
    String? message,
    DateTime? requestedAt,
    String? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? activationCodeId,
  }) {
    return ActivationRequestModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      message: message ?? this.message,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      activationCodeId: activationCodeId ?? this.activationCodeId,
    );
  }
}