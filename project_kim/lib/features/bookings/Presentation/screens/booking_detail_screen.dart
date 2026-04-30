import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/bookings/presentation/screens/booking_form_screen.dart';
import 'package:project_kim/features/bookings/presentation/screens/booking_logs_screen.dart';
import 'package:project_kim/features/bookings/presentation/screens/booking_payments_screen.dart';
import 'package:project_kim/features/bookings/services/booking_pdf_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final AppDatabase _db = AppDatabase();

  Map<String, dynamic>? _booking;
  double _paymentsTotal = 0;
  bool _loading = true;

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: "es_CR", symbol: "₡");
    return f.format(value);
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return DateFormat("dd/MM/yyyy").format(date);
  }

  String _timeSlotLabel(String slot) {
    switch (slot) {
      case "9am-12pm":
        return "9:00 a.m. - 12:00 p.m.";
      case "10am-1pm":
        return "10:00 a.m. - 1:00 p.m.";
      case "2pm-5pm":
        return "2:00 p.m. - 5:00 p.m.";
      case "3pm-6pm":
        return "3:00 p.m. - 6:00 p.m.";
      default:
        return slot;
    }
  }

  bool _isCotizacion() {
    final type = (_booking?["bookingType"] ?? "RESERVACION").toString();
    return type.toUpperCase() == "COTIZACION";
  }

  Future<void> _loadBooking() async {
    setState(() => _loading = true);

    final db = await _db.database;

    final bookingResult = await db.query(
      "bookings",
      where: "id = ?",
      whereArgs: [widget.bookingId],
      limit: 1,
    );

    if (bookingResult.isEmpty) {
      setState(() {
        _booking = null;
        _loading = false;
      });
      return;
    }

    final paymentsTotal =
        await _db.getTotalPaymentsForBooking(db, widget.bookingId);

    setState(() {
      _booking = bookingResult.first;
      _paymentsTotal = paymentsTotal;
      _loading = false;
    });
  }

  double _getPendingBalance() {
    if (_booking == null) return 0;

    final total = (_booking!["totalAmount"] as num).toDouble();
    final deposit = (_booking!["depositAmount"] as num).toDouble();

    final pending = total - deposit - _paymentsTotal;
    return pending < 0 ? 0 : pending;
  }

  String _calculateStatus(double total, double deposit, double paymentsTotal) {
    if (total <= 0) return "Pendiente";

    final pending = total - deposit - paymentsTotal;

    if (pending <= 0) return "Pagada";

    final minDeposit = total * 0.30;

    if (deposit >= minDeposit) return "Confirmada";

    return "Pendiente";
  }

  Future<void> _autoUpdateStatusIfNeeded() async {
    if (_booking == null) return;

    final db = await _db.database;

    final total = (_booking!["totalAmount"] as num).toDouble();
    final deposit = (_booking!["depositAmount"] as num).toDouble();

    final currentStatus = (_booking!["status"] ?? "Pendiente").toString();
    final newStatus = _calculateStatus(total, deposit, _paymentsTotal);

    if (currentStatus == "Cancelada" || currentStatus == "Finalizada") {
      return;
    }

    if (currentStatus != newStatus) {
      await db.update(
        "bookings",
        {"status": newStatus},
        where: "id = ?",
        whereArgs: [widget.bookingId],
      );

      await _db.insertBookingLog(
        db,
        widget.bookingId,
        "Cambio automático de estado: $currentStatus → $newStatus",
        actionType: "STATUS",
        fieldChanged: "status",
        changedBy: _booking!["createdBy"] ?? "system",
        oldValue: currentStatus,
        newValue: newStatus,
      );

      await _loadBooking();
    }
  }

  Future<void> _markAsCancelled() async {
    if (_booking == null) return;

    final db = await _db.database;

    final currentStatus = (_booking!["status"] ?? "Pendiente").toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Cancelar Evento"),
          content: const Text(
            "¿Estás seguro de cancelar este evento?\n\n"
            "Esto se registrará en el historial.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sí, cancelar"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await db.update(
      "bookings",
      {"status": "Cancelada"},
      where: "id = ?",
      whereArgs: [widget.bookingId],
    );

    await _db.insertBookingLog(
      db,
      widget.bookingId,
      "Evento cancelado",
      actionType: "STATUS",
      fieldChanged: "status",
      changedBy: _booking!["createdBy"] ?? "system",
      oldValue: currentStatus,
      newValue: "Cancelada",
    );

    await _loadBooking();
  }

  Future<void> _deleteBooking() async {
    if (_booking == null) return;

    final db = await _db.database;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Eliminar Evento"),
          content: const Text(
            "⚠️ Esta acción eliminará el evento y sus pagos.\n\n"
            "¿Deseas continuar?",
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

    await db.delete(
      "booking_payments",
      where: "bookingId = ?",
      whereArgs: [widget.bookingId],
    );

    await db.delete(
      "booking_logs",
      where: "bookingId = ?",
      whereArgs: [widget.bookingId],
    );

    await db.delete(
      "bookings",
      where: "id = ?",
      whereArgs: [widget.bookingId],
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _generatePdf() async {
    if (_booking == null) return;

    try {
      final bytes = await BookingPdfService.generateBookingPdf(
        bookingData: _booking!,
      );

      final nowStr = DateFormat("yyyyMMdd_HHmm").format(DateTime.now());

      final type = _isCotizacion() ? "cotizacion" : "reservacion";
      final suggestedName = "evento_${type}_$nowStr.pdf";

      final saveLocation = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: "PDF",
            extensions: ["pdf"],
          ),
        ],
      );

      if (saveLocation == null) return;

      final file = File(saveLocation.path);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("PDF generado"),
          content: Text("Archivo guardado en:\n\n${file.path}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      final db = await _db.database;

      await _db.insertBookingLog(
        db,
        widget.bookingId,
        "PDF generado para el evento",
        actionType: "PDF",
        fieldChanged: "ALL",
        changedBy: _booking!["createdBy"] ?? "system",
        oldValue: "",
        newValue: file.path,
      );
    } catch (e) {
      debugPrint("PDF GENERATE ERROR: $e");

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("No se pudo generar el PDF.\n\n$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBooking().then((_) => _autoUpdateStatusIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Evento"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Generar PDF",
            onPressed: _generatePdf,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Historial",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingLogsScreen(bookingId: widget.bookingId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualizar",
            onPressed: () async {
              await _loadBooking();
              await _autoUpdateStatusIfNeeded();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Eliminar",
            onPressed: _deleteBooking,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
              ? const Center(child: Text("Evento no encontrado."))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🎉 ${booking["celebrantFirstName"] ?? ""} ${booking["celebrantLastName"] ?? ""}",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isCotizacion()
                                    ? "📄 Tipo: Cotización"
                                    : "📌 Tipo: Reservación",
                              ),
                              const SizedBox(height: 6),
                              Text("🏷 División: ${booking["division"] ?? ""}"),
                              const SizedBox(height: 6),
                              Text("🎂 Edad: ${booking["celebrantAge"] ?? 0}"),
                              const SizedBox(height: 6),
                              Text("👤 Encargado: ${booking["guardianName"] ?? ""}"),
                              const SizedBox(height: 6),
                              Text("📞 ${booking["customerPhone"] ?? ""}"),
                              const SizedBox(height: 6),
                              Text("👧 Cantidad de niñ@s: ${booking["childCount"] ?? 0}"),
                              const SizedBox(height: 6),
                              Text("📅 ${_formatDate(booking["eventDate"] ?? "")}"),
                              const SizedBox(height: 6),
                              Text(
                                "⏰ Horario: ${_timeSlotLabel(booking["timeSlot"] ?? "")}",
                              ),
                              const SizedBox(height: 6),
                              Text("📍 Dirección: ${booking["fullAddress"] ?? ""}"),
                              const SizedBox(height: 6),
                              Text("🎁 Paquete: ${booking["packageName"] ?? ""}"),
                              const SizedBox(height: 12),
                              Text(
                                "Estado: ${booking["status"] ?? "Pendiente"}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: booking["status"] == "Pendiente"
                                      ? Colors.orange
                                      : booking["status"] == "Confirmada"
                                          ? Colors.blue
                                          : booking["status"] == "Pagada"
                                              ? Colors.green
                                              : booking["status"] == "Cancelada"
                                                  ? Colors.red
                                                  : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Resumen de Pagos",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Total: ${_formatCurrency((booking["totalAmount"] as num).toDouble())}",
                              ),
                              Text(
                                "Depósito: ${_formatCurrency((booking["depositAmount"] as num).toDouble())}",
                              ),
                              Text(
                                "Pagos adicionales: ${_formatCurrency(_paymentsTotal)}",
                              ),
                              const Divider(height: 20),
                              Text(
                                "Saldo pendiente: ${_formatCurrency(_getPendingBalance())}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "30% recomendado: ${_formatCurrency(((booking["totalAmount"] as num).toDouble() * 0.30))}",
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((booking["notes"] ?? "").toString().trim().isNotEmpty)
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "Observaciones:\n${booking["notes"]}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isCotizacion()
                                  ? null
                                  : () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingPaymentsScreen(
                                            bookingId: widget.bookingId,
                                            bookingStatus: booking["status"],
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        await _loadBooking();
                                        await _autoUpdateStatusIfNeeded();
                                      }
                                    },
                              icon: const Icon(Icons.payments),
                              label: const Text("Pagos"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingFormScreen(
                                      bookingToEdit: booking,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _loadBooking();
                                  await _autoUpdateStatusIfNeeded();
                                }
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text("Editar"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (booking["status"] != "Cancelada" &&
                          booking["status"] != "Finalizada")
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: _markAsCancelled,
                            icon: const Icon(Icons.cancel),
                            label: const Text("Cancelar Evento"),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}