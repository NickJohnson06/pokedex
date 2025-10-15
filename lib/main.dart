import 'package:flutter/material.dart';
import 'repo/pokemon_repository.dart';
import 'models/pokemon.dart';

void main() => runApp(const PokedexApp());

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Pokedex',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const PokedexHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PokedexHomePage extends StatefulWidget {
  const PokedexHomePage({super.key});

  @override
  State<PokedexHomePage> createState() => _PokedexHomePageState();
}

class _PokedexHomePageState extends State<PokedexHomePage> {
  final _repo = PokemonRepository();
  List<Pokemon> _pokedex = [];

  @override
  void initState() {
    super.initState();
    _loadPokedex();
  }

  Future<void> _loadPokedex() async {
    final all = await _repo.getAll();
    setState(() => _pokedex = all);
  }

  Future<void> _catchPokemon() async {
    // for now, we’ll just hardcode Pikachu to test SQLite
    final pikachu = Pokemon(name: 'Pikachu', type: 'Electric');
    await _repo.insert(pikachu);
    _loadPokedex();
  }

  Future<void> _releasePokemon(int id) async {
    await _repo.delete(id);
    _loadPokedex();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Personal Pokedex')),
      body: _pokedex.isEmpty
          ? const Center(child: Text('No Pokémon yet. Tap + to catch one!'))
          : ListView.builder(
              itemCount: _pokedex.length,
              itemBuilder: (context, index) {
                final pokemon = _pokedex[index];
                return ListTile(
                  title: Text(pokemon.name),
                  subtitle: Text('Type: ${pokemon.type}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _releasePokemon(pokemon.id!),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _catchPokemon,
        child: const Icon(Icons.add),
      ),
    );
  }
}
