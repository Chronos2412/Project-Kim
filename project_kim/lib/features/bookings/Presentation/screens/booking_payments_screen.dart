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

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _createdByCtrl =
      TextEditingController(text: "system");

  DateTime _paymentDate = DateTime.now();

  String _formatDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  Future<void> _savePayment() async {
    if (widget.bookingStatus == "Cancelada") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pueden registrar pagos en una reservación cancelada.")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final db = await _db.database;

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El monto debe ser mayor a 0.")),
      );
      return;
    }

    final data = {
      "bookingId": widget.bookingId,
      "amount": amount,
      "paymentDate": _paymentDate.toIso8601String(),
      "createdAt": DateTime.now().toIso8601String(),
      "createdBy": _createdByCtrl.text.trim(),
      "note": _noteCtrl.text.trim(),
    };

    await db.insert("booking_payments", data);

    await _db.insertBookingLog(
      db,
      widget.bookingId,
      "Pago registrado: ₡${amount.toStringAsFixed(2)}",
      actionType: "PAYMENT",
      fieldChanged: "payments",
      changedBy: _createdByCtrl.text.trim(),
      oldValue: "",
      newValue: amount.toString(),
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _createdByCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Pago"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Monto del pago (₡)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Campo requerido";

                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return "Monto inválido";

                  return null;
                },
              ),
              const SizedBox(height: 12),

              ListTile(
                title: const Text("Fecha del pago"),
                subtitle: Text(_formatDate(_paymentDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickPaymentDate,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Nota (opcional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _createdByCtrl,
                decoration: const InputDecoration(
                  labelText: "Creado por",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _savePayment,
                  icon: const Icon(Icons.save),
                  label: const Text("Guardar Pago"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}