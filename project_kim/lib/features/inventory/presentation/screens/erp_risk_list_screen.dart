import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/domain/erp_core.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';

class ErpRiskListScreen extends StatefulWidget {
  final ErpCore core;
  final bool showCritical;

  const ErpRiskListScreen({
    super.key,
    required this.core,
    required this.showCritical,
  });

  @override
  State<ErpRiskListScreen> createState() => _ErpRiskListScreenState();
}

class _ErpRiskListScreenState extends State<ErpRiskListScreen> {
  List<ProductModel> _list = [];

  @override
  void initState() {
    super.initState();
    _loadFromCore();
  }

  // =========================
  // LOAD LIST FROM CORE (SAFE)
  // =========================
  void _loadFromCore() {
    final ai = widget.core.ai;

    setState(() {
      _list = widget.showCritical ? ai.criticalStock() : ai.riskProducts();
    });
  }

  // =========================
  // REFRESH CORE + LIST
  // =========================
  Future<void> _refreshAll() async {
    await widget.core.refresh();

    if (!mounted) return;

    _loadFromCore();

    // Si ya no quedan productos, regresar al dashboard ERP
    if (_list.isEmpty) {
      Navigator.pop(context, true);
    }
  }

  // =========================
  // EDIT PRODUCT
  // =========================
  Future<void> _editProduct(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );

    // Si el usuario guardó cambios
    if (result == true) {
      await _refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.showCritical ? "Productos Críticos" : "Productos en Riesgo";

    final emptyMessage = widget.showCritical
        ? "No hay productos críticos 🎉"
        : "No hay productos en riesgo 🎉";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refrescar",
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: widget.core.loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _list.length,
                  itemBuilder: (context, index) {
                    final p = _list[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              widget.showCritical ? Colors.red : Colors.orange,
                          child: const Icon(
                            Icons.warning,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          "Stock: ${p.stockQuantity} / Min: ${p.minStockQuantity}",
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _editProduct(p),
                      ),
                    );
                  },
                ),
    );
  }
}