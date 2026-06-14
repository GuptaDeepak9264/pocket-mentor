import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/topic_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/card_model.dart';
import '../../widgets/cards/flashcard_widget.dart';
import '../../widgets/cards/response_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/feed/session_summary_widget.dart';

class InterviewScreen extends StatefulWidget {
  final String? topicId;
  final int? difficulty;

  const InterviewScreen({super.key, this.topicId, this.difficulty});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  bool _sessionStarted = false;
  String? _selectedTopicId;
  int? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedTopicId = widget.topicId;
    _selectedDifficulty = widget.difficulty;

    // If launched with arguments, start immediately
    if (widget.topicId != null) {
      _sessionStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<InterviewFeedProvider>().loadFeed(
              topicId: widget.topicId,
              difficulty: widget.difficulty,
            );
      });
    }
  }

  void _startSession() {
    setState(() => _sessionStarted = true);
    context.read<InterviewFeedProvider>().loadFeed(
          topicId: _selectedTopicId,
          difficulty: _selectedDifficulty,
        );
  }

  Future<void> _handleResponse(SRSResponse response) async {
    final provider = context.read<InterviewFeedProvider>();
    await provider.submitResponse(response);

    if (provider.isDone) {
      final stats = provider.session;
      await context.read<ProgressProvider>().postSession(
        topicId: _selectedTopicId,
        mode: 'interview',
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
    if (!_sessionStarted) {
      return _InterviewSetupScreen(
        selectedTopicId: _selectedTopicId,
        selectedDifficulty: _selectedDifficulty,
        onTopicSelected: (id) => setState(() => _selectedTopicId = id),
        onDifficultySelected: (d) =>
            setState(() => _selectedDifficulty = d),
        onStart: _startSession,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    return Consumer<InterviewFeedProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                if (provider.isDone ||
                    provider.status == FeedStatus.empty) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _sessionStarted = false);
                }
              },
            ),
            title: const Text('Interview Prep'),
            actions: [
              if (!provider.isDone &&
                  provider.status == FeedStatus.loaded)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${provider.cards.length - provider.currentIndex} left',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppTheme.textSecondary),
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
      BuildContext context, InterviewFeedProvider provider) {
    switch (provider.status) {
      case FeedStatus.loading:
        return const LoadingWidget(message: 'Loading questions…');

      case FeedStatus.empty:
        return EmptyStateWidget(
          icon: Icons.work_outline_rounded,
          title: 'No interview cards',
          subtitle:
              'Create cards with type "interview" to use this mode.',
          actionLabel: 'Go Back',
          onAction: () => Navigator.of(context).pop(),
        );

      case FeedStatus.loaded:
        if (provider.isDone) {
          return SessionSummaryWidget(
            stats: provider.session,
            mode: 'interview',
            onRestart: () => _startSession(),
            onHome: () => Navigator.of(context).pop(),
          );
        }
        return _InterviewContent(
          provider: provider,
          onResponse: _handleResponse,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _InterviewSetupScreen extends StatelessWidget {
  final String? selectedTopicId;
  final int? selectedDifficulty;
  final void Function(String?) onTopicSelected;
  final void Function(int?) onDifficultySelected;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const _InterviewSetupScreen({
    required this.selectedTopicId,
    required this.selectedDifficulty,
    required this.onTopicSelected,
    required this.onDifficultySelected,
    required this.onStart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<TopicProvider>().topics;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: onBack,
        ),
        title: const Text('Interview Prep'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.interviewColor.withOpacity(0.15),
                    AppTheme.interviewColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.interviewColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.work_rounded,
                      size: 48, color: AppTheme.interviewColor),
                  const SizedBox(height: 12),
                  Text('Interview Mode',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Practice answering questions under interview conditions.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 32),

            Text('Topic', style: Theme.of(context).textTheme.titleMedium)
                .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All topics',
                  selected: selectedTopicId == null,
                  onTap: () => onTopicSelected(null),
                ),
                ...topics.map((t) => _FilterChip(
                      label: t.title,
                      selected: selectedTopicId == t.id,
                      onTap: () => onTopicSelected(t.id),
                      color: t.color,
                    )),
              ],
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 28),

            Text('Difficulty',
                    style: Theme.of(context).textTheme.titleMedium)
                .animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'Any',
                  selected: selectedDifficulty == null,
                  onTap: () => onDifficultySelected(null),
                ),
                ...List.generate(
                  5,
                  (i) => _FilterChip(
                    label: ['Easy', 'Normal', 'Medium', 'Hard', 'Expert'][i],
                    selected: selectedDifficulty == i + 1,
                    color: AppTheme.difficultyColors[i],
                    onTap: () => onDifficultySelected(i + 1),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.interviewColor,
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? c.withOpacity(0.4) : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? c : AppTheme.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

class _InterviewContent extends StatelessWidget {
  final InterviewFeedProvider provider;
  final Future<void> Function(SRSResponse) onResponse;

  const _InterviewContent({
    required this.provider,
    required this.onResponse,
  });

  @override
  Widget build(BuildContext context) {
    final card = provider.currentCard!;

    return Column(
      children: [
        LinearProgressIndicator(
          value: provider.progress,
          backgroundColor: AppTheme.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.interviewColor),
          minHeight: 3,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
