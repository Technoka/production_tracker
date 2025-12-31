import 'package:flutter/material.dart';
import '../models/phase_model.dart';
import '../services/phase_service.dart';

class PhaseProgressIndicator extends StatelessWidget {
  final String organizationId;
  final String projectId;
  final String productId;
  final bool showLabel;
  final double size;

  const PhaseProgressIndicator({
    Key? key,
    required this.organizationId,
    required this.projectId,
    required this.productId,
    this.showLabel = true,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phaseService = PhaseService();

    return StreamBuilder<List<ProductPhaseProgress>>(
      stream: phaseService.getProductPhaseProgressStream(
        organizationId,
        projectId,
        productId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.error_outline, size: size * 0.8, color: Colors.red),
          );
        }

        final phases = snapshot.data!;
        if (phases.isEmpty) {
          return SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.help_outline, size: size * 0.8, color: Colors.grey),
          );
        }

        final completedCount = phases.where((p) => p.isCompleted).length;
        final progress = completedCount / phases.length;
        final percentage = (progress * 100).round();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progress),
                    ),
                  ),
                ],
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                '$completedCount/${phases.length}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.33) return Colors.red;
    if (progress < 0.66) return Colors.orange;
    if (progress < 1.0) return Colors.blue;
    return Colors.green;
  }
}

class PhaseProgressSummary extends StatelessWidget {
  final String organizationId;
  final String projectId;
  final String productId;
  final VoidCallback? onTap;

  const PhaseProgressSummary({
    Key? key,
    required this.organizationId,
    required this.projectId,
    required this.productId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phaseService = PhaseService();

    return StreamBuilder<List<ProductPhaseProgress>>(
      stream: phaseService.getProductPhaseProgressStream(
        organizationId,
        projectId,
        productId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Cargando fases...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final phases = snapshot.data!;
        if (phases.isEmpty) return const SizedBox.shrink();

        final completedCount = phases.where((p) => p.isCompleted).length;
        final inProgressCount = phases.where((p) => p.isInProgress).length;
        final progress = completedCount / phases.length;

        return InkWell(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(progress),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(progress),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progreso de Producción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount completadas · $inProgressCount en proceso',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.33) return Colors.red;
    if (progress < 0.66) return Colors.orange;
    if (progress < 1.0) return Colors.blue;
    return Colors.green;
  }
}

class MiniPhaseIndicator extends StatelessWidget {
  final String organizationId;
  final String projectId;
  final String productId;

  const MiniPhaseIndicator({
    Key? key,
    required this.organizationId,
    required this.projectId,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phaseService = PhaseService();

    return StreamBuilder<List<ProductPhaseProgress>>(
      stream: phaseService.getProductPhaseProgressStream(
        organizationId,
        projectId,
        productId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final phases = snapshot.data!;
        final completedCount = phases.where((p) => p.isCompleted).length;
        final totalCount = phases.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getBackgroundColor(completedCount, totalCount),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 14,
                color: _getIconColor(completedCount, totalCount),
              ),
              const SizedBox(width: 4),
              Text(
                '$completedCount/$totalCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getIconColor(completedCount, totalCount),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(int completed, int total) {
    final progress = completed / total;
    if (progress < 0.33) return Colors.red.withOpacity(0.1);
    if (progress < 0.66) return Colors.orange.withOpacity(0.1);
    if (progress < 1.0) return Colors.blue.withOpacity(0.1);
    return Colors.green.withOpacity(0.1);
  }

  Color _getIconColor(int completed, int total) {
    final progress = completed / total;
    if (progress < 0.33) return Colors.red;
    if (progress < 0.66) return Colors.orange;
    if (progress < 1.0) return Colors.blue;
    return Colors.green;
  }
}