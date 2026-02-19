import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pending_object_model.dart';

class PendingObjectService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _error;

  String? get error => _error;

  Future<String?> createPendingObject({
    required String organizationId,
    required PendingObjectType objectType,
    required String collectionRoute,
    required Map<String, dynamic> modelData,
    required String createdBy,
    required String createdByName,
    String? clientId,
    String? parentBatchId,
  }) async {
    try {
      _error = null;

      // 1. Sanitizar modelData ANTES de crear el modelo
      final sanitizedModelData = _sanitizeModelData(modelData);

      final pendingRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('pending_objects')
          .doc();

      final pendingObject = PendingObjectModel(
        id: pendingRef.id,
        objectType: objectType,
        collectionRoute: collectionRoute,
        modelData: sanitizedModelData, // ← Datos sanitizados
        createdBy: createdBy,
        createdByName: createdByName,
        clientId: clientId,
        createdAt: DateTime.now(),
        status: PendingObjectStatus.pendingApproval,
        parentBatchId: parentBatchId,
      );

      final dataMap = pendingObject.toMap();

      await pendingRef.set(dataMap);

      notifyListeners();
      return pendingRef.id;
    } catch (e, stackTrace) {
      print("❌ ERROR creating pending object: $e");
      print("📍 Stack trace: $stackTrace");
      _error = 'Error al crear objeto pendiente: $e';
      notifyListeners();
      return null;
    }
  }

  /// Obtener pending object por ID
  Future<PendingObjectModel?> getPendingObject(
    String organizationId,
    String pendingObjectId,
  ) async {
    try {
      _error = null;

      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('pending_objects')
          .doc(pendingObjectId)
          .get();

      if (!doc.exists) return null;

      return PendingObjectModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      _error = 'Error al obtener objeto pendiente: $e';
      notifyListeners();
      return null;
    }
  }

  /// Aprobar pending object
  Future<bool> approvePendingObject(
    String organizationId,
    String pendingObjectId,
    String approvedBy,
    String approvedByName,
  ) async {
    try {
      _error = null;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('pending_objects')
          .doc(pendingObjectId)
          .update({
        'status': PendingObjectStatus.approved.value,
        'reviewedBy': approvedBy,
        'reviewedByName': approvedByName,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al aprobar objeto: $e';
      notifyListeners();
      return false;
    }
  }

  /// Rechazar pending object
  Future<bool> rejectPendingObject(
    String organizationId,
    String pendingObjectId,
    String rejectedBy,
    String rejectedByName,
    String rejectionReason,
  ) async {
    try {
      _error = null;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('pending_objects')
          .doc(pendingObjectId)
          .update({
        'status': PendingObjectStatus.rejected.value,
        'reviewedBy': rejectedBy,
        'reviewedByName': rejectedByName,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al rechazar objeto: $e';
      notifyListeners();
      return false;
    }
  }

  /// Vincular notificación a pending object
  Future<bool> linkNotification(
    String organizationId,
    String pendingObjectId,
    String notificationId,
  ) async {
    try {
      _error = null;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('pending_objects')
          .doc(pendingObjectId)
          .update({
        'notificationId': notificationId,
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al vincular notificación: $e';
      notifyListeners();
      return false;
    }
  }

  /// Obtener stream de pending objects por estado
  Stream<List<PendingObjectModel>> getPendingObjectsStream(
    String organizationId, {
    PendingObjectStatus? status,
  }) {
    var query = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('pending_objects')
        .orderBy('createdAt', descending: false);

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PendingObjectModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Stream en tiempo real de un pending object individual
  /// Permite que el solicitante vea cambios de estado sin recargar la pantalla
  Stream<PendingObjectModel?> watchPendingObject(
    String organizationId,
    String pendingObjectId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('pending_objects')
        .doc(pendingObjectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      try {
        return PendingObjectModel.fromMap(doc.id, doc.data()!);
      } catch (e) {
        debugPrint('Error parsing pending object stream: $e');
        return null;
      }
    });
  }

  /// Eliminar pending object
  Future<bool> deletePendingObject(
    String organizationId,
    String pendingObjectId,
  ) async {
    try {
      _error = null;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('pending_objects')
          .doc(pendingObjectId)
          .delete();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar objeto pendiente: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sanitizar modelData: convierte FieldValue a Timestamp
  /// Firebase no permite FieldValue dentro de arrays/maps anidados
  Map<String, dynamic> _sanitizeModelData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      sanitized[key] = _sanitizeValue(value);
    });

    return sanitized;
  }

  /// Sanitizar un valor individual recursivamente
  dynamic _sanitizeValue(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is FieldValue) {
      // Convertir FieldValue a Timestamp actual
      return Timestamp.fromDate(DateTime.now());
    } else if (value is DateTime) {
      // Convertir DateTime a Timestamp
      return Timestamp.fromDate(value);
    } else if (value is List) {
      // Procesar cada elemento de la lista
      return value.map((item) => _sanitizeValue(item)).toList();
    } else if (value is Map<String, dynamic>) {
      // Procesar cada campo del mapa recursivamente
      final sanitizedMap = <String, dynamic>{};
      value.forEach((k, v) {
        sanitizedMap[k] = _sanitizeValue(v);
      });
      return sanitizedMap;
    } else {
      // Mantener el valor tal cual
      return value;
    }
  }
}
