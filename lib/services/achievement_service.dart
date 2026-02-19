import 'package:flutter/material.dart';
import '../models/collection_stats.dart';
import '../models/achievement.dart';
import '../repo/pokemon_repository.dart';
import '../utils/type_colors.dart';
import 'pokedex_catalog.dart';

class AchievementService {
  final PokemonRepository _repository;
  final PokedexCatalog _catalog;

  AchievementService({
    required PokemonRepository repo,
    PokedexCatalog? catalog,
  }) : _repository = repo,
       _catalog = catalog ?? PokedexCatalog.instance;

  Future<CollectionStats> getCollectionStats() async {
    final allPokemon = await _repository.getAll();
    final totalCaught = allPokemon.length;
    
    // Type distribution
    final byType = <String, int>{};
    for (final pokemon in allPokemon) {
      // Count primary type
      byType[pokemon.type] = (byType[pokemon.type] ?? 0) + 1;
      // Count secondary type if exists
      if (pokemon.type2 != null && pokemon.type2!.isNotEmpty) {
        byType[pokemon.type2!] = (byType[pokemon.type2!] ?? 0) + 1;
      }
    }
    
    // Generation progress
    final Map<int, int> caughtByGen = {};
    for (final pokemon in allPokemon) {
      if (pokemon.dex != null) { // Only count if dex ID is present
        final gen = _getGeneration(pokemon.dex!);
        caughtByGen[gen] = (caughtByGen[gen] ?? 0) + 1;
      }
    }
    
    final Map<int, GenerationStats> byGeneration = {};
    for (int gen = 1; gen <= 9; gen++) {
      final total = _getTotalPokemonForGeneration(gen);
      final caught = caughtByGen[gen] ?? 0;
      byGeneration[gen] = GenerationStats(
        generation: gen,
        caught: caught,
        total: total,
        percentage: total > 0 ? (caught / total * 100) : 0,
      );
    }
    
    return CollectionStats(
      totalCaught: totalCaught,
      totalAvailable: 1025, // Total Pokemon in National Dex
      byType: byType,
      byGeneration: byGeneration,
      completionPercentage: (totalCaught / 1025 * 100),
    );
  }

  int _getGeneration(int id) {
    if (id <= 151) return 1;
    if (id <= 251) return 2;
    if (id <= 386) return 3;
    if (id <= 493) return 4;
    if (id <= 649) return 5;
    if (id <= 721) return 6;
    if (id <= 809) return 7;
    if (id <= 905) return 8;
    return 9;
  }
  
  int _getTotalPokemonForGeneration(int gen) {
    switch (gen) {
      case 1: return 151;
      case 2: return 100;
      case 3: return 135;
      case 4: return 107;
      case 5: return 156;
      case 6: return 72;
      case 7: return 88;
      case 8: return 96;
      case 9: return 120; // Approx
      default: return 0;
    }
  }

  Future<List<Achievement>> getAchievements() async {
    final stats = await getCollectionStats();
    final achievements = <Achievement>[];
    
    // Add all milestone tier achievements
    achievements.addAll(_getMilestoneAchievements(stats.totalCaught));
    
    // Add special achievements
    achievements.addAll(_getSpecialAchievements(stats.totalCaught));
    
    // Add all type tier achievements
    achievements.addAll(_getTypeAchievements(stats.byType));
    
    return achievements;
  }

  List<Achievement> _getMilestoneAchievements(int totalCaught) {
    final achievements = <Achievement>[];
    
    // Define all milestone tiers
    final tiers = [
      {'id': 'milestone_1', 'name': 'Aspiring Trainer', 'target': 10, 'tier': 'I'},
      {'id': 'milestone_2', 'name': 'Getting Started', 'target': 50, 'tier': 'II'},
      {'id': 'milestone_3', 'name': 'Collector', 'target': 100, 'tier': 'III'},
      {'id': 'milestone_4', 'name': 'Elite Trainer', 'target': 200, 'tier': 'IV'},
      {'id': 'milestone_5', 'name': 'Pokedex Enthusiast', 'target': 500, 'tier': 'V'},
    ];
    
    for (int i = 0; i < tiers.length; i++) {
      final tier = tiers[i];
      final target = tier['target'] as int;
      final isUnlocked = totalCaught >= target;
      
      final tierIndex = i;
      Color? tierColor;
      switch (tierIndex) {
        case 0: tierColor = const Color(0xFFCD7F32); break; // Bronze
        case 1: tierColor = const Color(0xFFC0C0C0); break; // Silver
        case 2: tierColor = const Color(0xFFFFD700); break; // Gold
        case 3: tierColor = const Color(0xFFE5E4E2); break; // Platinum
        case 4: tierColor = const Color(0xFFB9F2FF); break; // Diamond
      }

      achievements.add(Achievement(
        id: tier['id'] as String,
        name: tier['name'] as String,
        description: isUnlocked
            ? 'You caught ${tier['target']} Pokemon!'
            : 'Catch ${tier['target']} Pokemon',
        iconPath: 'assets/badges/milestone.png',
        isUnlocked: isUnlocked,
        progress: totalCaught,
        target: target,
        category: AchievementCategory.milestone,
        currentTier: isUnlocked ? (tier['tier'] as String) : null,
        maxTier: 5,
        color: tierColor,
      ));
    }
    
    return achievements;
  }

  List<Achievement> _getSpecialAchievements(int totalCaught) {
    const nationalPokedexTotal = 1025;
    
    return [
      Achievement(
        id: 'special_national_dex',
        name: 'Gotta Catch \'Em All',
        description: totalCaught >= nationalPokedexTotal
            ? 'You caught every Pokemon in the National Pokedex!'
            : 'Catch all $nationalPokedexTotal Pokemon in the National Pokedex',
        iconPath: 'assets/badges/national_dex.png',
        isUnlocked: totalCaught >= nationalPokedexTotal,
        progress: totalCaught,
        target: nationalPokedexTotal,
        category: AchievementCategory.special,
        currentTier: totalCaught >= nationalPokedexTotal ? 'MAX' : null,
        maxTier: 1,
        isRainbow: true,
      ),
    ];
  }

  List<Achievement> _getTypeAchievements(Map<String, int> typeDistribution) {
    final achievements = <Achievement>[];
    final allTypes = [
      'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice',
      'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
      'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy'
    ];
    
    for (final type in allTypes) {
      final count = typeDistribution[type] ?? 0;
      
      // Define all type tiers
      final tiers = [
        {'tier': 'I', 'target': 10},
        {'tier': 'II', 'target': 25},
        {'tier': 'III', 'target': 50},
      ];
      
      for (int i = 0; i < tiers.length; i++) {
        final tier = tiers[i];
        final target = tier['target'] as int;
        final tierName = tier['tier'] as String;
        final isUnlocked = count >= target;
        
        achievements.add(Achievement(
          id: 'type_${type.toLowerCase()}_$tierName',
          name: '$type Master $tierName',
          description: isUnlocked
              ? 'You caught $target $type-type Pokemon!'
              : 'Catch $target $type-type Pokemon',
          iconPath: 'assets/badges/type_${type.toLowerCase()}.png',
          isUnlocked: isUnlocked,
          progress: count,
          target: target,
          category: AchievementCategory.type,
          currentTier: isUnlocked ? tierName : null,
          maxTier: 3,
          color: typeColor(type),
        ));
      }
    }
    
    return achievements;
  }
}
