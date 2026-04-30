import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingToEdit;

  const BookingFormScreen({
    super.key,
    this.bookingToEdit,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final AppDatabase _db = AppDatabase();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;

  // =========================
  // FORM FIELDS
  // =========================
  String _bookingType = "COTIZACION"; // COTIZACION / RESERVACION
  String _division = "Spa Party";

  String _celebrantFirstName = "";
  String _celebrantLastName = "";
  int _celebrantAge = 0;

  String _guardianName = "";
  String _customerPhone = "";

  int _childCount = 5;

  DateTime? _eventDate;
  String _timeSlot = "9am-12pm";

  String _fullAddress = "";

  String _packageName = "";
  double _packagePricePerChild = 0.0;

  // Alimentación adultos
  String _foodAdultsType = "No";
  int _foodAdultsCount = 0;
  double _foodAdultsTotal = 0.0;

  // Alimentación niños
  String _foodKidsType = "No";
  int _foodKidsCount = 0;
  double _foodKidsTotal = 0.0;

  // Decoración
  String _decorationType = "No";
  double _decorationTotal = 0.0;

  double _discountAmount = 0.0;

  double _subtotalAmount = 0.0;
  double _totalAmount = 0.0;

  double _depositAmount = 0.0;

  String _notes = "";

  bool _loading = false;

  // =========================
  // PACKAGE DEFINITIONS
  // =========================
  final Map<String, List<Map<String, dynamic>>> _packagesByDivision = {
    "Spa Party": [
      {"name": "Mini Glow Spa", "pricePerChild": 19500.0},
      {"name": "Glam Plus Spa", "pricePerChild": 25000.0},
      {"name": "Glam Premium Spa", "pricePerChild": 25000.0},
    ],
    "Baby Party": [
      {"name": "Paquete Baby Básico", "pricePerChild": 0.0},
      {"name": "Paquete Baby Premium", "pricePerChild": 0.0},
    ],
    "Movie Party": [
      {"name": "Paquete Movie Básico", "pricePerChild": 0.0},
      {"name": "Paquete Movie Premium", "pricePerChild": 0.0},
    ],
  };

  List<Map<String, dynamic>> get _availablePackages {
    return _packagesByDivision[_division] ?? [];
  }

  // =========================
  // HELPERS
  // =========================
  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: "es_CR", symbol: "₡");
    return f.format(value);
  }

  String _formatDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  void _recalculateTotals() {
    final packageTotal = _packagePricePerChild * _childCount;

    final subtotal =
        packageTotal + _foodAdultsTotal + _foodKidsTotal + _decorationTotal;

    final total = subtotal - _discountAmount;
    final safeTotal = total < 0 ? 0.0 : total.toDouble();

    final recommendedDeposit = safeTotal * 0.30;

    setState(() {
      _subtotalAmount = subtotal.toDouble();
      _totalAmount = safeTotal;

      if (_depositAmount <= 0) {
        _depositAmount = recommendedDeposit;
      }
    });
  }

  // =========================
  // VALIDATION BY STEP
  // =========================
  bool _validateStep(int step) {
    if (step == 0) {
      if (_bookingType.trim().isEmpty) return false;
      if (_division.trim().isEmpty) return false;
      return true;
    }

    if (step == 1) {
      if (_celebrantFirstName.trim().isEmpty) return false;
      if (_celebrantLastName.trim().isEmpty) return false;
      if (_celebrantAge <= 0) return false;
      if (_guardianName.trim().isEmpty) return false;
      if (_customerPhone.trim().isEmpty) return false;
      return true;
    }

    if (step == 2) {
      if (_eventDate == null) return false;
      if (_timeSlot.trim().isEmpty) return false;
      if (_fullAddress.trim().isEmpty) return false;
      return true;
    }

    if (step == 3) {
      if (_childCount < 5) return false;
      if (_packageName.trim().isEmpty) return false;
      if (_totalAmount <= 0) return false;
      return true;
    }

    return true;
  }

  void _nextStep() {
    final isValid = _validateStep(_currentStep);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes completar los campos requeridos antes de continuar."),
        ),
      );
      return;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // =========================
  // INIT EDIT MODE
  // =========================
  void _fillIfEditing() {
    final b = widget.bookingToEdit;
    if (b == null) return;

    _bookingType = (b["bookingType"] ?? "COTIZACION").toString();
    _division = (b["division"] ?? "Spa Party").toString();

    _celebrantFirstName = (b["celebrantFirstName"] ?? "").toString();
    _celebrantLastName = (b["celebrantLastName"] ?? "").toString();
    _celebrantAge = (b["celebrantAge"] as num?)?.toInt() ?? 0;

    _guardianName = (b["guardianName"] ?? "").toString();
    _customerPhone = (b["customerPhone"] ?? "").toString();

    _childCount = (b["childCount"] as num?)?.toInt() ?? 5;

    final dateStr = (b["eventDate"] ?? "").toString();
    _eventDate = DateTime.tryParse(dateStr);

    _timeSlot = (b["timeSlot"] ?? "9am-12pm").toString();
    _fullAddress = (b["fullAddress"] ?? "").toString();

    _packageName = (b["packageName"] ?? "").toString();
    _packagePricePerChild =
        (b["packagePricePerChild"] as num?)?.toDouble() ?? 0.0;

    _foodAdultsType = (b["foodAdultsType"] ?? "No").toString();
    _foodAdultsCount = (b["foodAdultsCount"] as num?)?.toInt() ?? 0;
    _foodAdultsTotal = (b["foodAdultsTotal"] as num?)?.toDouble() ?? 0.0;

    _foodKidsType = (b["foodKidsType"] ?? "No").toString();
    _foodKidsCount = (b["foodKidsCount"] as num?)?.toInt() ?? 0;
    _foodKidsTotal = (b["foodKidsTotal"] as num?)?.toDouble() ?? 0.0;

    _decorationType = (b["decorationType"] ?? "No").toString();
    _decorationTotal = (b["decorationTotal"] as num?)?.toDouble() ?? 0.0;

    _discountAmount = (b["discountAmount"] as num?)?.toDouble() ?? 0.0;

    _subtotalAmount = (b["subtotalAmount"] as num?)?.toDouble() ?? 0.0;
    _totalAmount = (b["totalAmount"] as num?)?.toDouble() ?? 0.0;

    _depositAmount = (b["depositAmount"] as num?)?.toDouble() ?? 0.0;

    _notes = (b["notes"] ?? "").toString();

    _recalculateTotals();
  }

  @override
  void initState() {
    super.initState();
    _fillIfEditing();
  }

  // =========================
  // SAVE BOOKING
  // =========================
  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar una fecha.")),
      );
      return;
    }

    if (_childCount < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El mínimo es 5 niñ@s.")),
      );
      return;
    }

    if (_packageName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar un paquete.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final db = await _db.database;

      final now = DateTime.now().toIso8601String();
      final eventDateIso = _eventDate!.toIso8601String();

      final data = {
        "bookingType": _bookingType,
        "division": _division,
        "celebrantFirstName": _celebrantFirstName.trim(),
        "celebrantLastName": _celebrantLastName.trim(),
        "celebrantAge": _celebrantAge,
        "guardianName": _guardianName.trim(),
        "customerPhone": _customerPhone.trim(),
        "childCount": _childCount,
        "eventDate": eventDateIso,
        "timeSlot": _timeSlot,
        "fullAddress": _fullAddress.trim(),
        "packageName": _packageName.trim(),
        "packagePricePerChild": _packagePricePerChild,
        "foodAdultsType": _foodAdultsType,
        "foodAdultsCount": _foodAdultsCount,
        "foodAdultsTotal": _foodAdultsTotal,
        "foodKidsType": _foodKidsType,
        "foodKidsCount": _foodKidsCount,
        "foodKidsTotal": _foodKidsTotal,
        "decorationType": _decorationType,
        "decorationTotal": _decorationTotal,
        "discountAmount": _discountAmount,
        "subtotalAmount": _subtotalAmount,
        "totalAmount": _totalAmount,
        "depositAmount": _depositAmount,
        "status": "Pendiente",
        "notes": _notes.trim(),
        "createdAt": now,
        "createdBy": "system",
      };

      if (widget.bookingToEdit == null) {
        final id = await db.insert("bookings", data);

        await _db.insertBookingLog(
          db,
          id,
          "Evento creado",
          actionType: "CREATE",
          fieldChanged: "ALL",
          changedBy: "system",
          oldValue: "",
          newValue: "Evento creado",
        );
      } else {
        final id = widget.bookingToEdit!["id"] as int;

        await db.update(
          "bookings",
          data,
          where: "id = ?",
          whereArgs: [id],
        );

        await _db.insertBookingLog(
          db,
          id,
          "Evento actualizado",
          actionType: "UPDATE",
          fieldChanged: "ALL",
          changedBy: "system",
          oldValue: "",
          newValue: "Evento actualizado",
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("SAVE BOOKING ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error guardando evento: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bookingToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Evento" : "Nuevo Evento"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: _nextStep,
                onStepCancel: _prevStep,
                controlsBuilder: (context, details) {
                  final isLast = _currentStep == 4;

                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: const Text("Atrás"),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLast ? _saveBooking : details.onStepContinue,
                            child: Text(isLast
                                ? (isEditing ? "Guardar cambios" : "Guardar evento")
                                : "Siguiente"),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text("Tipo y División"),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                    content: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _bookingType,
                          decoration: const InputDecoration(
                            labelText: "Tipo de evento",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "COTIZACION",
                              child: Text("Cotización"),
                            ),
                            DropdownMenuItem(
                              value: "RESERVACION",
                              child: Text("Reservación"),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _bookingType = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _division,
                          decoration: const InputDecoration(
                            labelText: "División",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "Spa Party",
                              child: Text("Experiencias 360° Spa Party"),
                            ),
                            DropdownMenuItem(
                              value: "Baby Party",
                              child: Text("Experiencias 360° Baby Party"),
                            ),
                            DropdownMenuItem(
                              value: "Movie Party",
                              child: Text("Experiencias 360° Movie Party"),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _division = value;
                              _packageName = "";
                              _packagePricePerChild = 0.0;
                            });

                            _recalculateTotals();
                          },
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text("Cumpleañer@ y Encargado"),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.indexed,
                    content: Column(
                      children: [
                        TextFormField(
                          initialValue: _celebrantFirstName,
                          decoration: const InputDecoration(
                            labelText: "Nombre del cumpleañer@",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Requerido" : null,
                          onChanged: (v) => _celebrantFirstName = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _celebrantLastName,
                          decoration: const InputDecoration(
                            labelText: "Apellido del cumpleañer@",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Requerido" : null,
                          onChanged: (v) => _celebrantLastName = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue:
                              _celebrantAge == 0 ? "" : _celebrantAge.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Edad",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Requerido";
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return "Edad inválida";
                            return null;
                          },
                          onChanged: (v) {
                            _celebrantAge = int.tryParse(v) ?? 0;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _guardianName,
                          decoration: const InputDecoration(
                            labelText: "Nombre del encargado",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Requerido" : null,
                          onChanged: (v) => _guardianName = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _customerPhone,
                          decoration: const InputDecoration(
                            labelText: "Teléfono",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Requerido" : null,
                          onChanged: (v) => _customerPhone = v,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text("Evento"),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2
                        ? StepState.complete
                        : StepState.indexed,
                    content: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  _eventDate == null
                                      ? "Seleccionar fecha"
                                      : _formatDate(_eventDate!),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _eventDate ?? DateTime.now(),
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 1)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365 * 2)),
                                  );

                                  if (picked != null) {
                                    setState(() => _eventDate = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _timeSlot,
                          decoration: const InputDecoration(
                            labelText: "Horario",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "9am-12pm",
                              child: Text("9:00 a.m. - 12:00 p.m."),
                            ),
                            DropdownMenuItem(
                              value: "10am-1pm",
                              child: Text("10:00 a.m. - 1:00 p.m."),
                            ),
                            DropdownMenuItem(
                              value: "2pm-5pm",
                              child: Text("2:00 p.m. - 5:00 p.m."),
                            ),
                            DropdownMenuItem(
                              value: "3pm-6pm",
                              child: Text("3:00 p.m. - 6:00 p.m."),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _timeSlot = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _fullAddress,
                          decoration: const InputDecoration(
                            labelText: "Dirección completa",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Requerido" : null,
                          onChanged: (v) => _fullAddress = v,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text("Paquete y Servicios"),
                    isActive: _currentStep >= 3,
                    state: _currentStep > 3
                        ? StepState.complete
                        : StepState.indexed,
                    content: Column(
                      children: [
                        TextFormField(
                          initialValue: _childCount.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Cantidad de niñ@s (mínimo 5)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? "");
                            if (n == null) return "Número inválido";
                            if (n < 5) return "Mínimo 5";
                            return null;
                          },
                          onChanged: (v) {
                            _childCount = int.tryParse(v) ?? 5;
                            _recalculateTotals();
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _packageName.isEmpty ? null : _packageName,
                          decoration: InputDecoration(
                            labelText: "Paquete ($_division)",
                            border: const OutlineInputBorder(),
                          ),
                          items: _availablePackages.map((p) {
                            return DropdownMenuItem<String>(
                              value: p["name"],
                              child: Text(
                                "${p["name"]} (${_formatCurrency((p["pricePerChild"] as num).toDouble())}/niñ@)",
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            final pkg = _availablePackages.firstWhere(
                              (p) => p["name"] == value,
                              orElse: () => {"name": value, "pricePerChild": 0.0},
                            );

                            setState(() {
                              _packageName = value;
                              _packagePricePerChild =
                                  (pkg["pricePerChild"] as num).toDouble();
                            });

                            _recalculateTotals();
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _decorationType,
                          decoration: const InputDecoration(
                            labelText: "Decoración",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "No", child: Text("No")),
                            DropdownMenuItem(value: "Básica", child: Text("Básica")),
                            DropdownMenuItem(value: "Intermedia", child: Text("Intermedia")),
                            DropdownMenuItem(value: "Premium", child: Text("Premium")),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            double total = 0.0;
                            if (value == "Básica") total = 25000;
                            if (value == "Intermedia") total = 35000;
                            if (value == "Premium") total = 50000;

                            setState(() {
                              _decorationType = value;
                              _decorationTotal = total;
                            });

                            _recalculateTotals();
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _discountAmount.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Descuento (₡)",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            _discountAmount = double.tryParse(v) ?? 0.0;
                            _recalculateTotals();
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _depositAmount.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Depósito (₡)",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _depositAmount = double.tryParse(v) ?? 0.0;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Resumen",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text("Subtotal: ${_formatCurrency(_subtotalAmount)}"),
                                Text("Descuento: ${_formatCurrency(_discountAmount)}"),
                                const Divider(height: 20),
                                Text(
                                  "TOTAL: ${_formatCurrency(_totalAmount)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "30% recomendado: ${_formatCurrency(_totalAmount * 0.30)}",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text("Observaciones y Guardar"),
                    isActive: _currentStep >= 4,
                    state: _currentStep == 4
                        ? StepState.indexed
                        : StepState.disabled,
                    content: Column(
                      children: [
                        TextFormField(
                          initialValue: _notes,
                          decoration: const InputDecoration(
                            labelText: "Observaciones",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          onChanged: (v) => _notes = v,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _saveBooking,
                            icon: const Icon(Icons.save),
                            label: Text(
                              isEditing ? "Guardar cambios" : "Guardar evento",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}