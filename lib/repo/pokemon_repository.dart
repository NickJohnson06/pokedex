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

      // 1) Try local catalog (fast/offline)
      data['dex'] ??= await PokedexCatalog.instance.dexForName(p.name);

      // 2) If still unknown, try PokeAPI (online)
      if (data['dex'] == null) {
        final api = await PokeApiService.fetchByName(p.name);
        if (api != null) {
          data['dex'] = api.dex;
        }
      }

      // 3) If still null (offline or miss), save with dex = null (placeholder)
      //    DO NOT auto-assign MAX(dex)+1 — that causes wrong numbers.
      //    UI already shows '#—' for null dex via formatDex().
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

      // If caller didn't set dex, try to resolve it (catalog → API), but don't force
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

  Future<List<Pokemon>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    // Sort: known dex first (ASC), then unknown (#—) at the end, then name
    final rows = await db.query(
      _table,
      orderBy:
          'CASE WHEN dex IS NULL THEN 1 ELSE 0 END, dex ASC, name COLLATE NOCASE ASC',
    );
    return rows.map((m) => Pokemon.fromMap(m)).toList();
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
}
