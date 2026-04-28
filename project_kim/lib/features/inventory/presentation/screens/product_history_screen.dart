import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';

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
  final AppDatabase _db = AppDatabase();

  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final db = await _db.database;

    final logs = await _db.getLogsByProduct(db, widget.productId);

    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial - ${widget.productName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text("No hay historial disponible."))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];

                    final action = log["action"]?.toString() ?? "";
                    final createdAt = log["createdAt"]?.toString() ?? "";

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(action),
                      subtitle: Text(_formatDate(createdAt)),
                    );
                  },
                ),
    );
  }
}