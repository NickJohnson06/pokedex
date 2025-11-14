import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/list_screen.dart';
import 'theme/theme_controller.dart';
import 'controllers/sort_filter_controller.dart';

void main() => runApp(const PokedexApp());

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Sort/Filter Controller
        ChangeNotifierProvider(
          create: (_) => SortFilterController()..load(),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.themeMode,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'Personal Pokedex',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF1A5175),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF1A5175),
              brightness: Brightness.dark,
            ),
            themeMode: mode,
            home: const ListScreen(),
          );
        },
      ),
    );
  }
}
