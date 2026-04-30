import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';

class BookingPaymentsScreen extends StatefulWidget {
  final int bookingId;
  final String bookingStatus;

  const BookingPaymentsScreen({
    super.key,
    required this.bookingId,
    required this.bookingStatus,
  });

  @override
  State<BookingPaymentsScreen> createState() => _BookingPaymentsScreenState();
}

class _BookingPaymentsScreenState extends State<BookingPaymentsScreen> {
  final AppDatabase _db = AppDatabase();

  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: "es_CR", symbol: "₡");
    return f.format(value);
  }

  String _formatDate(String isoDate) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return isoDate;
    return DateFormat("dd/MM/yyyy").format(d);
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);

    final db = await _db.database;

    final results = await db.query(
      "booking_payments",
      where: "bookingId = ?",
      whereArgs: [widget.bookingId],
      orderBy: "paymentDate DESC",
    );

    setState(() {
      _payments = results;
      _loading = false;
    });
  }

  double _getTotalPayments() {
    double total = 0;
    for (final p in _payments) {
      total += (p["amount"] as num).toDouble();
    }
    return total;
  }

  Future<void> _addPayment() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Registrar Pago"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Monto (₡)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: "Nota (opcional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;

    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Monto inválido.")),
      );
      return;
    }

    final db = await _db.database;

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    await db.insert("booking_payments", {
      "bookingId": widget.bookingId,
      "amount": amount,
      "paymentDate": nowIso,
      "createdAt": nowIso,
      "createdBy": "system",
      "note": noteController.text.trim(),
    });

    await _db.insertBookingLog(
      db,
      widget.bookingId,
      "Pago registrado: ${_formatCurrency(amount)}",
      actionType: "PAYMENT",
      fieldChanged: "amount",
      changedBy: "system",
      oldValue: "",
      newValue: amount.toString(),
    );

    await _loadPayments();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _deletePayment(int paymentId, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Eliminar Pago"),
          content: Text(
            "¿Deseas eliminar este pago?\n\nMonto: ${_formatCurrency(amount)}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final db = await _db.database;

    await db.delete(
      "booking_payments",
      where: "id = ?",
      whereArgs: [paymentId],
    );

    await _db.insertBookingLog(
      db,
      widget.bookingId,
      "Pago eliminado: ${_formatCurrency(amount)}",
      actionType: "PAYMENT_DELETE",
      fieldChanged: "amount",
      changedBy: "system",
      oldValue: amount.toString(),
      newValue: "",
    );

    await _loadPayments();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    final totalPayments = _getTotalPayments();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pagos del Evento"),
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPayment,
        icon: const Icon(Icons.add),
        label: const Text("Agregar pago"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total pagado",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatCurrency(totalPayments),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _payments.isEmpty
                      ? const Center(child: Text("No hay pagos registrados."))
                      : ListView.builder(
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final p = _payments[index];

                            final amount = (p["amount"] as num).toDouble();

                            return Card(
                              elevation: 2,
                              child: ListTile(
                                leading: const Icon(Icons.payments),
                                title: Text(
                                  _formatCurrency(amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("📅 ${_formatDate(p["paymentDate"] ?? "")}"),
                                    if ((p["note"] ?? "")
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                      Text("📝 ${p["note"]}"),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePayment(
                                    p["id"] as int,
                                    amount,
                                  ),
                                ),
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