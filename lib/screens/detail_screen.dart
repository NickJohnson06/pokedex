import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class DetailScreen extends StatelessWidget {
  final Pokemon pokemon;
  const DetailScreen({super.key, required this.pokemon});

  Widget _avatar() {
    final hasImage = pokemon.imageUrl != null && pokemon.imageUrl!.isNotEmpty;
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(64),
        child: Image.network(
          pokemon.imageUrl!,
          width: 128,
          height: 128,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(radius: 64, child: Text(pokemon.name.isNotEmpty ? pokemon.name[0] : '?'));
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
            Text(pokemon.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Chip(label: Text(pokemon.type)),
          ],
        ),
      ),
    );
  }
}
