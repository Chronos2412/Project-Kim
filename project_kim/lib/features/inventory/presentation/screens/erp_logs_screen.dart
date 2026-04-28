import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';

class ErpLogsScreen extends StatefulWidget {
  const ErpLogsScreen({super.key});

  @override
  State<ErpLogsScreen> createState() => _ErpLogsScreenState();
}

class _ErpLogsScreenState extends State<ErpLogsScreen> {
  final AppDatabase _db = AppDatabase();

  bool _loading = true;

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _filtered = [];

  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedType = "ALL";

  // Labels en español (lo que ve el usuario)
  static const Map<String, String> logTypeLabels = {
    "ALL": "Todos",
    "STOCK": "Stock",
    "PRICE": "Precio",
    "MIN_STOCK": "Stock Mínimo",
    "CREATE": "Creación",
    "UPDATE": "Edición",
    "DELETE": "Eliminación",
  };

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // =========================
  // LOAD LOGS
  // =========================
  Future<void> _loadLogs() async {
    setState(() {
      _loading = true;
    });

    final db = await _db.database;
    final raw = await _db.getAllLogs(db);

    if (!mounted) return;

    setState(() {
      _logs = raw;
      _filtered = raw;
      _loading = false;
    });
  }

  // =========================
  // APPLY FILTER
  // =========================
  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();

    List<Map<String, dynamic>> result = List.from(_logs);

    // Filtrar por tipo
    if (_selectedType != "ALL") {
      result = result.where((log) {
        final type = (log["actionType"] ?? "").toString();
        return type == _selectedType;
      }).toList();
    }

    // Filtrar por búsqueda
    if (query.isNotEmpty) {
      result = result.where((log) {
        final productName = (log["productName"] ?? "").toString().toLowerCase();
        final action = (log["action"] ?? "").toString().toLowerCase();
        final changedBy = (log["changedBy"] ?? "").toString().toLowerCase();

        return productName.contains(query) ||
            action.contains(query) ||
            changedBy.contains(query);
      }).toList();
    }

    setState(() {
      _filtered = result;
    });
  }

  // =========================
  // FORMAT DATE
  // =========================
  String _formatDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return "Sin fecha";

    try {
      final dt = DateTime.parse(iso);
      return DateFormat("dd/MM/yyyy HH:mm").format(dt);
    } catch (_) {
      return iso;
    }
  }

  // =========================
  // BUILD LOG CARD
  // =========================
  Widget _logCard(Map<String, dynamic> log) {
    final productName = (log["productName"] ?? "Producto desconocido").toString();
    final action = (log["action"] ?? "").toString();
    final actionType = (log["actionType"] ?? "").toString();
    final changedBy = (log["changedBy"] ?? "Sistema").toString();
    final createdAt = _formatDate(log["createdAt"]?.toString());

    final typeLabel = logTypeLabels[actionType] ?? actionType;

    IconData icon = Icons.history;
    Color color = Colors.blueGrey;

    switch (actionType) {
      case "STOCK":
        icon = Icons.inventory_2;
        color = Colors.orange;
        break;
      case "PRICE":
        icon = Icons.attach_money;
        color = Colors.green;
        break;
      case "MIN_STOCK":
        icon = Icons.warning;
        color = Colors.red;
        break;
      case "CREATE":
        icon = Icons.add_circle;
        color = Colors.blue;
        break;
      case "UPDATE":
        icon = Icons.edit;
        color = Colors.purple;
        break;
      case "DELETE":
        icon = Icons.delete;
        color = Colors.black87;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(action),
            const SizedBox(height: 6),
            Text(
              "Tipo: $typeLabel | Usuario: $changedBy",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            Text(
              createdAt,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial ERP"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Refrescar",
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),

                // SEARCH + FILTER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          labelText: "Buscar en historial",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _applyFilters();
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: "Filtrar por tipo",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: logTypeLabels.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedType = val;
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // LIST
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text("No hay registros en el historial."),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final log = _filtered[index];
                            return _logCard(log);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}