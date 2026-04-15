import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BadgeStreak extends StatelessWidget {
  final int streak;

  const BadgeStreak({super.key, this.streak = 0});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.fire(PhosphorIconsStyle.fill),
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            streak.toString(),
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
