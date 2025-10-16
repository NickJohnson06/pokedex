import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/poke_assets.dart';

class AddEditScreen extends StatefulWidget {
  final Pokemon? existing;
  const AddEditScreen({super.key, this.existing});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _typeCtrl;   // primary (required)
  late final TextEditingController _type2Ctrl;  // secondary (optional)

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.existing?.name  ?? '');
    _typeCtrl  = TextEditingController(text: widget.existing?.type  ?? '');
    _type2Ctrl = TextEditingController(text: widget.existing?.type2 ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _type2Ctrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<Widget> _buildPreview() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return const SizedBox.shrink();

    final path = assetPathFromName(name);
    final ok = await assetExists(path);

    if (!ok) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('No matching image in assets/pokemon/.'),
      );
    }

    // Non-cropping centered preview box
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 160,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25),
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                path,
                height: 140,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const Text('Image failed to load'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final t1 = _typeCtrl.text.trim();
    final t2raw = _type2Ctrl.text.trim();
    final t2 = t2raw.isEmpty ? null : t2raw;

    if (t2 != null && t2.toLowerCase() == t1.toLowerCase()) {
      _toast('Primary and secondary types must be different.');
      return;
    }

    final p = Pokemon(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      type: t1,
      type2: t2,
    );

    Navigator.of(context).pop(p);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Evolve Pokémon' : 'Catch Pokémon')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name (must match asset filename convention, e.g., "zapdos")
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name (must match filename, e.g., zapdos)',
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}), // refresh image preview as you type
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Primary type (required)
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'Primary Type (e.g., Electric)'),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Primary type is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Secondary type (optional)
              TextFormField(
                controller: _type2Ctrl,
                decoration: const InputDecoration(labelText: 'Secondary Type (optional, e.g., Flying)'),
                validator: (_) => null, // distinctness is checked in _save()
              ),

              // Local asset preview (non-cropping)
              const SizedBox(height: 12),
              FutureBuilder<Widget>(
                future: _buildPreview(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  return snap.data ?? const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Save Changes' : 'Catch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
