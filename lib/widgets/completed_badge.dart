import 'package:flutter/material.dart';
import '../models/achievement.dart';

/// Badge widget for displaying completed achievements without progress bars
/// Used in the Settings Badge Showcase
class CompletedBadge extends StatelessWidget {
  final Achievement achievement;

  const CompletedBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final displayName = achievement.isMaxed 
        ? '${achievement.name} ⭐' 
        : achievement.name;
    
    // Use achievement color if available, otherwise use theme color
    final badgeColor = achievement.color ?? Theme.of(context).primaryColor;
    
    return Tooltip(
      message: achievement.description,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: achievement.isMaxed 
              ? Colors.amber.withOpacity(0.2)
              : badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: achievement.isMaxed 
                ? Colors.amber
                : badgeColor,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achievement.isMaxed 
                  ? Icons.workspace_premium
                  : Icons.emoji_events,
              size: 40,
              color: achievement.isMaxed 
                  ? Colors.amber
                  : badgeColor,
            ),
            const SizedBox(height: 4),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
