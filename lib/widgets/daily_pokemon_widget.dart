import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../repo/pokemon_repository.dart';
import '../services/daily_rotation_service.dart';
import '../utils/poke_assets.dart';
import '../utils/type_theme.dart';
import '../screens/detail_screen.dart';

import '../utils/dex_format.dart';

class DailyPokemonWidget extends StatefulWidget {
  const DailyPokemonWidget({super.key});

  @override
  State<DailyPokemonWidget> createState() => _DailyPokemonWidgetState();
}

class _DailyPokemonWidgetState extends State<DailyPokemonWidget> {
  Pokemon? _pokemon;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = PokemonRepository();
      final all = await repo.getAll(); // Ideally we'd have a count() query but this works for now
      if (all.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      
      final dailyIndex = await DailyRotationService.getDailyId(all.length); 
      // dailyIndex is 1-based from service. 
      final index = (dailyIndex - 1) % all.length;
      
      if (mounted) {
        setState(() {
          _pokemon = all[index];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_pokemon == null) return const SizedBox.shrink();

    final p = _pokemon!;
    final theme = typeThemeFrom(p.type, p.type2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.primary.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(pokemon: p)),
        ),
        child: Container(
          decoration: BoxDecoration(gradient: theme.surfaceGradient),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pokémon of the Day'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDex(p.dex),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Hero(
                tag: 'daily-${p.id}', // Unique tag from list list
                child: Image.asset(
                  assetPathFromName(p.name),
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_,__,___) => const SizedBox(width: 80, height: 80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
