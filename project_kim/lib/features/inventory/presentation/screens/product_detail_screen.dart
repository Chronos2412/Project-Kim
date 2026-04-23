import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock =
        product.stockQuantity <= product.minStockQuantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // HEADER CARD
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLowStock
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isLowStock
                        ? Icons.warning
                        : Icons.check_circle,
                    color: isLowStock
                        ? Colors.red
                        : Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isLowStock
                          ? "Stock crítico"
                          : "Stock saludable",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLowStock
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // INFO
            // =========================
            _infoRow("Marca", product.brand),
            _infoRow("Proveedor", product.supplier),
            _infoRow(
              "Precio",
              "₡${product.unitPrice}",
            ),
            _infoRow(
              "Stock",
              "${product.stockQuantity} ${product.stockUnit}",
            ),
            _infoRow(
              "Mínimo",
              "${product.minStockQuantity}",
            ),

            const Spacer(),

            // =========================
            // CLOSE BUTTON
            // =========================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("Cerrar"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // INFO ROW WIDGET
  // =========================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}