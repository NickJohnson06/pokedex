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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final p = Pokemon(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
      imageUrl: widget.existing?.imageUrl, // untouched for now
    );
    Navigator.of(context).pop(p); // return the Pokemon to caller
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Evolve Pokémon' : 'Catch Pokémon')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Type is required';
                return null;
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Save Changes' : 'Catch'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
