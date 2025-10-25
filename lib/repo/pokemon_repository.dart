import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/pokemon.dart';

class PokemonRepository {
  final _table = 'pokemon';

  Future<int?> _nextDex(Database db) async {
    final res = await db.rawQuery('SELECT MAX(dex) AS m FROM $_table');
    final max = (res.first['m'] as int?) ?? 0;
    return max + 1;
  }

  Future<int> insert(Pokemon p) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final data = p.toMap();
      data['dex'] ??= await _nextDex(db); // auto-assign if null
      return await db.insert(_table, data, conflictAlgorithm: ConflictAlgorithm.abort);
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
      return await db.update(
        _table,
        p.toMap(),
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
    final rows = await db.query(_table, orderBy: 'CASE WHEN dex IS NULL THEN 1 ELSE 0 END, dex ASC');
    return rows.map((m) => Pokemon.fromMap(m)).toList();
  }

  Future<Pokemon?> findByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table,
        where: 'LOWER(name) = ?', whereArgs: [name.toLowerCase()], limit: 1);
    if (rows.isEmpty) return null;
    return Pokemon.fromMap(rows.first);
  }

  Future<Pokemon?> findByDex(int dex) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_table, where: 'dex = ?', whereArgs: [dex], limit: 1);
    if (rows.isEmpty) return null;
    return Pokemon.fromMap(rows.first);
  }
}