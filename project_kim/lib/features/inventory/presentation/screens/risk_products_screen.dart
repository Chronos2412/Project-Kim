import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';
import 'package:project_kim/features/inventory/domain/erp_ai_engine.dart';

class RiskProductsScreen extends StatefulWidget {
  const RiskProductsScreen({super.key});

  @override
  State<RiskProductsScreen> createState() =>
      _RiskProductsScreenState();
}

class _RiskProductsScreenState extends State<RiskProductsScreen> {
  final AppDatabase _db = AppDatabase();

  List<ProductModel> _riskProducts = [];

  @override
  void initState() {
    super.initState();
    _loadRiskProducts();
  }

  Future<void> _loadRiskProducts() async {
    final db = await _db.database;

    final data = await _db.getProducts(db: db);

    final products =
        data.map((e) => ProductModel.fromMap(e)).toList();

    final ai = ErpAiEngine(products);

    setState(() {
      _riskProducts = ai.riskProducts();
    });
  }

  Future<void> _edit(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductFormScreen(product: product),
      ),
    );

    _loadRiskProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Productos en Riesgo"),
      ),
      body: _riskProducts.isEmpty
          ? const Center(
              child: Text("Sin productos en riesgo"),
            )
          : ListView.builder(
              itemCount: _riskProducts.length,
              itemBuilder: (context, index) {
                final p = _riskProducts[index];

                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      "Stock: ${p.stockQuantity} • "
                      "Mínimo: ${p.minStockQuantity}",
                    ),
                    trailing: const Icon(
                      Icons.warning,
                      color: Colors.red,
                    ),
                    onTap: () => _edit(p),
                  ),
                );
              },
            ),
    );
  }
}