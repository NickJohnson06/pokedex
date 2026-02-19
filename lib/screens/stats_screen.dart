import 'package:flutter/material.dart';
import '../models/collection_stats.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../repo/pokemon_repository.dart';
import '../services/pokedex_catalog.dart';
import '../widgets/achievement_badge.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AchievementService(
      repo: PokemonRepository(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Stats'),
      ),
      body: FutureBuilder<(CollectionStats, List<Achievement>)>(
        future: Future.wait([
          service.getCollectionStats(),
          service.getAchievements(),
        ]).then((results) => (results[0] as CollectionStats, results[1] as List<Achievement>)),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final (stats, achievements) = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOverallProgress(context, stats),
                const SizedBox(height: 24),
                _buildGenerationProgress(context, stats),
                const SizedBox(height: 24),
                _buildAchievements(context, achievements),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallProgress(BuildContext context, CollectionStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Overall Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${stats.totalCaught} / ${stats.totalAvailable}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats.completionPercentage / 100,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.completionPercentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationProgress(BuildContext context, CollectionStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress by Generation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...stats.byGeneration.entries.map((entry) {
              final genStats = entry.value;
              if (genStats.total == 0) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gen ${genStats.generation}'),
                        Text('${genStats.caught}/${genStats.total}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: genStats.percentage / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, List<Achievement> achievements) {
    final milestones = achievements.where((a) => a.category == AchievementCategory.milestone).toList();
    final special = achievements.where((a) => a.category == AchievementCategory.special).toList();
    final types = achievements.where((a) => a.category == AchievementCategory.type).toList();
    final generations = achievements.where((a) => a.category == AchievementCategory.generation).toList();
    
    final orderedAchievements = [...milestones, ...special, ...types, ...generations];
    
    // Filter: Show only the next un-unlocked tier for each series
    final inProgress = <Achievement>[];
    final locked = <Achievement>[];
    final seriesMap = <String, List<Achievement>>{};

    // Group by series
    for (final a in orderedAchievements) {
      String seriesId = a.id;
      if (a.id.startsWith('milestone_')) {
        seriesId = 'milestone';
      } else if (a.id.startsWith('type_')) {
        final parts = a.id.split('_');
        // id is type_fire_I or similar. extract type_fire
        if (parts.length >= 2) seriesId = '${parts[0]}_${parts[1]}';
      }
      seriesMap.putIfAbsent(seriesId, () => []).add(a);
    }

    // Process each series
    for (final group in seriesMap.values) {
      // Sort by target
      group.sort((a, b) => (a.target ?? 0).compareTo(b.target ?? 0));
      
      // Find the first achievement that is NOT unlocked
      try {
        final next = group.firstWhere((a) => !a.isUnlocked);
        // This is the next goal for this series
        if ((next.progress ?? 0) > 0) {
          inProgress.add(next);
        } else {
          locked.add(next);
        }
      } catch (_) {
        // All achievements in this series are unlocked!
      }
    }

    final totalEarned = orderedAchievements.where((a) => a.isUnlocked).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            //const SizedBox(height: 16),
            if (inProgress.isNotEmpty) ...[
              Text(
                'In-Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: inProgress.map((a) => AchievementBadge(achievement: a)).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (locked.isNotEmpty) ...[
              Text(
                'Locked',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: locked.map((a) => AchievementBadge(achievement: a)).toList(),
              ),
            ],
            if (inProgress.isEmpty && locked.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'All achievements maxed! 🎉',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
