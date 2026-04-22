import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/tag_model.dart';
import 'package:project_kim/features/inventory/presentation/widgets/tag_input_widget.dart';

class ProductFormScreen extends StatefulWidget {
  final dynamic product; // reemplaza por ProductModel si tienes

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final AppDatabase _db = AppDatabase();

  List<TagModel> _existingTags = [];
  List<TagModel> _selectedTags = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

    _loadTags();

    if (isEditing) {
      _fillProductData();
      _loadProductTags(widget.product.id);
    }
  }

  // =========================
  // LOAD ALL TAGS (CATALOG)
  // =========================
  Future<void> _loadTags() async {
    final db = await _db.database;

    final result = await db.query('tags');

    setState(() {
      _existingTags =
          result.map((e) => TagModel.fromMap(e)).toList();
    });
  }

  // =========================
  // LOAD PRODUCT DATA (EDIT)
  // =========================
  void _fillProductData() {
    final product = widget.product;

    _nameController.text = product.name;
    _descController.text = product.description ?? "";
  }

  // =========================
  // LOAD PRODUCT TAGS (EDIT FIX)
  // =========================
  Future<void> _loadProductTags(int productId) async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT t.*
      FROM tags t
      INNER JOIN product_tags pt ON pt.tagId = t.id
      WHERE pt.productId = ?
    ''', [productId]);

    setState(() {
      _selectedTags =
          result.map((e) => TagModel.fromMap(e)).toList();
    });
  }

  // =========================
  // SAVE PRODUCT (CREATE/UPDATE)
  // =========================
  Future<void> saveProduct() async {
    final db = await _db.database;

    final productData = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    int productId;

    if (isEditing) {
      productId = widget.product.id;

      await db.update(
        'products',
        productData,
        where: 'id = ?',
        whereArgs: [productId],
      );
    } else {
      productId = await db.insert('products', productData);
    }

    // =========================
    // TAGS FLOW (IMPORTANT)
    // =========================
    final tagNames =
        _selectedTags.map((t) => t.name).toList();

    await _db.saveProductTags(
      db,
      productId,
      tagNames,
    );

    // =========================
    // LOG
    // =========================
    await db.insert('product_logs', {
      'productId': productId,
      'action': isEditing ? 'UPDATE' : 'CREATE',
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? "Editar Producto" : "Nuevo Producto",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // NAME
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre del producto",
              ),
            ),

            const SizedBox(height: 12),

            // DESCRIPTION
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Descripción",
              ),
            ),

            const SizedBox(height: 20),

            // TAG INPUT
            TagInputWidget(
              existingTags: _existingTags,
              selectedTags: _selectedTags,
              onAddTag: (tag) {
                setState(() {
                  final exists = _selectedTags.any(
                    (t) => t.name.toLowerCase() ==
                        tag.name.toLowerCase(),
                  );

                  if (!exists) {
                    _selectedTags.add(tag);
                  }
                });
              },
              onRemoveTag: (tag) {
                setState(() {
                  _selectedTags.removeWhere(
                    (t) =>
                        t.name.toLowerCase() ==
                        tag.name.toLowerCase(),
                  );
                });
              },
            ),

            const Spacer(),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveProduct,
                child: Text(
                  isEditing ? "Actualizar" : "Guardar",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}