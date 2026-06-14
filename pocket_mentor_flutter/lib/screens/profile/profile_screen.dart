import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';
import '../../models/progress_model.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadSummary();
      context.read<ProgressProvider>().loadHeatmap();
      context.read<ProgressProvider>().loadSessions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _ProfileHeader(),
          _StatsRow(),
          _TabBar(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _OverviewTab(),
                _HeatmapTab(),
                _SessionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AuthProvider>(),
        child: const _SettingsSheet(),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final summary = context.watch<ProgressProvider>().summary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                (user?.displayName.isNotEmpty == true)
                    ? user!.displayName[0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ).animate().scale(curve: Curves.elasticOut),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Learner',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StreakBadge(streak: summary.streak.currentStreak),
                    const SizedBox(width: 8),
                    if (summary.streak.longestStreak > 0)
                      _LongestStreakBadge(
                          streak: summary.streak.longestStreak),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 13, color: AppTheme.accent),
          const SizedBox(width: 4),
          Text(
            '$streak day${streak != 1 ? 's' : ''}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppTheme.accent),
          ),
        ],
      ),
    );
  }
}

class _LongestStreakBadge extends StatelessWidget {
  final int streak;
  const _LongestStreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              size: 13, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            'Best: $streak',
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

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProgressProvider>().summary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _StatBox(
            value: '${summary.streak.totalCardsReviewed}',
            label: 'Total Cards',
            icon: Icons.style_rounded,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 10),
          _StatBox(
            value: '${summary.streak.totalSessions}',
            label: 'Sessions',
            icon: Icons.play_circle_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(width: 10),
          _StatBox(
            value: '${summary.totalCardsInLibrary}',
            label: 'In Library',
            icon: Icons.library_books_rounded,
            color: AppTheme.accent,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Activity'),
          Tab(text: 'Sessions'),
        ],
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProgressProvider>().summary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // Today goal card
        _TodayCard(summary: summary),
        const SizedBox(height: 20),

        Text('Topic Progress',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        if (summary.topicProgress.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No topics yet. Create topics and start learning to see progress here.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...summary.topicProgress.map(
            (tp) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TopicProgressCard(progress: tp),
            ),
          ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final ProgressSummary summary;
  const _TodayCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final progress = summary.todayProgress;
    final color =
        summary.todayGoalMet ? AppTheme.secondary : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Progress",
                  style: Theme.of(context).textTheme.titleMedium),
              if (summary.todayGoalMet)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: AppTheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Goal met!',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppTheme.secondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${summary.todayCardsReviewed} of ${summary.todayGoal} cards',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicProgressCard extends StatelessWidget {
  final TopicProgress progress;
  const _TopicProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(progress.topicColor);
    final mastery = progress.masteryPercent / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.topicTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.masteryPercent.toStringAsFixed(0)}%',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: mastery,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ProgressChip(
                label: '${progress.cardsKnown}/${progress.totalCards} known',
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              if (progress.cardsDueToday > 0)
                _ProgressChip(
                  label: '${progress.cardsDueToday} due',
                  color: AppTheme.accent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ProgressChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color),
      ),
    );
  }
}

// ── Heatmap tab ───────────────────────────────────────────────────────────────

class _HeatmapTab extends StatelessWidget {
  const _HeatmapTab();

  @override
  Widget build(BuildContext context) {
    final heatmap = context.watch<ProgressProvider>().heatmap;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text('Activity Heatmap',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Last 90 days of learning activity',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        if (heatmap.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No activity yet. Start studying to see your progress here.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          _HeatmapGrid(entries: heatmap),
        const SizedBox(height: 24),
        _HeatmapLegend(),
      ],
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final List<HeatmapEntry> entries;
  const _HeatmapGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Build a map for quick lookup
    final entryMap = {
      for (final e in entries)
        '${e.date.year}-${e.date.month}-${e.date.day}': e,
    };

    final maxCards = entries.isEmpty
        ? 1
        : entries
            .map((e) => e.cardsReviewed)
            .reduce((a, b) => a > b ? a : b);

    // Build 13 weeks x 7 days grid (91 days)
    final now = DateTime.now();
    final cells = <Widget>[];

    for (int week = 12; week >= 0; week--) {
      final col = <Widget>[];
      for (int day = 6; day >= 0; day--) {
        final date = now.subtract(Duration(days: week * 7 + day));
        final key = '${date.year}-${date.month}-${date.day}';
        final entry = entryMap[key];
        final intensity = entry == null
            ? 0.0
            : (entry.cardsReviewed / maxCards).clamp(0.0, 1.0);

        col.add(
          Tooltip(
            message: entry != null
                ? '${date.shortDate}: ${entry.cardsReviewed} cards'
                : date.shortDate,
            child: Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: intensity == 0
                    ? AppTheme.surfaceVariant
                    : AppTheme.primary.withOpacity(0.15 + intensity * 0.85),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }
      cells.add(Column(children: col.reversed.toList()));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cells,
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less',
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 6),
        ...List.generate(5, (i) {
          final opacity = 0.15 + (i / 4) * 0.85;
          return Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == 0
                  ? AppTheme.surfaceVariant
                  : AppTheme.primary.withOpacity(opacity),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text('More',
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

// ── Sessions tab ──────────────────────────────────────────────────────────────

class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<ProgressProvider>().sessions;

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No sessions yet. Start learning to see your session history here.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SessionCard(session: s),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final dynamic session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final mode = session.mode as String;
    final color = mode == 'learn'
        ? AppTheme.learnColor
        : mode == 'revision'
            ? AppTheme.revisionColor
            : AppTheme.interviewColor;

    final accuracy = session.accuracyPercent as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_modeIcon(mode), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mode[0].toUpperCase()}${mode.substring(1)} session',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${session.cardsReviewed} cards',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTheme.textDisabled,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${accuracy.toStringAsFixed(0)}% accuracy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: accuracy >= 70
                                ? AppTheme.secondary
                                : accuracy >= 40
                                    ? AppTheme.accent
                                    : AppTheme.error,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTheme.textDisabled,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (session.durationSeconds as int).secondsToReadable,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            (session.startedAt as DateTime).relativeTime,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'revision': return Icons.refresh_rounded;
      case 'interview': return Icons.work_rounded;
      default: return Icons.bolt_rounded;
    }
  }
}

// ── Settings sheet ────────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late TextEditingController _nameCtrl;
  late int _dailyGoal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl =
        TextEditingController(text: user?.displayName ?? '');
    _dailyGoal = user?.settings.dailyGoal ?? 20;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      displayName: _nameCtrl.text.trim(),
      settings: {'daily_goal': _dailyGoal},
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    Navigator.of(context).pop();
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Settings',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          // Display name
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon:
                  Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Daily goal
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily goal',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text('Cards per day',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _dailyGoal > 5
                        ? () => setState(() => _dailyGoal -= 5)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceVariant,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_dailyGoal',
                      style:
                          Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: _dailyGoal < 200
                        ? () => setState(() => _dailyGoal += 5)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
