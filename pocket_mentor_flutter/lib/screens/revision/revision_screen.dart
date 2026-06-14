import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/card_model.dart';
import '../../widgets/cards/flashcard_widget.dart';
import '../../widgets/cards/response_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/feed/session_summary_widget.dart';
import '../../utils/extensions.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RevisionFeedProvider>().loadFeed();
    });
  }

  Future<void> _handleResponse(SRSResponse response) async {
    final provider = context.read<RevisionFeedProvider>();
    await provider.submitResponse(response);

    if (provider.isDone) {
      final stats = provider.session;
      await context.read<ProgressProvider>().postSession(
        mode: 'revision',
        cardsReviewed: stats.cardsReviewed,
        cardsKnown: stats.cardsKnown,
        cardsUnknown: stats.cardsUnknown,
        durationSeconds: stats.durationSeconds,
        startedAt: stats.startedAt,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RevisionFeedProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Revision'),
            actions: [
              if (provider.overdue > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${provider.overdue} overdue',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, RevisionFeedProvider provider) {
    switch (provider.status) {
      case FeedStatus.loading:
        return const LoadingWidget(message: 'Loading revision cards…');

      case FeedStatus.empty:
        return EmptyStateWidget(
          icon: Icons.celebration_rounded,
          title: "You're all caught up!",
          subtitle:
              'No cards due for revision. Come back tomorrow to keep your streak going.',
          actionLabel: 'Go Back',
          onAction: () => Navigator.of(context).pop(),
        );

      case FeedStatus.loaded:
        if (provider.isDone) {
          return SessionSummaryWidget(
            stats: provider.session,
            mode: 'revision',
            onRestart: () => provider.loadFeed(),
            onHome: () => Navigator.of(context).pop(),
          );
        }
        return _RevisionContent(
          provider: provider,
          onResponse: _handleResponse,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _RevisionContent extends StatelessWidget {
  final RevisionFeedProvider provider;
  final Future<void> Function(SRSResponse) onResponse;

  const _RevisionContent({
    required this.provider,
    required this.onResponse,
  });

  @override
  Widget build(BuildContext context) {
    final card = provider.currentCard!;
    final srsInfo = card.intervalDays;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: provider.progress,
          backgroundColor: AppTheme.surfaceVariant,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppTheme.revisionColor),
          minHeight: 3,
        ),

        // Interval badge
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _IntervalBadge(intervalDays: srsInfo),
              const SizedBox(width: 8),
              _RepsBadge(repetitions: card.repetitions),
              const Spacer(),
              Text(
                '${provider.cards.length - provider.currentIndex} remaining',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ).animate().fadeIn(),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: FlashCardWidget(
              key: ValueKey(card.id),
              card: card,
              isFlipped: provider.isFlipped,
              onTap: provider.flipCard,
            ),
          ),
        ),

        ResponseBar(
          visible: provider.isFlipped,
          onResponse: onResponse,
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _IntervalBadge extends StatelessWidget {
  final int intervalDays;
  const _IntervalBadge({required this.intervalDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.revisionColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded,
              size: 12, color: AppTheme.revisionColor),
          const SizedBox(width: 4),
          Text(
            intervalDays.daysToInterval,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppTheme.revisionColor),
          ),
        ],
      ),
    );
  }
}

class _RepsBadge extends StatelessWidget {
  final int repetitions;
  const _RepsBadge({required this.repetitions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat_rounded,
              size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            '$repetitions reps',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
