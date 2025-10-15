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
  late final TextEditingController _typeCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _typeCtrl = TextEditingController(text: widget.existing?.type ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
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
                height: 140,            // inside the 160 box -> no cropping
                fit: BoxFit.contain,    // preserve aspect ratio
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
    final p = Pokemon(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
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
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name (must match filename, e.g., pikachu)',
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}), // refresh preview
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'Type (e.g., Electric)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Type is required';
                  return null;
                },
              ),
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
