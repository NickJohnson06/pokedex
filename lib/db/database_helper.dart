import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'pokedex.db';
  static const _dbVersion = 5; // bumped version for dex entry
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
    CREATE TABLE pokemon (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL COLLATE NOCASE,
      type TEXT NOT NULL,
      type2 TEXT,
      dex INTEGER
    )
  ''');
  await db.execute('CREATE UNIQUE INDEX idx_pokemon_name ON pokemon(name);');
  await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_pokemon_dex ON pokemon(dex);'); // allow nulls, unique when set
}

FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_pokemon_name ON pokemon(name COLLATE NOCASE);');
  }
  if (oldVersion < 4) {
    await db.execute('ALTER TABLE pokemon ADD COLUMN type2 TEXT;');
  }
  if (oldVersion < 5) {
    await db.execute('ALTER TABLE pokemon ADD COLUMN dex INTEGER;');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_pokemon_dex ON pokemon(dex);');
  }
}
}
