import 'package:flutter/services.dart' show rootBundle;

String pokeSlug(String name) {
  // lowercase, keep letters/digits, convert spaces/punct to single dash
  final base = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return base.replaceAll(RegExp(r'^-+|-+$'), '');
}

String assetPathFromName(String name) => 'assets/pokemon/${pokeSlug(name)}.png';

Future<bool> assetExists(String assetPath) async {
  try {
    await rootBundle.load(assetPath);
    return true;
  } catch (_) {
    return false;
  }
}
