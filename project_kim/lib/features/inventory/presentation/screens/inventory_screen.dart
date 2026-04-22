import 'package:flutter/material.dart';
import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/tag_model.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final AppDatabase _db = AppDatabase();

  List<TagModel> _allTags = [];
  List<int> _selectedTagIds = [];
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadProducts();
  }

  // =========================
  // LOAD TAGS
  // =========================
  Future<void> _loadTags() async {
    final db = await _db.database;
    final result = await _db.getAllTags(db);

    setState(() {
      _allTags = result.map((e) => TagModel.fromMap(e)).toList();
    });
  }

  // =========================
  // LOAD PRODUCTS
  // =========================
  Future<void> _loadProducts() async {
    final db = await _db.database;

    final result = await _db.getProductsByTags(
      db,
      _selectedTagIds,
    );

    setState(() {
      _products =
          result.map((e) => ProductModel.fromMap(e)).toList();
    });
  }

  // =========================
  // TOGGLE TAG FILTER
  // =========================
  Future<void> _toggleTag(int tagId) async {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });

    await _loadProducts();
  }

  // =========================
  // CLEAR FILTER
  // =========================
  Future<void> _clearFilter() async {
    setState(() {
      _selectedTagIds.clear();
    });

    await _loadProducts();
  }

  // =========================
  // OPEN CREATE PRODUCT
  // =========================
  Future<void> _openCreateProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductFormScreen(),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearFilter,
            tooltip: "Limpiar filtros",
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateProduct,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // =========================
          // TAG FILTER
          // =========================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _allTags.map((tag) {
                final isSelected =
                    _selectedTagIds.contains(tag.id);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag.name),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag.id!),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // =========================
          // PRODUCT LIST
          // =========================
          Expanded(
            child: _products.isEmpty
                ? const Center(
                    child: Text("No hay productos"),
                  )
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];

                      return ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text(product.name),

subtitle: Text(
  "Marca: ${product.brand} • "
  "Stock Disponible: ${product.stockQuantity} ${product.stockUnit} • "
  "Precio: ₡${product.unitPrice}",
),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}