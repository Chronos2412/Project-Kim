import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

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
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        debugPrint("DB CREATE: version=$version");

        // =========================
        // PRODUCTS
        // =========================
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
        // PRODUCT_TAGS
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
        // PRODUCT LOGS (ERP LOGS)
        // =========================
        await db.execute('''
          CREATE TABLE product_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER NOT NULL,
            action TEXT NOT NULL,
            actionType TEXT NOT NULL,
            fieldChanged TEXT NOT NULL,
            oldValue TEXT,
            newValue TEXT,
            changedBy TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');

        debugPrint("DB CREATE FINISHED");
      },

      // =========================
      // MIGRATIONS
      // =========================
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint("DB UPGRADE: $oldVersion -> $newVersion");

        // -------------------------
        // MIGRATION: products.description
        // -------------------------
        if (oldVersion < 2) {
          final columns = await db.rawQuery("PRAGMA table_info(products)");
          final hasDescription =
              columns.any((c) => c["name"].toString() == "description");

          if (!hasDescription) {
            await db.execute("ALTER TABLE products ADD COLUMN description TEXT");
            debugPrint("DB MIGRATION: Added description column to products");
          }
        }

        // -------------------------
        // MIGRATION: product_logs basic table
        // -------------------------
        if (oldVersion < 3) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='product_logs'",
          );

          if (tables.isEmpty) {
            await db.execute('''
              CREATE TABLE product_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                productId INTEGER,
                action TEXT,
                createdAt TEXT
              )
            ''');
            debugPrint("DB MIGRATION: Created product_logs table (basic)");
          }
        }

        // -------------------------
        // MIGRATION: add changedBy
        // -------------------------
        if (oldVersion < 4) {
          final columns = await db.rawQuery("PRAGMA table_info(product_logs)");

          final hasChangedBy =
              columns.any((c) => c["name"].toString() == "changedBy");

          if (!hasChangedBy) {
            await db.execute(
              "ALTER TABLE product_logs ADD COLUMN changedBy TEXT",
            );

            // llenar valores default
            await db.execute(
              "UPDATE product_logs SET changedBy = 'system' WHERE changedBy IS NULL",
            );

            debugPrint("DB MIGRATION: Added changedBy column");
          }
        }

        // -------------------------
        // MIGRATION: actionType, fieldChanged, oldValue, newValue
        // -------------------------
        if (oldVersion < 5) {
          final columns = await db.rawQuery("PRAGMA table_info(product_logs)");

          bool hasActionType =
              columns.any((c) => c["name"].toString() == "actionType");
          bool hasFieldChanged =
              columns.any((c) => c["name"].toString() == "fieldChanged");
          bool hasOldValue =
              columns.any((c) => c["name"].toString() == "oldValue");
          bool hasNewValue =
              columns.any((c) => c["name"].toString() == "newValue");

          if (!hasActionType) {
            await db.execute(
              "ALTER TABLE product_logs ADD COLUMN actionType TEXT",
            );
            await db.execute(
              "UPDATE product_logs SET actionType = 'UPDATE' WHERE actionType IS NULL",
            );
            debugPrint("DB MIGRATION: Added actionType");
          }

          if (!hasFieldChanged) {
            await db.execute(
              "ALTER TABLE product_logs ADD COLUMN fieldChanged TEXT",
            );
            await db.execute(
              "UPDATE product_logs SET fieldChanged = 'ALL' WHERE fieldChanged IS NULL",
            );
            debugPrint("DB MIGRATION: Added fieldChanged");
          }

          if (!hasOldValue) {
            await db.execute(
              "ALTER TABLE product_logs ADD COLUMN oldValue TEXT",
            );
            debugPrint("DB MIGRATION: Added oldValue");
          }

          if (!hasNewValue) {
            await db.execute(
              "ALTER TABLE product_logs ADD COLUMN newValue TEXT",
            );
            debugPrint("DB MIGRATION: Added newValue");
          }

          // asegurar defaults para evitar NOT NULL
          await db.execute(
            "UPDATE product_logs SET changedBy = 'system' WHERE changedBy IS NULL",
          );

          await db.execute(
            "UPDATE product_logs SET actionType = 'UPDATE' WHERE actionType IS NULL",
          );

          await db.execute(
            "UPDATE product_logs SET fieldChanged = 'ALL' WHERE fieldChanged IS NULL",
          );

          debugPrint("DB MIGRATION: product_logs updated to full ERP schema");
        }
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
  // COUNT PRODUCTS (DEBUG)
  // =========================
  Future<int> countProducts(Database db) async {
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM products",
    );

    return (result.first["total"] as int?) ?? 0;
  }

  // =========================
  // RESET DEMO DATA
  // =========================
  Future<void> resetDemoData(Database db) async {
    debugPrint("RESET DEMO DATA START");

    await db.delete("product_tags");
    await db.delete("tags");
    await db.delete("product_logs");
    await db.delete("products");

    debugPrint("RESET DEMO DATA: tables cleared");

    await seedDemoProducts(db);

    debugPrint("RESET DEMO DATA FINISHED: total = ${await countProducts(db)}");
  }

  // =========================
  // SEED DEMO PRODUCTS
  // =========================
  Future<void> seedDemoProducts(Database db) async {
    debugPrint("SEED SMART START");

    final now = DateTime.now().toIso8601String();

    final demoProducts = [
      {
        "name": "Batas Médicas",
        "description": "Bata desechable para personal médico",
        "categoryId": 1,
        "brand": "KimCare",
        "supplier": "Proveedor Central",
        "unitPrice": 1500.0,
        "stockQuantity": 40.0,
        "stockUnit": "unit",
        "minStockQuantity": 50.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
      {
        "name": "Guantes de Nitrilo",
        "description": "Caja de guantes talla M",
        "categoryId": 1,
        "brand": "SafeHands",
        "supplier": "Distribuidora Médica",
        "unitPrice": 3500.0,
        "stockQuantity": 120.0,
        "stockUnit": "box",
        "minStockQuantity": 100.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
      {
        "name": "Mascarillas Quirúrgicas",
        "description": "Caja de mascarillas 50 unidades",
        "categoryId": 1,
        "brand": "MedProtect",
        "supplier": "Proveedor Central",
        "unitPrice": 2500.0,
        "stockQuantity": 90.0,
        "stockUnit": "box",
        "minStockQuantity": 80.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
      {
        "name": "Alcohol en Gel",
        "description": "Botella de alcohol gel 500ml",
        "categoryId": 1,
        "brand": "CleanMax",
        "supplier": "Farmacia Mayorista",
        "unitPrice": 2200.0,
        "stockQuantity": 25.0,
        "stockUnit": "unit",
        "minStockQuantity": 30.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
      {
        "name": "Jabón Antibacterial",
        "description": "Jabón líquido antibacterial",
        "categoryId": 1,
        "brand": "BioSafe",
        "supplier": "Farmacia Mayorista",
        "unitPrice": 1800.0,
        "stockQuantity": 60.0,
        "stockUnit": "unit",
        "minStockQuantity": 40.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
      {
        "name": "Gasas Esterilizadas",
        "description": "Paquete de gasas esterilizadas",
        "categoryId": 1,
        "brand": "SterilPro",
        "supplier": "Distribuidora Médica",
        "unitPrice": 1200.0,
        "stockQuantity": 15.0,
        "stockUnit": "box",
        "minStockQuantity": 20.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
      {
        "name": "Termómetro Digital",
        "description": "Termómetro digital portátil",
        "categoryId": 1,
        "brand": "ThermoPlus",
        "supplier": "Proveedor Central",
        "unitPrice": 4500.0,
        "stockQuantity": 12.0,
        "stockUnit": "unit",
        "minStockQuantity": 10.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
      {
        "name": "Toallas Desinfectantes",
        "description": "Paquete de toallas desinfectantes",
        "categoryId": 1,
        "brand": "WipeClean",
        "supplier": "Proveedor Central",
        "unitPrice": 3000.0,
        "stockQuantity": 18.0,
        "stockUnit": "box",
        "minStockQuantity": 25.0,
        "lastUpdatedAt": now,
        "lastUpdatedBy": "seed",
      },
    ];

    for (final p in demoProducts) {
      final id = await db.insert(
        "products",
        p,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await insertLog(
        db,
        id,
        "Producto creado: ${p["name"]}",
        actionType: "CREATE",
        fieldChanged: "ALL",
        changedBy: "seed",
        oldValue: "",
        newValue: p["name"].toString(),
      );

      debugPrint("SEED INSERTED: ${p["name"]} (id=$id)");
    }

    debugPrint("SEED SMART FINISHED: total = ${await countProducts(db)}");
  }

  // =========================
  // GET PRODUCTS
  // =========================
  Future<List<Map<String, dynamic>>> getProducts({
    required Database db,
    List<int>? tagIds,
    String? search,
  }) async {
    final searchQuery = (search ?? "").trim().toLowerCase();
    final hasSearch = searchQuery.isNotEmpty;
    final hasTags = tagIds != null && tagIds.isNotEmpty;

    final searchLike = "%$searchQuery%";

    if (!hasTags && !hasSearch) {
      return await db.query(
        'products',
        orderBy: 'name ASC',
      );
    }

    final whereParts = <String>[];
    final args = <dynamic>[];

    if (hasTags) {
      whereParts.add(
        '''
        EXISTS (
          SELECT 1
          FROM product_tags pt
          WHERE pt.productId = p.id
          AND pt.tagId IN (${List.filled(tagIds.length, '?').join(',')})
        )
        ''',
      );

      args.addAll(tagIds);
    }

    if (hasSearch) {
      whereParts.add(
        '''
        (
          LOWER(p.name) LIKE ?
          OR LOWER(p.brand) LIKE ?
          OR LOWER(p.supplier) LIKE ?
        )
        ''',
      );

      args.addAll([searchLike, searchLike, searchLike]);
    }

    final whereClause =
        whereParts.isEmpty ? "1=1" : whereParts.join(" AND ");

    return await db.rawQuery(
      '''
      SELECT p.*
      FROM products p
      WHERE $whereClause
      ORDER BY p.name ASC
      ''',
      args,
    );
  }

  // =========================
  // LOGS (FULL ERP)
  // =========================
  Future<void> insertLog(
    Database db,
    int productId,
    String action, {
    String actionType = "UPDATE",
    String fieldChanged = "ALL",
    String changedBy = "system",
    String? oldValue,
    String? newValue,
  }) async {
    await db.insert(
      'product_logs',
      {
        'productId': productId,
        'action': action,
        'actionType': actionType,
        'fieldChanged': fieldChanged,
        'oldValue': oldValue,
        'newValue': newValue,
        'changedBy': changedBy,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getLogsByProduct(
    Database db,
    int productId,
  ) async {
    return await db.query(
      "product_logs",
      where: "productId = ?",
      whereArgs: [productId],
      orderBy: "createdAt DESC",
    );
  }

  Future<List<Map<String, dynamic>>> getAllLogs(Database db) async {
    return await db.query(
      "product_logs",
      orderBy: "createdAt DESC",
    );
  }

  Future<List<Map<String, dynamic>>> getLogsByType(
    Database db,
    String actionType,
  ) async {
    return await db.query(
      "product_logs",
      where: "actionType = ?",
      whereArgs: [actionType],
      orderBy: "createdAt DESC",
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
}