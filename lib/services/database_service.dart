import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/escape_record.dart';

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
    if (kIsWeb) {
      // Web: sqflite_common_ffi_web 사용
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'escdiary.db',
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // Mobile: 기본 sqflite 사용
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'escdiary.db');
      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 -> v2: clearTimeType 컬럼 추가
      await db.execute(
          'ALTER TABLE escape_records ADD COLUMN clearTimeType INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      // v2 -> v3: detailMemos 컬럼 추가
      await db.execute(
          'ALTER TABLE escape_records ADD COLUMN detailMemos TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE escape_records (
        id TEXT PRIMARY KEY,
        themeName TEXT NOT NULL,
        storeName TEXT NOT NULL,
        branchName TEXT,
        playDate TEXT NOT NULL,
        playTime INTEGER NOT NULL,
        playerCount INTEGER NOT NULL,
        isCleared INTEGER NOT NULL,
        hintCount INTEGER,
        clearTime TEXT,
        clearTimeType INTEGER DEFAULT 0,
        ratingInterior REAL DEFAULT 0,
        ratingSatisfaction REAL DEFAULT 0,
        ratingPuzzle REAL DEFAULT 0,
        ratingStory REAL DEFAULT 0,
        ratingProduction REAL DEFAULT 0,
        ratingHorror REAL DEFAULT 0,
        content TEXT,
        detailMemos TEXT,
        tags TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // 검색을 위한 인덱스
    await db.execute(
        'CREATE INDEX idx_themeName ON escape_records(themeName)');
    await db.execute(
        'CREATE INDEX idx_storeName ON escape_records(storeName)');
    await db.execute(
        'CREATE INDEX idx_playDate ON escape_records(playDate DESC)');
  }

  // CRUD Operations

  Future<String> insertRecord(EscapeRecord record) async {
    final db = await database;
    await db.insert(
      'escape_records',
      record.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return record.id;
  }

  Future<EscapeRecord?> getRecord(String id) async {
    final db = await database;
    final maps = await db.query(
      'escape_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return EscapeRecord.fromJson(maps.first);
  }

  Future<List<EscapeRecord>> getAllRecords({
    String? orderBy,
    bool descending = true,
  }) async {
    final db = await database;
    final order = orderBy ?? 'playDate';
    final maps = await db.query(
      'escape_records',
      orderBy: '$order ${descending ? 'DESC' : 'ASC'}',
    );
    return maps.map((map) => EscapeRecord.fromJson(map)).toList();
  }

  Future<int> updateRecord(EscapeRecord record) async {
    final db = await database;
    return await db.update(
      'escape_records',
      record.toJson(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(String id) async {
    final db = await database;
    return await db.delete(
      'escape_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 검색 기능
  Future<List<EscapeRecord>> searchRecords(String query) async {
    final db = await database;
    final searchPattern = '%$query%';
    final maps = await db.query(
      'escape_records',
      where: 'themeName LIKE ? OR storeName LIKE ? OR branchName LIKE ? OR content LIKE ?',
      whereArgs: [searchPattern, searchPattern, searchPattern, searchPattern],
      orderBy: 'playDate DESC',
    );
    return maps.map((map) => EscapeRecord.fromJson(map)).toList();
  }

  // 통계 정보
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM escape_records'),
    );

    final clearedCount = Sqflite.firstIntValue(
      await db.rawQuery(
          'SELECT COUNT(*) FROM escape_records WHERE isCleared = 1'),
    );

    final avgRating = await db.rawQuery('''
      SELECT AVG(
        (CASE WHEN ratingInterior > 0 THEN ratingInterior ELSE 0 END +
         CASE WHEN ratingSatisfaction > 0 THEN ratingSatisfaction ELSE 0 END +
         CASE WHEN ratingPuzzle > 0 THEN ratingPuzzle ELSE 0 END +
         CASE WHEN ratingStory > 0 THEN ratingStory ELSE 0 END +
         CASE WHEN ratingProduction > 0 THEN ratingProduction ELSE 0 END +
         CASE WHEN ratingHorror > 0 THEN ratingHorror ELSE 0 END) /
        (CASE WHEN ratingInterior > 0 THEN 1 ELSE 0 END +
         CASE WHEN ratingSatisfaction > 0 THEN 1 ELSE 0 END +
         CASE WHEN ratingPuzzle > 0 THEN 1 ELSE 0 END +
         CASE WHEN ratingStory > 0 THEN 1 ELSE 0 END +
         CASE WHEN ratingProduction > 0 THEN 1 ELSE 0 END +
         CASE WHEN ratingHorror > 0 THEN 1 ELSE 0 END)
      ) as avg FROM escape_records
      WHERE ratingInterior > 0 OR ratingSatisfaction > 0 OR ratingPuzzle > 0 OR ratingStory > 0 OR ratingProduction > 0 OR ratingHorror > 0
    ''');

    return {
      'totalCount': totalCount ?? 0,
      'clearedCount': clearedCount ?? 0,
      'clearRate': totalCount != null && totalCount > 0
          ? (clearedCount ?? 0) / totalCount * 100
          : 0.0,
      'averageRating': avgRating.isNotEmpty ? avgRating.first['avg'] ?? 0.0 : 0.0,
    };
  }

  // 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
