// Starter Flutter/Dart Code for Personal Pokedex CRUD App

import 'package:flutter/material.dart';

void main() {
  runApp(PokedexApp());
}

class PokedexApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Pokedex',
      theme: ThemeData(primarySwatch: Colors.red),
      home: PokedexHomePage(),
    );
  }
}

class Pokemon {
  int id;
  String name;
  String type;

  Pokemon({required this.id, required this.name, required this.type});
}

class PokedexHomePage extends StatefulWidget {
  @override
  _PokedexHomePageState createState() => _PokedexHomePageState();
}

class _PokedexHomePageState extends State<PokedexHomePage> {
  List<Pokemon> pokedex = [];
  int nextId = 1;

  void catchPokemon(String name, String type) {
    setState(() {
      pokedex.add(Pokemon(id: nextId++, name: name, type: type));
    });
  }

  void evolvePokemon(int id, String newName, String newType) {
    setState(() {
      for (var p in pokedex) {
        if (p.id == id) {
          p.name = newName;
          p.type = newType;
          break;
        }
      }
    });
  }

  void releasePokemon(int id) {
    setState(() {
      pokedex.removeWhere((p) => p.id == id);
    });
  }

  Pokemon? findPokemonByName(String name) {
    return pokedex.firstWhere((p) => p.name.toLowerCase() == name.toLowerCase(), orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Personal Pokedex')),
      body: ListView.builder(
        itemCount: pokedex.length,
        itemBuilder: (context, index) {
          final pokemon = pokedex[index];
          return ListTile(
            title: Text(pokemon.name),
            subtitle: Text('Type: ${pokemon.type}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => releasePokemon(pokemon.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Example: Catch a new Pokémon
          catchPokemon('Pikachu', 'Electric');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
