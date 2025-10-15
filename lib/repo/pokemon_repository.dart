import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/pokemon.dart';

class PokemonRepository {
  final _table = 'pokemon';

  Future<int> insert(Pokemon p) async {
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.insert(_table, p.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('A Pokémon named ${p.name} already exists.');
      }
      rethrow;
    }
  }

  Future<int> update(Pokemon p) async {
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.update(_table, p.toMap(), where: 'id = ?', whereArgs: [p.id], conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('A Pokémon named ${p.name} already exists.');
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
    final rows = await db.query(_table, orderBy: 'id DESC');
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
}
