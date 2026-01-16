import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/phase_model.dart';
import 'phase_service.dart';

/// Modelo para métricas diarias/mensuales
class AnalyticsSnapshot {
  final String id;
  final String organizationId;
  final DateTime period;
  final String periodType; // 'daily' o 'monthly'
  
  // Producción
  final int productsCompleted;
  final int productsInProgress;
  final int productsPending;
  
  // Proyectos
  final int projectsCompleted;
  final int projectsActive;
  final int projectsDelayed;
  
  // Fases
  final Map<String, int> productsPerPhase;
  final Map<String, double> averageTimePerPhase;
  
  // SLA
  final double slaComplianceRate;
  final int criticalAlerts;
  final int warningAlerts;
  
  // Financiero (opcional)
  final double? revenue;
  final double? pendingRevenue;
  
  final DateTime createdAt;

  AnalyticsSnapshot({
    required this.id,
    required this.organizationId,
    required this.period,
    required this.periodType,
    required this.productsCompleted,
    required this.productsInProgress,
    required this.productsPending,
    required this.projectsCompleted,
    required this.projectsActive,
    required this.projectsDelayed,
    required this.productsPerPhase,
    required this.averageTimePerPhase,
    required this.slaComplianceRate,
    required this.criticalAlerts,
    required this.warningAlerts,
    this.revenue,
    this.pendingRevenue,
    required this.createdAt,
  });

  factory AnalyticsSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsSnapshot(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      period: (data['period'] as Timestamp).toDate(),
      periodType: data['periodType'] ?? 'daily',
      productsCompleted: data['productsCompleted'] ?? 0,
      productsInProgress: data['productsInProgress'] ?? 0,
      productsPending: data['productsPending'] ?? 0,
      projectsCompleted: data['projectsCompleted'] ?? 0,
      projectsActive: data['projectsActive'] ?? 0,
      projectsDelayed: data['projectsDelayed'] ?? 0,
      productsPerPhase: Map<String, int>.from(data['productsPerPhase'] ?? {}),
      averageTimePerPhase: (data['averageTimePerPhase'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {},
      slaComplianceRate: (data['slaComplianceRate'] ?? 0).toDouble(),
      criticalAlerts: data['criticalAlerts'] ?? 0,
      warningAlerts: data['warningAlerts'] ?? 0,
      revenue: data['revenue']?.toDouble(),
      pendingRevenue: data['pendingRevenue']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'period': Timestamp.fromDate(period),
      'periodType': periodType,
      'productsCompleted': productsCompleted,
      'productsInProgress': productsInProgress,
      'productsPending': productsPending,
      'projectsCompleted': projectsCompleted,
      'projectsActive': projectsActive,
      'projectsDelayed': projectsDelayed,
      'productsPerPhase': productsPerPhase,
      'averageTimePerPhase': averageTimePerPhase,
      'slaComplianceRate': slaComplianceRate,
      'criticalAlerts': criticalAlerts,
      'warningAlerts': warningAlerts,
      'revenue': revenue,
      'pendingRevenue': pendingRevenue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PhaseService _phaseService = PhaseService();

  // ==================== REAL-TIME ANALYTICS ====================

  /// Get current organization metrics (calculated in real-time)
  Future<Map<String, dynamic>> getCurrentMetrics(String organizationId) async {
    try {
      // Get all projects
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .get();

      int projectsActive = 0;
      int projectsCompleted = 0;
      int projectsDelayed = 0;

      int productsCompleted = 0;
      int productsInProgress = 0;
      int productsPending = 0;

      final productsPerPhase = <String, int>{};
      final phaseCompletionTimes = <String, List<double>>{};

      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final status = projectData['status'] ?? '';

        // Count projects
        if (status == 'completed') {
          projectsCompleted++;
        } else {
          projectsActive++;
          if (projectData['isDelayed'] == true) {
            projectsDelayed++;
          }
        }

        // Get products in project
        final productsSnapshot = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(projectDoc.id)
            .collection('batch_products')
            .get();

        for (final productDoc in productsSnapshot.docs) {
          final productData = productDoc.data();
          final productStatus = productData['status'] ?? '';

          // Count products by status
          if (productStatus == 'completed') {
            productsCompleted++;
          } else if (productStatus == 'in_progress') {
            productsInProgress++;
          } else {
            productsPending++;
          }

          // Get phase progress
          final phasesSnapshot = await _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('projects')
              .doc(projectDoc.id)
              .collection('products')
              .doc(productDoc.id)
              .collection('phaseProgress')
              .get();

          for (final phaseDoc in phasesSnapshot.docs) {
            final phaseData = phaseDoc.data();
            final phaseId = phaseData['phaseId'] ?? '';
            final phaseName = phaseData['phaseName'] ?? '';
            final status = phaseData['status'] ?? '';

            // Count products per phase (in progress)
            if (status == 'inProgress') {
              productsPerPhase[phaseName] = (productsPerPhase[phaseName] ?? 0) + 1;
            }

            // Calculate completion times
            if (status == 'completed' &&
                phaseData['startedAt'] != null &&
                phaseData['completedAt'] != null) {
              final startedAt = (phaseData['startedAt'] as Timestamp).toDate();
              final completedAt = (phaseData['completedAt'] as Timestamp).toDate();
              final hours = completedAt.difference(startedAt).inHours.toDouble();

              if (!phaseCompletionTimes.containsKey(phaseName)) {
                phaseCompletionTimes[phaseName] = [];
              }
              phaseCompletionTimes[phaseName]!.add(hours);
            }
          }
        }
      }

      // Calculate average time per phase
      final averageTimePerPhase = <String, double>{};
      phaseCompletionTimes.forEach((phaseName, times) {
        if (times.isNotEmpty) {
          final average = times.reduce((a, b) => a + b) / times.length;
          averageTimePerPhase[phaseName] = average;
        }
      });

      // Get SLA alerts
      final alertsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('sla_alerts')
          .where('status', whereIn: ['active', 'acknowledged'])
          .get();

      int criticalAlerts = 0;
      int warningAlerts = 0;

      for (final alertDoc in alertsSnapshot.docs) {
        final severity = alertDoc.data()['severity'] ?? '';
        if (severity == 'critical') {
          criticalAlerts++;
        } else {
          warningAlerts++;
        }
      }

      // Calculate SLA compliance rate
      final totalProducts = productsCompleted + productsInProgress;
      final productsWithIssues = criticalAlerts; // Simplificado
      final slaComplianceRate = totalProducts > 0
          ? ((totalProducts - productsWithIssues) / totalProducts) * 100
          : 100.0;

      return {
        'projectsActive': projectsActive,
        'projectsCompleted': projectsCompleted,
        'projectsDelayed': projectsDelayed,
        'productsCompleted': productsCompleted,
        'productsInProgress': productsInProgress,
        'productsPending': productsPending,
        'productsPerPhase': productsPerPhase,
        'averageTimePerPhase': averageTimePerPhase,
        'slaComplianceRate': slaComplianceRate,
        'criticalAlerts': criticalAlerts,
        'warningAlerts': warningAlerts,
        'totalAlerts': criticalAlerts + warningAlerts,
      };
    } catch (e) {
      print('Error getting current metrics: $e');
      return {
        'projectsActive': 0,
        'projectsCompleted': 0,
        'projectsDelayed': 0,
        'productsCompleted': 0,
        'productsInProgress': 0,
        'productsPending': 0,
        'productsPerPhase': <String, int>{},
        'averageTimePerPhase': <String, double>{},
        'slaComplianceRate': 100.0,
        'criticalAlerts': 0,
        'warningAlerts': 0,
        'totalAlerts': 0,
      };
    }
  }

  // ==================== HISTORICAL ANALYTICS ====================

  /// Get daily analytics snapshot
  Stream<AnalyticsSnapshot?> getDailyAnalyticsStream(
    String organizationId,
    DateTime date,
  ) {
    final dateStr = _formatDate(date);
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('analytics')
        .doc('daily')
        .collection('snapshots')
        .doc(dateStr)
        .snapshots()
        .map((doc) => doc.exists ? AnalyticsSnapshot.fromFirestore(doc) : null);
  }

  /// Get monthly analytics snapshot
  Stream<AnalyticsSnapshot?> getMonthlyAnalyticsStream(
    String organizationId,
    DateTime month,
  ) {
    final monthStr = _formatMonth(month);
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('analytics')
        .doc('monthly')
        .collection('snapshots')
        .doc(monthStr)
        .snapshots()
        .map((doc) => doc.exists ? AnalyticsSnapshot.fromFirestore(doc) : null);
  }

  /// Get range of daily analytics
  Future<List<AnalyticsSnapshot>> getDailyAnalyticsRange(
    String organizationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('analytics')
          .doc('daily')
          .collection('snapshots')
          .where('period', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('period', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('period')
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsSnapshot.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting daily analytics range: $e');
      return [];
    }
  }

  /// Get last N days of analytics
  Future<List<AnalyticsSnapshot>> getLastNDays(
    String organizationId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getDailyAnalyticsRange(organizationId, startDate, endDate);
  }

  /// Get range of monthly analytics
  Future<List<AnalyticsSnapshot>> getMonthlyAnalyticsRange(
    String organizationId,
    DateTime startMonth,
    DateTime endMonth,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('analytics')
          .doc('monthly')
          .collection('snapshots')
          .where('period', isGreaterThanOrEqualTo: Timestamp.fromDate(startMonth))
          .where('period', isLessThanOrEqualTo: Timestamp.fromDate(endMonth))
          .orderBy('period')
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsSnapshot.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting monthly analytics range: $e');
      return [];
    }
  }

  /// Get last N months of analytics
  Future<List<AnalyticsSnapshot>> getLastNMonths(
    String organizationId,
    int months,
  ) async {
    final endMonth = DateTime.now();
    final startMonth = DateTime(endMonth.year, endMonth.month - months, 1);
    return getMonthlyAnalyticsRange(organizationId, startMonth, endMonth);
  }

  // ==================== TREND ANALYSIS ====================

  /// Calculate productivity trend (comparing periods)
  Map<String, dynamic> calculateTrend(
    List<AnalyticsSnapshot> snapshots,
  ) {
    if (snapshots.length < 2) {
      return {
        'trend': 'insufficient_data',
        'percentageChange': 0.0,
        'direction': 'neutral',
      };
    }

    // Compare last period vs previous
    final latest = snapshots.last;
    final previous = snapshots[snapshots.length - 2];

    final latestTotal = latest.productsCompleted;
    final previousTotal = previous.productsCompleted;

    if (previousTotal == 0) {
      return {
        'trend': 'no_comparison',
        'percentageChange': 0.0,
        'direction': 'neutral',
      };
    }

    final percentageChange = ((latestTotal - previousTotal) / previousTotal) * 100;

    String direction;
    if (percentageChange > 5) {
      direction = 'up';
    } else if (percentageChange < -5) {
      direction = 'down';
    } else {
      direction = 'stable';
    }

    return {
      'trend': 'calculated',
      'percentageChange': percentageChange,
      'direction': direction,
      'latestValue': latestTotal,
      'previousValue': previousTotal,
    };
  }

  /// Get bottleneck phases (fases con más tiempo promedio)
  List<Map<String, dynamic>> getBottlenecks(
    Map<String, double> averageTimePerPhase,
  ) {
    final bottlenecks = <Map<String, dynamic>>[];

    final sorted = averageTimePerPhase.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted) {
      bottlenecks.add({
        'phaseName': entry.key,
        'averageHours': entry.value,
      });
    }

    return bottlenecks;
  }

  /// Calculate efficiency score (0-100)
  double calculateEfficiencyScore(Map<String, dynamic> metrics) {
    double score = 100.0;

    // Penalizar por alertas críticas (-5 por cada una)
    final criticalAlerts = metrics['criticalAlerts'] as int? ?? 0;
    score -= (criticalAlerts * 5).clamp(0, 30);

    // Penalizar por proyectos retrasados (-3 por cada uno)
    final delayedProjects = metrics['projectsDelayed'] as int? ?? 0;
    score -= (delayedProjects * 3).clamp(0, 20);

    // Bonus por SLA compliance
    final slaRate = metrics['slaComplianceRate'] as double? ?? 100.0;
    if (slaRate >= 95) {
      score += 10;
    } else if (slaRate < 80) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // ==================== PHASE PERFORMANCE ====================

  /// Get detailed phase performance metrics
  Future<Map<String, dynamic>> getPhasePerformance(
    String organizationId,
    String phaseId,
  ) async {
    try {
      final projectsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .get();

      final completionTimes = <double>[];
      int totalProducts = 0;
      int completedProducts = 0;
      int delayedProducts = 0;

      for (final projectDoc in projectsSnapshot.docs) {
        final productsSnapshot = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('projects')
            .doc(projectDoc.id)
            .collection('products')
            .get();

        for (final productDoc in productsSnapshot.docs) {
          final phaseDoc = await _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('projects')
              .doc(projectDoc.id)
              .collection('products')
              .doc(productDoc.id)
              .collection('phaseProgress')
              .doc(phaseId)
              .get();

          if (!phaseDoc.exists) continue;

          final phaseData = phaseDoc.data()!;
          totalProducts++;

          if (phaseData['status'] == 'completed') {
            completedProducts++;

            if (phaseData['startedAt'] != null && phaseData['completedAt'] != null) {
              final startedAt = (phaseData['startedAt'] as Timestamp).toDate();
              final completedAt = (phaseData['completedAt'] as Timestamp).toDate();
              final hours = completedAt.difference(startedAt).inHours.toDouble();
              completionTimes.add(hours);
            }
          }
        }
      }

      // Calculate statistics
      double averageTime = 0;
      double minTime = 0;
      double maxTime = 0;

      if (completionTimes.isNotEmpty) {
        averageTime = completionTimes.reduce((a, b) => a + b) / completionTimes.length;
        minTime = completionTimes.reduce((a, b) => a < b ? a : b);
        maxTime = completionTimes.reduce((a, b) => a > b ? a : b);
      }

      return {
        'totalProducts': totalProducts,
        'completedProducts': completedProducts,
        'completionRate': totalProducts > 0 ? (completedProducts / totalProducts) * 100 : 0,
        'averageTime': averageTime,
        'minTime': minTime,
        'maxTime': maxTime,
        'delayedProducts': delayedProducts,
      };
    } catch (e) {
      print('Error getting phase performance: $e');
      return {
        'totalProducts': 0,
        'completedProducts': 0,
        'completionRate': 0.0,
        'averageTime': 0.0,
        'minTime': 0.0,
        'maxTime': 0.0,
        'delayedProducts': 0,
      };
    }
  }
}