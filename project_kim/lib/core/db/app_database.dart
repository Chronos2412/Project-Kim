import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  // =========================
  // GET DB INSTANCE
  // =========================
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('project_kim.db');
    return _db!;
  }

  // =========================
  // INIT DATABASE
  // =========================
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,

      onConfigure: (db) async {
        // 🔥 IMPORTANT: enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (db, version) async {
        // =========================
        // PRODUCTS
        // =========================
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        // =========================
        // TAGS
        // =========================
        await db.execute('''
          CREATE TABLE tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            createdAt TEXT NOT NULL
          )
        ''');

        // =========================
        // PRODUCT_TAGS (MANY TO MANY)
        // =========================
        await db.execute('''
          CREATE TABLE product_tags (
            productId INTEGER NOT NULL,
            tagId INTEGER NOT NULL,
            PRIMARY KEY (productId, tagId),
            FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE,
            FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE
          )
        ''');

        // =========================
        // PRODUCT LOGS
        // =========================
        await db.execute('''
          CREATE TABLE product_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER NOT NULL,
            action TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // =====================================================
  // 🟢 TAGS
  // =====================================================

  Future<int> getOrCreateTag(Database db, String name) async {
    final normalized = name.trim();

    final result = await db.query(
      'tags',
      where: 'LOWER(name) = ?',
      whereArgs: [normalized.toLowerCase()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }

    return await db.insert('tags', {
      'name': normalized,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllTags(Database db) async {
    return await db.query(
      'tags',
      orderBy: 'name ASC',
    );
  }

  // =====================================================
  // 🟢 PRODUCT TAGS RELATION
  // =====================================================

  Future<void> saveProductTags(
    Database db,
    int productId,
    List<String> tagNames,
  ) async {
    // remove old relations
    await db.delete(
      'product_tags',
      where: 'productId = ?',
      whereArgs: [productId],
    );

    for (final name in tagNames) {
      final tagId = await getOrCreateTag(db, name);

      await db.insert('product_tags', {
        'productId': productId,
        'tagId': tagId,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getTagsByProduct(
    Database db,
    int productId,
  ) async {
    return await db.rawQuery('''
      SELECT t.*
      FROM tags t
      INNER JOIN product_tags pt ON pt.tagId = t.id
      WHERE pt.productId = ?
    ''', [productId]);
  }

  // =====================================================
  // 🟢 PRODUCTS FILTER
  // =====================================================

  Future<List<Map<String, dynamic>>> getProductsByTags(
  Database db,
  List<int> tagIds,
) async {
  if (tagIds.isEmpty) {
    return await db.query(
      'products',
      orderBy: 'name ASC',
    );
  }

  final placeholders = List.filled(tagIds.length, '?').join(',');

  return await db.rawQuery('''
    SELECT DISTINCT p.*
    FROM products p
    INNER JOIN product_tags pt ON pt.productId = p.id
    WHERE pt.tagId IN ($placeholders)
    ORDER BY p.name ASC
  ''', tagIds);
}

  // =====================================================
  // 🟢 OPTIONAL: LOGS
  // =====================================================

  Future<void> insertLog(
    Database db,
    int productId,
    String action,
  ) async {
    await db.insert('product_logs', {
      'productId': productId,
      'action': action,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}