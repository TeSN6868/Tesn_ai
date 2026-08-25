import 'package:sqflite/sqflite.dart';

class BhreKnowledgeRecord {
  final String id;
  final String title;
  final String content;
  final String tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BhreKnowledgeRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
}

class BhreKnowledgeDatabase {
  static const _databaseVersion = 1;
  static const _table = 'knowledge';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await openDatabase(
      joinDatabasePath(await getDatabasesPath()),
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_knowledge_title
          ON $_table(title)
        ''');

        await db.execute('''
          CREATE INDEX idx_knowledge_updated
          ON $_table(updated_at)
        ''');
      },
    );

    return _database!;
  }

  Future<void> save({
    required String id,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      _table,
      {
        'id': id.trim(),
        'title': title.trim(),
        'content': content.trim(),
        'tags': tags
            .map((tag) => tag.trim().toLowerCase())
            .where((tag) => tag.isNotEmpty)
            .join(','),
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<BhreKnowledgeRecord?> getById(String id) async {
    final db = await database;

    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  Future<List<BhreKnowledgeRecord>> search(String query) async {
    final db = await database;
    final clean = query.trim();

    if (clean.isEmpty) return const [];

    final pattern = '%$clean%';

    final rows = await db.query(
      _table,
      where: '''
        title LIKE ?
        OR content LIKE ?
        OR tags LIKE ?
      ''',
      whereArgs: [
        pattern,
        pattern,
        pattern,
      ],
      orderBy: 'updated_at DESC',
    );

    return rows.map(_fromMap).toList(growable: false);
  }

  Future<List<BhreKnowledgeRecord>> getAll({
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;

    final rows = await db.query(
      _table,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(_fromMap).toList(growable: false);
  }

  Future<void> delete(String id) async {
    final db = await database;

    await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete(_table);
  }

  Future<int> count() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_table',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  BhreKnowledgeRecord _fromMap(
    Map<String, Object?> map,
  ) {
    return BhreKnowledgeRecord(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: map['tags'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int,
      ),
    );
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

String joinDatabasePath(String databasesPath) {
  const databaseName = 'bhre_knowledge.db';

  if (databasesPath.endsWith('/')) {
    return '$databasesPath$databaseName';
  }

  return '$databasesPath/$databaseName';
}
