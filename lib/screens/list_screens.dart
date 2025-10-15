import 'package:flutter/material.dart';
import '../repo/pokemon_repository.dart';
import '../models/pokemon.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repo.getAll();
    setState(() => _items = rows);
  }

  Future<void> _add() async {
    final p = await Navigator.push<Pokemon>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditScreen()),
    );
    if (p != null) {
      await _repo.insert(p);
      _load();
      _toast('Caught ${p.name}');
    }
  }

  Future<void> _edit(Pokemon p) async {
    final updated = await Navigator.push<Pokemon>(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(existing: p)),
    );
    if (updated != null) {
      await _repo.update(updated..id = p.id);
      _load();
      _toast('Evolved to ${updated.name}');
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
      await _repo.delete(p.id!);
      _load();
      _toast('Released ${p.name}');
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or type…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('No Pokémon yet. Tap + to catch one!'))
          : ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final p = filtered[i];
                return ListTile(
                  leading: Hero(tag: 'poke-${p.id}', child: CircleAvatar(child: Text(p.name[0]))),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Type: ${p.type} • #${p.id}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailScreen(pokemon: p)),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(p)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(p)),
                  ]),
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
