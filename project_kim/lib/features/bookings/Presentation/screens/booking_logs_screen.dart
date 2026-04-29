import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';

class BookingLogsScreen extends StatefulWidget {
  final int bookingId;

  const BookingLogsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingLogsScreen> createState() => _BookingLogsScreenState();
}

class _BookingLogsScreenState extends State<BookingLogsScreen> {
  final AppDatabase _db = AppDatabase();

  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat("dd/MM/yyyy HH:mm").format(date);
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);

    final db = await _db.database;
    final logs = await _db.getBookingLogs(db, widget.bookingId);

    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Reservación"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text("No hay historial disponible."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          log["action"] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tipo: ${log["actionType"]}"),
                            Text("Campo: ${log["fieldChanged"]}"),
                            Text("Por: ${log["changedBy"]}"),
                            Text("Fecha: ${_formatDate(log["createdAt"])}"),
                            if ((log["oldValue"] ?? "").toString().isNotEmpty)
                              Text("Antes: ${log["oldValue"]}"),
                            if ((log["newValue"] ?? "").toString().isNotEmpty)
                              Text("Después: ${log["newValue"]}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}