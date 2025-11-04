import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';

class PokeCache {
  static Future<Map<String, dynamic>?> getByDex(int dex) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'pokemon_cache',
      where: 'dex = ?',
      whereArgs: [dex],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first;
    final jsonStr = raw['json'] as String;
    return json.decode(jsonStr) as Map<String, dynamic>;
  }

  static Future<void> put(int dex, Map<String, dynamic> jsonMap) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'pokemon_cache',
      {
        'dex': dex,
        'json': json.encode(jsonMap),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Optional TTL helper (milliseconds). Returns null if stale.
  static Future<Map<String, dynamic>?> getByDexWithTtl(int dex, {int? ttlMs}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'pokemon_cache',
      where: 'dex = ?',
      whereArgs: [dex],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first;
    if (ttlMs != null) {
      final updated = raw['updated_at'] as int;
      if (DateTime.now().millisecondsSinceEpoch - updated > ttlMs) {
        return null; // stale
      }
    }
    final jsonStr = raw['json'] as String;
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
}
