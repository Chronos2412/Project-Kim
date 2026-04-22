import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AppDatabase _db = AppDatabase();

  late ProductModel product;

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  // =========================
  // DELETE PRODUCT
  // =========================
  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: const Text(
          "¿Estás seguro de que deseas eliminar este producto?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = await _db.database;

    await db.delete(
      "products",
      where: "id = ?",
      whereArgs: [product.id],
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  // =========================
  // EDIT (placeholder listo para conectar form)
  // =========================
  Future<void> _editProduct() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductFormScreen(product: product),
    ),
  );

  if (result == true) {
    // opcional: podrías recargar del DB aquí si quieres
    Navigator.pop(context, true);
  }
}

  // =========================
  // UI HELPERS
  // =========================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _stockColor() {
    return product.isLowStock ? Colors.red : Colors.green;
  }

  String _stockText() {
    return "${product.stockQuantity} ${product.stockUnit}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProduct,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteProduct,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // TITLE
            // =========================
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // =========================
            // INFO SECTION
            // =========================
            _infoRow("Marca:", product.brand),
            _infoRow("Proveedor:", product.supplier),
            _infoRow("Precio:", "₡${product.unitPrice}"),

            const SizedBox(height: 12),

            // =========================
            // STOCK HIGHLIGHT
            // =========================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _stockColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _stockColor()),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Stock disponible",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _stockText(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _stockColor(),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _infoRow("Stock mínimo:", "${product.minStockQuantity}"),
            _infoRow("Unidad:", product.stockUnit),
            _infoRow("Última actualización:",
                product.lastUpdatedAt.toLocal().toString()),
            _infoRow("Actualizado por:", product.lastUpdatedBy),

            const SizedBox(height: 24),

            // =========================
            // WARNING
            // =========================
            if (product.isLowStock)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Stock bajo: considera reabastecer este producto.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}