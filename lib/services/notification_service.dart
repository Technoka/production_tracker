import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _error;

  String? get error => _error;

  /// Obtener stream de notificaciones para un usuario
  /// Incluye pendientes y leídas no resueltas
  Stream<List<NotificationModel>> getUserNotificationsStream(
    String organizationId,
    String userId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('notifications')
        .where('destinationUserIds', arrayContains: userId)
        .where('status', whereIn: [
          NotificationStatus.pending.value,
          // Las resueltas se filtran en el cliente según readBy
        ])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .where((notif) {
                // Incluir pendientes y leídas no resueltas
                return notif.status == NotificationStatus.pending ||
                    (notif.isReadBy(userId) && !notif.isResolved);
              })
              .toList();
        });
  }

  /// Obtener count de notificaciones no leídas
  Stream<int> getUnreadCountStream(
    String organizationId,
    String userId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('notifications')
        .where('destinationUserIds', arrayContains: userId)
        .where('status', isEqualTo: NotificationStatus.pending.value)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .where((notif) => !notif.isReadBy(userId))
              .length;
        });
  }

  /// Crear notificación
  Future<String?> createNotification({
    required String organizationId,
    required NotificationType type,
    required List<String> destinationUserIds,
    required String title,
    required String message,
    Map<String, dynamic> metadata = const {},
    List<NotificationAction> actions = const [],
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    try {
      _error = null;

      if (destinationUserIds.isEmpty) {
        _error = 'No hay destinatarios';
        return null;
      }

      final notifRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('notifications')
          .doc();

      final notification = NotificationModel(
        id: notifRef.id,
        type: type,
        destinationUserIds: destinationUserIds,
        readBy: [],
        status: NotificationStatus.pending,
        priority: priority,
        title: title,
        message: message,
        metadata: metadata,
        actions: actions,
        createdAt: DateTime.now(),
      );

      await notifRef.set(notification.toMap());

      notifyListeners();
      return notifRef.id;
    } catch (e) {
      _error = 'Error al crear notificación: $e';
      notifyListeners();
      return null;
    }
  }

  /// Marcar notificación como leída por un usuario
  Future<bool> markAsRead(
    String organizationId,
    String notificationId,
    String userId,
  ) async {
    try {
      _error = null;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al marcar como leída: $e';
      notifyListeners();
      return false;
    }
  }

  /// Marcar todas las notificaciones de un usuario como leídas
  Future<bool> markAllAsRead(
    String organizationId,
    String userId,
  ) async {
    try {
      _error = null;

      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('notifications')
          .where('destinationUserIds', arrayContains: userId)
          .where('status', isEqualTo: NotificationStatus.pending.value)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final notif = NotificationModel.fromMap(doc.id, doc.data());
        if (!notif.isReadBy(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }

      await batch.commit();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al marcar todas como leídas: $e';
      notifyListeners();
      return false;
    }
  }

  /// Resolver notificación (marcar como completada)
  Future<bool> resolveNotification(
    String organizationId,
    String notificationId,
  ) async {
    try {
      _error = null;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': NotificationStatus.resolved.value,
        'resolvedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al resolver notificación: $e';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar notificación
  Future<bool> deleteNotification(
    String organizationId,
    String notificationId,
  ) async {
    try {
      _error = null;

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar notificación: $e';
      notifyListeners();
      return false;
    }
  }

  /// Obtener notificación por ID
  Future<NotificationModel?> getNotification(
    String organizationId,
    String notificationId,
  ) async {
    try {
      _error = null;

      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!doc.exists) return null;

      return NotificationModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      _error = 'Error al obtener notificación: $e';
      notifyListeners();
      return null;
    }
  }
}