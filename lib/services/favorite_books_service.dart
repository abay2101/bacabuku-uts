import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/book.dart';

class FavoriteBooksService {
  static const _databaseName = 'bacabuku.db';
  static const _tableName = 'favorite_books';
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), _databaseName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author_names TEXT NOT NULL,
            first_publish_year INTEGER,
            cover_id INTEGER,
            edition_count INTEGER
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<Book>> getAll() async {
    final rows = await (await _db).query(_tableName, orderBy: 'title COLLATE NOCASE');
    return rows.map(Book.fromDatabaseMap).toList(growable: false);
  }

  Future<bool> contains(String key) async {
    final rows = await (await _db).query(
      _tableName,
      columns: ['key'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> save(Book book) async {
    if (book.key.isEmpty) return;
    await (await _db).insert(
      _tableName,
      book.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String key) async {
    await (await _db).delete(_tableName, where: 'key = ?', whereArgs: [key]);
  }
}
