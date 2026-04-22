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

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _minStockCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  int? _categoryId;
  String _unit = "unidades";

  final List<String> _allowedUnits = ["unidades", "kg", "ml"];

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      final p = widget.product!;

      _nameCtrl.text = p.name;
      _brandCtrl.text = p.brand;
      _supplierCtrl.text = p.supplier;
      _stockCtrl.text = p.stockQuantity.toString();
      _minStockCtrl.text = p.minStockQuantity.toString();
      _priceCtrl.text = p.unitPrice.toString();
      _categoryId = p.categoryId;

      // 🔥 FIX CRÍTICO DROPDOWN SAFE
      final rawUnit = p.stockUnit.trim().toLowerCase();

      _unit = _allowedUnits.contains(rawUnit)
          ? rawUnit
          : "unidades";
    } else {
      _unit = "unidades";
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _supplierCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final db = await _db.database;

    final product = ProductModel(
      id: widget.product?.id,
      categoryId: _categoryId ?? 1,
      name: _nameCtrl.text,
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0.0,
      stockQuantity: double.tryParse(_stockCtrl.text) ?? 0.0,
      stockUnit: _unit,
      brand: _brandCtrl.text,
      supplier: _supplierCtrl.text,
      minStockQuantity: double.tryParse(_minStockCtrl.text) ?? 0.0,
      lastUpdatedAt: DateTime.now(),
      lastUpdatedBy: "admin",
    );

    if (widget.product == null) {
      await db.insert("products", product.toMap());
    } else {
      await db.update(
        "products",
        product.toMap(),
        where: "id = ?",
        whereArgs: [product.id],
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Editar producto" : "Nuevo producto"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: "Marca"),
            ),
            TextField(
              controller: _supplierCtrl,
              decoration: const InputDecoration(labelText: "Proveedor"),
            ),
            TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock"),
            ),
            TextField(
              controller: _minStockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock mínimo"),
            ),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Precio"),
            ),

            const SizedBox(height: 20),

            DropdownButton<String>(
              value: _unit,
              items: _allowedUnits.map((u) {
                return DropdownMenuItem(
                  value: u,
                  child: Text(u),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _unit = value;
                });
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveProduct,
              child: Text(isEdit ? "Actualizar" : "Crear"),
            ),
          ],
        ),
      ),
    );
  }
}