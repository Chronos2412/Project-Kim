import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/bookings/presentation/screens/booking_form_screen.dart';
import 'package:project_kim/features/bookings/presentation/screens/booking_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final AppDatabase _db = AppDatabase();

  List<Map<String, dynamic>> _bookings = [];
  String _search = "";

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);

    final db = await _db.database;

    final searchQuery = _search.trim().toLowerCase();
    final hasSearch = searchQuery.isNotEmpty;

    List<Map<String, dynamic>> results;

    if (!hasSearch) {
      results = await db.query(
        "bookings",
        orderBy: "eventDate DESC",
      );
    } else {
      final like = "%$searchQuery%";

      results = await db.rawQuery('''
        SELECT *
        FROM bookings
        WHERE 
          LOWER(guardianName) LIKE ?
          OR LOWER(customerPhone) LIKE ?
          OR LOWER(packageName) LIKE ?
          OR LOWER(fullAddress) LIKE ?
          OR LOWER(division) LIKE ?
        ORDER BY eventDate DESC
      ''', [like, like, like, like, like]);
    }

    setState(() {
      _bookings = results;
      _loading = false;
    });
  }

  int _countByStatus(String status) {
    return _bookings.where((b) => b["status"] == status).length;
  }

  Widget _buildKpiCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 6),
              Text(
                "$value",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: "es_CR", symbol: "₡");
    return f.format(value);
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat("dd/MM/yyyy").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _countByStatus("Pendiente");
    final confirmadas = _countByStatus("Confirmada");
    final pagadas = _countByStatus("Pagada");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eventos"),
        actions: [
          IconButton(
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BookingFormScreen(),
            ),
          );

          if (result == true) {
            _loadBookings();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Evento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildKpiCard("Pendientes", pendientes, Icons.pending_actions),
                const SizedBox(width: 8),
                _buildKpiCard("Confirmadas", confirmadas, Icons.check_circle),
                const SizedBox(width: 8),
                _buildKpiCard("Pagadas", pagadas, Icons.paid),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Buscar evento",
                hintText: "Encargado, teléfono, paquete, dirección o división",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _search = value);
                _loadBookings();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _bookings.isEmpty
                      ? const Center(
                          child: Text("No hay eventos registrados."),
                        )
                      : ListView.builder(
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];

                            final total =
                                (booking["totalAmount"] as num).toDouble();
                            final deposit =
                                (booking["depositAmount"] as num).toDouble();

                            final division =
                                (booking["division"] ?? "Sin división").toString();

                            return Card(
                              elevation: 2,
                              child: ListTile(
                                leading: const Icon(Icons.event_note),
                                title: Text(
                                  booking["guardianName"] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("📌 División: $division"),
                                    Text(
                                      "📅 ${_formatDate(booking["eventDate"])} • 📍 ${booking["fullAddress"]}",
                                    ),
                                    Text("🎁 Paquete: ${booking["packageName"]}"),
                                    Text(
                                      "Total: ${_formatCurrency(total)} | Depósito: ${_formatCurrency(deposit)}",
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      booking["status"] ?? "",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: booking["status"] == "Pendiente"
                                            ? Colors.orange
                                            : booking["status"] == "Confirmada"
                                                ? Colors.blue
                                                : booking["status"] == "Pagada"
                                                    ? Colors.green
                                                    : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingDetailScreen(
                                        bookingId: booking["id"],
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    _loadBookings();
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}