import 'package:flutter/foundation.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/domain/erp_ai_engine.dart';

class ErpCore extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  bool loading = false;

  List<ProductModel> products = [];

  ErpAiEngine get ai => ErpAiEngine(products);

  // =========================
  // SET PRODUCTS (InventoryScreen use)
  // =========================
  void setProducts(List<ProductModel> newProducts) {
    products = newProducts;
    notifyListeners();
  }

  // =========================
  // REFRESH FROM DB (ERP use)
  // =========================
  Future<void> refresh() async {
    loading = true;
    notifyListeners();

    final db = await _db.database;

    final result = await _db.getProducts(
      db: db,
      tagIds: [],
      search: "",
    );

    products = result.map((e) => ProductModel.fromMap(e)).toList();

    loading = false;
    notifyListeners();

    debugPrint("ERP CORE REFRESH DONE: products=${products.length}");
  }
}