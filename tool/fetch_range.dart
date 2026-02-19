
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Fetches Pokemon data for a given range of IDs.
/// Usage: dart tool/fetch_range.dart <start_id> <end_id> [output_file]
/// Example: dart tool/fetch_range.dart 252 386 gen3.json
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart tool/fetch_range.dart <start_id> <end_id> [output_file]');
    return;
  }

  final startId = int.tryParse(args[0]);
  final endId = int.tryParse(args[1]);
  final outputFile = args.length > 2 ? args[2] : 'fetched_data.json';

  if (startId == null || endId == null) {
    print('Error: Start and End IDs must be integers.');
    return;
  }

  print('Fetching range $startId to $endId...');
  final entries = <Map<String, dynamic>>[];

  for (int i = startId; i <= endId; i++) {
    print('Fetching #$i...');
    try {
      final data = await fetchPokemon(i);
      entries.add(data);
    } catch (e) {
      print('Error fetching #$i: $e');
    }
    // Rate limit slightly
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // save
  final jsonStr = JsonEncoder.withIndent('  ').convert(entries);
  final file = File(outputFile);
  await file.writeAsString(jsonStr);
  print('Done! Saved ${entries.length} entries to $outputFile');
}

Future<Map<String, dynamic>> fetchPokemon(int id) async {
  final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$id');
  final res = await http.get(url);
  if (res.statusCode != 200) throw Exception('Failed to load pokemon $id');

  final jsonMap = json.decode(res.body) as Map<String, dynamic>;
  
  // Also fetch species for evolution/genus
  final speciesUrl = Uri.parse(jsonMap['species']['url']);
  final speciesRes = await http.get(speciesUrl);
  final speciesMap = (speciesRes.statusCode == 200)
      ? json.decode(speciesRes.body)
      : <String, dynamic>{};

  // 1. Basic Info
  final name = jsonMap['name'] as String;
  final types = (jsonMap['types'] as List)
      .map((t) => _capitalize(t['type']['name']))
      .toList();
  
  // 2. Stats
  final stats = <String, int>{};
  for (final s in (jsonMap['stats'] as List)) {
    final statName = s['stat']['name'] as String;
    final val = s['base_stat'] as int;
    stats[_mapStatName(statName)] = val;
  }

  // 3. Abilities
  final abilities = (jsonMap['abilities'] as List).map((a) {
    return {
      'name': a['ability']['name'],
      'is_hidden': a['is_hidden'],
      'slot': a['slot'],
    };
  }).toList();

  // 4. Genus (Category)
  String genus = 'Unknown Pokemon';
  if (speciesMap.isNotEmpty) {
    final genera = speciesMap['genera'] as List?;
    final englishGenus = genera?.firstWhere(
      (g) => g['language']['name'] == 'en',
      orElse: () => null,
    );
    if (englishGenus != null) genus = englishGenus['genus'];
  }

  // 5. Evolutions
  var evoList = <Map<String, dynamic>>[];
  if (speciesMap.isNotEmpty && speciesMap['evolution_chain'] != null) {
      final chainUrl = speciesMap['evolution_chain']['url'];
      final chainRes = await http.get(Uri.parse(chainUrl));
      if (chainRes.statusCode == 200) {
        final chainData = json.decode(chainRes.body);
        evoList = _parseEvoChain(chainData['chain']);
      }
  }

  return {
    'name': name,
    'dex': id,
    'types': types,
    'base_stats': stats,
    'height_m': (jsonMap['height'] as num) / 10.0,
    'weight_kg': (jsonMap['weight'] as num) / 10.0,
    'evolutions': evoList,
    'abilities': abilities,
    'genus': genus,
  };
}

List<Map<String, dynamic>> _parseEvoChain(Map<String, dynamic> chainLink) {
    final List<Map<String, dynamic>> list = [];
    
    void traverse(Map<String, dynamic> node, int? parentJsDex) {
       final speciesName = node['species']['name'];
       final url = node['species']['url'] as String; 
       final dexId = int.parse(url.split('/').where((e) => e.isNotEmpty).last); 

       String? trigger;
       if (node['evolution_details'] != null && (node['evolution_details'] as List).isNotEmpty) {
          final details = (node['evolution_details'] as List).first;
          trigger = _formatTrigger(details);
       }

       list.add({
         'dex': dexId,
         'name': speciesName,
         'evolves_from_dex': parentJsDex,
         'trigger': trigger,
       });

       for (final child in (node['evolves_to'] as List)) {
         traverse(child, dexId);
       }
    }

    traverse(chainLink, null);
    // Sort by dex
    list.sort((a, b) => (a['dex'] as int).compareTo(b['dex'] as int));
    return list;
}

String? _formatTrigger(Map<String, dynamic> details) {
  final type = details['trigger']['name'];
  
  if (type == 'level-up') {
    if (details['min_level'] != null) return 'Level ${details['min_level']}';
    if (details['min_happiness'] != null) return 'Friendship';
    if (details['held_item'] != null) return 'Hold ${_capitalize(details['held_item']['name'])}';
    if (details['known_move'] != null) return 'Know ${_capitalize(details['known_move']['name'])}';
    if (details['location'] != null) return 'Near ${_capitalize(details['location']['name'])}';
    if (details['time_of_day'] != null && details['time_of_day'].isNotEmpty) return 'Level Up (${details['time_of_day']})';
    
    // Add known_move_type for things like Eevee -> Sylveon
    if (details['known_move_type'] != null) return 'Know ${_capitalize(details['known_move_type']['name'])} Move';
    
    return 'Level Up';
  }
  
  if (type == 'use-item') {
    return _capitalize(details['item']['name']);
  }
  
  if (type == 'trade') {
    if (details['held_item'] != null) return 'Trade w/ ${_capitalize(details['held_item']['name'])}';
    return 'Trade';
  }
  
  return _capitalize(type);
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s.split('-').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}

String _mapStatName(String apiName) {
  switch (apiName) {
    case 'hp': return 'hp';
    case 'attack': return 'atk';
    case 'defense': return 'def';
    case 'special-attack': return 'spa';
    case 'special-defense': return 'spd';
    case 'speed': return 'spe';
    default: return apiName;
  }
}
