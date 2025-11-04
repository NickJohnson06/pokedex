import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';
import '../utils/dex_format.dart';
import '../widgets/dual_type_chip.dart';
import '../widgets/stat_bar.dart';
import '../services/pokedex_catalog.dart';
import '../services/pokeapi_service.dart';
import '../services/poke_cache.dart';
import '../repo/pokemon_repository.dart';

// Internal shape to normalize data from either Catalog, Cache, or PokeAPI.
class _DetailData {
  final int? dex;
  final List<String>? types;
  final int? hp, atk, def, spa, spd, spe;
  final double? heightM, weightKg;
  final String source; // 'catalog' | 'cache' | 'api'

  const _DetailData({
    required this.dex,
    this.types,
    this.hp,
    this.atk,
    this.def,
    this.spa,
    this.spd,
    this.spe,
    this.heightM,
    this.weightKg,
    required this.source,
  });

  bool get hasStats =>
      hp != null && atk != null && def != null && spa != null && spd != null && spe != null;
}

class DetailScreen extends StatelessWidget {
  final Pokemon pokemon;
  const DetailScreen({super.key, required this.pokemon});

  Widget _avatar() {
    final path = assetPathFromName(pokemon.name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(64),
      child: Image.asset(
        path,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            CircleAvatar(radius: 64, child: Text(pokemon.name[0])),
      ),
    );
  }

  Future<_DetailData?> _loadDetailData() async {
    // 1) Local catalog first (fast/offline)
    final catalog = PokedexCatalog.instance;
    final entry = pokemon.dex != null
        ? await catalog.byDex(pokemon.dex!)
        : await catalog.byName(pokemon.name);

    if (entry != null) {
      final s = entry.baseStats;
      return _DetailData(
        dex: entry.dex,
        types: entry.types,
        hp: s.hp,
        atk: s.atk,
        def: s.def,
        spa: s.spa,
        spd: s.spd,
        spe: s.spe,
        heightM: entry.heightM,
        weightKg: entry.weightKg,
        source: 'catalog',
      );
    }

    // 2) Cache by known dex
    if (pokemon.dex != null) {
      final cachedMap = await PokeCache.getByDex(pokemon.dex!);
      if (cachedMap != null) {
        final api = PokeApiEntry.fromJson(cachedMap);
        return _DetailData(
          dex: api.dex,
          types: api.types,
          hp: api.stats['hp'],
          atk: api.stats['atk'],
          def: api.stats['def'],
          spa: api.stats['spa'],
          spd: api.stats['spd'],
          spe: api.stats['spe'],
          heightM: api.heightM,
          weightKg: api.weightKg,
          source: 'cache',
        );
      }
    }

    // 3) Network fallback — prefer name to avoid wrong-mon by fallback dex
    PokeApiEntry? api = await PokeApiService.fetchByName(pokemon.name, ttlMs: 0);
    api ??= (pokemon.dex != null)
        ? await PokeApiService.fetchByDex(pokemon.dex!, ttlMs: 0)
        : null;

    if (api == null) return null;

    // Correct stored dex if needed (e.g., Mew saved as 146)
    if (pokemon.id != null && pokemon.dex != api.dex) {
      try {
        final repo = PokemonRepository();
        final updated = Pokemon(
          id: pokemon.id,
          name: pokemon.name,
          type: pokemon.type,
          type2: pokemon.type2,
          dex: api.dex,
        );
        await repo.update(updated);
      } catch (_) {
        // Ignore if update collides; we still display correct info
      }
    }

    return _DetailData(
      dex: api.dex,
      types: api.types,
      hp: api.stats['hp'],
      atk: api.stats['atk'],
      def: api.stats['def'],
      spa: api.stats['spa'],
      spd: api.stats['spd'],
      spe: api.stats['spe'],
      heightM: api.heightM,
      weightKg: api.weightKg,
      source: 'api',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Hero(tag: 'poke-${pokemon.id}', child: _avatar()),
              const SizedBox(height: 16),
              Text(
                pokemon.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              DualTypeChip(type1: pokemon.type, type2: pokemon.type2),

              const SizedBox(height: 24),
              FutureBuilder<_DetailData?>(
                future: _loadDetailData(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final data = snap.data;
                  if (data == null) {
                    return const Text('No additional details available.');
                  }

                  // Show corrected dex immediately (from catalog/cache/api)
                  final dexLine = Text(
                    formatDex(data.dex),
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  );

                  final statsSection = data.hasStats
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Base Stats',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            StatBar(label: 'HP',  value: data.hp!),
                            StatBar(label: 'ATK', value: data.atk!),
                            StatBar(label: 'DEF', value: data.def!),
                            StatBar(label: 'SpA', value: data.spa!),
                            StatBar(label: 'SpD', value: data.spd!),
                            StatBar(label: 'SPE', value: data.spe!),
                          ],
                        )
                      : const SizedBox.shrink();

                  final sizeLine = (data.heightM != null || data.weightKg != null)
                      ? Text(
                          [
                            if (data.heightM != null) 'Height: ${data.heightM} m',
                            if (data.weightKg != null) 'Weight: ${data.weightKg} kg',
                          ].join('  •  '),
                          textAlign: TextAlign.center,
                        )
                      : const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      dexLine,
                      const SizedBox(height: 8),
                      if (statsSection is! SizedBox) statsSection,
                      if (statsSection is! SizedBox) const SizedBox(height: 12),
                      sizeLine,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
