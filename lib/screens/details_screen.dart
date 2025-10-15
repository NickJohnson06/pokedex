import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class DetailScreen extends StatelessWidget {
  final Pokemon pokemon;
  const DetailScreen({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'poke-${pokemon.id}',
              child: CircleAvatar(
                radius: 48,
                child: Text(pokemon.name.isNotEmpty ? pokemon.name[0] : '?'),
              ),
            ),
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
