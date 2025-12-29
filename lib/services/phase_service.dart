import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/phase_model.dart';
import '../models/user_model.dart';

class PhaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== PRODUCTION PHASES (Organization Level) ====================

  /// Get phases for an organization (with real-time updates)
  Stream<List<ProductionPhase>> getOrganizationPhasesStream(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('phases')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductionPhase.fromFirestore(doc))
            .toList());
  }

  /// Get phases for an organization (one-time fetch)
  Future<List<ProductionPhase>> getOrganizationPhases(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ProductionPhase.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting organization phases: $e');
      return [];
    }
  }

  /// Get only active phases
  Future<List<ProductionPhase>> getActivePhases(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ProductionPhase.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting active phases: $e');
      return [];
    }
  }

  /// Initialize default phases for an organization
  Future<void> initializeDefaultPhases(String organizationId) async {
    try {
      final defaultPhases = ProductionPhase.getDefaultPhases();
      
      final batch = _firestore.batch();
      for (final phase in defaultPhases) {
        final docRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('phases')
            .doc(phase.id);
        
        batch.set(docRef, phase.toFirestore());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error initializing default phases: $e');
      rethrow;
    }
  }

  /// Update a phase
  Future<void> updatePhase(
    String organizationId,
    String phaseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .doc(phaseId)
          .update(updates);
    } catch (e) {
      print('Error updating phase: $e');
      rethrow;
    }
  }

  /// Toggle phase active status
  Future<void> togglePhaseStatus(
    String organizationId,
    String phaseId,
    bool isActive,
  ) async {
    try {
      await updatePhase(organizationId, phaseId, {'isActive': isActive});
    } catch (e) {
      print('Error toggling phase status: $e');
      rethrow;
    }
  }

  /// Create custom phase
  Future<String> createCustomPhase(
    String organizationId,
    ProductionPhase phase,
  ) async {
    try {
      final docRef = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .add(phase.toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Error creating custom phase: $e');
      rethrow;
    }
  }

  // ==================== PRODUCT PHASE PROGRESS ====================

  /// Get phase progress for a product (with real-time updates)
  Stream<List<ProductPhaseProgress>> getProductPhaseProgressStream(
    String organizationId,
    String projectId,
    String productId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .doc(productId)
        .collection('phaseProgress')
        .orderBy('phaseOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductPhaseProgress.fromFirestore(doc))
            .toList());
  }

  /// Get phase progress for a product (one-time fetch)
  Future<List<ProductPhaseProgress>> getProductPhaseProgress(
    String organizationId,
    String projectId,
    String productId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .collection('phaseProgress')
          .orderBy('phaseOrder')
          .get();

      return snapshot.docs
          .map((doc) => ProductPhaseProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting product phase progress: $e');
      return [];
    }
  }

  /// Initialize phase progress for a new product
  Future<void> initializeProductPhases(
    String organizationId,
    String projectId,
    String productId,
  ) async {
    try {
      final phases = await getActivePhases(organizationId);
      
      final batch = _firestore.batch();
      
      for (final phase in phases) {
        final progress = ProductPhaseProgress(
          id: phase.id,
          productId: productId,
          phaseId: phase.id,
          phaseName: phase.name,
          phaseOrder: phase.order,
          status: PhaseStatus.pending,
          createdAt: DateTime.now(),
        );
        
        final docRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .doc(productId)
            .collection('phaseProgress')
            .doc(phase.id);
        
        batch.set(docRef, progress.toFirestore());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error initializing product phases: $e');
      rethrow;
    }
  }

  /// Update phase status
  Future<void> updatePhaseStatus(
    String organizationId,
    String projectId,
    String productId,
    String phaseId,
    PhaseStatus newStatus,
    UserModel user, {
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final updates = <String, dynamic>{
        'status': newStatus.toFirestore(),
      };

      // Update timestamps and user info based on status
      switch (newStatus) {
        case PhaseStatus.inProgress:
          updates['startedAt'] = Timestamp.fromDate(now);
          updates['startedByUserId'] = user.uid;
          updates['startedByUserName'] = user.name;
          break;
        case PhaseStatus.completed:
          updates['completedAt'] = Timestamp.fromDate(now);
          updates['completedByUserId'] = user.uid;
          updates['completedByUserName'] = user.name;
          break;
        case PhaseStatus.pending:
          // Reset timestamps when moving back to pending
          updates['startedAt'] = null;
          updates['completedAt'] = null;
          updates['startedByUserId'] = null;
          updates['startedByUserName'] = null;
          updates['completedByUserId'] = null;
          updates['completedByUserName'] = null;
          break;
      }

      if (notes != null && notes.isNotEmpty) {
        updates['notes'] = notes;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .collection('phaseProgress')
          .doc(phaseId)
          .update(updates);
    } catch (e) {
      print('Error updating phase status: $e');
      rethrow;
    }
  }

  /// Move to next phase
  Future<void> moveToNextPhase(
    String organizationId,
    String projectId,
    String productId,
    String currentPhaseId,
    UserModel user, {
    String? notes,
  }) async {
    try {
      // Get all phases for this product
      final phases = await getProductPhaseProgress(
        organizationId,
        projectId,
        productId,
      );

      // Find current phase
      final currentIndex = phases.indexWhere((p) => p.phaseId == currentPhaseId);
      if (currentIndex == -1) {
        throw Exception('Current phase not found');
      }

      // Complete current phase
      await updatePhaseStatus(
        organizationId,
        projectId,
        productId,
        currentPhaseId,
        PhaseStatus.completed,
        user,
        notes: notes,
      );

      // Start next phase if exists
      if (currentIndex < phases.length - 1) {
        final nextPhase = phases[currentIndex + 1];
        await updatePhaseStatus(
          organizationId,
          projectId,
          productId,
          nextPhase.phaseId,
          PhaseStatus.inProgress,
          user,
        );
      }
    } catch (e) {
      print('Error moving to next phase: $e');
      rethrow;
    }
  }

  /// Calculate overall product progress percentage
  Future<double> calculateProductProgress(
    String organizationId,
    String projectId,
    String productId,
  ) async {
    try {
      final phases = await getProductPhaseProgress(
        organizationId,
        projectId,
        productId,
      );

      if (phases.isEmpty) return 0.0;

      final totalProgress = phases.fold<double>(
        0.0,
        (sum, phase) => sum + phase.progressPercentage,
      );

      return totalProgress / phases.length;
    } catch (e) {
      print('Error calculating product progress: $e');
      return 0.0;
    }
  }

  /// Get statistics for a project
  Future<Map<String, dynamic>> getProjectPhaseStatistics(
    String organizationId,
    String projectId,
  ) async {
    try {
      final productsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .get();

      int totalPhases = 0;
      int completedPhases = 0;
      int inProgressPhases = 0;
      int pendingPhases = 0;

      for (final productDoc in productsSnapshot.docs) {
        final phases = await getProductPhaseProgress(
          organizationId,
          projectId,
          productDoc.id,
        );

        totalPhases += phases.length;
        completedPhases += phases.where((p) => p.isCompleted).length;
        inProgressPhases += phases.where((p) => p.isInProgress).length;
        pendingPhases += phases.where((p) => p.isPending).length;
      }

      final overallProgress = totalPhases > 0 
          ? (completedPhases / totalPhases) * 100 
          : 0.0;

      return {
        'totalPhases': totalPhases,
        'completedPhases': completedPhases,
        'inProgressPhases': inProgressPhases,
        'pendingPhases': pendingPhases,
        'overallProgress': overallProgress,
        'totalProducts': productsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting project phase statistics: $e');
      return {
        'totalPhases': 0,
        'completedPhases': 0,
        'inProgressPhases': 0,
        'pendingPhases': 0,
        'overallProgress': 0.0,
        'totalProducts': 0,
      };
    }
  }

  /// Check if user can manage a specific phase (for operator role)
  Future<bool> canUserManagePhase(
    String userId,
    String organizationId,
    String phaseId,
  ) async {
    try {
      // Check if user has specific phase assignment
      final assignmentDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phaseAssignments')
          .doc(userId)
          .get();

      if (!assignmentDoc.exists) {
        // No specific assignments, allow all phases
        return true;
      }

      final data = assignmentDoc.data() as Map<String, dynamic>;
      final assignedPhases = List<String>.from(data['phases'] ?? []);
      
      return assignedPhases.contains(phaseId);
    } catch (e) {
      print('Error checking phase permission: $e');
      return false;
    }
  }

  /// Assign phases to an operator
  Future<void> assignPhasesToUser(
    String userId,
    String organizationId,
    List<String> phaseIds,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phaseAssignments')
          .doc(userId)
          .set({
        'phases': phaseIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error assigning phases to user: $e');
      rethrow;
    }
  }
}