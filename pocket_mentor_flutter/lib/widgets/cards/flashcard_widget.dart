import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/feed_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/extensions.dart';

class FlashCardWidget extends StatefulWidget {
  final FeedCard card;
  final bool isFlipped;
  final VoidCallback onTap;

  const FlashCardWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(FlashCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final angle = _animation.value * math.pi;
          final isFront = angle < math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? _CardFace(
                    card: widget.card,
                    isFront: true,
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _CardFace(
                      card: widget.card,
                      isFront: false,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final FeedCard card;
  final bool isFront;

  const _CardFace({required this.card, required this.isFront});

  @override
  Widget build(BuildContext context) {
    final topicColor = card.color;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: topicColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: topicColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top bar with topic info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: topicColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: topicColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.topicTitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: topicColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _DifficultyBadge(difficulty: card.difficulty),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFront ? 'Question' : 'Answer',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFront ? card.question : card.answer,
                    style: isFront
                        ? Theme.of(context).textTheme.titleLarge?.copyWith(
                              height: 1.5,
                              fontSize: _adaptiveFontSize(
                                  isFront ? card.question : card.answer),
                            )
                        : Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: AppTheme.textPrimary,
                              fontSize: _adaptiveFontSize(
                                  isFront ? card.question : card.answer),
                            ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isFront && card.hint != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.accent.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              size: 14, color: AppTheme.accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              card.hint!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.accent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom tap hint
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFront
                      ? Icons.touch_app_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: AppTheme.textDisabled,
                ),
                const SizedBox(width: 6),
                Text(
                  isFront ? 'Tap to reveal answer' : 'Rate your response below',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _adaptiveFontSize(String text) {
    if (text.length > 300) return 13;
    if (text.length > 150) return 15;
    if (text.length > 80) return 17;
    return 19;
  }
}

class _DifficultyBadge extends StatelessWidget {
  final int difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.difficultyColors[
        (difficulty - 1).clamp(0, AppTheme.difficultyColors.length - 1)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          difficulty.clamp(1, 5),
          (_) => Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
