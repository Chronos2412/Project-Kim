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

  double get totalValue {
    return _products.fold(
      0,
      (sum, p) => sum + (p.unitPrice * p.stockQuantity),
    );
  }

  int get lowStockCount {
    return _products.where((p) => p.stockQuantity <= p.minStockQuantity).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = _products.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard 360"),
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
            // KPI CARDS
            // =========================
            Row(
              children: [
                _kpi("Productos", total.toString(), Colors.blue),
                const SizedBox(width: 10),
                _kpi("Stock Bajo", lowStockCount.toString(), Colors.red),
                const SizedBox(width: 10),
                _kpi("Valor ₡", totalValue.toStringAsFixed(0), Colors.green),
              ],
            ),

            const SizedBox(height: 20),

            // =========================
            // INSIGHT BOX
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getInsight(),
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

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
                      value: lowStockCount.toDouble(),
                      title: "Low",
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
          color: color.withValues(alpha: 0.1),
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

  String _getInsight() {
    if (lowStockCount == 0) {
      return "✅ Inventario saludable. No hay riesgos de stock bajo.";
    } else if (lowStockCount < 3) {
      return "⚠️ Atención: algunos productos están cerca de agotarse.";
    } else {
      return "🚨 Riesgo alto: múltiples productos con stock crítico.";
    }
  }
}