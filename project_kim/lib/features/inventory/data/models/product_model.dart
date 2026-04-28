class ProductModel {
  final int? id;
  final int categoryId;

  final String name;
  final String? description;

  final String brand;
  final String supplier;

  final double unitPrice;
  final double stockQuantity;
  final String stockUnit;
  final double minStockQuantity;

  final DateTime? lastUpdatedAt;
  final String lastUpdatedBy;

  ProductModel({
    this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.brand,
    required this.supplier,
    required this.unitPrice,
    required this.stockQuantity,
    required this.stockUnit,
    required this.minStockQuantity,
    required this.lastUpdatedAt,
    required this.lastUpdatedBy,
  });

  // =========================
  // FROM MAP (DB -> MODEL)
  // =========================
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map["id"] as int?,
      categoryId: (map["categoryId"] as int?) ?? 1,
      name: (map["name"] ?? "").toString(),
      description: map["description"]?.toString(),
      brand: (map["brand"] ?? "").toString(),
      supplier: (map["supplier"] ?? "").toString(),
      unitPrice: _toDouble(map["unitPrice"]),
      stockQuantity: _toDouble(map["stockQuantity"]),
      stockUnit: (map["stockUnit"] ?? "unit").toString(),
      minStockQuantity: _toDouble(map["minStockQuantity"]),
      lastUpdatedAt: _toDate(map["lastUpdatedAt"]),
      lastUpdatedBy: (map["lastUpdatedBy"] ?? "").toString(),
    );
  }

  // =========================
  // TO MAP (MODEL -> DB)
  // =========================
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "categoryId": categoryId,
      "name": name,
      "description": description,
      "brand": brand,
      "supplier": supplier,
      "unitPrice": unitPrice,
      "stockQuantity": stockQuantity,
      "stockUnit": stockUnit,
      "minStockQuantity": minStockQuantity,
      "lastUpdatedAt": lastUpdatedAt?.toIso8601String(),
      "lastUpdatedBy": lastUpdatedBy,
    };
  }

  // =========================
  // COPY WITH
  // =========================
  ProductModel copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    String? brand,
    String? supplier,
    double? unitPrice,
    double? stockQuantity,
    String? stockUnit,
    double? minStockQuantity,
    DateTime? lastUpdatedAt,
    String? lastUpdatedBy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      supplier: supplier ?? this.supplier,
      unitPrice: unitPrice ?? this.unitPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockUnit: stockUnit ?? this.stockUnit,
      minStockQuantity: minStockQuantity ?? this.minStockQuantity,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
    );
  }

  // =========================
  // HELPERS
  // =========================
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}