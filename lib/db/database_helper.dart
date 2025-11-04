import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'pokedex.db';
  static const _dbVersion = 6; // v6: add favorite column + pokemon_cache table
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
      onOpen: _onOpen,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // Main table (fresh installs get the full, current schema)
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE,
        type TEXT NOT NULL,
        type2 TEXT,
        dex INTEGER,
        favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE UNIQUE INDEX idx_pokemon_name ON $_table(name);');
    // SQLite UNIQUE allows multiple NULLs; so dex can be NULL for unresolved entries
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_pokemon_dex ON $_table(dex);');

    // Create cache table on fresh install
    await _createCacheTable(db);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Keep existing upgrade steps for users coming from older versions
    if (oldVersion < 2) {
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_pokemon_name ON $_table(name COLLATE NOCASE);',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $_table ADD COLUMN type2 TEXT;');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE $_table ADD COLUMN dex INTEGER;');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_pokemon_dex ON $_table(dex);');
    }
    if (oldVersion < 6) {
      // v6 migration: add favorite column + create cache table
      await _ensureFavoriteColumn(db);
      await _createCacheTable(db);
    }
  }

  FutureOr<void> _onOpen(Database db) async {
    // Safety net for partially-migrated states
    await _createCacheTable(db);
    await _ensureFavoriteColumn(db);
  }

  Future<void> _createCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pokemon_cache (
        dex INTEGER PRIMARY KEY,
        json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensureFavoriteColumn(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE $_table ADD COLUMN favorite INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {
    }
  }
}
