import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/domain/erp_core.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';

class ErpRiskListScreen extends StatelessWidget {
  final String mode; // "critical" o "risk"
  final ErpCore core;

  const ErpRiskListScreen({
    super.key,
    required this.mode,
    required this.core,
  });

  @override
  Widget build(BuildContext context) {
    final ai = core.ai;

    final list = mode == "critical"
        ? ai.criticalStock()
        : ai.riskProducts();

    final title =
        mode == "critical" ? "Productos Críticos" : "Productos en Riesgo";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No hay productos en esta categoría"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Volver al ERP"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final p = list[index];
                final risk = ai.riskLevel(p);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          mode == "critical" ? Colors.red : Colors.orange,
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      "Stock: ${p.stockQuantity} / Min: ${p.minStockQuantity}",
                    ),
                    trailing: Text(
                      "${risk.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(product: p),
                        ),
                      );

                      if (result == true) {
                        await core.refresh();

                        final updatedList = mode == "critical"
                            ? core.ai.criticalStock()
                            : core.ai.riskProducts();

                        // si ya no hay críticos/riesgo, volvemos al ERP
                        if (updatedList.isEmpty) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}