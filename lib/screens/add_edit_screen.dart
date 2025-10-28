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

  late final TextEditingController _nameCtrl;
  late final TextEditingController _type1Ctrl;
  late final TextEditingController _type2Ctrl;

  // Track whether the user has manually edited type fields
  bool _type1Touched = false;
  bool _type2Touched = false;

  // Remember which name we last auto-filled for, so we don’t re-apply on every keystroke
  String? _lastAutofillName;
  String? _autofillNote; // UI hint like “Filled from catalog: Electric / Flying”

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.existing?.name  ?? '');
    _type1Ctrl = TextEditingController(text: widget.existing?.type  ?? '');
    _type2Ctrl = TextEditingController(text: widget.existing?.type2 ?? '');

    _type1Ctrl.addListener(() {
      // If the user changes the field after an autofill, mark touched
      _type1Touched = true;
    });
    _type2Ctrl.addListener(() {
      _type2Touched = true;
    });
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
      setState(() {
        _autofillNote = null;
      });
      return;
    }
    // Avoid repeat work if same name as last time and fields already set
    if (_lastAutofillName != null && _lastAutofillName!.toLowerCase() == name.toLowerCase()) {
      return;
    }

    final entry = await PokedexCatalog.instance.byName(name);
    if (entry == null) {
      // Unknown in catalog
      setState(() {
        _autofillNote = null;
      });
      return;
    }

    // Only autofill fields the user hasn’t touched (or that are still empty),
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
        _type2Ctrl.text = t2; // may be empty string if mono-type
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

    // Prevent duplicate identical types in UI
    final type2 = (t2.isEmpty || t2.toLowerCase() == t1.toLowerCase()) ? null : t2;

    final p = Pokemon(
      id: widget.existing?.id,
      name: name,
      type: t1,
      type2: type2,
    );

    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pokémon' : 'Catch Pokémon'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name field (drives autofill)
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Pikachu, Zapdos',
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: _maybeAutofillTypes,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              if (_autofillNote != null) ...[
                const SizedBox(height: 6),
                Text(
                  _autofillNote!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),

              // Primary type (required) – gets auto-filled if known
              TextFormField(
                controller: _type1Ctrl,
                decoration: const InputDecoration(labelText: 'Primary Type'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Primary type required' : null,
              ),
              const SizedBox(height: 12),

              // Secondary type (optional) – auto-filled if known dual type
              TextFormField(
                controller: _type2Ctrl,
                decoration: const InputDecoration(labelText: 'Secondary Type (optional)'),
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