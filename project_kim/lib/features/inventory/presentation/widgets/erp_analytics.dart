import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ErpAnalytics extends StatelessWidget {
  final List<ProductModel> products;

  const ErpAnalytics({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final totalProducts = products.length;

    final totalStock = products.fold<double>(
      0,
      (sum, p) => sum + p.stockQuantity,
    );

    final lowStock = products.where(
      (p) => p.stockQuantity <= p.minStockQuantity,
    ).length;

    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.stockQuantity * p.unitPrice),
    );

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ERP Analytics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kpiCard(
                "Productos",
                totalProducts.toString(),
                Colors.blue,
              ),
              _kpiCard(
                "Stock Total",
                totalStock.toStringAsFixed(0),
                Colors.green,
              ),
              _kpiCard(
                "Bajo Stock",
                lowStock.toString(),
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Valor Total Inventario",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  "₡${totalValue.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // KPI CARD
  // =========================
  Widget _kpiCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
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
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}