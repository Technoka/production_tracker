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

  /// Get active phases stream (real-time)
  Stream<List<ProductionPhase>> getActivePhasesStream(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('phases')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductionPhase.fromFirestore(doc))
            .toList());
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
        
        batch.set(docRef, phase.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error initializing default phases: $e');
      rethrow;
    }
  }

  /// Update a phase with any fields
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
          .add(phase.toMap());
      
      return docRef.id;
    } catch (e) {
      print('Error creating custom phase: $e');
      rethrow;
    }
  }

/// Delete a phase (solo si no tiene productos asociados)
  Future<void> deletePhase(
    String organizationId,
    String phaseId,
  ) async {
    try {
      // Verificar que no haya productos en esta fase antes de eliminar
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .get();

      // Revisar todos los proyectos
      for (final projectDoc in projectsSnapshot.docs) {
        final productsInPhase = await getProductsInPhase(
          organizationId,
          projectDoc.id,
          phaseId,
        );

        if (productsInPhase.isNotEmpty) {
          throw Exception(
            'Cannot delete phase: ${productsInPhase.length} product(s) are currently in this phase. '
            'Move or complete these products before deleting the phase.'
          );
        }

        // Verificar también si hay productos con esta fase en su progreso (aunque no estén activos en ella)
        final productsSnapshot = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(projectDoc.id)
            .collection('products')
            .get();

        for (final productDoc in productsSnapshot.docs) {
          final phaseProgressDoc = await _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('projects')
              .doc(projectDoc.id)
              .collection('products')
              .doc(productDoc.id)
              .collection('phaseProgress')
              .doc(phaseId)
              .get();

          if (phaseProgressDoc.exists) {
            throw Exception(
              'Cannot delete phase: This phase is part of existing product workflows. '
              'Deactivate the phase instead to hide it from new products.'
            );
          }
        }
      }

      // Si no hay productos, proceder a eliminar
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .doc(phaseId)
          .delete();
    } catch (e) {
      print('Error deleting phase: $e');
      rethrow;
    }
  }

  // ==================== PERSONALIZACIÓN AVANZADA ====================

  /// Update phase visual settings (color, icon)
  Future<void> updatePhaseVisuals(
    String organizationId,
    String phaseId, {
    String? color,
    String? icon,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (color != null) {
        // Validar formato hex
        if (!color.startsWith('#') || color.length != 7) {
          throw Exception('Invalid color format. Use #RRGGBB');
        }
        updates['color'] = color;
      }
      
      if (icon != null) {
        updates['icon'] = icon;
      }
      
      if (updates.isNotEmpty) {
        await updatePhase(organizationId, phaseId, updates);
      }
    } catch (e) {
      print('Error updating phase visuals: $e');
      rethrow;
    }
  }

  /// Update WIP limit
  Future<void> updateWipLimit(
    String organizationId,
    String phaseId,
    int wipLimit,
  ) async {
    try {
      if (wipLimit < 1) {
        throw Exception('WIP limit must be at least 1');
      }
      
      await updatePhase(organizationId, phaseId, {'wipLimit': wipLimit});
    } catch (e) {
      print('Error updating WIP limit: $e');
      rethrow;
    }
  }

  /// Update SLA settings
  Future<void> updateSLASettings(
    String organizationId,
    String phaseId, {
    int? maxDurationHours,
    int? warningThresholdPercent,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (maxDurationHours != null) {
        if (maxDurationHours < 0) {
          throw Exception('Max duration must be positive');
        }
        updates['maxDurationHours'] = maxDurationHours;
      }
      
      if (warningThresholdPercent != null) {
        if (warningThresholdPercent < 1 || warningThresholdPercent > 100) {
          throw Exception('Warning threshold must be between 1 and 100');
        }
        updates['warningThresholdPercent'] = warningThresholdPercent;
      }
      
      if (updates.isNotEmpty) {
        await updatePhase(organizationId, phaseId, updates);
      }
    } catch (e) {
      print('Error updating SLA settings: $e');
      rethrow;
    }
  }

  /// Reorder phases
  Future<void> reorderPhases(
    String organizationId,
    List<String> orderedPhaseIds,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < orderedPhaseIds.length; i++) {
        final docRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('phases')
            .doc(orderedPhaseIds[i]);
        
        batch.update(docRef, {
          'order': i + 1,
          'kanbanPosition': i + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error reordering phases: $e');
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
            .map((doc) => ProductPhaseProgress.fromMap(doc))
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
          .map((doc) => ProductPhaseProgress.fromMap(doc))
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
        
        batch.set(docRef, progress.toMap());
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
        'status': newStatus.toMap(),
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

  // ==================== ANALYTICS Y MÉTRICAS ====================

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

  /// Get products in a specific phase (para Kanban)
  Future<List<String>> getProductsInPhase(
    String organizationId,
    String projectId,
    String phaseId,
  ) async {
    try {
      final productsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .get();

      final productsInPhase = <String>[];

      for (final productDoc in productsSnapshot.docs) {
        final phaseDoc = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .doc(productDoc.id)
            .collection('phaseProgress')
            .doc(phaseId)
            .get();

        if (phaseDoc.exists) {
          final progress = ProductPhaseProgress.fromMap(phaseDoc);
          if (progress.isInProgress) {
            productsInPhase.add(productDoc.id);
          }
        }
      }

      return productsInPhase;
    } catch (e) {
      print('Error getting products in phase: $e');
      return [];
    }
  }

  /// Check WIP limit for a phase
  Future<bool> isPhaseAtWipLimit(
    String organizationId,
    String phaseId,
  ) async {
    try {
      // Get phase configuration
      final phaseDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .doc(phaseId)
          .get();

      if (!phaseDoc.exists) return false;

      final phase = ProductionPhase.fromFirestore(phaseDoc);

      // Count products currently in this phase across all projects
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .get();

      int currentCount = 0;

      for (final projectDoc in projectsSnapshot.docs) {
        final productsInPhase = await getProductsInPhase(
          organizationId,
          projectDoc.id,
          phaseId,
        );
        currentCount += productsInPhase.length;
      }

      return currentCount >= phase.wipLimit;
    } catch (e) {
      print('Error checking WIP limit: $e');
      return false;
    }
  }

  // ==================== PHASE ASSIGNMENTS (Para Operarios) ====================

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
      
      return assignedPhases.isEmpty || assignedPhases.contains(phaseId);
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

  /// Get assigned phases for a user
  Future<List<String>> getAssignedPhases(
    String userId,
    String organizationId,
  ) async {
    try {
      final assignmentDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phaseAssignments')
          .doc(userId)
          .get();

      if (!assignmentDoc.exists) return [];

      final data = assignmentDoc.data() as Map<String, dynamic>;
      return List<String>.from(data['phases'] ?? []);
    } catch (e) {
      print('Error getting assigned phases: $e');
      return [];
    }
  }
}