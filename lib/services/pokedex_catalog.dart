import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/poke_stats.dart';

class EvolutionSpecies {
  final int dex;
  final String name;
  final int? evolvesFromDex;
  final String? trigger;

  EvolutionSpecies({
    required this.dex, 
    required this.name, 
    this.evolvesFromDex,
    this.trigger,
  });
  
  factory EvolutionSpecies.fromMap(Map<String, dynamic> m) => EvolutionSpecies(
    dex: m['dex'] as int,
    name: m['name'] as String,
    evolvesFromDex: m['evolves_from_dex'] as int?,
    trigger: m['trigger'] as String?,
  );
}

class Ability {
  final String name;
  final bool isHidden;
  final int slot;

  const Ability({
    required this.name,
    required this.isHidden,
    required this.slot,
  });

  factory Ability.fromMap(Map<String, dynamic> map) => Ability(
    name: map['name'] as String,
    isHidden: map['is_hidden'] as bool,
    slot: map['slot'] as int,
  );
}

class PokedexEntry {
  final int dex;
  final List<String> types;
  final PokeStats baseStats;
  final double? heightM;
  final double? weightKg;
  final String? genus;
  final List<EvolutionSpecies> evolutions;
  final List<Ability> abilities;

  PokedexEntry({
    required this.dex,
    required this.types,
    required this.baseStats,
    this.heightM,
    this.weightKg,
    this.genus,
    this.evolutions = const [],
    this.abilities = const [],
  });

  factory PokedexEntry.fromMap(Map<String, dynamic> m) => PokedexEntry(
        dex: m['dex'] as int,
        types: (m['types'] as List).map((e) => (e as String).trim()).toList(),
        baseStats: PokeStats.fromMap(m['base_stats'] as Map<String, dynamic>),
        heightM: (m['height_m'] as num?)?.toDouble(),
        weightKg: (m['weight_kg'] as num?)?.toDouble(),
        genus: m['genus'] as String?,
        evolutions: (m['evolutions'] as List?)
            ?.map((e) => EvolutionSpecies.fromMap(e as Map<String, dynamic>))
            .toList() ?? [],
        abilities: (m['abilities'] as List?)
            ?.map((e) => Ability.fromMap(e as Map<String, dynamic>))
            .toList() ?? [],
      );
}

class PokedexCatalog {
  PokedexCatalog._();
  static final PokedexCatalog instance = PokedexCatalog._();

  Map<String, PokedexEntry>? _byName; // lowercase name -> entry
  Map<int, PokedexEntry>? _byDex;

  Future<void> _ensureLoaded() async {
    if (_byName != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/pokedex_catalog.json');
    final List<dynamic> raw = json.decode(jsonStr);
    final byName = <String, PokedexEntry>{};
    final byDex = <int, PokedexEntry>{};
    for (var item in raw) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as String;
      final entry = PokedexEntry.fromMap(map);
      byName[name.toLowerCase()] = entry;
      byDex[entry.dex] = entry;
    }
    _byName = byName;
    _byDex = byDex;
  }

  Future<PokedexEntry?> byName(String name) async {
    await _ensureLoaded();
    return _byName![name.trim().toLowerCase()];
  }

  Future<PokedexEntry?> byDex(int dex) async {
    await _ensureLoaded();
    return _byDex![dex];
  }

  Future<int?> dexForName(String name) async {
    final e = await byName(name);
    return e?.dex;
  }

  Future<List<String>> allNames() async {
    await _ensureLoaded();
    final names = _byName!.keys.map((n) {
      if (n.isEmpty) return n;
      // Capitalize first letter for display
      return n[0].toUpperCase() + n.substring(1);
    }).toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  Future<List<PokedexEntry>> allEntries() async {
    await _ensureLoaded();
    return _byDex!.values.toList();
  }
}
