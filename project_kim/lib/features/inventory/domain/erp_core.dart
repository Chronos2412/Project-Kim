import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/domain/erp_ai_engine.dart';

class ErpCore extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  bool _loading = false;
  bool get loading => _loading;

  ErpAiEngine get ai => ErpAiEngine(_products);

  Future<void> refresh({String search = ""}) async {
    _loading = true;
    notifyListeners();

    final conn = await _db.database;

    final data = await _db.getProducts(
      db: conn,
      tagIds: [],
      search: search,
    );

    _products = data.map((e) => ProductModel.fromMap(e)).toList();

    _loading = false;
    notifyListeners();
  }
}