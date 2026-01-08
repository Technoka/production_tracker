import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sla_alert_model.dart';
import '../models/phase_model.dart';
import 'phase_service.dart';

class SLAService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PhaseService _phaseService = PhaseService();

  // ==================== ALERT CRUD ====================

  /// Get all alerts for an organization (stream)
  Stream<List<SLAAlert>> getOrganizationAlertsStream(
    String organizationId, {
    SLAAlertStatus? status,
    SLAAlertSeverity? severity,
  }) {
    Query query = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('sla_alerts')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toMap());
    }

    if (severity != null) {
      query = query.where('severity', isEqualTo: severity.toMap());
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SLAAlert.fromFirestore(doc)).toList());
  }

  /// Get active alerts count
  Future<int> getActiveAlertsCount(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .where('status', isEqualTo: SLAAlertStatus.active.toMap())
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active alerts count: $e');
      return 0;
    }
  }

  /// Get alerts for a specific project
  Stream<List<SLAAlert>> getProjectAlertsStream(
    String organizationId,
    String projectId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('sla_alerts')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SLAAlert.fromFirestore(doc)).toList());
  }

  /// Get alerts for a specific product
  Stream<List<SLAAlert>> getProductAlertsStream(
    String organizationId,
    String productId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('sla_alerts')
        .where('productId', isEqualTo: productId)
        .where('status', whereIn: [
          SLAAlertStatus.active.toMap(),
          SLAAlertStatus.acknowledged.toMap(),
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SLAAlert.fromFirestore(doc)).toList());
  }

  /// Create a new alert
  Future<String> createAlert(String organizationId, SLAAlert alert) async {
    try {
      // Check if similar alert already exists
      final existingAlerts = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .where('entityId', isEqualTo: alert.entityId)
          .where('alertType', isEqualTo: alert.alertType.toMap())
          .where('status', whereIn: [
            SLAAlertStatus.active.toMap(),
            SLAAlertStatus.acknowledged.toMap(),
          ])
          .get();

      if (existingAlerts.docs.isNotEmpty) {
        // Update existing alert instead of creating duplicate
        final existingId = existingAlerts.docs.first.id;
        await updateAlert(organizationId, existingId, {
          'currentValue': alert.currentValue,
          'deviationPercent': alert.deviationPercent,
          'severity': alert.severity.toMap(),
        });
        return existingId;
      }

      final docRef = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .add(alert.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creating alert: $e');
      rethrow;
    }
  }

  /// Update alert
  Future<void> updateAlert(
    String organizationId,
    String alertId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .doc(alertId)
          .update(updates);
    } catch (e) {
      print('Error updating alert: $e');
      rethrow;
    }
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(
    String organizationId,
    String alertId,
    String userId,
  ) async {
    try {
      await updateAlert(organizationId, alertId, {
        'status': SLAAlertStatus.acknowledged.toMap(),
        'acknowledgedBy': userId,
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error acknowledging alert: $e');
      rethrow;
    }
  }

  /// Resolve alert
  Future<void> resolveAlert(
    String organizationId,
    String alertId, {
    String? notes,
  }) async {
    try {
      final updates = {
        'status': SLAAlertStatus.resolved.toMap(),
        'resolvedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updates['resolutionNotes'] = notes;
      }

      await updateAlert(organizationId, alertId, updates);
    } catch (e) {
      print('Error resolving alert: $e');
      rethrow;
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String organizationId, String alertId) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .doc(alertId)
          .delete();
    } catch (e) {
      print('Error deleting alert: $e');
      rethrow;
    }
  }

  // ==================== SLA CALCULATIONS ====================

  /// Check if a product phase is exceeding SLA
  Future<SLAAlert?> checkProductPhaseSLA(
    String organizationId,
    String projectId,
    String productId,
    ProductPhaseProgress phaseProgress,
  ) async {
    try {
      // Get phase configuration
      final phaseDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('phases')
          .doc(phaseProgress.phaseId)
          .get();

      if (!phaseDoc.exists) return null;

      final phase = ProductionPhase.fromFirestore(phaseDoc);

      // Check if phase has SLA configured
      if (!phase.hasSLA || !phaseProgress.isInProgress) return null;

      // Calculate hours in current phase
      final hoursInPhase = phaseProgress.hoursInCurrentStatus;
      if (hoursInPhase == null) return null;

      final maxHours = phase.maxDurationHours!;
      final warningHours = phase.warningHours ?? (maxHours * 0.8).round();

      // Determine if alert is needed
      if (hoursInPhase >= maxHours) {
        // Critical: SLA exceeded
        final deviation = ((hoursInPhase - maxHours) / maxHours) * 100;
        
        return SLAAlert(
          id: '',
          organizationId: organizationId,
          entityType: SLAEntityType.product,
          entityId: productId,
          entityName: 'Product in ${phase.name}',
          alertType: SLAAlertType.slaExceeded,
          severity: SLAAlertSeverity.critical,
          currentValue: hoursInPhase.toDouble(),
          thresholdValue: maxHours.toDouble(),
          deviationPercent: deviation,
          createdAt: DateTime.now(),
          projectId: projectId,
          phaseId: phase.id,
          productId: productId,
        );
      } else if (hoursInPhase >= warningHours) {
        // Warning: Approaching SLA
        final percentComplete = (hoursInPhase / maxHours) * 100;
        
        return SLAAlert(
          id: '',
          organizationId: organizationId,
          entityType: SLAEntityType.product,
          entityId: productId,
          entityName: 'Product in ${phase.name}',
          alertType: SLAAlertType.slaWarning,
          severity: SLAAlertSeverity.warning,
          currentValue: hoursInPhase.toDouble(),
          thresholdValue: maxHours.toDouble(),
          deviationPercent: percentComplete,
          createdAt: DateTime.now(),
          projectId: projectId,
          phaseId: phase.id,
          productId: productId,
        );
      }

      return null;
    } catch (e) {
      print('Error checking product phase SLA: $e');
      return null;
    }
  }

  /// Scan all products in organization for SLA violations
  Future<List<SLAAlert>> scanOrganizationForSLAViolations(
    String organizationId,
  ) async {
    final alerts = <SLAAlert>[];

    try {
      // Get all projects
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .get();

      for (final projectDoc in projectsSnapshot.docs) {
        final projectId = projectDoc.id;

        // Get all products in project
        final productsSnapshot = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .get();

        for (final productDoc in productsSnapshot.docs) {
          final productId = productDoc.id;

          // Get phase progress
          final phases = await _phaseService.getProductPhaseProgress(
            organizationId,
            projectId,
            productId,
          );

          // Check each in-progress phase
          for (final phase in phases.where((p) => p.isInProgress)) {
            final alert = await checkProductPhaseSLA(
              organizationId,
              projectId,
              productId,
              phase,
            );

            if (alert != null) {
              alerts.add(alert);
            }
          }
        }
      }

      return alerts;
    } catch (e) {
      print('Error scanning organization for SLA violations: $e');
      return [];
    }
  }

  /// Create alerts for detected SLA violations
  Future<void> createAlertsForViolations(
    String organizationId,
    List<SLAAlert> alerts,
  ) async {
    try {
      for (final alert in alerts) {
        await createAlert(organizationId, alert);
      }
    } catch (e) {
      print('Error creating alerts for violations: $e');
      rethrow;
    }
  }

  /// Auto-resolve alerts that are no longer valid
  Future<void> autoResolveInvalidAlerts(String organizationId) async {
    try {
      // Get active alerts
      final alertsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .where('status', whereIn: [
            SLAAlertStatus.active.toMap(),
            SLAAlertStatus.acknowledged.toMap(),
          ])
          .get();

      for (final alertDoc in alertsSnapshot.docs) {
        final alert = SLAAlert.fromFirestore(alertDoc);

        // Check if entity still exists and is in problematic state
        bool shouldResolve = false;

        if (alert.entityType == SLAEntityType.product && alert.productId != null) {
          // Check if product still in problematic phase
          final phases = await _phaseService.getProductPhaseProgress(
            organizationId,
            alert.projectId!,
            alert.productId!,
          );

          final currentPhase = phases.firstWhere(
            (p) => p.phaseId == alert.phaseId,
            orElse: () => phases.first,
          );

          // Resolve if phase is completed or no longer in progress
          if (currentPhase.isCompleted || !currentPhase.isInProgress) {
            shouldResolve = true;
          }
        }

        if (shouldResolve) {
          await resolveAlert(
            organizationId,
            alert.id,
            notes: 'Auto-resolved: condition no longer applies',
          );
        }
      }
    } catch (e) {
      print('Error auto-resolving invalid alerts: $e');
    }
  }

  // ==================== STATISTICS ====================

  /// Get SLA compliance statistics for organization
  Future<Map<String, dynamic>> getSLAStatistics(
    String organizationId,
  ) async {
    try {
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));

      // Get all alerts from last 30 days
      final alertsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(last30Days))
          .get();

      final alerts = alertsSnapshot.docs
          .map((doc) => SLAAlert.fromFirestore(doc))
          .toList();

      final totalAlerts = alerts.length;
      final criticalAlerts = alerts.where((a) => a.isCritical).length;
      final warningAlerts = alerts.where((a) => a.isWarning).length;
      final resolvedAlerts = alerts.where((a) => a.isResolved).length;
      final activeAlerts = alerts.where((a) => a.isActive).length;

      final complianceRate = totalAlerts > 0
          ? ((totalAlerts - criticalAlerts) / totalAlerts) * 100
          : 100.0;

      return {
        'totalAlerts': totalAlerts,
        'criticalAlerts': criticalAlerts,
        'warningAlerts': warningAlerts,
        'resolvedAlerts': resolvedAlerts,
        'activeAlerts': activeAlerts,
        'complianceRate': complianceRate,
        'averageResolutionTime': _calculateAverageResolutionTime(alerts),
      };
    } catch (e) {
      print('Error getting SLA statistics: $e');
      return {
        'totalAlerts': 0,
        'criticalAlerts': 0,
        'warningAlerts': 0,
        'resolvedAlerts': 0,
        'activeAlerts': 0,
        'complianceRate': 100.0,
        'averageResolutionTime': 0.0,
      };
    }
  }

  double _calculateAverageResolutionTime(List<SLAAlert> alerts) {
    final resolvedAlerts = alerts.where((a) => a.isResolved && a.resolvedAt != null);
    
    if (resolvedAlerts.isEmpty) return 0.0;

    final totalHours = resolvedAlerts.fold<double>(
      0.0,
      (sum, alert) =>
          sum + alert.resolvedAt!.difference(alert.createdAt).inHours,
    );

    return totalHours / resolvedAlerts.length;
  }
}