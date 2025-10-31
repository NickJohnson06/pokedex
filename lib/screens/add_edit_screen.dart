import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokedex_catalog.dart';

class AddEditScreen extends StatefulWidget {
  final Pokemon? existing;
  const AddEditScreen({super.key, this.existing});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // We still keep our own controllers for saving and autofill
  late final TextEditingController _nameCtrl;
  late final TextEditingController _type1Ctrl;
  late final TextEditingController _type2Ctrl;

  bool _type1Touched = false;
  bool _type2Touched = false;
  String? _lastAutofillName;
  String? _autofillNote; // e.g., “Filled from catalog: Electric / Flying”

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.existing?.name  ?? '');
    _type1Ctrl = TextEditingController(text: widget.existing?.type  ?? '');
    _type2Ctrl = TextEditingController(text: widget.existing?.type2 ?? '');

    _type1Ctrl.addListener(() => _type1Touched = true);
    _type2Ctrl.addListener(() => _type2Touched = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _type1Ctrl.dispose();
    _type2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _maybeAutofillTypes(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      setState(() => _autofillNote = null);
      return;
    }
    if (_lastAutofillName != null &&
        _lastAutofillName!.toLowerCase() == name.toLowerCase()) {
      return;
    }

    final entry = await PokedexCatalog.instance.byName(name);
    if (entry == null) {
      setState(() => _autofillNote = null);
      return;
    }

    final types = entry.types;
    final t1 = types.isNotEmpty ? types[0] : '';
    final t2 = types.length > 1 ? types[1] : '';

    bool changed = false;

    if (!_type1Touched || (_type1Ctrl.text.trim().isEmpty)) {
      if (t1.isNotEmpty && _type1Ctrl.text != t1) {
        _type1Ctrl.text = t1;
        changed = true;
      }
    }
    if (!_type2Touched || (_type2Ctrl.text.trim().isEmpty)) {
      if (_type2Ctrl.text != t2) {
        _type2Ctrl.text = t2; // empty allowed for mono-type
        changed = true;
      }
    }

    if (changed) {
      setState(() {
        _lastAutofillName = name;
        _autofillNote = types.isNotEmpty
            ? 'Filled from catalog: ${types.join(" / ")}'
            : null;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final t1 = _type1Ctrl.text.trim();
    final t2 = _type2Ctrl.text.trim();

    final p = Pokemon(
      id: widget.existing?.id,
      name: name,
      type: t1,
      type2: (t2.isEmpty || t2.toLowerCase() == t1.toLowerCase()) ? null : t2,
    );

    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pokémon' : 'Catch Pokémon'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name with Autocomplete (typeahead)
              FutureBuilder<List<String>>(
                future: PokedexCatalog.instance.allNames(),
                builder: (context, snap) {
                  final options = (snap.data ?? const <String>[]);
                  if (snap.connectionState != ConnectionState.done) {
                    // Fallback simple field while loading options
                    return TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Pikachu, Zapdos',
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) {
                        _maybeAutofillTypes(v);
                      },
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name required' : null,
                    );
                  }

                  return Autocomplete<String>(
                    initialValue: TextEditingValue(text: _nameCtrl.text),
                    optionsBuilder: (TextEditingValue tev) {
                      final q = tev.text.trim().toLowerCase();
                      if (q.isEmpty) return const Iterable<String>.empty();
                      // Case-insensitive contains; limit for UX
                      return options
                          .where((name) => name.toLowerCase().contains(q))
                          .take(12);
                    },
                    displayStringForOption: (opt) => opt,
                    fieldViewBuilder:
                        (context, textCtrl, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: textCtrl,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Start typing…',
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (v) {
                          _nameCtrl.text = v;            // mirror only
                          _nameCtrl.selection = textCtrl.selection;
                          _maybeAutofillTypes(v);        // trigger autofill
                        },
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name required' : null,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, iterable) {
                      final results = iterable.toList(growable: false);
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxHeight: 240, minWidth: 280),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 0),
                              itemBuilder: (context, index) {
                                final opt = results[index];
                                return ListTile(
                                  title: Text(opt),
                                  onTap: () => onSelected(opt),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    onSelected: (String selected) {
                      // Autocomplete will set its own field text automatically
                      _nameCtrl.text = selected;
                      _nameCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _nameCtrl.text.length),
                      );
                      _maybeAutofillTypes(selected);
                    },
                  );
                },
              ),

              if (_autofillNote != null) ...[
                const SizedBox(height: 6),
                Text(_autofillNote!, style: Theme.of(context).textTheme.bodySmall),
              ],

              const SizedBox(height: 16),

              // Primary type
              TextFormField(
                controller: _type1Ctrl,
                decoration: const InputDecoration(labelText: 'Primary Type'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Primary type required' : null,
              ),
              const SizedBox(height: 12),

              // Secondary type (optional)
              TextFormField(
                controller: _type2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Secondary Type (optional)',
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.catching_pokemon),
                label: Text(isEdit ? 'Save Changes' : 'Catch Pokémon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
