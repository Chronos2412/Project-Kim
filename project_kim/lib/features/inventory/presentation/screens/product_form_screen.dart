import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final AppDatabase _db = AppDatabase();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _minStockCtrl = TextEditingController();

  String _unit = "unit";
  final List<String> _units = ["unit", "kg", "lt", "box"];

  @override
  void initState() {
    super.initState();

    final p = widget.product;

    if (p != null) {
      _nameCtrl.text = p.name;
      _brandCtrl.text = p.brand;
      _supplierCtrl.text = p.supplier;
      _priceCtrl.text = p.unitPrice.toString();
      _stockCtrl.text = p.stockQuantity.toString();
      _minStockCtrl.text = p.minStockQuantity.toString();
      _unit = p.stockUnit;
    }

    // Safety: si viene una unidad rara desde DB
    if (!_units.contains(_unit)) {
      _unit = "unit";
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = await _db.database;

    final product = ProductModel(
      id: widget.product?.id,
      categoryId: widget.product?.categoryId ?? 1,
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      supplier: _supplierCtrl.text.trim(),
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      stockQuantity: double.tryParse(_stockCtrl.text) ?? 0,
      minStockQuantity: double.tryParse(_minStockCtrl.text) ?? 0,
      stockUnit: _unit,
      lastUpdatedAt: DateTime.now(),
      lastUpdatedBy: "admin",
    );

    if (widget.product == null) {
      await _db.insertProduct(db, product.toMap());
    } else {
      await _db.updateProduct(db, product.toMap());
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Editar Producto" : "Nuevo Producto"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Requerido" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(
                  labelText: "Marca",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _supplierCtrl,
                decoration: const InputDecoration(
                  labelText: "Proveedor",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Precio",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stock",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _minStockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stock mínimo",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
  // ignore: deprecated_member_use
  value: _unit,
  decoration: const InputDecoration(
    labelText: "Unidad",
    border: OutlineInputBorder(),
  ),
  items: _units.map((u) {
    return DropdownMenuItem<String>(
      value: u,
      child: Text(u),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      _unit = value ?? "unit";
    });
  },
),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? "Actualizar" : "Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}