import 'package:flutter/material.dart';
import 'screens/list_screen.dart';

void main() => runApp(const PokedexApp());

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Pokedex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,                 // modern Material styling
        colorSchemeSeed: Colors.red,        // cohesive color palette
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,          // follow device light/dark
      home: const ListScreen(),             // main screen (CRUD + search)
    );
  }
}
