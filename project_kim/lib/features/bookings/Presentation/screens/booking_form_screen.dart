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

  // =========================
  // STEPPER
  // =========================
  int _currentStep = 0;
  bool _hasChanges = false;

  bool get isEditing => widget.bookingToEdit != null;

  // =========================
  // CONTROLLERS
  // =========================
  final TextEditingController _celebrantFirstCtrl = TextEditingController();
  final TextEditingController _celebrantLastCtrl = TextEditingController();
  final TextEditingController _celebrantAgeCtrl = TextEditingController();

  final TextEditingController _guardianNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();
  final TextEditingController _childCountCtrl = TextEditingController(text: "5");

  final TextEditingController _fullAddressCtrl = TextEditingController();

  final TextEditingController _foodAdultsTotalCtrl =
      TextEditingController(text: "0");
  final TextEditingController _foodKidsTotalCtrl =
      TextEditingController(text: "0");

  final TextEditingController _discountCtrl = TextEditingController(text: "0");
  final TextEditingController _notesCtrl = TextEditingController();

  final TextEditingController _createdByCtrl =
      TextEditingController(text: "system");

  // =========================
  // DROPDOWNS
  // =========================
  String _bookingType = "COTIZACION"; // COTIZACION / RESERVACION

  DateTime _eventDate = DateTime.now();

  String _timeSlot = "9am-12pm";

  String _packageName = "Mini Glow Spa";
  double _packagePricePerChild = 19500;

  String _foodAdultsType = "No";
  int _foodAdultsCount = 0;

  String _foodKidsType = "No";
  int _foodKidsCount = 0;

  String _decorationType = "No";
  double _decorationTotal = 0;

  // =========================
  // INIT
  // =========================
  @override
  void initState() {
    super.initState();
    _fillIfEditing();
    _listenChanges();
  }

  void _listenChanges() {
    final controllers = [
      _celebrantFirstCtrl,
      _celebrantLastCtrl,
      _celebrantAgeCtrl,
      _guardianNameCtrl,
      _customerPhoneCtrl,
      _childCountCtrl,
      _fullAddressCtrl,
      _foodAdultsTotalCtrl,
      _foodKidsTotalCtrl,
      _discountCtrl,
      _notesCtrl,
      _createdByCtrl,
    ];

    for (final c in controllers) {
      c.addListener(() {
        setState(() {
          _hasChanges = true;
        });
      });
    }
  }

  void _fillIfEditing() {
    if (!isEditing) return;

    final b = widget.bookingToEdit!;

    _bookingType = (b["bookingType"] ?? "COTIZACION").toString();

    _celebrantFirstCtrl.text = b["celebrantFirstName"] ?? "";
    _celebrantLastCtrl.text = b["celebrantLastName"] ?? "";
    _celebrantAgeCtrl.text = (b["celebrantAge"] ?? "").toString();

    _guardianNameCtrl.text = b["guardianName"] ?? "";
    _customerPhoneCtrl.text = b["customerPhone"] ?? "";
    _childCountCtrl.text = (b["childCount"] ?? 5).toString();

    _eventDate = DateTime.tryParse(b["eventDate"] ?? "") ?? DateTime.now();
    _timeSlot = (b["timeSlot"] ?? "9am-12pm").toString();

    _fullAddressCtrl.text = b["fullAddress"] ?? "";

    _packageName = (b["packageName"] ?? "Mini Glow Spa").toString();
    _packagePricePerChild =
        (b["packagePricePerChild"] as num?)?.toDouble() ?? 19500;

    _foodAdultsType = (b["foodAdultsType"] ?? "No").toString();
    _foodAdultsCount = (b["foodAdultsCount"] ?? 0) as int;
    _foodAdultsTotalCtrl.text =
        ((b["foodAdultsTotal"] as num?)?.toDouble() ?? 0).toStringAsFixed(0);

    _foodKidsType = (b["foodKidsType"] ?? "No").toString();
    _foodKidsCount = (b["foodKidsCount"] ?? 0) as int;
    _foodKidsTotalCtrl.text =
        ((b["foodKidsTotal"] as num?)?.toDouble() ?? 0).toStringAsFixed(0);

    _decorationType = (b["decorationType"] ?? "No").toString();
    _decorationTotal = (b["decorationTotal"] as num?)?.toDouble() ?? 0;

    _discountCtrl.text =
        ((b["discountAmount"] as num?)?.toDouble() ?? 0).toStringAsFixed(0);

    _notesCtrl.text = b["notes"] ?? "";
    _createdByCtrl.text = b["createdBy"] ?? "system";

    _hasChanges = false;
  }

  // =========================
  // HELPERS
  // =========================
  int _getChildCount() {
    final raw = int.tryParse(_childCountCtrl.text.trim()) ?? 0;
    if (raw < 0) return 0;
    return raw;
  }

  int _getChargedChildCount() {
    final count = _getChildCount();
    return count < 5 ? 5 : count;
  }

  double _getFoodAdultsTotal() {
    return double.tryParse(_foodAdultsTotalCtrl.text.trim()) ?? 0;
  }

  double _getFoodKidsTotal() {
    return double.tryParse(_foodKidsTotalCtrl.text.trim()) ?? 0;
  }

  double _getDiscount() {
    final d = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    return d < 0 ? 0 : d;
  }

  double _packageTotal() {
    return _packagePricePerChild * _getChargedChildCount();
  }

  double _subtotal() {
    return _packageTotal() +
        _getFoodAdultsTotal() +
        _getFoodKidsTotal() +
        _decorationTotal;
  }

  double _total() {
    final t = _subtotal() - _getDiscount();
    return t < 0 ? 0 : t;
  }

  double _minDeposit() {
    return _total() * 0.30;
  }

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: "es_CR", symbol: "₡");
    return f.format(value);
  }

  String _formatDate(DateTime dt) {
    return DateFormat("dd/MM/yyyy").format(dt);
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

  double _decorationPrice(String type) {
    switch (type) {
      case "Básica":
        return 25000;
      case "Intermedia":
        return 35000;
      case "Premium":
        return 50000;
      default:
        return 0;
    }
  }

  double _packagePrice(String name) {
    switch (name) {
      case "Mini Glow Spa":
        return 19500;
      case "Glam Plus Spa":
        return 25000;
      case "Glam Premium Spa":
        return 25000;
      default:
        return 0;
    }
  }

  void _showPackageInfo() {
    String text = "";

    if (_packageName == "Mini Glow Spa") {
      text = """
Incluye:
• Obsequio para la cumpleañera
• Facial: jabón de limpieza, exfoliación, tónico, mascarilla e hidratación
• Esmaltado de uñas
• Peinados con glitter, accesorios y mechones de colores
• Maquillaje express: sombras de ojos, rubor, iluminador y glitter para el rostro
• Música durante el evento
• Kit Spa Party

Paquete mínimo: 5 niñ@s
Precio por niñ@: ₡19,500
""";
    } else if (_packageName == "Glam Plus Spa") {
      text = """
Incluye todo lo del Mini Glow Spa, más:
• Manicura spa o pedicura spa
• Actividad creativa (pulseras, decoración de antifaz o lienzo)
• Juegos durante la actividad (incluye premios)

Paquete mínimo: 5 niñ@s
Precio por niñ@: ₡25,000
""";
    } else if (_packageName == "Glam Premium Spa") {
      text = """
Incluye:
• Brindis “Divas Sparkle”
• Obsequio para la cumpleañera
• Facial: jabón de limpieza, exfoliación, tónico, mascarilla e hidratación
• Manicura spa y pedicura spa (exfoliación, masaje, esmaltado, stickers)
• Maquillaje glam: sombras, rubor, iluminador, glitter, diseños y gemas
• Actividad creativa (pulseras, decoración de espejos o pintura en lienzo)
• Juegos, pasarela y karaoke (incluye premios)
• Animación durante la piñata
• Kit para cada niña

Paquete mínimo: 5 niñ@s
Precio por niñ@: ₡25,000
""";
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Información del paquete: $_packageName"),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showDecorationInfo() {
    String text = "";

    if (_decorationType == "Básica") {
      text = """
Incluye:
• Cortina según temática
• Medio arco de globos sencillo (3 colores diferentes)
• Ideal para lugares pequeños

Precio: ₡25,000

Nota: Los detalles se verán con la persona encargada y se pueden cotizar extras.
""";
    } else if (_decorationType == "Intermedia") {
      text = """
Incluye:
• Arco de globos más abundante
• Diferentes tamaños de globos
• Fondo decorativo sencillo o temática
• Número de cumpleaños

Precio: ₡35,000

Nota: Los detalles se verán con la persona encargada y se pueden cotizar extras.
""";
    } else if (_decorationType == "Premium") {
      text = """
Incluye:
• Arco abundante completo o medio arco + torre
• Globos especiales
• Fondo decorativo elaborado
• Número de cumpleaños
• Torre de cajas letras (4 letras)
• Alfombra si se requiere

Precio: ₡50,000

Nota: Los detalles se verán con la persona encargada y se pueden cotizar extras.
""";
    } else {
      text = "No aplica.";
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Información decoración: $_decorationType"),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // =========================
  // DATE PICKER
  // =========================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _eventDate = picked;
        _hasChanges = true;
      });
    }
  }

  // =========================
  // AVAILABILITY VALIDATION
  // =========================
  Future<List<String>> _getUnavailableSlotsForDate(DateTime date) async {
    final db = await _db.database;

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final results = await db.query(
      "bookings",
      where: "eventDate >= ? AND eventDate < ? AND status != ?",
      whereArgs: [
        dayStart.toIso8601String(),
        dayEnd.toIso8601String(),
        "Cancelada",
      ],
    );

    // si estamos editando, ignorar el evento actual
    final filtered = results.where((b) {
      if (!isEditing) return true;
      return b["id"] != widget.bookingToEdit!["id"];
    }).toList();

    if (filtered.isEmpty) return [];

    final bookedSlots = filtered.map((b) => (b["timeSlot"] ?? "").toString());

    final unavailable = <String>{};

    for (final slot in bookedSlots) {
      if (slot == "9am-12pm") {
        unavailable.add("9am-12pm");
        unavailable.add("10am-1pm");
      }

      if (slot == "10am-1pm") {
        unavailable.add("9am-12pm");
        unavailable.add("10am-1pm");
        unavailable.add("2pm-5pm");
      }

      if (slot == "2pm-5pm") {
        unavailable.add("10am-1pm");
        unavailable.add("2pm-5pm");
        unavailable.add("3pm-6pm");
      }

      if (slot == "3pm-6pm") {
        unavailable.add("2pm-5pm");
        unavailable.add("3pm-6pm");
      }
    }

    // regla máxima 2 eventos por día
    if (filtered.length >= 2) {
      return ["9am-12pm", "10am-1pm", "2pm-5pm", "3pm-6pm"];
    }

    return unavailable.toList();
  }

  // =========================
  // STATUS
  // =========================
  String _calculateStatus(double total, double deposit) {
    if (total <= 0) return "Pendiente";

    if (deposit >= total) return "Pagada";

    final minDeposit = total * 0.30;

    if (deposit >= minDeposit) return "Confirmada";

    return "Pendiente";
  }

  // =========================
  // EXIT CONFIRM
  // =========================
  Future<bool> _confirmExit() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Cambios sin guardar"),
          content: const Text(
            "Tienes cambios sin guardar. ¿Deseas salir sin guardar?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sí, salir"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // =========================
  // SAVE
  // =========================
  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final db = await _db.database;

    final celebrantAge = int.tryParse(_celebrantAgeCtrl.text.trim()) ?? 0;
    final childCount = _getChildCount();

    if (childCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La cantidad de niñ@s debe ser mayor a 0.")),
      );
      return;
    }

    final subtotal = _subtotal();
    final total = _total();

    final deposit = 0.0; // depósito inicial (se registrará después con pagos)

    final status = _calculateStatus(total, deposit);

    final data = {
      "bookingType": _bookingType,

      "celebrantFirstName": _celebrantFirstCtrl.text.trim(),
      "celebrantLastName": _celebrantLastCtrl.text.trim(),
      "celebrantAge": celebrantAge,

      "guardianName": _guardianNameCtrl.text.trim(),
      "customerPhone": _customerPhoneCtrl.text.trim(),

      "childCount": childCount,

      "eventDate": _eventDate.toIso8601String(),
      "timeSlot": _timeSlot,

      "fullAddress": _fullAddressCtrl.text.trim(),

      "packageName": _packageName,
      "packagePricePerChild": _packagePricePerChild,

      "foodAdultsType": _foodAdultsType,
      "foodAdultsCount": _foodAdultsCount,
      "foodAdultsTotal": _getFoodAdultsTotal(),

      "foodKidsType": _foodKidsType,
      "foodKidsCount": _foodKidsCount,
      "foodKidsTotal": _getFoodKidsTotal(),

      "decorationType": _decorationType,
      "decorationTotal": _decorationTotal,

      "discountAmount": _getDiscount(),

      "subtotalAmount": subtotal,
      "totalAmount": total,

      "depositAmount": deposit,

      "status": status,

      "notes": _notesCtrl.text.trim(),

      "createdAt": DateTime.now().toIso8601String(),
      "createdBy": _createdByCtrl.text.trim(),
    };

    if (isEditing) {
      final id = widget.bookingToEdit!["id"];

      await db.update(
        "bookings",
        data,
        where: "id = ?",
        whereArgs: [id],
      );

      await _db.insertBookingLog(
        db,
        id,
        "Evento actualizado: Fiesta de ${data["celebrantFirstName"]} ${data["celebrantLastName"]}",
        actionType: "UPDATE",
        fieldChanged: "ALL",
        changedBy: _createdByCtrl.text.trim(),
        oldValue: "",
        newValue: data.toString(),
      );
    } else {
      final newId = await db.insert("bookings", data);

      await _db.insertBookingLog(
        db,
        newId,
        "Evento creado: Fiesta de ${data["celebrantFirstName"]} ${data["celebrantLastName"]}",
        actionType: "CREATE",
        fieldChanged: "ALL",
        changedBy: _createdByCtrl.text.trim(),
        oldValue: "",
        newValue: data.toString(),
      );
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // =========================
  // VALIDATORS
  // =========================
  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Campo requerido";
    return null;
  }

  String? _ageValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Campo requerido";
    final parsed = int.tryParse(v.trim());
    if (parsed == null || parsed < 0 || parsed > 120) {
      return "Edad inválida";
    }
    return null;
  }

  String? _childCountValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Campo requerido";
    final parsed = int.tryParse(v.trim());
    if (parsed == null || parsed <= 0) {
      return "Cantidad inválida";
    }
    return null;
  }

  String? _moneyValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = double.tryParse(v.trim());
    if (parsed == null || parsed < 0) {
      return "Monto inválido";
    }
    return null;
  }

  // =========================
  // STEPS
  // =========================
  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text("Tipo de evento"),
        isActive: _currentStep >= 0,
        content: DropdownButtonFormField<String>(
          value: _bookingType,
          decoration: const InputDecoration(
            labelText: "Tipo",
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
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _bookingType = v;
              _hasChanges = true;
            });
          },
        ),
      ),

      Step(
        title: const Text("Festejad@"),
        isActive: _currentStep >= 1,
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _celebrantFirstCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _celebrantLastCtrl,
                    decoration: const InputDecoration(
                      labelText: "Apellido",
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _celebrantAgeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Edad",
                border: OutlineInputBorder(),
              ),
              validator: _ageValidator,
            ),
          ],
        ),
      ),

      Step(
        title: const Text("Encargado"),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            TextFormField(
              controller: _guardianNameCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre del padre/madre/encargado",
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerPhoneCtrl,
              decoration: const InputDecoration(
                labelText: "Teléfono",
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _childCountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Cantidad de niñ@s",
                border: OutlineInputBorder(),
                helperText: "Mínimo facturable: 5 niñ@s",
              ),
              validator: _childCountValidator,
            ),
          ],
        ),
      ),

      Step(
        title: const Text("Fecha y horario"),
        isActive: _currentStep >= 3,
        content: FutureBuilder<List<String>>(
          future: _getUnavailableSlotsForDate(_eventDate),
          builder: (context, snapshot) {
            final unavailable = snapshot.data ?? [];

            final allSlots = [
              "9am-12pm",
              "10am-1pm",
              "2pm-5pm",
              "3pm-6pm",
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text("Fecha del evento"),
                  subtitle: Text(_formatDate(_eventDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _timeSlot,
                  decoration: const InputDecoration(
                    labelText: "Horario",
                    border: OutlineInputBorder(),
                  ),
                  items: allSlots.map((slot) {
                    final disabled = unavailable.contains(slot);

                    return DropdownMenuItem(
                      value: slot,
                      enabled: !disabled,
                      child: Text(
                        "${_timeSlotLabel(slot)}${disabled ? " (No disponible)" : ""}",
                        style: TextStyle(
                          color: disabled ? Colors.grey : null,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v == null) return;

                    if (unavailable.contains(v)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Ya hay una reservación que conflictúa con ese horario.",
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _timeSlot = v;
                      _hasChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (unavailable.isNotEmpty)
                  Text(
                    "Horarios bloqueados para este día: ${unavailable.map(_timeSlotLabel).join(", ")}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
              ],
            );
          },
        ),
      ),

      Step(
        title: const Text("Dirección"),
        isActive: _currentStep >= 4,
        content: TextFormField(
          controller: _fullAddressCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Dirección completa",
            border: OutlineInputBorder(),
          ),
          validator: _requiredValidator,
        ),
      ),

      Step(
        title: const Text("Paquete"),
        isActive: _currentStep >= 5,
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _packageName,
                    decoration: const InputDecoration(
                      labelText: "Paquete de fiesta",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Mini Glow Spa",
                        child: Text("Mini Glow Spa"),
                      ),
                      DropdownMenuItem(
                        value: "Glam Plus Spa",
                        child: Text("Glam Plus Spa"),
                      ),
                      DropdownMenuItem(
                        value: "Glam Premium Spa",
                        child: Text("Glam Premium Spa"),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;

                      setState(() {
                        _packageName = v;
                        _packagePricePerChild = _packagePrice(v);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: "Ver detalles del paquete",
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showPackageInfo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Precio por niñ@: ${_formatCurrency(_packagePricePerChild)}"),
                    const SizedBox(height: 6),
                    Text("Cantidad ingresada: ${_getChildCount()}"),
                    Text("Cantidad facturable: ${_getChargedChildCount()}"),
                    const Divider(height: 20),
                    Text(
                      "Total paquete: ${_formatCurrency(_packageTotal())}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      Step(
        title: const Text("Alimentación"),
        isActive: _currentStep >= 6,
        content: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _foodAdultsType,
              decoration: const InputDecoration(
                labelText: "Alimentación para Adultos",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "No", child: Text("No")),
                DropdownMenuItem(value: "Desayuno", child: Text("Desayuno")),
                DropdownMenuItem(value: "Almuerzo", child: Text("Almuerzo")),
                DropdownMenuItem(value: "Café", child: Text("Café")),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _foodAdultsType = v;
                  if (v == "No") {
                    _foodAdultsCount = 0;
                    _foodAdultsTotalCtrl.text = "0";
                  }
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              enabled: _foodAdultsType != "No",
              keyboardType: TextInputType.number,
              initialValue: _foodAdultsCount.toString(),
              decoration: const InputDecoration(
                labelText: "Número de Adultos",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  _foodAdultsCount = int.tryParse(v.trim()) ?? 0;
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _foodAdultsTotalCtrl,
              enabled: _foodAdultsType != "No",
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Total alimentación adultos (₡)",
                border: OutlineInputBorder(),
              ),
              validator: _moneyValidator,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _foodKidsType,
              decoration: const InputDecoration(
                labelText: "Alimentación para Niñ@s",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "No", child: Text("No")),
                DropdownMenuItem(value: "Desayuno", child: Text("Desayuno")),
                DropdownMenuItem(value: "Almuerzo", child: Text("Almuerzo")),
                DropdownMenuItem(value: "Café", child: Text("Café")),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _foodKidsType = v;
                  if (v == "No") {
                    _foodKidsCount = 0;
                    _foodKidsTotalCtrl.text = "0";
                  }
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              enabled: _foodKidsType != "No",
              keyboardType: TextInputType.number,
              initialValue: _foodKidsCount.toString(),
              decoration: const InputDecoration(
                labelText: "Número de Niñ@s",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  _foodKidsCount = int.tryParse(v.trim()) ?? 0;
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _foodKidsTotalCtrl,
              enabled: _foodKidsType != "No",
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Total alimentación niñ@s (₡)",
                border: OutlineInputBorder(),
              ),
              validator: _moneyValidator,
            ),
          ],
        ),
      ),

      Step(
        title: const Text("Decoración"),
        isActive: _currentStep >= 7,
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _decorationType,
                    decoration: const InputDecoration(
                      labelText: "Decoración",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "No", child: Text("No")),
                      DropdownMenuItem(value: "Básica", child: Text("Básica")),
                      DropdownMenuItem(
                        value: "Intermedia",
                        child: Text("Intermedia"),
                      ),
                      DropdownMenuItem(value: "Premium", child: Text("Premium")),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _decorationType = v;
                        _decorationTotal = _decorationPrice(v);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: "Ver detalles de decoración",
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showDecorationInfo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Costo decoración:"),
                    Text(
                      _formatCurrency(_decorationTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      Step(
        title: const Text("Descuento y observaciones"),
        isActive: _currentStep >= 8,
        content: Column(
          children: [
            TextFormField(
              controller: _discountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Descuento (₡)",
                border: OutlineInputBorder(),
              ),
              validator: _moneyValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Observaciones",
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
              validator: _requiredValidator,
            ),
          ],
        ),
      ),

      Step(
        title: const Text("Resumen final"),
        isActive: _currentStep >= 9,
        content: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fiesta de ${_celebrantFirstCtrl.text} ${_celebrantLastCtrl.text}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Fecha: ${_formatDate(_eventDate)}"),
                Text("Horario: ${_timeSlotLabel(_timeSlot)}"),
                const Divider(height: 22),
                Text("Paquete: $_packageName"),
                Text("Precio por niñ@: ${_formatCurrency(_packagePricePerChild)}"),
                Text("Cantidad ingresada: ${_getChildCount()}"),
                Text("Cantidad facturable: ${_getChargedChildCount()}"),
                Text("Total paquete: ${_formatCurrency(_packageTotal())}"),
                const Divider(height: 22),
                Text("Alimentación adultos: ${_formatCurrency(_getFoodAdultsTotal())}"),
                Text("Alimentación niñ@s: ${_formatCurrency(_getFoodKidsTotal())}"),
                Text("Decoración: ${_formatCurrency(_decorationTotal)}"),
                const Divider(height: 22),
                Text("Subtotal: ${_formatCurrency(_subtotal())}"),
                Text("Descuento: ${_formatCurrency(_getDiscount())}"),
                const SizedBox(height: 6),
                Text(
                  "TOTAL: ${_formatCurrency(_total())}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Adelanto mínimo requerido (30%): ${_formatCurrency(_minDeposit())}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tipo: ${_bookingType == "COTIZACION" ? "Cotización" : "Reservación"}",
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? "Editar Evento" : "Nuevo Evento"),
        ),
        body: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            steps: _buildSteps(),
            onStepContinue: () async {
              if (_currentStep == 3) {
                // validar disponibilidad antes de avanzar
                final unavailable =
                    await _getUnavailableSlotsForDate(_eventDate);

                if (unavailable.contains(_timeSlot)) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Ya hay una reservación que conflictúa con ese horario.",
                      ),
                    ),
                  );
                  return;
                }
              }

              if (_currentStep < _buildSteps().length - 1) {
                setState(() {
                  _currentStep++;
                });
              } else {
                await _saveBooking();
              }
            },
            onStepCancel: () {
              if (_currentStep == 0) return;
              setState(() {
                _currentStep--;
              });
            },
            controlsBuilder: (context, details) {
              final isLast = _currentStep == _buildSteps().length - 1;

              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(isLast ? "Guardar Evento" : "Siguiente"),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text("Atrás"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _celebrantFirstCtrl.dispose();
    _celebrantLastCtrl.dispose();
    _celebrantAgeCtrl.dispose();
    _guardianNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _childCountCtrl.dispose();
    _fullAddressCtrl.dispose();
    _foodAdultsTotalCtrl.dispose();
    _foodKidsTotalCtrl.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _createdByCtrl.dispose();
    super.dispose();
  }
}