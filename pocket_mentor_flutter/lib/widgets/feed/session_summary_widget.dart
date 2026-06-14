import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/extensions.dart';

class SessionSummaryWidget extends StatelessWidget {
  final SessionStats stats;
  final String mode;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const SessionSummaryWidget({
    super.key,
    required this.stats,
    required this.mode,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = stats.accuracy;
    final accuracyColor = accuracy >= 70
        ? AppTheme.secondary
        : accuracy >= 40
            ? AppTheme.accent
            : AppTheme.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Trophy icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.accent,
              size: 40,
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(),

          const SizedBox(height: 20),

          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.headlineMedium,
          )
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          Text(
            '${mode.toUpperCase()} SESSION',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  letterSpacing: 1.5,
                ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 36),

          // Stats grid
          Row(
            children: [
              _StatCard(
                label: 'Reviewed',
                value: '${stats.cardsReviewed}',
                icon: Icons.style_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Got It',
                value: '${stats.cardsKnown}',
                icon: Icons.check_circle_rounded,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Missed',
                value: '${stats.cardsUnknown}',
                icon: Icons.cancel_rounded,
                color: AppTheme.error,
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // Accuracy + time
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Accuracy',
                  value: accuracy.percentString,
                  icon: Icons.track_changes_rounded,
                  color: accuracyColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Time',
                  value: stats.durationSeconds.secondsToReadable,
                  icon: Icons.timer_outlined,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Study Again'),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Back to Home'),
          ).animate().fadeIn(delay: 650.ms),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
