import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/card_model.dart';
import '../../theme/app_theme.dart';

class ResponseBar extends StatelessWidget {
  final bool visible;
  final void Function(SRSResponse) onResponse;

  const ResponseBar({
    super.key,
    required this.visible,
    required this.onResponse,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Animate(
      effects: const [FadeEffect(duration: Duration(milliseconds: 200))],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _ResponseButton(
                label: "Don't Know",
                icon: Icons.close_rounded,
                color: AppTheme.error,
                onTap: () => onResponse(SRSResponse.dontKnow),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ResponseButton(
                label: 'Got It',
                icon: Icons.check_rounded,
                color: AppTheme.secondary,
                onTap: () => onResponse(SRSResponse.know),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ResponseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
