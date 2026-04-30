import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';

import 'package:project_kim/core/db/app_database.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/domain/erp_core.dart';
import 'package:project_kim/features/inventory/presentation/screens/erp_control_center_screen.dart';
import 'package:project_kim/features/inventory/presentation/screens/erp_logs_screen.dart';
import 'package:project_kim/features/inventory/presentation/screens/erp_risk_list_screen.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:project_kim/features/inventory/presentation/screens/product_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final AppDatabase _db = AppDatabase();
  final ErpCore _core = ErpCore();

  bool _loading = true;

  List<ProductModel> _products = [];
  List<ProductModel> _filtered = [];

  final TextEditingController _searchCtrl = TextEditingController();

  // KPI values
  double _health = 0;
  int _criticalCount = 0;
  int _riskCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // =========================
  // LOAD PRODUCTS
  // =========================
  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
    });

    final db = await _db.database;
    final raw = await _db.getProducts(db: db);

    final list = raw.map((e) => ProductModel.fromMap(e)).toList();

    _core.setProducts(list);
    final ai = _core.ai;

    if (!mounted) return;

    setState(() {
      _products = list;
      _filtered = list;

      _criticalCount = ai.criticalStock().length;
      _riskCount = ai.riskProducts().length;
      _health = ai.healthScore();

      _loading = false;
    });
  }

  // =========================
  // SEARCH
  // =========================
  void _search(String value) {
    final q = value.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _filtered = _products;
      });
      return;
    }

    setState(() {
      _filtered = _products.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.supplier.toLowerCase().contains(q);
      }).toList();
    });
  }

  // =========================
  // OPEN CREATE
  // =========================
  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductFormScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadProducts();
    }
  }

  // =========================
  // OPEN DETAIL
  // =========================
  Future<void> _openDetail(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadProducts();
    }
  }

  // =========================
  // OPEN ERP CONTROL CENTER
  // =========================
  Future<void> _openErp() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ErpControlCenterScreen(),
      ),
    );

    if (!mounted) return;
    await _loadProducts();
  }

  // =========================
  // OPEN ERP LOGS
  // =========================
  Future<void> _openLogs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ErpLogsScreen(),
      ),
    );

    if (!mounted) return;
  }

  // =========================
  // OPEN CRITICAL LIST
  // =========================
  Future<void> _openCritical() async {
    if (_criticalCount == 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ErpRiskListScreen(
          core: _core,
          showCritical: true,
        ),
      ),
    );

    if (!mounted) return;
    await _loadProducts();
  }

  // =========================
  // OPEN RISK LIST
  // =========================
  Future<void> _openRisk() async {
    if (_riskCount == 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ErpRiskListScreen(
          core: _core,
          showCritical: false,
        ),
      ),
    );

    if (!mounted) return;
    await _loadProducts();
  }

  // =========================
  // INFO BUTTON
  // =========================
  void _showInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clasificación ERP"),
        content: const Text(
          "📌 CRÍTICO:\n"
          "Stock <= Stock mínimo\n\n"
          "📌 EN RIESGO:\n"
          "Stock > mínimo y <= mínimo * 1.2\n\n"
          "📌 OK:\n"
          "Stock > mínimo * 1.2\n\n"
          "Esto permite detectar productos que están cerca de caer en crítico.",
        ),
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
  // EXPORT DIALOG
  // =========================
  void _export() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exportar Inventario"),
        content: const Text(
          "Seleccione el formato para exportar el inventario completo.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportExcel();
            },
            child: const Text("Exportar Excel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportPdf();
            },
            child: const Text("Exportar PDF"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }

  // =========================
  // EXPORT EXCEL
  // =========================
  Future<void> _exportExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel["Inventario"];

      sheet.appendRow([
        TextCellValue("Producto"),
        TextCellValue("Marca"),
        TextCellValue("Proveedor"),
        TextCellValue("Precio"),
        TextCellValue("Stock"),
        TextCellValue("Unidad"),
        TextCellValue("Mínimo"),
        TextCellValue("Última actualización"),
      ]);

      for (final p in _products) {
        sheet.appendRow([
          TextCellValue(p.name),
          TextCellValue(p.brand),
          TextCellValue(p.supplier),
          TextCellValue("₡${p.unitPrice.toStringAsFixed(2)}"),
          TextCellValue(p.stockQuantity.toString()),
          TextCellValue(p.stockUnit),
          TextCellValue(p.minStockQuantity.toString()),
          TextCellValue(p.lastUpdatedAt?.toIso8601String() ?? ""),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      final now = DateFormat("yyyyMMdd_HHmm").format(DateTime.now());
      final suggestedName = "inventario_$now.xlsx";

      final saveLocation = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: "Excel",
            extensions: ["xlsx"],
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
          title: const Text("Exportación Exitosa"),
          content: Text("Archivo Excel guardado en:\n\n${file.path}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("EXCEL EXPORT ERROR: $e");

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("No se pudo exportar Excel.\n\n$e"),
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

  // =========================
  // EXPORT PDF
  // =========================
  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();

      final logoData = await DefaultAssetBundle.of(context)
          .load("assets/logo_experiencias360.jpg");
      final Uint8List logoBytes = logoData.buffer.asUint8List();

      // NotoSans (soporta ₡, °, ñ, etc)
      final fontRegular = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      final now = DateTime.now();
      final dateText = DateFormat("dd/MM/yyyy HH:mm").format(now);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Generado: $dateText",
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
          build: (context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(
                    pw.MemoryImage(logoBytes),
                    width: 90,
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Experiencias 360°",
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                        ),
                      ),
                      pw.Text(
                        "Reporte de Inventario",
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellStyle: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 9,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  "Producto",
                  "Marca",
                  "Proveedor",
                  "Precio",
                  "Stock",
                  "Mínimo",
                ],
                data: _products.map((p) {
                  return [
                    p.name,
                    p.brand,
                    p.supplier,
                    "₡${p.unitPrice.toStringAsFixed(2)}",
                    "${p.stockQuantity} ${p.stockUnit}",
                    p.minStockQuantity.toString(),
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      final nowStr = DateFormat("yyyyMMdd_HHmm").format(DateTime.now());
      final suggestedName = "inventario_$nowStr.pdf";

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
          title: const Text("Exportación Exitosa"),
          content: Text("Archivo PDF guardado en:\n\n${file.path}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("PDF EXPORT ERROR: $e");

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("No se pudo exportar PDF.\n\n$e"),
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

  // =========================
  // KPI CARD
  // =========================
  Widget _kpiCard({
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario 360"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Historial ERP",
            icon: const Icon(Icons.history),
            onPressed: _openLogs,
          ),
          IconButton(
            tooltip: "Info ERP",
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
          IconButton(
            tooltip: "Exportar",
            icon: const Icon(Icons.file_download),
            onPressed: _export,
          ),
          IconButton(
            tooltip: "ERP Control Center",
            icon: const Icon(Icons.dashboard_customize),
            onPressed: _openErp,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),

                // KPI BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _kpiCard(
                        title: "Salud",
                        value: "${_health.toStringAsFixed(0)}%",
                        color: Colors.green,
                        onTap: null,
                      ),
                      const SizedBox(width: 10),
                      _kpiCard(
                        title: "En riesgo",
                        value: _riskCount.toString(),
                        color: Colors.orange,
                        onTap: _riskCount == 0 ? null : _openRisk,
                      ),
                      const SizedBox(width: 10),
                      _kpiCard(
                        title: "Críticos",
                        value: _criticalCount.toString(),
                        color: Colors.red,
                        onTap: _criticalCount == 0 ? null : _openCritical,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: "Buscar producto",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search("");
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _search,
                  ),
                ),

                const SizedBox(height: 12),

                // LIST
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text("No hay productos registrados."),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final p = _filtered[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(p.name),
                                subtitle: Text(
                                  "Stock: ${p.stockQuantity} | Min: ${p.minStockQuantity}",
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openDetail(p),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}