import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';

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
        fit: BoxFit.contain,            // keep full sprite visible
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            CircleAvatar(radius: 64, child: Text(pokemon.name[0])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(tag: 'poke-${pokemon.id}', child: _avatar()),
            const SizedBox(height: 16),
            Text(
              pokemon.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Chip(label: Text(pokemon.type)),
          ],
        ),
      ),
    );
  }
}
