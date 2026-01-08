import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/analytics/kpi_card.dart';

class MetricsDashboardScreen extends StatefulWidget {
  final String organizationId;
  final UserModel currentUser;

  const MetricsDashboardScreen({
    Key? key,
    required this.organizationId,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<MetricsDashboardScreen> createState() => _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  Map<String, dynamic>? _currentMetrics;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      final metrics = await _analyticsService.getCurrentMetrics(widget.organizationId);
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading metrics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
            tooltip: l10n.refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.loadingMetrics),
                ],
              ),
            )
          : _currentMetrics == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noDataAvailable,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMetrics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Section: Overview KPIs
                      _buildSectionHeader(l10n.overview, Icons.dashboard),
                      const SizedBox(height: 12),
                      _buildOverviewKPIs(l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Production Status
                      _buildSectionHeader(l10n.production, Icons.inventory_2),
                      const SizedBox(height: 12),
                      _buildProductionStatus(l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Projects Status
                      _buildSectionHeader(l10n.projects, Icons.folder),
                      const SizedBox(height: 12),
                      _buildProjectsStatus(l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Performance
                      _buildSectionHeader(l10n.performance, Icons.speed),
                      const SizedBox(height: 12),
                      _buildPerformanceMetrics(l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Products per Phase
                      _buildSectionHeader(l10n.productsPerPhase, Icons.workspaces),
                      const SizedBox(height: 12),
                      _buildProductsPerPhase(l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Bottlenecks
                      if (_hasBottlenecks()) ...[
                        _buildSectionHeader(l10n.bottlenecks, Icons.warning_amber),
                        const SizedBox(height: 12),
                        _buildBottlenecks(l10n),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewKPIs(AppLocalizations l10n) {
    final efficiencyScore = _analyticsService.calculateEfficiencyScore(_currentMetrics!);
    final slaCompliance = _currentMetrics!['slaComplianceRate'] as double;

    return Row(
      children: [
        Expanded(
          child: ScoreGauge(
            score: efficiencyScore,
            label: l10n.efficiencyScore,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CircularKPICard(
            title: l10n.slaCompliance,
            percentage: slaCompliance,
            icon: Icons.schedule,
            color: slaCompliance >= 90 ? Colors.green : Colors.orange,
            subtitle: '${slaCompliance.toStringAsFixed(1)}% on time',
          ),
        ),
      ],
    );
  }

  Widget _buildProductionStatus(AppLocalizations l10n) {
    final completed = _currentMetrics!['productsCompleted'] as int;
    final inProgress = _currentMetrics!['productsInProgress'] as int;
    final pending = _currentMetrics!['productsPending'] as int;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: KPICard(
                title: l10n.productsCompleted,
                value: completed.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KPICard(
                title: l10n.productsInProgress,
                value: inProgress.toString(),
                icon: Icons.sync,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        KPICard(
          title: l10n.productsPending,
          value: pending.toString(),
          icon: Icons.pending,
          color: Colors.grey,
          subtitle: 'Waiting to start',
        ),
      ],
    );
  }

  Widget _buildProjectsStatus(AppLocalizations l10n) {
    final active = _currentMetrics!['projectsActive'] as int;
    final completed = _currentMetrics!['projectsCompleted'] as int;
    final delayed = _currentMetrics!['projectsDelayed'] as int;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MiniKPICard(
                label: l10n.activeProjects,
                value: active.toString(),
                icon: Icons.folder_open,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MiniKPICard(
                label: l10n.completedProjects,
                value: completed.toString(),
                icon: Icons.check,
                color: Colors.green,
              ),
            ),
          ],
        ),
        if (delayed > 0) ...[
          const SizedBox(height: 8),
          MiniKPICard(
            label: l10n.delayedProjects,
            value: delayed.toString(),
            icon: Icons.warning,
            color: Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildPerformanceMetrics(AppLocalizations l10n) {
    final criticalAlerts = _currentMetrics!['criticalAlerts'] as int;
    final warningAlerts = _currentMetrics!['warningAlerts'] as int;
    final totalAlerts = criticalAlerts + warningAlerts;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: KPICard(
                title: l10n.criticalSeverity,
                value: criticalAlerts.toString(),
                icon: Icons.error,
                color: Colors.red,
                subtitle: 'SLA exceeded',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KPICard(
                title: l10n.warningSeverity,
                value: warningAlerts.toString(),
                icon: Icons.warning_amber,
                color: Colors.orange,
                subtitle: 'Approaching limit',
              ),
            ),
          ],
        ),
        if (totalAlerts == 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All products are on time!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductsPerPhase(AppLocalizations l10n) {
    final productsPerPhase = _currentMetrics!['productsPerPhase'] as Map<String, int>;

    if (productsPerPhase.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.noDataAvailable,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final sortedEntries = productsPerPhase.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sortedEntries.map((entry) {
            final total = productsPerPhase.values.reduce((a, b) => a + b);
            final percentage = (entry.value / total) * 100;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _hasBottlenecks() {
    final averageTimePerPhase = _currentMetrics!['averageTimePerPhase'] as Map<String, double>;
    return averageTimePerPhase.isNotEmpty;
  }

  Widget _buildBottlenecks(AppLocalizations l10n) {
    final averageTimePerPhase = _currentMetrics!['averageTimePerPhase'] as Map<String, double>;
    final bottlenecks = _analyticsService.getBottlenecks(averageTimePerPhase);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phases with longest average time',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ...bottlenecks.take(5).map((bottleneck) {
              final phaseName = bottleneck['phaseName'] as String;
              final averageHours = bottleneck['averageHours'] as double;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phaseName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${averageHours.toStringAsFixed(1)}h avg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}