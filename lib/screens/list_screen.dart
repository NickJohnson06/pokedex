import 'package:flutter/material.dart';
import '../repo/pokemon_repository.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';
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
    // Fixed-size, non-cropping thumbnail with rounded corners
    return Hero(
      tag: 'poke-${p.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image.asset(
            path,
            fit: BoxFit.contain,           // keep full sprite visible
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
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.type.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Personal Pokedex'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or type…',
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
          : filtered.isEmpty
              ? const Center(child: Text('No Pokémon yet. Tap + to catch one!'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: _leadingThumb(p),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Type: ${p.type} • #${p.id}'),
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
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Catch'),
      ),
    );
  }
}
