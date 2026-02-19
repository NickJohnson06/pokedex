import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final int? progress;
  final int? target;
  final AchievementCategory category;
  final String? currentTier;
  final int? maxTier;
  final Color? color;
  final bool isRainbow;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.isUnlocked,
    this.progress,
    this.target,
    required this.category,
    this.currentTier,
    this.maxTier,
    this.color,
    this.isRainbow = false,
  });

  double get progressPercentage {
    if (progress == null || target == null || target == 0) return 0.0;
    return (progress! / target!).clamp(0.0, 1.0);
  }

  bool get isMaxed => 
    isUnlocked && (currentTier == 'MAX' || currentTier == 'III' || currentTier == 'V' || currentTier == maxTier.toString());
}

enum AchievementCategory {
  generation,
  type,
  milestone,
  special,
}
