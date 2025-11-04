import 'dart:convert';
import 'package:http/http.dart' as http;
import 'poke_cache.dart';

class PokeApiEntry {
  final int dex;
  final List<String> types;
  final Map<String,int> stats; // hp/atk/def/spa/spd/spe
  final double heightM, weightKg;

  PokeApiEntry({
    required this.dex,
    required this.types,
    required this.stats,
    required this.heightM,
    required this.weightKg,
  });

  static String _statKey(String apiName) {
    switch (apiName) {
      case 'hp': return 'hp';
      case 'attack': return 'atk';
      case 'defense': return 'def';
      case 'special-attack': return 'spa';
      case 'special-defense': return 'spd';
      case 'speed': return 'spe';
      default: return apiName;
    }
  }

  factory PokeApiEntry.fromJson(Map<String, dynamic> m) {
    final id = m['id'] as int;
    final types = (m['types'] as List)
        .map((t) => (t['type']['name'] as String))
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .toList();

    final stats = <String,int>{};
    for (final s in (m['stats'] as List)) {
      stats[_statKey(s['stat']['name'] as String)] = s['base_stat'] as int;
    }

    // height in decimeters, weight in hectograms
    final h = ((m['height'] as num).toDouble()) / 10.0;
    final w = ((m['weight'] as num).toDouble()) / 10.0;

    return PokeApiEntry(
      dex: id,
      types: types,
      stats: stats,
      heightM: h,
      weightKg: w,
    );
  }
}

class PokeApiService {
  static const _base = 'https://pokeapi.co/api/v2';

  /// Cache-first by dex. If stale/missing, hit network, then cache.
  static Future<PokeApiEntry?> fetchByDex(int dex, {int? ttlMs}) async {
    // 1) Cache
    final cached = await PokeCache.getByDexWithTtl(dex, ttlMs: ttlMs);
    if (cached != null) {
      return PokeApiEntry.fromJson(cached);
    }

    // 2) Network
    final url = Uri.parse('$_base/pokemon/$dex');
    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final map = json.decode(res.body) as Map<String, dynamic>;
    await PokeCache.put(dex, map);
    return PokeApiEntry.fromJson(map);
  }

  /// Name lookup → we still cache by dex (id) so subsequent loads are fast.
  static Future<PokeApiEntry?> fetchByName(String name, {int? ttlMs}) async {
    final slug = name.trim().toLowerCase();

    // We can't know dex before fetch; network first, then store by dex
    final url = Uri.parse('$_base/pokemon/$slug');
    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final map = json.decode(res.body) as Map<String, dynamic>;
    final dex = (map['id'] as num).toInt();

    // Optionally check cache freshness first (skip if you prefer)
    final cached = await PokeCache.getByDexWithTtl(dex, ttlMs: ttlMs);
    if (cached != null) {
      return PokeApiEntry.fromJson(cached);
    }

    await PokeCache.put(dex, map);
    return PokeApiEntry.fromJson(map);
  }
}
