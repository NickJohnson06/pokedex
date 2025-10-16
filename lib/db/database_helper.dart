import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'pokedex.db';
  static const _dbVersion = 4; // bumped version for type2 migration
  static const _table = 'pokemon';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE,
        type TEXT NOT NULL,
        type2 TEXT
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX idx_pokemon_name ON $_table(name);');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_pokemon_name ON $_table(name COLLATE NOCASE);');
    }
    if (oldVersion < 4) {
      // add type2 column for dual typing
      await db.execute('ALTER TABLE $_table ADD COLUMN type2 TEXT;');
    }
  }
}
