import '../models/product_model.dart';

class ErpIntelligenceRepository {
  final List<ProductModel> products;

  ErpIntelligenceRepository(this.products);

  // =========================
  // 🚨 CRITICAL STOCK
  // =========================
  List<ProductModel> get criticalStock {
    return products
        .where((p) => p.stockQuantity <= 0)
        .toList();
  }

  // =========================
  // ⚠️ LOW STOCK
  // =========================
  List<ProductModel> get lowStock {
    return products
        .where((p) =>
            p.stockQuantity > 0 &&
            p.stockQuantity <= p.minStockQuantity)
        .toList();
  }

  // =========================
  // 📦 REORDER SUGGESTIONS
  // =========================
  Map<ProductModel, double> get reorderSuggestions {
    final Map<ProductModel, double> result = {};

    for (final p in products) {
      if (p.stockQuantity <= p.minStockQuantity) {
        final suggested =
            (p.minStockQuantity * 2) - p.stockQuantity;

        result[p] = suggested.clamp(1, 9999);
      }
    }

    return result;
  }

  // =========================
  // 💰 TOP VALUE PRODUCTS
  // =========================
  List<ProductModel> get topValueProducts {
    final sorted = List<ProductModel>.from(products);

    sorted.sort((a, b) =>
        (b.unitPrice * b.stockQuantity)
            .compareTo(a.unitPrice * a.stockQuantity));

    return sorted.take(5).toList();
  }

  // =========================
  // 💀 DEAD STOCK
  // =========================
  List<ProductModel> get deadStock {
    return products
        .where((p) => p.stockQuantity == 0)
        .toList();
  }

  // =========================
  // 📊 HEALTH SCORE
  // =========================
  double get healthScore {
    if (products.isEmpty) return 100;

    final critical = criticalStock.length;
    final low = lowStock.length;

    final score =
        100 - ((critical * 3) + (low * 1.5));

    return score.clamp(0, 100);
  }
}