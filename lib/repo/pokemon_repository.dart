import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/pokemon.dart';
import '../services/pokedex_catalog.dart';
import '../services/pokeapi_service.dart';

class PokemonRepository {
  final _table = 'pokemon';

  Future<int> insert(Pokemon p) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final data = p.toMap();

      data['dex'] ??= await PokedexCatalog.instance.dexForName(p.name);

      if (data['dex'] == null) {
        final api = await PokeApiService.fetchByName(p.name);
        if (api != null) data['dex'] = api.dex;
      }

      return await db.insert(
        _table,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Duplicate name or dex number.');
      }
      rethrow;
    }
  }

  Future<int> update(Pokemon p) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final data = p.toMap();

      data['dex'] ??= await PokedexCatalog.instance.dexForName(p.name);
      if (data['dex'] == null) {
        final api = await PokeApiService.fetchByName(p.name);
        if (api != null) data['dex'] = api.dex;
      }

      return await db.update(
        _table,
        data,
        where: 'id = ?',
        whereArgs: [p.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Duplicate name or dex number.');
      }
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Get all Pokémon, optionally filtering only favorites.
  Future<List<Pokemon>> getAll({bool onlyFavorites = false}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: onlyFavorites ? 'favorite = 1' : null,
      orderBy:
          'CASE WHEN dex IS NULL THEN 1 ELSE 0 END, dex ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Pokemon.fromMap).toList();
  }

  Future<Pokemon?> findByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Pokemon.fromMap(rows.first);
  }

  Future<Pokemon?> findByDex(int dex) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'dex = ?',
      whereArgs: [dex],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Pokemon.fromMap(rows.first);
  }

  /// Toggle/set favorite flag.
  Future<void> setFavorite(int id, bool favorite) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _table,
      {'favorite': favorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTotalCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getTypeDistribution() async {
    final all = await getAll();
    final distribution = <String, int>{};
    
    for (final pokemon in all) {
      distribution[pokemon.type] = (distribution[pokemon.type] ?? 0) + 1;
      if (pokemon.type2 != null) {
        distribution[pokemon.type2!] = (distribution[pokemon.type2!] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  Future<Map<int, int>> getGenerationDistribution() async {
    final all = await getAll();
    final distribution = <int, int>{};
    
    for (final pokemon in all) {
      if (pokemon.dex != null) {
        final gen = _getGeneration(pokemon.dex!);
        distribution[gen] = (distribution[gen] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  int _getGeneration(int dex) {
    if (dex >= 1 && dex <= 151) return 1;
    if (dex >= 152 && dex <= 251) return 2;
    if (dex >= 252 && dex <= 386) return 3;
    if (dex >= 387 && dex <= 493) return 4;
    if (dex >= 494 && dex <= 649) return 5;
    if (dex >= 650 && dex <= 721) return 6;
    if (dex >= 722 && dex <= 809) return 7;
    if (dex >= 810 && dex <= 905) return 8;
    if (dex >= 906 && dex <= 1025) return 9;
    return 0;
  }
}
