import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pending_object_model.dart';

class PendingObjectService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _error;

  String? get error => _error;

  /// Crear pending object
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

      final pendingRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('pending_objects')
          .doc();

      final pendingObject = PendingObjectModel(
        id: pendingRef.id,
        objectType: objectType,
        collectionRoute: collectionRoute,
        modelData: modelData,
        createdBy: createdBy,
        createdByName: createdByName,
        clientId: clientId,
        createdAt: DateTime.now(),
        status: PendingObjectStatus.pendingApproval,
        parentBatchId: parentBatchId,
      );

      await pendingRef.set(pendingObject.toMap());

      notifyListeners();
      return pendingRef.id;
    } catch (e) {
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
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PendingObjectModel.fromMap(doc.id, doc.data()))
          .toList();
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
}