import 'package:flutter/material.dart';
import '../models/sort_filter.dart';
import '../controllers/sort_filter_controller.dart';
import '../utils/type_colors.dart';

class FilterSheet extends StatefulWidget {
  final SortFilterController controller;

  const FilterSheet({super.key, required this.controller});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> _types;
  late Set<int> _gens;

  // Sync logic handled via controller updates

  @override
  void initState() {
    super.initState();
    _types = Set.from(widget.controller.filter.types);
    _gens = Set.from(widget.controller.filter.generations);
  }

  void _apply() {
    widget.controller.setFilter(widget.controller.filter.copyWith(
      types: _types,
      generations: _gens,
    ));
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _types.clear();
      _gens.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const allTypes = [
      'Normal', 'Fire', 'Water', 'Grass', 'Electric', 'Ice', 'Fighting',
      'Poison', 'Ground', 'Flying', 'Psychic', 'Bug', 'Rock', 'Ghost',
      'Dragon', 'Steel', 'Dark', 'Fairy'
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ),
          const Divider(),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Types', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allTypes.map((t) {
                    final isSelected = _types.contains(t);
                    return FilterChip(
                      label: Text(t),
                      selected: isSelected,
                      selectedColor: typeColor(t).withOpacity(0.3),
                      checkmarkColor: typeColor(t),
                      labelStyle: TextStyle(
                        color: isSelected ? typeColor(t) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (v) => setState(() {
                        if (v) _types.add(t); else _types.remove(t);
                      }),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                const Text('Generations', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(9, (i) {
                    final gen = i + 1;
                    final isSelected = _gens.contains(gen);
                    return FilterChip(
                      label: Text('Gen $gen'),
                      selected: isSelected,
                      onSelected: (v) => setState(() {
                        if (v) _gens.add(gen); else _gens.remove(gen);
                      }),
                    );
                  }),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _apply, 
                child: const Text('Show Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
