import 'package:flutter/material.dart';
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

class LearnFeedScreen extends StatefulWidget {
  final String? topicId;
  const LearnFeedScreen({super.key, this.topicId});

  @override
  State<LearnFeedScreen> createState() => _LearnFeedScreenState();
}

class _LearnFeedScreenState extends State<LearnFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<LearnFeedProvider>()
          .loadFeed(topicId: widget.topicId);
    });
  }

  Future<void> _handleResponse(SRSResponse response) async {
    final provider = context.read<LearnFeedProvider>();
    await provider.submitResponse(response);

    // If session is done, save it
    if (provider.isDone) {
      final stats = provider.session;
      await context.read<ProgressProvider>().postSession(
        topicId: widget.topicId,
        mode: 'learn',
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
    return Consumer<LearnFeedProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: _buildAppBar(context, provider),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, LearnFeedProvider provider) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Learn'),
      actions: [
        if (provider.status == FeedStatus.loaded &&
            !provider.isDone)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${provider.remaining} left',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, LearnFeedProvider provider) {
    switch (provider.status) {
      case FeedStatus.loading:
        return const LoadingWidget(message: 'Loading cards…');

      case FeedStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(provider.error ?? 'Something went wrong'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    provider.loadFeed(topicId: widget.topicId),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case FeedStatus.empty:
        return EmptyStateWidget(
          icon: Icons.check_circle_rounded,
          title: 'All caught up!',
          subtitle: 'No cards available. Create some cards or upload notes.',
          actionLabel: 'Go Back',
          onAction: () => Navigator.of(context).pop(),
        );

      case FeedStatus.loaded:
        if (provider.isDone) {
          return SessionSummaryWidget(
            stats: provider.session,
            mode: 'learn',
            onRestart: () =>
                provider.loadFeed(topicId: widget.topicId),
            onHome: () => Navigator.of(context).pop(),
          );
        }
        return _LearnContent(
          provider: provider,
          onResponse: _handleResponse,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _LearnContent extends StatelessWidget {
  final LearnFeedProvider provider;
  final Future<void> Function(SRSResponse) onResponse;

  const _LearnContent({
    required this.provider,
    required this.onResponse,
  });

  @override
  Widget build(BuildContext context) {
    final card = provider.currentCard!;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: provider.progress,
          backgroundColor: AppTheme.surfaceVariant,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppTheme.learnColor),
          minHeight: 3,
        ),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
