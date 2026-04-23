import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppDatabase _db = AppDatabase();
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await _db.database;
    final data = await _db.getProducts(db: db);

    setState(() {
      _products = data.map((e) => ProductModel.fromMap(e)).toList();
    });
  }

  // =========================
  // METRICS
  // =========================

  double get totalValue =>
      _products.fold(0, (s, p) => s + (p.unitPrice * p.stockQuantity));

  int get lowStock =>
      _products.where((p) => p.stockQuantity <= p.minStockQuantity).length;

  int get criticalStock =>
      _products.where((p) => p.stockQuantity <= (p.minStockQuantity * 0.5)).length;

  // 🔥 SIMULATED CONSUMPTION (ERP logic básico)
  double _dailyConsumption(ProductModel p) {
    final base = p.minStockQuantity * 0.2;
    return base == 0 ? 1 : base;
  }

  int _daysLeft(ProductModel p) {
    final consumption = _dailyConsumption(p);
    if (consumption <= 0) return 999;
    return (p.stockQuantity / consumption).floor();
  }

  // =========================
  // INSIGHTS ENGINE
  // =========================

  String getInsight() {
    if (criticalStock > 0) {
      return "🚨 CRÍTICO: Hay productos en riesgo inmediato de ruptura de stock.";
    }
    if (lowStock > 0) {
      return "⚠️ Atención: inventario con niveles bajos detectados.";
    }
    return "✅ Inventario estable. Sin riesgos detectados.";
  }

  // =========================
  // TOP PRODUCTS
  // =========================

  List<ProductModel> get topValueProducts {
    final list = [..._products];
    list.sort((a, b) =>
        (b.unitPrice * b.stockQuantity)
            .compareTo(a.unitPrice * a.stockQuantity));
    return list.take(3).toList();
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final total = _products.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ERP Inteligente 360"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // =========================
            // KPI ROW
            // =========================
            Row(
              children: [
                _kpi("Productos", "$total", Colors.blue),
                const SizedBox(width: 10),
                _kpi("Bajo Stock", "$lowStock", Colors.orange),
                const SizedBox(width: 10),
                _kpi("Críticos", "$criticalStock", Colors.red),
              ],
            ),

            const SizedBox(height: 12),

            // =========================
            // INSIGHT BOX
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getInsight(),
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // TOP PRODUCTS
            // =========================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Top Productos (Valor)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topValueProducts.length,
                itemBuilder: (context, i) {
                  final p = topValueProducts[i];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("₡${(p.unitPrice * p.stockQuantity).toStringAsFixed(0)}"),
                        const SizedBox(height: 6),
                        Text("Días: ${_daysLeft(p)}"),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // =========================
            // CHART
            // =========================
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: total.toDouble(),
                      title: "Total",
                      color: Colors.blue,
                    ),
                    PieChartSectionData(
                      value: lowStock.toDouble(),
                      title: "Low",
                      color: Colors.orange,
                    ),
                    PieChartSectionData(
                      value: criticalStock.toDouble(),
                      title: "Crit",
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}