import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:project_kim/features/inventory/domain/erp_ai_engine.dart';
import 'package:project_kim/features/inventory/presentation/screens/erp_control_center_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final AppDatabase _db = AppDatabase();

  List<ProductModel> _products = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await _db.database;

    final products = await _db.getProducts(
      db: db,
      tagIds: [],
      search: _searchCtrl.text,
    );

    setState(() {
      _products = products.map((e) => ProductModel.fromMap(e)).toList();
    });
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductFormScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openEdit(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openDetail(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );

    _loadData();
  }

  Widget _kpi(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = ErpAiEngine(_products);

    final health = ai.healthScore();
    final riskCount = ai.riskProducts().length;
    final criticalCount = ai.criticalStock().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario 360"),
        centerTitle: true,

        // =========================
        // ERP BUTTON
        // =========================
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: "Centro de Control ERP",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ErpControlCenterScreen(),
                ),
              );

              // 🔥 refresca automáticamente al volver del ERP
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // =========================
          // KPI BAR
          // =========================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _kpi(
                    "Salud",
                    "${health.toStringAsFixed(0)}%",
                  ),
                  _kpi(
                    "En riesgo",
                    riskCount.toString(),
                  ),
                  _kpi(
                    "Críticos",
                    criticalCount.toString(),
                  ),
                ],
              ),
            ),
          ),

          // =========================
          // SEARCH
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _loadData(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Buscar producto...",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // LIST
          // =========================
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text("No hay productos"))
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final isLow = p.stockQuantity <= p.minStockQuantity;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLow ? Colors.red : Colors.green,
                            child: Icon(
                              isLow ? Icons.warning : Icons.inventory,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            "Marca: ${p.brand} • Stock: ${p.stockQuantity} ${p.stockUnit} • ₡${p.unitPrice}",
                          ),
                          onTap: () => _openDetail(p),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                            ],
                            onSelected: (_) => _openEdit(p),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}