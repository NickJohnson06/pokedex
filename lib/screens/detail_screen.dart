import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';
import '../utils/type_colors.dart';

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
        fit: BoxFit.contain, // keep full sprite visible
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            CircleAvatar(radius: 64, child: Text(pokemon.name[0])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type2Text = (pokemon.type2 ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name)),
      body: Center(
        child: Padding(
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
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  Chip(
                    label: Text(pokemon.type),
                    backgroundColor: typeColor(pokemon.type).withOpacity(0.15),
                    labelStyle:
                        TextStyle(color: typeColor(pokemon.type).withOpacity(0.95)),
                  ),
                  if (type2Text.isNotEmpty)
                    Chip(
                      label: Text(type2Text),
                      backgroundColor: typeColor(type2Text).withOpacity(0.15),
                      labelStyle: TextStyle(
                          color: typeColor(type2Text).withOpacity(0.95)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // (Optional) Room for more details later
              // Text('Dex: ...'), Stats, etc.
            ],
          ),
        ),
      ),
    );
  }
}
