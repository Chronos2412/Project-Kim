import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final AppDatabase _db = AppDatabase();

  final _formKey = GlobalKey<FormState>();

  bool _saving = false;

  late bool _editing;
  ProductModel? _original;

  // controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _minStockCtrl = TextEditingController();

  String _stockUnit = "unit";

  final List<String> _units = [
    "unit",
    "box",
    "pack",
    "kg",
    "g",
    "l",
    "ml",
  ];

  @override
  void initState() {
    super.initState();

    _editing = widget.product != null;
    _original = widget.product;

    if (_editing) {
      _fillEditing();
    }
  }

  void _fillEditing() {
    final p = widget.product!;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description ?? "";
    _brandCtrl.text = p.brand;
    _supplierCtrl.text = p.supplier;
    _priceCtrl.text = p.unitPrice.toString();
    _stockCtrl.text = p.stockQuantity.toString();
    _minStockCtrl.text = p.minStockQuantity.toString();
    _stockUnit = p.stockUnit;
  }

  double _parseDouble(String text) {
    final cleaned = text.trim().replaceAll(",", ".");
    return double.tryParse(cleaned) ?? 0;
  }

  // =========================
  // SAVE
  // =========================
  Future<void> _save() async {
    if (_saving) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _saving = true;
    });

    try {
      final db = await _db.database;
      final nowIso = DateTime.now().toIso8601String();

      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final brand = _brandCtrl.text.trim();
      final supplier = _supplierCtrl.text.trim();

      final price = _parseDouble(_priceCtrl.text);
      final stock = _parseDouble(_stockCtrl.text);
      final minStock = _parseDouble(_minStockCtrl.text);

      final user = "admin"; // futuro: usuario real logueado

      if (!_editing) {
        // =========================
        // CREATE PRODUCT
        // =========================
        final id = await db.insert("products", {
          "name": name,
          "description": desc.isEmpty ? null : desc,
          "categoryId": 1,
          "brand": brand,
          "supplier": supplier,
          "unitPrice": price,
          "stockQuantity": stock,
          "stockUnit": _stockUnit,
          "minStockQuantity": minStock,
          "lastUpdatedAt": nowIso,
          "lastUpdatedBy": user,
        });

        await _db.insertLog(
          db,
          id,
          "Producto creado: $name",
          actionType: "CREATE",
          changedBy: user,
          fieldChanged: "ALL",
          oldValue: "",
          newValue: name,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      // =========================
      // UPDATE PRODUCT
      // =========================
      final p = _original!;
      final productId = p.id!;

      // Logs: comparar valores viejos vs nuevos
      final logs = <Map<String, dynamic>>[];

      void addLog({
        required String field,
        required String label,
        required String oldVal,
        required String newVal,
        required String actionType,
      }) {
        if (oldVal.trim() == newVal.trim()) return;

        logs.add({
          "fieldChanged": field,
          "action": "$label actualizado: $oldVal → $newVal",
          "actionType": actionType,
          "changedBy": user,
          "oldValue": oldVal,
          "newValue": newVal,
        });
      }

      addLog(
        field: "name",
        label: "Nombre",
        oldVal: p.name,
        newVal: name,
        actionType: "UPDATE",
      );

      addLog(
        field: "description",
        label: "Descripción",
        oldVal: p.description ?? "",
        newVal: desc,
        actionType: "UPDATE",
      );

      addLog(
        field: "brand",
        label: "Marca",
        oldVal: p.brand,
        newVal: brand,
        actionType: "UPDATE",
      );

      addLog(
        field: "supplier",
        label: "Proveedor",
        oldVal: p.supplier,
        newVal: supplier,
        actionType: "UPDATE",
      );

      addLog(
        field: "unitPrice",
        label: "Precio",
        oldVal: p.unitPrice.toStringAsFixed(2),
        newVal: price.toStringAsFixed(2),
        actionType: "PRICE",
      );

      addLog(
        field: "stockQuantity",
        label: "Stock",
        oldVal: p.stockQuantity.toString(),
        newVal: stock.toString(),
        actionType: "STOCK",
      );

      addLog(
        field: "stockUnit",
        label: "Unidad",
        oldVal: p.stockUnit,
        newVal: _stockUnit,
        actionType: "UPDATE",
      );

      addLog(
        field: "minStockQuantity",
        label: "Stock mínimo",
        oldVal: p.minStockQuantity.toString(),
        newVal: minStock.toString(),
        actionType: "MIN_STOCK",
      );

      // actualizar producto
      await db.update(
        "products",
        {
          "id": productId,
          "name": name,
          "description": desc.isEmpty ? null : desc,
          "categoryId": 1,
          "brand": brand,
          "supplier": supplier,
          "unitPrice": price,
          "stockQuantity": stock,
          "stockUnit": _stockUnit,
          "minStockQuantity": minStock,
          "lastUpdatedAt": nowIso,
          "lastUpdatedBy": user,
        },
        where: "id = ?",
        whereArgs: [productId],
      );

      // insertar logs
      for (final l in logs) {
        await _db.insertLog(
          db,
          productId,
          l["action"],
          actionType: l["actionType"],
          changedBy: l["changedBy"],
          fieldChanged: l["fieldChanged"],
          oldValue: l["oldValue"],
          newValue: l["newValue"],
        );
      }

      // Si no hubo cambios, registrar un log general
      if (logs.isEmpty) {
        await _db.insertLog(
          db,
          productId,
          "Producto guardado sin cambios",
          actionType: "UPDATE",
          changedBy: user,
          fieldChanged: "NONE",
          oldValue: "",
          newValue: "",
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("SAVE ERROR: $e");

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("No se pudo guardar.\n\n$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    }
  }

  // =========================
  // UI HELPERS
  // =========================
  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? "Editar Producto" : "Nuevo Producto";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nombre
              TextFormField(
                controller: _nameCtrl,
                decoration: _dec("Nombre del producto", Icons.inventory_2),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Ingrese un nombre válido";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Descripción
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: _dec("Descripción", Icons.description),
              ),

              const SizedBox(height: 12),

              // Marca
              TextFormField(
                controller: _brandCtrl,
                decoration: _dec("Marca", Icons.branding_watermark),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Ingrese una marca";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Proveedor
              TextFormField(
                controller: _supplierCtrl,
                decoration: _dec("Proveedor", Icons.local_shipping),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Ingrese un proveedor";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Precio
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec("Precio Unitario (₡)", Icons.attach_money),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Ingrese un precio";
                  }
                  final n = _parseDouble(v);
                  if (n < 0) return "Precio inválido";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Stock
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec("Stock Actual", Icons.inventory),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Ingrese stock";
                  }
                  final n = _parseDouble(v);
                  if (n < 0) return "Stock inválido";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Unidad
              DropdownButtonFormField<String>(
                value: _stockUnit,
                decoration: _dec("Unidad", Icons.straighten),
                items: _units.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _stockUnit = val;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Stock mínimo
              TextFormField(
                controller: _minStockCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec("Stock Mínimo", Icons.warning),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Ingrese stock mínimo";
                  }
                  final n = _parseDouble(v);
                  if (n < 0) return "Mínimo inválido";
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // BOTÓN GUARDAR
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? "Guardando..." : "Guardar"),
                  onPressed: _saving ? null : _save,
                ),
              ),

              const SizedBox(height: 10),

              // INFO
              if (_editing && _original?.lastUpdatedAt != null)
                Text(
                  "Última actualización: ${DateFormat("dd/MM/yyyy HH:mm").format(_original!.lastUpdatedAt!)}",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _brandCtrl.dispose();
    _supplierCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }
}