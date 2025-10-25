import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';
import '../utils/dex_format.dart';
import '../widgets/dual_type_chip.dart';
import '../widgets/stat_bar.dart';
import '../services/pokedex_catalog.dart';

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

  Future _loadCatalogEntry() async {
    final c = PokedexCatalog.instance;
    if (pokemon.dex != null) {
      return await c.byDex(pokemon.dex!);
    }
    return await c.byName(pokemon.name);
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
              Text(
                formatDex(pokemon.dex),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DualTypeChip(type1: pokemon.type, type2: pokemon.type2),
              const SizedBox(height: 24),

              // Base stats + size from catalog JSON (if available)
              FutureBuilder(
                future: _loadCatalogEntry(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final entry = snap.data;
                  if (entry == null) {
                    return const Text('No stats available.');
                  }
                  final s = entry.baseStats;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Base Stats',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      StatBar(label: 'HP',  value: s.hp),
                      StatBar(label: 'ATK', value: s.atk),
                      StatBar(label: 'DEF', value: s.def),
                      StatBar(label: 'SpA', value: s.spa),
                      StatBar(label: 'SpD', value: s.spd),
                      StatBar(label: 'SPE', value: s.spe),
                      const SizedBox(height: 12),
                      // Size (if provided)
                      Builder(builder: (_) {
                        final hasHeight = entry.heightM != null;
                        final hasWeight = entry.weightKg != null;
                        if (!hasHeight && !hasWeight) return const SizedBox.shrink();
                        return Text(
                          [
                            if (hasHeight) 'Height: ${entry.heightM} m',
                            if (hasWeight) 'Weight: ${entry.weightKg} kg',
                          ].join('  •  '),
                          textAlign: TextAlign.center,
                        );
                      }),
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
