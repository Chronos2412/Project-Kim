class ProductModel {
  final int? id;
  final int categoryId;
  final String name;
  final double unitPrice;
  final double stockQuantity;
  final String stockUnit; // "unit" | "ml" | "kg"
  final String brand;
  final String supplier;
  final double minStockQuantity;
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

  bool get isLowStock => stockQuantity < minStockQuantity;

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

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map["id"],
      categoryId: map["categoryId"],
      name: map["name"],
      unitPrice: (map["unitPrice"] as num).toDouble(),
      stockQuantity: (map["stockQuantity"] as num).toDouble(),
      stockUnit: map["stockUnit"],
      brand: map["brand"],
      supplier: map["supplier"],
      minStockQuantity: (map["minStockQuantity"] as num).toDouble(),
      lastUpdatedAt: DateTime.parse(map["lastUpdatedAt"]),
      lastUpdatedBy: map["lastUpdatedBy"],
    );
  }
}