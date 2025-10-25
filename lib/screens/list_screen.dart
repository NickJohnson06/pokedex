import 'package:flutter/material.dart';
import '../repo/pokemon_repository.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';
import '../utils/dex_format.dart';
import '../widgets/dual_type_chip.dart';
import '../theme/theme_controller.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _repo = PokemonRepository();
  List<Pokemon> _items = [];
  String _query = '';
  bool _loading = true;
  bool _grid = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _repo.getAll();
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Failed to load: $e');
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final p = await Navigator.push<Pokemon>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditScreen()),
    );
    if (p != null) {
      try {
        final existing = await _repo.findByName(p.name);
        if (existing != null) {
          _toast('A Pokémon named ${p.name} already exists.');
          return;
        }
        await _repo.insert(p);
        await _load();
        _toast('Caught ${p.name}');
      } catch (e) {
        _toast('Failed to save: $e');
      }
    }
  }

  Future<void> _edit(Pokemon p) async {
    final updated = await Navigator.push<Pokemon>(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(existing: p)),
    );
    if (updated != null) {
      try {
        final clash = await _repo.findByName(updated.name);
        if (clash != null && clash.id != p.id) {
          _toast('Another Pokémon named ${updated.name} already exists.');
          return;
        }
        await _repo.update(updated..id = p.id);
        await _load();
        _toast('Evolved to ${updated.name}');
      } catch (e) {
        _toast('Failed to update: $e');
      }
    }
  }

  Future<void> _delete(Pokemon p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Release Pokémon'),
        content: Text('Are you sure you want to release ${p.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Release')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.delete(p.id!);
        await _load();
        _toast('Released ${p.name}');
      } catch (e) {
        _toast('Failed to delete: $e');
      }
    }
  }

  Widget _leadingThumb(Pokemon p) {
    final path = assetPathFromName(p.name);
    return Hero(
      tag: 'poke-${p.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                Center(child: CircleAvatar(radius: 20, child: Text(p.name[0]))),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((p) {
      if (_query.isEmpty) return true;
      final raw = _query.toLowerCase().trim();
      final q = raw.startsWith('#') ? raw.substring(1) : raw;
      final t2 = p.type2?.toLowerCase() ?? '';
      final dexStr = (p.dex ?? -1).toString();
      return p.name.toLowerCase().contains(q)
          || p.type.toLowerCase().contains(q)
          || t2.contains(q)
          || dexStr == q;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Personal Pokedex'),
        actions: [
          // Theme toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.themeMode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark ||
                  (mode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: ThemeController.toggle,
              );
            },
          ),
          // Grid/List toggle
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _grid = !_grid),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, type, or #dex…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grid
              ? _buildGrid(filtered)
              : _buildList(filtered),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Catch'),
      ),
    );
  }

  Widget _buildList(List<Pokemon> data) {
    if (data.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.catching_pokemon, size: 64),
          SizedBox(height: 12),
          Center(child: Text('No Pokémon yet')),
          SizedBox(height: 4),
          Center(child: Text('Tap the Catch button to add your first one.')),
          SizedBox(height: 120),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: data.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final p = data[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: _leadingThumb(p),
              title: Text(
                '${formatDex(p.dex)}  ${p.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: DualTypeChip(type1: p.type, type2: p.type2),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(pokemon: p)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(p)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(p)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Pokemon> data) {
    if (data.isEmpty) {
      return _buildList(data); // reuse empty state
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70, // taller cells (fix overflow)
        ),
        itemCount: data.length,
        itemBuilder: (_, i) {
          final p = data[i];
          final path = assetPathFromName(p.name);
          return GestureDetector(
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => DetailScreen(pokemon: p))),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'poke-${p.id}',
                      child: SizedBox(
                        width: 64, height: 64,
                        child: Image.asset(
                          path,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              CircleAvatar(child: Text(p.name[0])),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // #dex (scales down)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatDex(p.dex),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Name (scales down)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Chip (scales down)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: DualTypeChip(type1: p.type, type2: p.type2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}