
import 'dart:convert';
import 'dart:io';

/// Merges a JSON data file into assets/data/pokedex_catalog.json
/// Usage: dart tool/merge_catalogs.dart [input_file]
Future<void> main(List<String> args) async {
  final catalogFile = File('assets/data/pokedex_catalog.json');
  final inputFile = args.isNotEmpty ? args[0] : 'fetched_data.json';
  final newFile = File(inputFile);

  if (!await catalogFile.exists()) {
    print('Error: Catalog file not found at ${catalogFile.path}');
    return;
  }
  if (!await newFile.exists()) {
    print('Error: New data file not found at ${newFile.path}');
    return;
  }

  // Read existing
  final catalogContent = await catalogFile.readAsString();
  final List<dynamic> existingList = json.decode(catalogContent);

  // Read new
  final newContent = await newFile.readAsString();
  final List<dynamic> newList = json.decode(newContent);

  print('Existing: ${existingList.length} entries');
  print('New: ${newList.length} entries from $inputFile');

  // Merge
  final mergedMap = <int, Map<String, dynamic>>{};
  
  for (var item in existingList) {
    if (item['dex'] != null) {
      mergedMap[item['dex']] = item;
    }
  }
  
  for (var item in newList) {
    if (item['dex'] != null) {
      mergedMap[item['dex']] = item; // Overwrite if exists
    }
  }

  final sortedList = mergedMap.values.toList()
    ..sort((a, b) => (a['dex'] as int).compareTo(b['dex'] as int));

  print('Merged Total: ${sortedList.length} entries');

  // Write back
  final encoder = JsonEncoder.withIndent('  ');
  await catalogFile.writeAsString(encoder.convert(sortedList));
  print('Successfully updated ${catalogFile.path}');
}
