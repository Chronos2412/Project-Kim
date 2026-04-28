import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_logs_screen.dart';

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
  late ProductModel _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: _product),
      ),
    );

    if (result == true) {
      if (!mounted) return;

      // Volver al InventoryScreen para que recargue data
      Navigator.pop(context, true);
    }
  }

  void _openLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductLogsScreen(product: _product),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "N/A";
    return DateFormat("yyyy-MM-dd HH:mm").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final stock = _product.stockQuantity;
    final minStock = _product.minStockQuantity;

    final isCritical = minStock > 0 && stock < minStock;
    final isRisk = minStock > 0 && stock >= minStock && stock < (minStock * 1.2);

    String statusText = "OK";
    Color statusColor = Colors.green;

    if (isCritical) {
      statusText = "CRÍTICO";
      statusColor = Colors.red;
    } else if (isRisk) {
      statusText = "RIESGO";
      statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Ver Historial",
            icon: const Icon(Icons.history),
            onPressed: _openLogs,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text(
                        statusText,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: statusColor,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if ((_product.description ?? "").trim().isNotEmpty)
                  Text(
                    _product.description!,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),

                _infoRow("Marca", _product.brand),
                _infoRow("Proveedor", _product.supplier),
                _infoRow("Precio Unitario", "₡${_product.unitPrice}"),
                _infoRow("Stock", "${_product.stockQuantity}"),
                _infoRow("Unidad", _product.stockUnit),
                _infoRow("Stock Mínimo", "${_product.minStockQuantity}"),

                const SizedBox(height: 10),
                const Divider(),

                _infoRow(
                  "Última actualización",
                  _formatDate(_product.lastUpdatedAt),
                ),
                _infoRow(
                  "Actualizado por",
                  _product.lastUpdatedBy.isEmpty ? "N/A" : _product.lastUpdatedBy,
                ),

                const SizedBox(height: 18),

                // BOTONES
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text("Ver Historial"),
                        onPressed: _openLogs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Editar"),
                        onPressed: _openEdit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}