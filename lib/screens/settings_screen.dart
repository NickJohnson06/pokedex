import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Color> _palette = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
    Colors.cyan,
    Colors.indigoAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildInfoSection(context),
          const Divider(),
          _buildThemeSection(context),
          const Divider(),
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: const Text('Trainer Preferences'),
      subtitle: const Text('Customize your Pokedex experience.'),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        
        // Dark Mode Toggle
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.themeMode,
          builder: (context, mode, _) {
            final isDark = mode == ThemeMode.dark ||
                (mode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
            
            return SwitchListTile(
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Dark Mode'),
              subtitle: Text(mode == ThemeMode.system ? 'System Default' : (isDark ? 'On' : 'Off')),
              value: isDark,
              onChanged: (_) => ThemeController.toggle(),
            );
          },
        ),

        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Trainer Palette', style: TextStyle(fontSize: 16)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('Choose your global accent color.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        
        // Color Picker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ValueListenableBuilder<Color>(
            valueListenable: ThemeController.trainerColor,
            builder: (context, current, _) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _palette.map((c) {
                  final isSelected = c.value == current.value;
                  return GestureDetector(
                    onTap: () => ThemeController.setTrainerColor(c),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                        boxShadow: [
                           if (isSelected) BoxShadow(color: c.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAppInfo() {
    return const ListTile(
      leading: Icon(Icons.info_outline),
      title: Text('Version'),
      subtitle: Text('1.0.0 - Phase 3'),
    );
  }
}
