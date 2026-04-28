import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_kim/features/inventory/data/models/product_model.dart';
import 'package:project_kim/features/inventory/domain/erp_ai_engine.dart';

class InventoryExportService {
  // =========================
  // EXPORT EXCEL
  // =========================
  static Future<File> exportToExcel(List<ProductModel> products) async {
    final excel = Excel.createExcel();
    final sheet = excel['Inventario'];

    final ai = ErpAiEngine(products);

    sheet.appendRow([
      TextCellValue("ID"),
      TextCellValue("Nombre"),
      TextCellValue("Marca"),
      TextCellValue("Proveedor"),
      TextCellValue("Precio"),
      TextCellValue("Stock"),
      TextCellValue("Unidad"),
      TextCellValue("Stock Mínimo"),
      TextCellValue("Estado"),
      TextCellValue("Última Actualización"),
      TextCellValue("Actualizado Por"),
    ]);

    for (final p in products) {
      final status = ai.isCritical(p)
          ? "CRÍTICO"
          : ai.isRisk(p)
              ? "RIESGO"
              : "OK";

      sheet.appendRow([
        IntCellValue(p.id ?? 0),
        TextCellValue(p.name),
        TextCellValue(p.brand),
        TextCellValue(p.supplier),
        DoubleCellValue(p.unitPrice),
        DoubleCellValue(p.stockQuantity),
        TextCellValue(p.stockUnit),
        DoubleCellValue(p.minStockQuantity),
        TextCellValue(status),
        TextCellValue(p.lastUpdatedAt?.toIso8601String() ?? ""),
        TextCellValue(p.lastUpdatedBy),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();

    final fileName =
        "Inventario_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    final filePath = "${directory.path}/$fileName";

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception("No se pudo generar Excel.");
    }

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    return file;
  }
}