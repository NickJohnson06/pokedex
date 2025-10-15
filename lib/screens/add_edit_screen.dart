import 'package:flutter/material.dart';
import '../models/pokemon.dart';

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
  late final TextEditingController _imageCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _typeCtrl = TextEditingController(text: widget.existing?.type ?? '');
    _imageCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeUrl(String v) {
    final s = v.trim();
    if (s.isEmpty) return true; // optional
    // Very lightweight check (http/https + dot)
    final hasScheme = s.startsWith('http://') || s.startsWith('https://');
    final hasDot = s.contains('.');
    return hasScheme && hasDot;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final p = Pokemon(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
    );

    Navigator.of(context).pop(p); // return to caller (ListScreen) with data
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final imageUrl = _imageCtrl.text.trim();

    Widget imagePreview() {
      if (imageUrl.isEmpty || !_looksLikeUrl(imageUrl)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text(
              'Could not load image preview.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Evolve Pokémon' : 'Catch Pokémon')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Type is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  hintText: 'https://example.com/pikachu.png',
                ),
                onChanged: (_) => setState(() {}), // refresh preview
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // optional
                  if (!_looksLikeUrl(v)) return 'Enter a valid http(s) URL';
                  return null;
                },
              ),
              imagePreview(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Save Changes' : 'Catch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
