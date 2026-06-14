import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/topic_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';
import '../../models/topic_model.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../notes/notes_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _DashboardTab(),
    _NotesTabWrapper(),
    _ProfileTabWrapper(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadSummary();
      context.read<ProgressProvider>().loadSessions();
      context.read<TopicProvider>().loadTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file_rounded),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _NotesTabWrapper extends StatelessWidget {
  const _NotesTabWrapper();
  @override
  Widget build(BuildContext context) => const NotesScreen(embedded: true);
}

class _ProfileTabWrapper extends StatelessWidget {
  const _ProfileTabWrapper();
  @override
  Widget build(BuildContext context) => const ProfileScreen(embedded: true);
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await context.read<ProgressProvider>().loadSummary();
          await context.read<TopicProvider>().loadTopics();
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _GreetingSection(),
                  const SizedBox(height: 24),
                  _DailyGoalCard(),
                  const SizedBox(height: 28),
                  _QuickActions(),
                  const SizedBox(height: 28),
                  _TopicsSection(),
                  const SizedBox(height: 28),
                  _RecentActivity(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Pocket Mentor',
              style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _GreetingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final summary = context.watch<ProgressProvider>().summary;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${user?.displayName.split(' ').first ?? 'Learner'} 👋',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          summary.streak.currentStreak > 0
              ? '🔥 ${summary.streak.currentStreak} day streak — keep it up!'
              : 'Start learning to build your streak',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _DailyGoalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProgressProvider>().summary;
    final progress = summary.todayProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Goal",
                  style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: summary.todayGoalMet
                      ? AppTheme.secondary.withOpacity(0.2)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary.todayGoalMet ? '✓ Done!' : 'In progress',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: summary.todayGoalMet
                            ? AppTheme.secondary
                            : AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                summary.todayGoalMet
                    ? AppTheme.secondary
                    : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${summary.todayCardsReviewed} / ${summary.todayGoal} cards',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetaChip(
                  icon: Icons.style_rounded,
                  label: '${summary.cardsDueToday} due today'),
              const SizedBox(width: 8),
              _MetaChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${summary.streak.currentStreak}d streak',
                  color: AppTheme.accent),
              const SizedBox(width: 8),
              _MetaChip(
                  icon: Icons.library_books_rounded,
                  label: '${summary.totalCardsInLibrary} cards'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip(
      {required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: c)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Study Modes',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.bolt_rounded,
                label: 'Learn',
                subtitle: 'New cards',
                color: AppTheme.learnColor,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.learn),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.refresh_rounded,
                label: 'Revision',
                subtitle: 'Due today',
                color: AppTheme.revisionColor,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.revision),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.work_rounded,
                label: 'Interview',
                subtitle: 'Prep mode',
                color: AppTheme.interviewColor,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.interview),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TopicProvider>(
      builder: (context, tp, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Topics',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => _showCreateTopicSheet(context),
                  child: const Text('+ New'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tp.isLoading)
              const ShimmerList(count: 3, itemHeight: 72)
            else if (tp.topics.isEmpty)
              EmptyStateWidget(
                icon: Icons.topic_rounded,
                title: 'No topics yet',
                subtitle: 'Create your first topic to start learning',
                actionLabel: 'Create Topic',
                onAction: () => _showCreateTopicSheet(context),
              )
            else
              ...tp.topics.map((topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TopicTile(topic: topic),
                  )),
          ],
        );
      },
    ).animate().fadeIn(delay: 300.ms);
  }

  void _showCreateTopicSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateTopicSheet(),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final TopicModel topic;
  const _TopicTile({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context)
            .pushNamed(AppRoutes.learn, arguments: {'topicId': topic.id}),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: topic.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topic.iconData, color: topic.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${topic.cardCount} cards',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateTopicSheet extends StatefulWidget {
  @override
  State<_CreateTopicSheet> createState() => _CreateTopicSheetState();
}

class _CreateTopicSheetState extends State<_CreateTopicSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedColor = '#6366F1';
  String _selectedIcon = 'book';
  bool _loading = false;

  static const _colors = [
    '#6366F1', '#10B981', '#F59E0B', '#EF4444',
    '#3B82F6', '#8B5CF6', '#EC4899', '#14B8A6',
  ];

  static const _icons = [
    'book', 'code', 'science', 'math',
    'language', 'history', 'business', 'brain',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final tp = context.read<TopicProvider>();
    await tp.createTopic(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      colorTag: _selectedColor,
      icon: _selectedIcon,
    );
    if (mounted) Navigator.of(context).pop();
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
          Text('New Topic',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(labelText: 'Topic name', hintText: 'e.g. Python Basics'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: 'Description (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text('Colour',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((hex) {
              final color = Color(int.parse('FF${hex.substring(1)}', radix: 16));
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _selectedColor == hex
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _create,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create Topic'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sessions =
        context.watch<ProgressProvider>().sessions;
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Sessions',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...sessions.take(3).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SessionTile(session: s),
            )),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _SessionTile extends StatelessWidget {
  final dynamic session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.style_rounded,
                color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(session.mode as String).toUpperCase()} session',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${session.cardsReviewed} cards · ${session.accuracyPercent.toStringAsFixed(0)}% accuracy',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
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
}
