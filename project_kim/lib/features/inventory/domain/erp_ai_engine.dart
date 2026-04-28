import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ErpAiEngine {
  final List<ProductModel> products;

  ErpAiEngine(this.products);

  // =========================
  // VALIDACIONES
  // =========================
  bool _hasValidMin(ProductModel p) {
    return p.minStockQuantity > 0;
  }

  // =========================
  // CRÍTICO
  // stock <= minStock
  // =========================
  bool isCritical(ProductModel p) {
    if (!_hasValidMin(p)) return false;
    return p.stockQuantity <= p.minStockQuantity;
  }

  // =========================
  // RIESGO
  // stock > minStock AND <= minStock * 1.2
  // =========================
  bool isRisk(ProductModel p) {
    if (!_hasValidMin(p)) return false;

    final min = p.minStockQuantity;
    final warning = min * 1.2;

    return p.stockQuantity > min && p.stockQuantity <= warning;
  }

  // =========================
  // LISTA CRÍTICOS
  // =========================
  List<ProductModel> criticalStock() {
    return products.where(isCritical).toList();
  }

  // =========================
  // LISTA RIESGO
  // =========================
  List<ProductModel> riskProducts() {
    return products.where(isRisk).toList();
  }

  // =========================
  // SCORE DE SALUD (%)
  // =========================
  double healthScore() {
    if (products.isEmpty) return 100;

    final criticalCount = criticalStock().length;
    final riskCount = riskProducts().length;

    // peso:
    // crítico resta 10%
    // riesgo resta 5%
    double score = 100 - (criticalCount * 10) - (riskCount * 5);

    if (score < 0) score = 0;
    if (score > 100) score = 100;

    return score;
  }

  // =========================
  // RISK LEVEL (0 - 100)
  // =========================
  double riskLevel(ProductModel p) {
    if (!_hasValidMin(p)) return 0;

    final stock = p.stockQuantity;
    final min = p.minStockQuantity;

    if (stock <= 0) return 100;

    // Si está por debajo del mínimo → riesgo máximo
    if (stock <= min) return 100;

    // Si está dentro del rango de riesgo → riesgo medio
    final warning = min * 1.2;
    if (stock <= warning) return 70;

    // Si está saludable
    return 0;
  }

  // =========================
  // TOP RISK PRODUCTS
  // =========================
  List<ProductModel> topRiskProducts({int limit = 5}) {
    final list = [...products];

    list.sort((a, b) => riskLevel(b).compareTo(riskLevel(a)));

    return list.take(limit).toList();
  }

  // =========================
  // INSIGHT (TEXT AI)
  // =========================
  String insight() {
    final critical = criticalStock().length;
    final risk = riskProducts().length;

    if (critical > 0) {
      return "⚠️ Hay $critical productos críticos. Se recomienda reabastecer inmediatamente.";
    }

    if (risk > 0) {
      return "🟠 Hay $risk productos en riesgo. Revisa pronto el inventario.";
    }

    return "✅ Inventario saludable. No hay productos en riesgo ni críticos.";
  }
}