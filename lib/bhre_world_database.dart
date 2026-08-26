import 'package:sqflite/sqflite.dart';

import 'bhre_world_event.dart';

class BhreWorldDatabase {
  static const _databaseName = 'bhre_world.db';
  static const _databaseVersion = 1;
  static const _table = 'world_events';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = databasesPath.endsWith('/')
        ? '$databasesPath$_databaseName'
        : '$databasesPath/$_databaseName';

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            source TEXT NOT NULL,
            url TEXT NOT NULL,
            country TEXT NOT NULL,
            category TEXT NOT NULL,
            published_at INTEGER NOT NULL,
            collected_at INTEGER NOT NULL,
            importance REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_world_published
          ON $_table(published_at)
        ''');

        await db.execute('''
          CREATE INDEX idx_world_country
          ON $_table(country)
        ''');

        await db.execute('''
          CREATE INDEX idx_world_category
          ON $_table(category)
        ''');

        await db.execute('''
          CREATE INDEX idx_world_importance
          ON $_table(importance)
        ''');
      },
    );

    return _database!;
  }

  Future<void> save(BhreWorldEvent event) async {
    final db = await database;

    await db.insert(
      _table,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> saveAll(List<BhreWorldEvent> events) async {
    if (events.isEmpty) return 0;

    final db = await database;
    final batch = db.batch();

    for (final event in events) {
      batch.insert(
        _table,
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    return events.length;
  }

  Future<BhreWorldEvent?> getById(String id) async {
    final db = await database;

    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return BhreWorldEvent.fromMap(rows.first);
  }

  Future<List<BhreWorldEvent>> latest({int limit = 50}) async {
    final db = await database;

    final rows = await db.query(
      _table,
      orderBy: 'published_at DESC',
      limit: limit,
    );

    return rows.map(BhreWorldEvent.fromMap).toList(growable: false);
  }

  Future<List<BhreWorldEvent>> important({
    double minimumImportance = 0.70,
    int limit = 50,
  }) async {
    final db = await database;

    final rows = await db.query(
      _table,
      where: 'importance >= ?',
      whereArgs: [minimumImportance],
      orderBy: 'importance DESC, published_at DESC',
      limit: limit,
    );

    return rows.map(BhreWorldEvent.fromMap).toList(growable: false);
  }

  Future<List<BhreWorldEvent>> byCategory(
    BhreWorldCategory category, {
    int limit = 50,
  }) async {
    final db = await database;

    final rows = await db.query(
      _table,
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'published_at DESC',
      limit: limit,
    );

    return rows.map(BhreWorldEvent.fromMap).toList(growable: false);
  }

  Future<List<BhreWorldEvent>> byCountry(
    String country, {
    int limit = 50,
  }) async {
    final db = await database;

    final clean = country.trim();

    if (clean.isEmpty) return const [];

    final rows = await db.query(
      _table,
      where: 'LOWER(country) = LOWER(?)',
      whereArgs: [clean],
      orderBy: 'published_at DESC',
      limit: limit,
    );

    return rows.map(BhreWorldEvent.fromMap).toList(growable: false);
  }

  Future<List<BhreWorldEvent>> search(String query, {int limit = 50}) async {
    final db = await database;

    final clean = query.trim();

    if (clean.isEmpty) return const [];

    final pattern = '%$clean%';

    final rows = await db.query(
      _table,
      where: '''
        title LIKE ?
        OR description LIKE ?
        OR source LIKE ?
        OR country LIKE ?
        OR category LIKE ?
      ''',
      whereArgs: [pattern, pattern, pattern, pattern, pattern],
      orderBy: 'importance DESC, published_at DESC',
      limit: limit,
    );

    return rows.map(BhreWorldEvent.fromMap).toList(growable: false);
  }

  Future<List<BhreWorldEvent>> between(
    DateTime start,
    DateTime end, {
    int limit = 500,
  }) async {
    final db = await database;

    final rows = await db.query(
      _table,
      where: '''
        published_at >= ?
        AND published_at < ?
      ''',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'published_at DESC',
      limit: limit,
    );

    return rows.map(BhreWorldEvent.fromMap).toList(growable: false);
  }

  Future<int> count() async {
    final db = await database;

    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM $_table');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> delete(String id) async {
    final db = await database;

    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete(_table);
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
