class ProductModel {
  final int? id;
  final int categoryId;

  final String name;

  final double unitPrice;

  // 🔥 STOCK DEBE SER INT en inventario real
  final int stockQuantity;

  final String stockUnit; // "unit" | "ml" | "kg"

  final String brand;
  final String supplier;

  final int minStockQuantity;

  final DateTime lastUpdatedAt;
  final String lastUpdatedBy;

  ProductModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.unitPrice,
    required this.stockQuantity,
    required this.stockUnit,
    required this.brand,
    required this.supplier,
    required this.minStockQuantity,
    required this.lastUpdatedAt,
    required this.lastUpdatedBy,
  });

  // -------------------------
  // BUSINESS LOGIC
  // -------------------------
  bool get isLowStock => stockQuantity <= minStockQuantity;

  // -------------------------
  // TO MAP (DB)
  // -------------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "categoryId": categoryId,
      "name": name,
      "unitPrice": unitPrice,
      "stockQuantity": stockQuantity,
      "stockUnit": stockUnit,
      "brand": brand,
      "supplier": supplier,
      "minStockQuantity": minStockQuantity,
      "lastUpdatedAt": lastUpdatedAt.toIso8601String(),
      "lastUpdatedBy": lastUpdatedBy,
    };
  }

  // -------------------------
  // FROM MAP (DB)
  // -------------------------
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map["id"],
      categoryId: map["categoryId"],
      name: map["name"],
      unitPrice: (map["unitPrice"] as num).toDouble(),

      // 🔥 FIX: int seguro
      stockQuantity: (map["stockQuantity"] as num).toInt(),

      stockUnit: map["stockUnit"],
      brand: map["brand"],
      supplier: map["supplier"],

      // 🔥 FIX: int seguro
      minStockQuantity: (map["minStockQuantity"] as num).toInt(),

      lastUpdatedAt: DateTime.parse(map["lastUpdatedAt"]),
      lastUpdatedBy: map["lastUpdatedBy"],
    );
  }
}