import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('krayon_music.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS history');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id TEXT,
        user_id TEXT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        thumbnailUrl TEXT NOT NULL,
        durationMs INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        PRIMARY KEY (id, user_id)
      )
    ''');
  }

  Future<void> addToHistory(Song song) async {
    final db = await instance.database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    print('ADDING TO HISTORY for user: $_userId, song: ${song.title}');

    await db.insert(
      'history',
      {
        'id': song.id,
        'user_id': _userId,
        'title': song.title,
        'author': song.author,
        'thumbnailUrl': song.thumbnailUrl,
        'durationMs': song.duration.inMilliseconds,
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Song>> getHistory() async {
    final db = await instance.database;
    print('GETTING HISTORY for user: $_userId');
    final result = await db.query(
      'history',
      where: 'user_id = ?',
      whereArgs: [_userId],
      orderBy: 'timestamp DESC',
    );
    print('HISTORY RESULT COUNT: ${result.length}');

    return result.map((json) => Song(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
    )).toList();
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete(
      'history',
      where: 'user_id = ?',
      whereArgs: [_userId],
    );
  }
}
