import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const AchievementBadge({super.key, required this.achievement});

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
          color: achievement.isUnlocked && !achievement.isRainbow
              ? (achievement.isMaxed 
                  ? Colors.amber.withOpacity(0.2)
                  : badgeColor.withOpacity(0.1))
              : (achievement.isRainbow && achievement.isUnlocked ? null : badgeColor.withOpacity(0.05)),
          gradient: (achievement.isUnlocked && achievement.isRainbow)
              ? const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: achievement.isUnlocked
                ? (achievement.isRainbow ? Colors.white.withOpacity(0.5) : (achievement.isMaxed ? Colors.amber : badgeColor))
                : badgeColor.withOpacity(0.5), 
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achievement.isMaxed 
                  ? Icons.workspace_premium
                  : (achievement.isUnlocked ? Icons.emoji_events : Icons.lock),
              size: 40,
              color: achievement.isUnlocked
                  ? (achievement.isMaxed 
                      ? Colors.amber
                      : badgeColor)
                  : badgeColor.withOpacity(0.7), // Use type color for lock icon
            ),
            const SizedBox(height: 4),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!achievement.isMaxed && achievement.progress != null && achievement.target != null) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: achievement.progressPercentage,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
              const SizedBox(height: 2),
              Text(
                '${achievement.progress}/${achievement.target}',
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
