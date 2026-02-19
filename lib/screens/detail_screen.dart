import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';
import '../utils/dex_format.dart';
import '../widgets/dual_type_chip.dart';
import '../widgets/hero_text.dart';
import '../widgets/stat_view_container.dart';
import '../services/pokedex_catalog.dart';
import '../services/pokeapi_service.dart';
import '../services/poke_cache.dart';
import '../repo/pokemon_repository.dart';
import '../utils/type_theme.dart';

// Internal shape to normalize data from either Catalog, Cache, or PokeAPI.
class _DetailData {
  final int? dex;
  final List<String>? types;
  final int? hp, atk, def, spa, spd, spe;
  final double? heightM, weightKg;
  final String? genus;
  final List<EvolutionSpecies>? evolutions;
  final List<Ability>? abilities;
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
    this.genus,
    this.evolutions,
    this.abilities,
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
    return Hero(
      tag: 'poke-${pokemon.id}',
      child: ClipRRect(
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
      ),
    );
  }

  Future<_DetailData?> _loadDetailData() async {
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
        genus: entry.genus,
        evolutions: entry.evolutions,
        abilities: entry.abilities,
        source: 'catalog',
      );
    }

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
          genus: null,
          source: 'cache',
        );
      }
    }

    PokeApiEntry? api = await PokeApiService.fetchByName(pokemon.name, ttlMs: 0);
    api ??= (pokemon.dex != null)
        ? await PokeApiService.fetchByDex(pokemon.dex!, ttlMs: 0)
        : null;

    if (api == null) return null;

    // Update stored dex if mismatched
    if (pokemon.id != null && pokemon.dex != api.dex) {
      try {
        final repo = PokemonRepository();
        final updated = Pokemon(
          id: pokemon.id,
          name: pokemon.name,
          type: pokemon.type,
          type2: pokemon.type2,
          dex: api.dex,
          favorite: pokemon.favorite,
        );
        await repo.update(updated);
      } catch (_) {}
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
      genus: null,
      evolutions: null,
      abilities: null,
      source: 'api',
    );
  }

  Widget _buildAbilities(BuildContext context, List<Ability> abilities) {
    if (abilities.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: abilities.map((a) {
            return Chip(
              label: Text(
                a.name[0].toUpperCase() + a.name.substring(1) + (a.isHidden ? ' (H)' : ''),
                style: TextStyle(
                  fontStyle: a.isHidden ? FontStyle.italic : FontStyle.normal,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildEvolutionChainWithArrows(BuildContext context, List<EvolutionSpecies> displayList) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < displayList.length; i++) {
      final e = displayList[i];
      final isCurrent = e.dex == pokemon.dex;
      final path = assetPathFromName(e.name);
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isCurrent)
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  GestureDetector(
                    onTap: isCurrent ? null : () async {
                      final catalog = PokedexCatalog.instance;
                      final entry = await catalog.byDex(e.dex);
                      if (entry != null && context.mounted) {
                        final p = Pokemon(
                          name: e.name,
                          type: entry.types.first,
                          type2: entry.types.length > 1 ? entry.types[1] : null,
                          dex: entry.dex,
                          favorite: false,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailScreen(pokemon: p))
                        );
                      }
                    },
                    child: Opacity(
                      opacity: isCurrent ? 1.0 : 0.7,
                      child: Image.asset(
                        path,
                        width: 50, height: 50,
                        errorBuilder: (_, __, ___) => CircleAvatar(child: Text(e.name[0])),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                e.name[0].toUpperCase() + e.name.substring(1),
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                )
              ),
              Text(
                formatDex(e.dex),
                style: const TextStyle(fontSize: 10, color: Colors.grey)
              ),
            ],
          ),
        ),
      );
      
      if (i < displayList.length - 1) {
        final nextEvolution = displayList[i + 1];
        final triggerText = nextEvolution.trigger ?? '';
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                if (triggerText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    triggerText,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  Widget _buildEvolutions(BuildContext context, List<EvolutionSpecies> evos) {
    if (evos.isEmpty) return const SizedBox.shrink();

    final currentDex = pokemon.dex;
    if (currentDex == null) return const SizedBox.shrink();

    EvolutionSpecies? currentNode;
    try {
      currentNode = evos.firstWhere((e) => e.dex == currentDex);
    } catch (_) {
      return const SizedBox.shrink(); 
    }

    final ancestors = <EvolutionSpecies>[];
    var parentDex = currentNode.evolvesFromDex;
    while (parentDex != null) {
      try {
        final parent = evos.firstWhere((e) => e.dex == parentDex);
        ancestors.add(parent);
        parentDex = parent.evolvesFromDex;
      } catch (_) {
        break;
      }
    }
    
    final descendants = <EvolutionSpecies>[];
    final queue = [...evos.where((e) => e.evolvesFromDex == currentDex)];
    
    while (queue.isNotEmpty) {
      final child = queue.removeAt(0);
      descendants.add(child);
      queue.addAll(evos.where((e) => e.evolvesFromDex == child.dex));
    }

    final displayList = [...ancestors.reversed, currentNode, ...descendants];

    if (displayList.length <= 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          '${pokemon.name[0].toUpperCase()}${pokemon.name.substring(1)} does not evolve.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Evolution Chain',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildEvolutionChainWithArrows(context, displayList),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = PokemonRepository();
    final favVN = ValueNotifier<bool>(pokemon.favorite);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(pokemon.name[0].toUpperCase() + pokemon.name.substring(1)),
        actions: [
          IconButton(
            tooltip: 'Back to List',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: favVN,
            builder: (context, fav, _) {
              return IconButton(
                tooltip: fav ? 'Unfavorite' : 'Favorite',
                icon: Icon(fav ? Icons.star : Icons.star_border),
                color: fav ? Colors.amber : null,
                onPressed: () async {
                  if (pokemon.id == null) return;
                  final newVal = !fav;
                  await repo.setFavorite(pokemon.id!, newVal);
                  favVN.value = newVal; // update UI immediately
                },
              );
            },
          ),
        ],
      ),
      body: AnimatedContainer(
        padding: const EdgeInsets.only(top: kToolbarHeight + 24), // Add padding for status bar/app bar
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: typeThemeFrom(pokemon.type, pokemon.type2).surfaceGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _avatar(),
                
                const SizedBox(height: 16),
                
                HeroText(
                  tag: 'name-${pokemon.id}',
                  child: Text(
                    pokemon.name[0].toUpperCase() + pokemon.name.substring(1),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 8),

                FutureBuilder<_DetailData?>(
                  future: _loadDetailData(),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return Column(
                        children: [
                          if (pokemon.dex != null)
                             HeroText(
                                tag: 'dex-${pokemon.id}',
                                child: Text(formatDex(pokemon.dex!), style: Theme.of(context).textTheme.labelLarge),
                             ),
                           const SizedBox(height: 24),
                           const CircularProgressIndicator(),
                        ],
                      );
                    }
                    final data = snap.data;
                    if (data == null) {
                      return const Text('No additional details available.');
                    }

                    final combinedLine = HeroText(
                      tag: 'dex-${pokemon.id}',
                      child: Text(
                        [
                          if (data.genus != null) data.genus,
                          'Pokedex ${formatDex(data.dex)}'
                        ].join(' | '),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );

                    final typing = DualTypeChip(type1: pokemon.type, type2: pokemon.type2);


                    final statsSection = data.hasStats
                        ? StatViewContainer(
                            hp: data.hp!,
                            atk: data.atk!,
                            def: data.def!,
                            spa: data.spa!,
                            spd: data.spd!,
                            spe: data.spe!,
                            themeColor: typeThemeFrom(pokemon.type, pokemon.type2).primary,
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
                        combinedLine,
                        const SizedBox(height: 8),
                        typing,
                        const SizedBox(height: 8),

                        if (data.abilities != null && data.abilities!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Abilities',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          _buildAbilities(context, data.abilities!),
                        ],

                        const SizedBox(height: 16),
                        
                        if (statsSection is! SizedBox) statsSection,
                        if (statsSection is! SizedBox) const SizedBox(height: 12),
                        sizeLine,
                        
                        if (data.evolutions != null) _buildEvolutions(context, data.evolutions!),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
