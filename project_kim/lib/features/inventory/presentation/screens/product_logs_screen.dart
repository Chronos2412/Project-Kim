import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ProductLogsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductLogsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductLogsScreen> createState() => _ProductLogsScreenState();
}

class _ProductLogsScreenState extends State<ProductLogsScreen> {
  final AppDatabase _db = AppDatabase();

  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _loading = true;
    });

    final db = await _db.database;

    final logs = await _db.getLogsByProduct(
      db,
      widget.product.id!,
    );

    if (!mounted) return;

    setState(() {
      _logs = logs;
      _loading = false;
    });

    debugPrint("LOGS FOUND: ${logs.length}");
  }

  String _formatDate(String? iso) {
    if (iso == null) return "-";

    try {
      final dt = DateTime.parse(iso);
      return DateFormat("dd/MM/yyyy - HH:mm").format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial - ${widget.product.name}"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refrescar",
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    "No hay historial todavía.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];

                    final action = log["action"]?.toString() ?? "Sin acción";
                    final createdAt = log["createdAt"]?.toString();
                    final changedBy = log["changedBy"]?.toString() ?? "unknown";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.history),
                        ),
                        title: Text(action),
                        subtitle: Text(
                          "${_formatDate(createdAt)}\nPor: $changedBy",
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}