import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/explored_area.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'openworld.db');
    print('💾 Database: $path');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE explored_areas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            radius REAL DEFAULT 20.0
          )
        ''');
        print('✨ Table explored_areas created');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          print('🔄 Migration v$oldVersion -> v$newVersion: adding radius column');
          try {
            await db.execute('ALTER TABLE explored_areas ADD COLUMN radius REAL DEFAULT 20.0');
            print('✅ Radius column added (existing zones get 20m default)');
          } catch (e) {
            print('⚠️ Column might already exist: $e');
          }
        }
      },
    );
  }

  Future<int> insertExploredArea(ExploredArea area) async {
    final db = await database;
    return await db.insert('explored_areas', area.toMap());
  }

  Future<List<ExploredArea>> getAllExploredAreas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('explored_areas');
    return List.generate(maps.length, (i) => ExploredArea.fromMap(maps[i]));
  }

  Future<int> deleteAllExploredAreas() async {
    final db = await database;
    return await db.delete('explored_areas');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
