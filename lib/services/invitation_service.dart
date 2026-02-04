import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import '../models/invitation_model.dart';

/// Service para gestión de invitaciones directas
///
/// VERSIÓN 2.0: Usa colección global /invitations y Cloud Functions
class InvitationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String? _error;
  String? get error => _error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ==================== CREAR INVITACIÓN ====================

  /// Crear invitación directa en colección global
  Future<InvitationModel?> createInvitation({
    required String organizationId,
    required String organizationName,
    required String roleId,
    required String createdBy,
    String? description,
    String? clientId,
    String? clientName,
    int maxUses = 1,
    int daysUntilExpiration = 7,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final code = _generateInvitationCode();

      final invitation = InvitationModel(
        id: '',
        organizationId: organizationId,
        organizationName: organizationName,
        code: code,
        roleId: roleId,
        clientId: clientId,
        clientName: clientName,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: daysUntilExpiration)),
        maxUses: maxUses,
        description: description,
      );

      // ✅ Colección global
      final docRef = await _firestore
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

  // ==================== VALIDAR INVITACIÓN ====================

  /// Validar código usando Cloud Function
  Future<InvitationModel?> validateInvitationCode({
    required String code,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('🔍 Validando código: $code');

      final result = await _functions
          .httpsCallable('validateInvitationCode')
          .call({'code': code.toUpperCase()});

      debugPrint('✅ Respuesta recibida: ${result.data}');

      // Manejar la respuesta de forma segura
      final responseData = result.data;
      
      if (responseData == null) {
        throw Exception('Respuesta vacía del servidor');
      }

      // Convertir a Map de forma segura
      Map<String, dynamic> dataMap;
      if (responseData is Map) {
        dataMap = Map<String, dynamic>.from(responseData);
      } else {
        throw Exception('Formato de respuesta inválido');
      }

      // Obtener el objeto invitation
      final invitationData = dataMap['invitation'];
      if (invitationData == null) {
        throw Exception('No se encontró información de invitación');
      }

      Map<String, dynamic> invitationMap;
      if (invitationData is Map) {
        invitationMap = Map<String, dynamic>.from(invitationData);
      } else {
        throw Exception('Formato de invitación inválido');
      }

      debugPrint('📦 Datos de invitación: $invitationMap');

      // Crear el modelo manualmente
      final invitation = InvitationModel(
        id: invitationMap['id']?.toString() ?? '',
        organizationId: invitationMap['organizationId']?.toString() ?? '',
        organizationName: invitationMap['organizationName']?.toString() ?? '',
        code: invitationMap['code']?.toString() ?? '',
        type: invitationMap['type']?.toString() ?? 'direct',
        roleId: invitationMap['roleId']?.toString() ?? '',
        clientId: invitationMap['clientId']?.toString(),
        clientName: invitationMap['clientName']?.toString(),
        createdBy: invitationMap['createdBy']?.toString() ?? '',
        createdAt: _parseTimestamp(invitationMap['createdAt']),
        expiresAt: _parseTimestamp(invitationMap['expiresAt']),
        maxUses: _parseInt(invitationMap['maxUses']) ?? 1,
        status: invitationMap['status']?.toString() ?? 'active',
        usedCount: _parseInt(invitationMap['usedCount']) ?? 0,
        usedBy: _parseStringList(invitationMap['usedBy']),
        description: invitationMap['description']?.toString(),
      );

      debugPrint('✅ Invitación creada: ${invitation.code}');

      _isLoading = false;
      notifyListeners();
      return invitation;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Error FirebaseFunctions: ${e.code} - ${e.message}');
      _error = e.message ?? 'Código inválido';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('❌ Error general: $e');
      _error = 'Error validando código: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== HELPERS DE PARSING ====================

  /// Parsear Timestamp a DateTime
  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is Map) {
      // Formato: {_seconds: xxx, _nanoseconds: xxx}
      final seconds = value['_seconds'] ?? value['seconds'];
      
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds as num).toInt() * 1000,
        );
      }
    }
    
    return DateTime.now();
  }

  /// Parsear número de forma segura
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parsear lista de strings
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  // ==================== GESTIÓN ====================

  Stream<List<InvitationModel>> watchActiveInvitations(String organizationId) {
    return _firestore
        .collection('invitations')
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<InvitationModel>> getOrganizationInvitations(
    String organizationId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  Future<InvitationModel?> getInvitationById({
    required String invitationId,
  }) async {
    try {
      final doc =
          await _firestore.collection('invitations').doc(invitationId).get();
      if (!doc.exists) return null;
      return InvitationModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  Future<bool> revokeInvitation({required String invitationId}) async {
    try {
      await _firestore
          .collection('invitations')
          .doc(invitationId)
          .update({'status': 'revoked'});
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInvitation({required String invitationId}) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).delete();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILIDADES ====================

  String _generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}