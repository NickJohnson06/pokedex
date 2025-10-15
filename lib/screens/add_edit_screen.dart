import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../repo/pokemon_repository.dart';

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
  final _repo = PokemonRepository();
  bool _saving = false;

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
    return (s.startsWith('http://') || s.startsWith('https://')) && s.contains('.');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final p = Pokemon(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
    );

    try {
      // Prevent duplicate names
      final existing = await _repo.findByName(p.name);
      if (existing != null && existing.id != p.id) {
        _showToast('A Pokémon named ${p.name} already exists.');
        setState(() => _saving = false);
        return;
      }

      Navigator.of(context).pop(p); // return Pokémon back to ListScreen
    } catch (e) {
      _showToast('Error saving Pokémon: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                  if (!RegExp(r"^[a-zA-Z0-9\s]+$").hasMatch(v.trim())) {
                    return 'Only letters and numbers allowed';
                  }
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
                  if (v.trim().length < 3) return 'Type too short';
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
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
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
