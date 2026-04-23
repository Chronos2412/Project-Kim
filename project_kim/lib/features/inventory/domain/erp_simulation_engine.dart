import '../data/models/product_model.dart';

class ErpSimulationEngine {
  final List<ProductModel> products;

  ErpSimulationEngine(this.products);

  // =========================
  // CONSUMO BASE
  // =========================
  double _dailyConsumption(ProductModel p) {
    final base = p.minStockQuantity * 0.3;
    return base <= 0 ? 1 : base;
  }

  // =========================
  // SIMULAR STOCK EN N DÍAS
  // =========================
  double simulateStock(ProductModel p, int days, double demandMultiplier) {
    final daily = _dailyConsumption(p) * demandMultiplier;
    final consumption = daily * days;

    return p.stockQuantity - consumption;
  }

  // =========================
  // SIMULAR ESCENARIO GLOBAL
  // =========================
  Map<String, dynamic> simulateScenario({
    double demandMultiplier = 1.0,
    int days = 30,
  }) {
    double totalRemainingStock = 0;
    int stockouts = 0;
    int criticalItems = 0;

    for (final p in products) {
      final remaining =
          simulateStock(p, days, demandMultiplier);

      totalRemainingStock += remaining;

      if (remaining <= 0) {
        stockouts++;
      }

      if (remaining > 0 &&
          remaining <= p.minStockQuantity) {
        criticalItems++;
      }
    }

    return {
      "days": days,
      "demandMultiplier": demandMultiplier,
      "totalRemainingStock": totalRemainingStock,
      "stockouts": stockouts,
      "criticalItems": criticalItems,
    };
  }

  // =========================
  // ESCENARIOS PRECONFIGURADOS
  // =========================

  Map<String, dynamic> optimistic() {
    return simulateScenario(
      demandMultiplier: 0.8,
      days: 30,
    );
  }

  Map<String, dynamic> normal() {
    return simulateScenario(
      demandMultiplier: 1.0,
      days: 30,
    );
  }

  Map<String, dynamic> stress() {
    return simulateScenario(
      demandMultiplier: 1.5,
      days: 30,
    );
  }

  Map<String, dynamic> crisis() {
    return simulateScenario(
      demandMultiplier: 2.0,
      days: 30,
    );
  }

  // =========================
  // INSIGHT ENGINE (ERP AI)
  // =========================
  String insight() {
    final stress = simulateScenario(
      demandMultiplier: 1.5,
      days: 30,
    );

    final stockouts = stress["stockouts"] as int;
    final critical = stress["criticalItems"] as int;

    if (stockouts > 0) {
      return "🚨 SIMULACIÓN: riesgo de $stockouts productos sin stock en 30 días.";
    }

    if (critical > 0) {
      return "⚠️ SIMULACIÓN: $critical productos entran en zona crítica.";
    }

    return "✅ SIMULACIÓN: inventario estable bajo escenarios normales y estrés.";
  }
}