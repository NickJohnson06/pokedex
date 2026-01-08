import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/list_screen.dart';
import 'theme/theme_controller.dart';
import 'controllers/sort_filter_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SortFilterController()..load(),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.themeMode,
        builder: (context, mode, _) {
          return ValueListenableBuilder<Color>(
            valueListenable: ThemeController.trainerColor,
            builder: (context, color, _) {
              return MaterialApp(
                title: 'Personal Pokedex',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  colorSchemeSeed: color,
                  brightness: Brightness.light,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorSchemeSeed: color,
                  brightness: Brightness.dark,
                ),
                themeMode: mode,
                home: const ListScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
