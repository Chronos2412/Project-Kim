import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BookingPdfService {
  static String _formatMoney(double value) {
    final format = NumberFormat.currency(locale: "es_CR", symbol: "₡");
    return format.format(value);
  }

  static String _timeSlotLabel(String slot) {
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

  static Future<Uint8List> generateBookingPdf({
    required Map<String, dynamic> bookingData,
    double paymentsTotal = 0.0, // opcional
  }) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load("assets/logo_experiencias360.jpg");
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Fuentes NotoSans (para ₡, ñ, etc)
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final bookingType = (bookingData["bookingType"] ?? "COTIZACION").toString();

    final celebrantFirst = bookingData["celebrantFirstName"] ?? "";
    final celebrantLast = bookingData["celebrantLastName"] ?? "";
    final celebrantAge = bookingData["celebrantAge"] ?? 0;

    final guardianName = bookingData["guardianName"] ?? "";
    final phone = bookingData["customerPhone"] ?? "";

    final childCount = bookingData["childCount"] ?? 0;

    final billableChildCount = childCount < 5 ? 5 : childCount;

    final eventDateRaw = bookingData["eventDate"] ?? "";
    final eventDate = DateTime.tryParse(eventDateRaw) ?? DateTime.now();
    final formattedDate = DateFormat("dd/MM/yyyy").format(eventDate);

    final timeSlot = bookingData["timeSlot"] ?? "";
    final timeSlotLabel = _timeSlotLabel(timeSlot);

    final fullAddress = bookingData["fullAddress"] ?? "";

    final packageName = bookingData["packageName"] ?? "";
    final packagePricePerChild =
        (bookingData["packagePricePerChild"] as num?)?.toDouble() ?? 0.0;

    final foodAdultsType = bookingData["foodAdultsType"] ?? "No";
    final foodAdultsCount = bookingData["foodAdultsCount"] ?? 0;
    final foodAdultsTotal =
        (bookingData["foodAdultsTotal"] as num?)?.toDouble() ?? 0.0;

    final foodKidsType = bookingData["foodKidsType"] ?? "No";
    final foodKidsCount = bookingData["foodKidsCount"] ?? 0;
    final foodKidsTotal =
        (bookingData["foodKidsTotal"] as num?)?.toDouble() ?? 0.0;

    final decorationType = bookingData["decorationType"] ?? "No";
    final decorationTotal =
        (bookingData["decorationTotal"] as num?)?.toDouble() ?? 0.0;

    final discountAmount =
        (bookingData["discountAmount"] as num?)?.toDouble() ?? 0.0;

    final subtotalAmount =
        (bookingData["subtotalAmount"] as num?)?.toDouble() ?? 0.0;

    final totalAmount =
        (bookingData["totalAmount"] as num?)?.toDouble() ?? 0.0;

    final depositAmount =
        (bookingData["depositAmount"] as num?)?.toDouble() ?? 0.0;

    final notes = bookingData["notes"] ?? "";

    final minDeposit = totalAmount * 0.30;

    final pendingAmount = totalAmount - depositAmount - paymentsTotal;

    final pendingFixed = pendingAmount < 0 ? 0.0 : pendingAmount;

    final packageTotal = packagePricePerChild * billableChildCount;

    // =========================
    // PACKAGE DETAILS
    // =========================
    String packageDetails = "";

    if (packageName == "Mini Glow Spa") {
      packageDetails = """
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
    } else if (packageName == "Glam Plus Spa") {
      packageDetails = """
Incluye todo lo del Mini Glow Spa, más:
• Manicura spa o pedicura spa
• Peinados con glitter, accesorios y mechones de colores
• Actividad creativa (pulseras, decoración de antifaz o lienzo)
• Juegos durante la actividad (incluye premios)

Paquete mínimo: 5 niñ@s
Precio por niñ@: ₡25,000
""";
    } else if (packageName == "Glam Premium Spa") {
      packageDetails = """
Incluye:
• Brindis “Divas Sparkle”
• Obsequio para la cumpleañera
• Facial: jabón de limpieza, exfoliación, tónico, mascarilla e hidratación
• Manicura spa y pedicura spa (exfoliación, masaje, esmaltado, stickers para uñas)
• Maquillaje glam: sombras, rubor, iluminador, glitter, diseños y gemas para el rostro
• Peinados con glitter, accesorios y mechones de colores a elección
• Actividad creativa: pulseras, decoración de espejos o pintura en lienzo (a coordinar previamente)
• Actividades: juegos, pasarela y karaoke (incluye premios)
• Animación durante la piñata
• Kit para cada niña

Paquete mínimo: 5 niñ@s
Precio por niñ@: ₡25,000
""";
    }

    // =========================
    // DECORATION DETAILS
    // =========================
    String decorationDetails = "";

    if (decorationType == "Básica") {
      decorationDetails = """
• Cortina según temática
• Medio arco de globos sencillo (3 colores diferentes)
• Ideal para lugares pequeños

Precio: ₡25,000
""";
    } else if (decorationType == "Intermedia") {
      decorationDetails = """
• Arco de globos más abundante
• Diferentes tamaños de globos
• 1 fondo decorativo sencillo o temática
• Número de cumpleaños

Precio: ₡35,000
""";
    } else if (decorationType == "Premium") {
      decorationDetails = """
• Arco de globos más abundante y completo o medio arco abundante + torre
• Diferentes tamaños de globos especiales
• 1 fondo decorativo elaborado
• Número de cumpleaños
• Torre de cajas letras (4 letras)
• Alfombra (en caso que se necesite)

Precio: ₡50,000
""";
    } else {
      decorationDetails = "No aplica.";
    }

    // =========================
    // POLICIES
    // =========================
    final policies = """
🔹 La reserva se confirma con el adelanto del 30% del valor total del paquete.
🔹 El adelanto no es reembolsable.
🔹 Los cambios de fecha se realizan únicamente según disponibilidad de Experiencias 360 y se negociará con la persona encargada.
🔹 Si se desea hacer un cambio en las actividades, temáticas, etc., deberá hacerse con 8 días hábiles de anticipación.
🔹 El lugar del evento deberá reunir las condiciones mínimas necesarias para llevar a cabo la actividad (seguridad, servicio de agua, electricidad y demás).
🔹 El día del evento, nuestro equipo de Experiencias 360 llegará 1 hora y 30 minutos antes para decorar el espacio asignado y preparar todos los detalles de la actividad.
🔹 Cualquier afectación generada por un atraso por parte del cliente será responsabilidad del cliente y no se extenderá el evento para compensar el retraso, salvo decisión a criterio del personal.
🔹 El cliente deberá informar de forma anticipada cualquier condición especial de los participantes (alergias, necesidades específicas o cualquier otro aspecto importante).
🔹 El pago de la reserva se realiza mediante transferencia o SINPE Móvil a las siguientes cuentas:

-SINPE Móvil: 83189437 a nombre de Kimberly Gonzalez Bolaños.
-Cuenta IBAN: CR34010200009391755929 a nombre de Kimberly Gonzalez Bolaños.
""";

    final now = DateTime.now();
    final nowText = DateFormat("dd/MM/yyyy HH:mm").format(now);

    // =========================
    // HELPERS PDF
    // =========================
    pw.Widget _sectionTitle(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 14,
            color: PdfColors.blueGrey900,
          ),
        ),
      );
    }

    pw.Widget _line(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Expanded(
              flex: 6,
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  font: bold ? fontBold : fontRegular,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // =========================
    // PDF PAGE
    // =========================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              "Generado el $nowText",
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
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 110),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Experiencias 360°",
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      bookingType.toUpperCase() == "COTIZACION"
                          ? "COTIZACIÓN"
                          : "RESERVACIÓN",
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 14,
                        color: PdfColors.blueGrey700,
                      ),
                    ),
                  ],
                )
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Divider(),

            // TITLE
            pw.Text(
              "Fiesta de $celebrantFirst $celebrantLast",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
              ),
            ),

            pw.SizedBox(height: 6),

            _line("Edad", "$celebrantAge años"),
            _line("Encargado", guardianName),
            _line("Teléfono", phone),
            _line("Fecha", formattedDate),
            _line("Horario", timeSlotLabel),
            _line("Dirección", fullAddress),

            // PACKAGE
            _sectionTitle("Paquete seleccionado"),
            _line("Paquete", packageName),
            _line("Cantidad real de niñ@s", "$childCount"),
            _line("Cantidad facturada (mínimo 5)", "$billableChildCount"),
            _line("Precio por niñ@", _formatMoney(packagePricePerChild)),
            _line("Total paquete", _formatMoney(packageTotal), bold: true),

            pw.SizedBox(height: 6),
            pw.Text(
              packageDetails,
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),

            // FOOD
            _sectionTitle("Alimentación"),
            _line(
              "Adultos",
              "$foodAdultsType ($foodAdultsCount personas) - Total: ${_formatMoney(foodAdultsTotal)}",
            ),
            _line(
              "Niñ@s",
              "$foodKidsType ($foodKidsCount personas) - Total: ${_formatMoney(foodKidsTotal)}",
            ),

            // DECORATION
            _sectionTitle("Decoración"),
            _line("Tipo", decorationType),
            _line("Costo", _formatMoney(decorationTotal), bold: true),

            pw.SizedBox(height: 6),
            pw.Text(
              decorationDetails,
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),

            // TOTALS
            _sectionTitle("Resumen de costos"),
            _line("Subtotal", _formatMoney(subtotalAmount)),
            _line("Descuento", _formatMoney(discountAmount)),
            _line("TOTAL", _formatMoney(totalAmount), bold: true),

            pw.SizedBox(height: 6),
            _line(
              "Adelanto mínimo requerido (30%)",
              _formatMoney(minDeposit),
              bold: true,
            ),
            _line(
              "Adelanto recibido",
              _formatMoney(depositAmount),
            ),
            _line(
              "Pagos adicionales",
              _formatMoney(paymentsTotal),
            ),
            _line(
              "Saldo pendiente",
              _formatMoney(pendingFixed),
              bold: true,
            ),

            // NOTES
            if (notes.toString().trim().isNotEmpty) ...[
              _sectionTitle("Observaciones"),
              pw.Text(
                notes,
                style: pw.TextStyle(font: fontRegular, fontSize: 10),
              ),
            ],

            // POLICIES
            _sectionTitle("Políticas de servicio"),
            pw.Text(
              policies,
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),

            pw.SizedBox(height: 12),
            pw.Text(
              "Al contratar el servicio, el cliente acepta todas las políticas anteriores.",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}