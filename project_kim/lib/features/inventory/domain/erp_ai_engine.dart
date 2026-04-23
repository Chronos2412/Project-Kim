import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ErpAiEngine {
  final List<ProductModel> products;

  ErpAiEngine(this.products);

  // =========================
  // 🧠 HEALTH DEL INVENTARIO
  // =========================
  double healthScore() {
  if (products.isEmpty) return 0;

  final healthy = products.where((p) {
    return p.stockQuantity > p.minStockQuantity;
  }).length;

  return (healthy / products.length) * 100;
}

  // =========================
  // 📦 COBERTURA DE STOCK
  // =========================
  double _stockCoverage(ProductModel p) {
    if (p.minStockQuantity <= 0) return 100;

    final coverage =
        (p.stockQuantity / p.minStockQuantity) * 100;

    return coverage.clamp(0, 100).toDouble();
  }

  // =========================
  // ⚠️ RISK LEVEL (0 - 100)
  // =========================
  double riskLevel(ProductModel p) {
    final coverage = _stockCoverage(p);

    final risk = 100 - coverage;

    return risk.clamp(0, 100).toDouble();
  }

  // =========================
  // 🔴 PRODUCTOS EN RIESGO
  // =========================
  List<ProductModel> riskProducts() {
    return products.where((p) {
      return riskLevel(p) > 20;
    }).toList();
  }

  // =========================
  // 🔴 CRÍTICOS (STOCK BAJO)
  // =========================
  List<ProductModel> criticalStock() {
    return products.where((p) {
      return p.stockQuantity <= p.minStockQuantity;
    }).toList();
  }

  // =========================
  // 🔥 TOP RISK PRODUCTS (FIX DEL ERROR)
  // =========================
  List<ProductModel> topRiskProducts() {
    final sorted = List<ProductModel>.from(products);

    sorted.sort((a, b) {
      return riskLevel(b).compareTo(riskLevel(a));
    });

    return sorted;
  }

  // =========================
  // 💰 VALOR TOTAL INVENTARIO
  // =========================
  double totalInventoryValue() {
    double total = 0;

    for (final p in products) {
      total += p.unitPrice * p.stockQuantity;
    }

    return total;
  }

  // =========================
  // ⏳ DAYS LEFT (BÁSICO ERP)
  // =========================
  int daysLeft(ProductModel p) {
    if (p.stockQuantity <= 0) return 0;

    const dailyConsumption = 1;

    return (p.stockQuantity / dailyConsumption).floor();
  }

  // =========================
  // 🧠 INSIGHT ERP
  // =========================
  String insight() {
    final risk = riskProducts().length;

    if (risk == 0) {
      return "Inventario saludable";
    } else if (risk <= 3) {
      return "Atención: productos en riesgo";
    } else {
      return "Alerta crítica de inventario";
    }
  }
}