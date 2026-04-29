import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:project_kim/features/bookings/presentation/screens/booking_form_screen.dart';

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
          LOWER(celebrantFirstName) LIKE ?
          OR LOWER(celebrantLastName) LIKE ?
          OR LOWER(guardianName) LIKE ?
          OR LOWER(customerPhone) LIKE ?
          OR LOWER(packageName) LIKE ?
          OR LOWER(fullAddress) LIKE ?
        ORDER BY eventDate DESC
      ''', [like, like, like, like, like, like]);
    }

    setState(() {
      _bookings = results;
      _loading = false;
    });
  }

  int _countByStatus(String status) {
    return _bookings.where((b) => b["status"] == status).length;
  }

  int _countByType(String type) {
    return _bookings.where((b) => b["bookingType"] == type).length;
  }

  Widget _buildKpiCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
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

  Color _statusColor(String status) {
    if (status == "Pendiente") return Colors.orange;
    if (status == "Confirmada") return Colors.blue;
    if (status == "Pagada") return Colors.green;
    if (status == "Cancelada") return Colors.red;
    if (status == "Finalizada") return Colors.grey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _countByStatus("Pendiente");
    final confirmadas = _countByStatus("Confirmada");
    final pagadas = _countByStatus("Pagada");

    final cotizaciones = _countByType("COTIZACION");
    final reservaciones = _countByType("RESERVACION");

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
            // ==========================
            // KPI CARDS (STATUS)
            // ==========================
            Row(
              children: [
                _buildKpiCard(
                  "Pendientes",
                  pendientes,
                  Icons.pending_actions,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  "Confirmadas",
                  confirmadas,
                  Icons.check_circle,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  "Pagadas",
                  pagadas,
                  Icons.paid,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==========================
            // KPI CARDS (TYPE)
            // ==========================
            Row(
              children: [
                _buildKpiCard(
                  "Cotizaciones",
                  cotizaciones,
                  Icons.description,
                  Colors.purple,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  "Reservaciones",
                  reservaciones,
                  Icons.event_available,
                  Colors.teal,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  "Total",
                  _bookings.length,
                  Icons.list_alt,
                  Colors.black87,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==========================
            // SEARCH
            // ==========================
            TextField(
              decoration: InputDecoration(
                labelText: "Buscar evento",
                hintText: "Festejad@, encargado, teléfono, paquete o dirección",
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

            // ==========================
            // LIST
            // ==========================
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

                            final status = booking["status"] ?? "Pendiente";
                            final type = booking["bookingType"] ?? "RESERVACION";

                            final celebrant =
                                "${booking["celebrantFirstName"]} ${booking["celebrantLastName"]}";

                            return Card(
                              elevation: 2,
                              child: ListTile(
                                leading: Icon(
                                  type == "COTIZACION"
                                      ? Icons.description
                                      : Icons.event_note,
                                  color: type == "COTIZACION"
                                      ? Colors.purple
                                      : Colors.teal,
                                ),
                                title: Text(
                                  "Fiesta de $celebrant",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "📅 ${_formatDate(booking["eventDate"])} • ⏰ ${booking["timeSlot"]}",
                                    ),
                                    Text("👤 Encargado: ${booking["guardianName"]}"),
                                    Text("📞 ${booking["customerPhone"]}"),
                                    Text("🎁 ${booking["packageName"]}"),
                                    Text(
                                      "Total: ${_formatCurrency(total)} | Adelanto: ${_formatCurrency(deposit)}",
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Chip(
                                      label: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _statusColor(status),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type == "COTIZACION"
                                          ? "Cotización"
                                          : "Reservación",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: type == "COTIZACION"
                                            ? Colors.purple
                                            : Colors.teal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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