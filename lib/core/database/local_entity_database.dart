import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalEntityRecord {
  const LocalEntityRecord({
    required this.id,
    required this.payload,
    required this.updatedAt,
  });

  final String id;
  final String payload;
  final String updatedAt;

  Map<String, dynamic> toGraphqlJson() => <String, dynamic>{
    '__typename': 'LocalEntityRecord',
    'id': id,
    'payload': payload,
    'updatedAt': updatedAt,
  };
}

class LocalEntityDatabase {
  static const _databaseName = 'sellhub_local_graphql_v2.db';
  static const _databaseVersion = 7;
  static const _tableName = 'entities';

  Database? _database;
  DatabaseFactory? _databaseFactory;
  bool _memoryFallbackEnabled = false;
  final Map<String, Map<String, LocalEntityRecord>> _memoryCollections =
      <String, Map<String, LocalEntityRecord>>{};

  Future<void> initialize() async {
    _databaseFactory ??= _resolveDatabaseFactory();
    if (_memoryFallbackEnabled) {
      return;
    }
    try {
      await _open();
    } on MissingPluginException {
      _enableMemoryFallback();
    } on DatabaseException {
      _enableMemoryFallback();
    }
  }

  Future<List<LocalEntityRecord>> listCollection(String collection) async {
    if (_memoryFallbackEnabled) {
      final rows = _memoryCollections[collection]?.values.toList() ?? const [];
      rows.sort((a, b) {
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return a.id.compareTo(b.id);
      });
      return rows;
    }
    final db = await _open();
    final rows = await db.query(
      _tableName,
      columns: const <String>['entity_id', 'payload', 'updated_at'],
      where: 'collection = ?',
      whereArgs: <Object?>[collection],
      orderBy: 'updated_at DESC, entity_id ASC',
    );
    return rows
        .map(
          (row) => LocalEntityRecord(
            id: row['entity_id'] as String? ?? '',
            payload: row['payload'] as String? ?? '{}',
            updatedAt: row['updated_at'] as String? ?? '',
          ),
        )
        .toList(growable: false);
  }

  Future<LocalEntityRecord?> getEntity({
    required String collection,
    required String id,
  }) async {
    if (_memoryFallbackEnabled) {
      return _memoryCollections[collection]?[id];
    }
    final db = await _open();
    final rows = await db.query(
      _tableName,
      columns: const <String>['entity_id', 'payload', 'updated_at'],
      where: 'collection = ? AND entity_id = ?',
      whereArgs: <Object?>[collection, id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return LocalEntityRecord(
      id: row['entity_id'] as String? ?? '',
      payload: row['payload'] as String? ?? '{}',
      updatedAt: row['updated_at'] as String? ?? '',
    );
  }

  Future<LocalEntityRecord> upsertEntity({
    required String collection,
    required String id,
    required String payload,
    required String updatedAt,
  }) async {
    if (_memoryFallbackEnabled) {
      final record = LocalEntityRecord(
        id: id,
        payload: payload,
        updatedAt: updatedAt,
      );
      final bucket = _memoryCollections.putIfAbsent(
        collection,
        () => <String, LocalEntityRecord>{},
      );
      bucket[id] = record;
      return record;
    }
    final db = await _open();
    await db.insert(_tableName, <String, Object?>{
      'collection': collection,
      'entity_id': id,
      'payload': payload,
      'updated_at': updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return LocalEntityRecord(id: id, payload: payload, updatedAt: updatedAt);
  }

  Future<bool> deleteEntity({
    required String collection,
    required String id,
  }) async {
    if (_memoryFallbackEnabled) {
      final bucket = _memoryCollections[collection];
      if (bucket == null) return false;
      return bucket.remove(id) != null;
    }
    final db = await _open();
    final deleted = await db.delete(
      _tableName,
      where: 'collection = ? AND entity_id = ?',
      whereArgs: <Object?>[collection, id],
    );
    return deleted > 0;
  }

  Future<int> replaceCollection({
    required String collection,
    required List<LocalEntityRecord> records,
  }) async {
    if (_memoryFallbackEnabled) {
      _memoryCollections[collection] = {
        for (final record in records) record.id: record,
      };
      return records.length;
    }
    final db = await _open();
    return db.transaction((txn) async {
      await txn.delete(
        _tableName,
        where: 'collection = ?',
        whereArgs: <Object?>[collection],
      );
      final batch = txn.batch();
      for (final record in records) {
        batch.insert(_tableName, <String, Object?>{
          'collection': collection,
          'entity_id': record.id,
          'payload': record.payload,
          'updated_at': record.updatedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      return records.length;
    });
  }

  Future<Database> _open() async {
    if (_database != null) {
      return _database!;
    }
    var factory = _databaseFactory ?? _resolveDatabaseFactory();
    try {
      _database = await _openWithFactory(factory);
      return _database!;
    } on MissingPluginException {
      if (kIsWeb || !_shouldUseDesktopFfiFallback()) {
        rethrow;
      }
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
      _databaseFactory = factory;
      _database = await _openWithFactory(factory);
      return _database!;
    }
  }

  Future<Database> _openWithFactory(DatabaseFactory factory) async {
    final databasesPath = await factory.getDatabasesPath();
    final dbPath = p.join(databasesPath, _databaseName);
    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('DROP TABLE IF EXISTS $_tableName');
            await _createSchema(db);
          }
          if (oldVersion < 3) {
            await db.delete(
              _tableName,
              where: 'collection IN (?, ?, ?)',
              whereArgs: const <Object?>[
                'commerce_payout_batches',
                'commerce_payout_adjustments',
                'commerce_payout_disputes',
              ],
            );
          }
          if (oldVersion < 4) {
            await db.delete(
              _tableName,
              where: 'collection IN (?, ?)',
              whereArgs: const <Object?>[
                'commerce_users',
                'commerce_auth_meta',
              ],
            );
          }
          if (oldVersion < 5) {
            await db.delete(
              _tableName,
              where: 'collection IN (?, ?)',
              whereArgs: const <Object?>[
                'commerce_payment_methods',
                'commerce_delivery_places',
              ],
            );
          }
          if (oldVersion < 6) {
            await db.delete(
              _tableName,
              where: 'collection = ?',
              whereArgs: const <Object?>['commerce_pricing_memory'],
            );
          }
          if (oldVersion < 7) {
            await db.delete(
              _tableName,
              where: 'collection IN (?, ?, ?)',
              whereArgs: const <Object?>[
                'commerce_customers',
                'commerce_orders',
                'commerce_reviews',
              ],
            );
          }
        },
      ),
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        collection TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (collection, entity_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${_tableName}_collection_updated_at '
      'ON $_tableName(collection, updated_at DESC)',
    );
  }

  DatabaseFactory _resolveDatabaseFactory() {
    if (_shouldUseDesktopFfiFallback()) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    try {
      return databaseFactory;
    } on StateError {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
  }

  bool _shouldUseDesktopFfiFallback() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows);
  }

  void _enableMemoryFallback() {
    _memoryFallbackEnabled = true;
    _database = null;
  }
}
