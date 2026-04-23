import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/data/models/product_log_model.dart';
import 'package:project_kim/features/inventory/data/repositories/inventory_repository.dart';

class ProductHistoryScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductHistoryScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends State<ProductHistoryScreen> {
  final InventoryRepository _repo = InventoryRepository();

  bool _loading = true;
  List<ProductLogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  String _translateAction(String action) {
    switch (action) {
      case "CREATE":
        return "Creación";
      case "UPDATE":
        return "Actualización";
      case "DELETE":
        return "Eliminación";
      case "ADJUST_STOCK":
        return "Ajuste de Stock";
      default:
        return action;
    }
  }

  String _translateField(String field) {
    switch (field) {
      case "ALL":
        return "Producto Completo";
      case "name":
        return "Nombre";
      case "unitPrice":
        return "Precio por Unidad";
      case "stockQuantity":
        return "Cantidad en Stock";
      case "stockUnit":
        return "Unidad";
      case "brand":
        return "Marca";
      case "supplier":
        return "Proveedor";
      case "minStockQuantity":
        return "Stock Mínimo";
      case "categoryId":
        return "Categoría";
      default:
        return field;
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);

    final logs = await _repo.getProductLogsLast2Months(widget.productId);

    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return "${local.day.toString().padLeft(2, '0')}/"
        "${local.month.toString().padLeft(2, '0')}/"
        "${local.year} "
        "${local.hour.toString().padLeft(2, '0')}:"
        "${local.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial: ${widget.productName}"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    "No hay historial en los últimos 2 meses.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        title: Text(
                          "${_translateAction(log.actionType)} - ${_translateField(log.fieldChanged)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Fecha: ${_formatDate(log.createdAt)}"),
                              Text("Usuario: ${log.changedBy}"),
                              if (log.oldValue != null || log.newValue != null)
                                Text(
                                  "Cambio: ${log.oldValue ?? "-"} → ${log.newValue ?? "-"}",
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}