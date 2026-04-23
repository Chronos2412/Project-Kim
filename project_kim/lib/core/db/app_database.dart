import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  // =========================
  // DB INSTANCE
  // =========================
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('project_kim.db');
    return _db!;
  }

  // =========================
  // INIT DB
  // =========================
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            categoryId INTEGER,
            brand TEXT,
            supplier TEXT,
            unitPrice REAL,
            stockQuantity REAL,
            stockUnit TEXT,
            minStockQuantity REAL,
            lastUpdatedAt TEXT,
            lastUpdatedBy TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE product_tags (
            productId INTEGER NOT NULL,
            tagId INTEGER NOT NULL,
            PRIMARY KEY (productId, tagId),
            FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE,
            FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE product_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER,
            action TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  // =========================
  // INSERT PRODUCT
  // =========================
  Future<int> insertProduct(
    Database db,
    Map<String, dynamic> data,
  ) async {
    return await db.insert(
      'products',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =========================
  // UPDATE PRODUCT
  // =========================
  Future<int> updateProduct(
    Database db,
    Map<String, dynamic> data,
  ) async {
    final id = data['id'];

    return await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // GET PRODUCTS (SEARCH + FILTER)
  // =========================
  Future<List<Map<String, dynamic>>> getProducts({
    required Database db,
    List<int>? tagIds,
    String? search,
  }) async {
    final searchQuery = (search ?? "").trim();
    final hasSearch = searchQuery.isNotEmpty;
    final hasTags = tagIds != null && tagIds.isNotEmpty;

    final searchLike = "%${searchQuery.toLowerCase()}%";

    if (!hasTags && !hasSearch) {
      return await db.query(
        'products',
        orderBy: 'name ASC',
      );
    }

    final tagsCondition = hasTags
        ? "pt.tagId IN (${List.filled(tagIds.length, '?').join(',')})"
        : "1=1";

    return await db.rawQuery(
      '''
      SELECT DISTINCT p.*
      FROM products p
      LEFT JOIN product_tags pt ON pt.productId = p.id
      LEFT JOIN tags t ON t.id = pt.tagId
      WHERE
        $tagsCondition
        AND (
          ? = ''
          OR LOWER(p.name) LIKE ?
          OR LOWER(p.brand) LIKE ?
          OR LOWER(p.supplier) LIKE ?
          OR LOWER(t.name) LIKE ?
        )
      ORDER BY p.name ASC
      ''',
      [
        if (hasTags) ...tagIds,
        searchQuery,
        searchLike,
        searchLike,
        searchLike,
        searchLike,
      ],
    );
  }

  // =========================
  // TAGS
  // =========================
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

  // =========================
  // PRODUCT TAGS
  // =========================
  Future<void> saveProductTags(
    Database db,
    int productId,
    List<String> tagNames,
  ) async {
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

  // =========================
  // LOGS
  // =========================
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