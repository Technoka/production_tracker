import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/invitation_model.dart';

/// Service para gestión de invitaciones directas
/// 
/// Permite a los admins crear invitaciones con código y rol predefinido
/// para que nuevos usuarios se unan automáticamente
class InvitationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _error;
  String? get error => _error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ==================== CREAR INVITACIÓN ====================

  /// Crear invitación directa
  Future<InvitationModel?> createInvitation({
    required String organizationId,
    required String roleId,
    required String createdBy,
    String? description,
    int maxUses = 1,
    int daysUntilExpiration = 7,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Generar código único
      final code = _generateInvitationCode();

      // Crear invitación
      final invitation = InvitationModel(
        id: '', // Se asignará automáticamente
        organizationId: organizationId,
        code: code,
        roleId: roleId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: daysUntilExpiration)),
        maxUses: maxUses,
        description: description,
      );

      final docRef = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('invitations')
          .add(invitation.toMap());

      final created = invitation.copyWith(id: docRef.id);

      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Error al crear invitación: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== VALIDAR Y USAR INVITACIÓN ====================

  /// Validar código de invitación
  Future<InvitationModel?> validateInvitationCode({
    required String code,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Buscar en todas las organizaciones
      // (podría optimizarse con un índice global, pero por ahora así funciona)
      final orgsSnapshot = await _firestore
          .collection('organizations')
          .get();

      for (final orgDoc in orgsSnapshot.docs) {
        final invitationsSnapshot = await _firestore
            .collection('organizations')
            .doc(orgDoc.id)
            .collection('invitations')
            .where('code', isEqualTo: code.toUpperCase())
            .limit(1)
            .get();

        if (invitationsSnapshot.docs.isNotEmpty) {
          final invitation = InvitationModel.fromMap(
            invitationsSnapshot.docs.first.data(),
            invitationsSnapshot.docs.first.id,
          );

          // Verificar validez
          if (!invitation.canBeUsed) {
            if (invitation.isExpired) {
              _error = 'Esta invitación ha expirado';
            } else if (invitation.isRevoked) {
              _error = 'Esta invitación ha sido revocada';
            } else if (invitation.hasReachedMaxUses) {
              _error = 'Esta invitación ya alcanzó el máximo de usos';
            } else {
              _error = 'Esta invitación no está activa';
            }
            _isLoading = false;
            notifyListeners();
            return null;
          }

          _isLoading = false;
          notifyListeners();
          return invitation;
        }
      }

      _error = 'Código de invitación inválido';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error al validar invitación: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Marcar invitación como usada
  Future<bool> markInvitationAsUsed({
    required String organizationId,
    required String invitationId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('invitations')
          .doc(invitationId)
          .update({
        'usedCount': FieldValue.increment(1),
        'usedBy': FieldValue.arrayUnion([userId]),
      });

      // Si alcanzó el máximo de usos, marcar como used
      final invDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('invitations')
          .doc(invitationId)
          .get();

      if (invDoc.exists) {
        final inv = InvitationModel.fromMap(invDoc.data()!, invDoc.id);
        if (inv.hasReachedMaxUses) {
          await _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('invitations')
              .doc(invitationId)
              .update({'status': 'used'});
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error marcando invitación como usada: $e');
      return false;
    }
  }

  // ==================== GESTIÓN DE INVITACIONES ====================

  /// Stream de invitaciones activas de una organización
  Stream<List<InvitationModel>> watchActiveInvitations(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('invitations')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Obtener todas las invitaciones de una organización
  Future<List<InvitationModel>> getOrganizationInvitations(
    String organizationId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('invitations')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo invitaciones: $e');
      return [];
    }
  }

  /// Revocar invitación
  Future<bool> revokeInvitation({
    required String organizationId,
    required String invitationId,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('invitations')
          .doc(invitationId)
          .update({
        'status': 'revoked',
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al revocar invitación: $e';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar invitación
  Future<bool> deleteInvitation({
    required String organizationId,
    required String invitationId,
  }) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('invitations')
          .doc(invitationId)
          .delete();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar invitación: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  /// Generar código de invitación único (8 caracteres)
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}