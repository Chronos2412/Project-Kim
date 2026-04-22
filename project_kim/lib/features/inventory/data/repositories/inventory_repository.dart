import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/category_model.dart';
import 'package:project_kim/features/inventory/data/models/product_log_model.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/data/models/tag_model.dart';

class InventoryRepository {
  // -------------------------
  // CATEGORY CRUD
  // -------------------------

  Future<int> createCategory(String name) async {
    final db = await AppDatabase().database;

    final category = CategoryModel(
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    return await db.insert("categories", category.toMap());
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await AppDatabase().database;

    final rows = await db.query(
      "categories",
      orderBy: "name ASC",
    );

    return rows.map((row) => CategoryModel.fromMap(row)).toList();
  }

  // -------------------------
  // TAG CRUD
  // -------------------------

  Future<int> createTag(String name) async {
    final db = await AppDatabase().database;

    final tag = TagModel(
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    return await db.insert("tags", tag.toMap());
  }

  Future<List<TagModel>> getTags() async {
    final db = await AppDatabase().database;

    final rows = await db.query(
      "tags",
      orderBy: "name ASC",
    );

    return rows.map((row) => TagModel.fromMap(row)).toList();
  }

  Future<TagModel?> getTagByName(String name) async {
    final db = await AppDatabase().database;

    final rows = await db.query(
      "tags",
      where: "name = ?",
      whereArgs: [name.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return TagModel.fromMap(rows.first);
  }

  // -------------------------
  // PRODUCT CRUD
  // -------------------------

  Future<int> createProduct(ProductModel product) async {
    final db = await AppDatabase().database;

    final id = await db.insert("products", product.toMap());

    // log
    await addProductLog(
      ProductLogModel(
        productId: id,
        changedBy: product.lastUpdatedBy,
        actionType: "CREATE",
        fieldChanged: "ALL",
        oldValue: null,
        newValue: "Product Created",
        createdAt: DateTime.now(),
      ),
    );

    return id;
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await AppDatabase().database;

    return await db.update(
      "products",
      product.toMap(),
      where: "id = ?",
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(int productId, String deletedBy) async {
    final db = await AppDatabase().database;

    await addProductLog(
      ProductLogModel(
        productId: productId,
        changedBy: deletedBy,
        actionType: "DELETE",
        fieldChanged: "ALL",
        oldValue: null,
        newValue: "Product Deleted",
        createdAt: DateTime.now(),
      ),
    );

    await db.delete(
      "products",
      where: "id = ?",
      whereArgs: [productId],
    );
  }

  Future<List<ProductModel>> getProducts() async {
    final db = await AppDatabase().database;

    final rows = await db.query(
      "products",
      orderBy: "name ASC",
    );

    return rows.map((row) => ProductModel.fromMap(row)).toList();
  }

  Future<ProductModel?> getProductById(int productId) async {
    final db = await AppDatabase().database;

    final rows = await db.query(
      "products",
      where: "id = ?",
      whereArgs: [productId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  // -------------------------
  // PRODUCT TAGS (MANY TO MANY)
  // -------------------------

  Future<void> assignTagsToProduct({
    required int productId,
    required List<int> tagIds,
  }) async {
    final db = await AppDatabase().database;

    // remove existing
    await db.delete(
      "product_tags",
      where: "productId = ?",
      whereArgs: [productId],
    );

    // insert new
    for (final tagId in tagIds) {
      await db.insert("product_tags", {
        "productId": productId,
        "tagId": tagId,
      });
    }
  }

  Future<List<TagModel>> getTagsForProduct(int productId) async {
    final db = await AppDatabase().database;

    final rows = await db.rawQuery('''
      SELECT t.id, t.name, t.createdAt
      FROM tags t
      INNER JOIN product_tags pt ON pt.tagId = t.id
      WHERE pt.productId = ?
      ORDER BY t.name ASC
    ''', [productId]);

    return rows.map((row) => TagModel.fromMap(row)).toList();
  }

  // -------------------------
  // SEARCH
  // -------------------------

  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await AppDatabase().database;
    final q = "%${query.trim().toLowerCase()}%";

    final rows = await db.rawQuery('''
      SELECT DISTINCT p.*
      FROM products p
      LEFT JOIN categories c ON c.id = p.categoryId
      LEFT JOIN product_tags pt ON pt.productId = p.id
      LEFT JOIN tags t ON t.id = pt.tagId
      WHERE 
        LOWER(p.name) LIKE ?
        OR LOWER(p.brand) LIKE ?
        OR LOWER(p.supplier) LIKE ?
        OR LOWER(c.name) LIKE ?
        OR LOWER(t.name) LIKE ?
      ORDER BY p.name ASC
    ''', [q, q, q, q, q]);

    return rows.map((row) => ProductModel.fromMap(row)).toList();
  }

  // -------------------------
  // PRODUCT LOGS
  // -------------------------

  Future<int> addProductLog(ProductLogModel log) async {
    final db = await AppDatabase().database;
    return await db.insert("product_logs", log.toMap());
  }

  Future<List<ProductLogModel>> getProductLogsLast2Months(int productId) async {
    final db = await AppDatabase().database;

    final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));

    final rows = await db.query(
      "product_logs",
      where: "productId = ? AND createdAt >= ?",
      whereArgs: [productId, twoMonthsAgo.toIso8601String()],
      orderBy: "createdAt DESC",
    );

    return rows.map((row) => ProductLogModel.fromMap(row)).toList();
  }

  // -------------------------
  // HELPERS
  // -------------------------

  Future<void> logProductFieldChange({
    required int productId,
    required String changedBy,
    required String fieldChanged,
    required String? oldValue,
    required String? newValue,
  }) async {
    await addProductLog(
      ProductLogModel(
        productId: productId,
        changedBy: changedBy,
        actionType: "UPDATE",
        fieldChanged: fieldChanged,
        oldValue: oldValue,
        newValue: newValue,
        createdAt: DateTime.now(),
      ),
    );
  }
}