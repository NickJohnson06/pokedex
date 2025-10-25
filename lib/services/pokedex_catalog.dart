import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/poke_stats.dart';

class PokedexEntry {
  final int dex;
  final List<String> types;
  final PokeStats baseStats;
  final double? heightM;
  final double? weightKg;

  PokedexEntry({required this.dex, required this.types, required this.baseStats, this.heightM, this.weightKg});

  factory PokedexEntry.fromMap(Map<String, dynamic> m) => PokedexEntry(
    dex: m['dex'] as int,
    types: (m['types'] as List).map((e) => (e as String).trim()).toList(),
    baseStats: PokeStats.fromMap(m['base_stats'] as Map<String, dynamic>),
    heightM: (m['height_m'] as num?)?.toDouble(),
    weightKg: (m['weight_kg'] as num?)?.toDouble(),
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
    final Map<String, dynamic> raw = json.decode(jsonStr);
    final byName = <String, PokedexEntry>{};
    final byDex = <int, PokedexEntry>{};
    raw.forEach((name, value) {
      final entry = PokedexEntry.fromMap(value as Map<String, dynamic>);
      byName[name.toLowerCase()] = entry;
      byDex[entry.dex] = entry;
    });
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

  /// Returns National Dex for a given name (or null if unknown)
  Future<int?> dexForName(String name) async => (await byName(name))?.dex;
}
