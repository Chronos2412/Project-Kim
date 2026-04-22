import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final AppDatabase _db = AppDatabase();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();

  String _unit = "unidades";

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _supplierCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = await _db.database;

    final product = ProductModel(
      categoryId: 1, // temporal mientras conectamos categories UI
      name: _nameCtrl.text.trim(),
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0.0,
      stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
      stockUnit: _unit,
      brand: _brandCtrl.text.trim(),
      supplier: _supplierCtrl.text.trim(),
      minStockQuantity: int.tryParse(_minStockCtrl.text) ?? 0,
      lastUpdatedAt: DateTime.now(),
      lastUpdatedBy: "system",
    );

    await db.insert("products", product.toMap());

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Producto")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Requerido" : null,
              ),

              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: "Marca"),
              ),

              TextFormField(
                controller: _supplierCtrl,
                decoration: const InputDecoration(labelText: "Proveedor"),
              ),

              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: "Precio unitario"),
                keyboardType: TextInputType.number,
              ),

              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: "Stock actual"),
                keyboardType: TextInputType.number,
              ),

              TextFormField(
                controller: _minStockCtrl,
                decoration: const InputDecoration(labelText: "Stock mínimo"),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
  value: _unit,
  items: const [
    DropdownMenuItem(value: "unidades", child: Text("Unidades")),
    DropdownMenuItem(value: "kg", child: Text("Kilogramos")),
    DropdownMenuItem(value: "g", child: Text("Gramos")),
    DropdownMenuItem(value: "ml", child: Text("Mililitros")),
    DropdownMenuItem(value: "l", child: Text("Litros")),
    DropdownMenuItem(value: "caja", child: Text("Caja")),
  ],
  onChanged: (value) {
    if (value != null) setState(() => _unit = value);
  },
  decoration: const InputDecoration(labelText: "Unidad de medida"),
),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _save,
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}