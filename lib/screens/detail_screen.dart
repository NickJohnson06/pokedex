import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';
import '../utils/dex_format.dart';
import '../widgets/dual_type_chip.dart';
import '../widgets/stat_bar.dart';
import '../services/pokedex_catalog.dart';
import '../services/pokeapi_service.dart';
import '../repo/pokemon_repository.dart';

/// Internal shape to normalize data from either Catalog or PokeAPI.
class _DetailData {
  final int? dex;
  final List<String>? types;
  final int? hp, atk, def, spa, spd, spe;
  final double? heightM, weightKg;
  final String source; // 'catalog' or 'api'

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
    // 1) Try local catalog first (fast/offline)
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

    // 2) Fallback to PokeAPI — IMPORTANT: prefer name first to avoid wrong-mon by dex
    PokeApiEntry? api = await PokeApiService.fetchByName(pokemon.name);
    api ??= (pokemon.dex != null) ? await PokeApiService.fetchByDex(pokemon.dex!) : null;

    if (api == null) return null;

    // 2b) OPTIONAL: Correct stored dex if it differs (e.g., "Mew" saved as 146)
    // This updates your DB so future loads are accurate.
    if (pokemon.id != null && pokemon.dex != api.dex) {
      try {
        final repo = PokemonRepository();
        final updated = Pokemon(
          id: pokemon.id,
          name: pokemon.name,
          type: pokemon.type,
          type2: pokemon.type2,
          // set the correct dex from API
          // (other fields unchanged)
          // Note: your repo enforces unique dex, which is correct.
          // If another entry mistakenly took that dex, you'll get a friendly error from repo.
          dex: api.dex,
        );
        await repo.update(updated);
      } catch (_) {
        // Silent fail: we still show correct details from API even if DB update collides
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
              const SizedBox(height: 4),
              // Show whatever is currently stored; corrected dex will appear next time after DB update
              Text(
                formatDex(pokemon.dex),
                style: Theme.of(context).textTheme.labelLarge,
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
