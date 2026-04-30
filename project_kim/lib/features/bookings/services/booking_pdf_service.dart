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
  }) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load("assets/logo_experiencias360.jpg");
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final bookingType = bookingData["bookingType"] ?? "COTIZACION";
    final division = bookingData["division"] ?? "Spa Party";

    final celebrantFirst = bookingData["celebrantFirstName"] ?? "";
    final celebrantLast = bookingData["celebrantLastName"] ?? "";
    final celebrantAge = bookingData["celebrantAge"] ?? 0;

    final guardianName = bookingData["guardianName"] ?? "";
    final phone = bookingData["customerPhone"] ?? "";

    final childCount = bookingData["childCount"] ?? 0;

    final eventDateRaw = bookingData["eventDate"] ?? "";
    final eventDate = DateTime.tryParse(eventDateRaw) ?? DateTime.now();
    final formattedDate = DateFormat("dd/MM/yyyy").format(eventDate);

    final timeSlot = bookingData["timeSlot"] ?? "";
    final timeSlotLabel = _timeSlotLabel(timeSlot);

    final fullAddress = bookingData["fullAddress"] ?? "";

    final packageName = bookingData["packageName"] ?? "";
    final packagePricePerChild =
        (bookingData["packagePricePerChild"] as num?)?.toDouble() ?? 0.0;

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

    final pendingAmount = totalAmount - depositAmount;

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
    } else {
      packageDetails = "Detalles no disponibles para este paquete.";
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
                      bookingType == "COTIZACION"
                          ? "COTIZACIÓN"
                          : "RESERVACIÓN",
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "División: $division",
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              "Fiesta de $celebrantFirst $celebrantLast",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "Edad: $celebrantAge años",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Encargado: $guardianName",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Teléfono: $phone",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              "Fecha: $formattedDate",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Horario: $timeSlotLabel",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              "Dirección: $fullAddress",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              "Paquete seleccionado",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              "Paquete: $packageName",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Cantidad de niñ@s: $childCount",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Precio por niñ@: ${_formatMoney(packagePricePerChild)}",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Total paquete: ${_formatMoney(packagePricePerChild * childCount)}",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              packageDetails,
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              "Decoración",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              "Tipo: $decorationType",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Costo: ${_formatMoney(decorationTotal)}",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              decorationDetails,
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              "Resumen de costos",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "Subtotal: ${_formatMoney(subtotalAmount)}",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Descuento: ${_formatMoney(discountAmount)}",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "TOTAL: ${_formatMoney(totalAmount)}",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 15,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "Depósito recomendado (30%): ${_formatMoney(totalAmount * 0.30)}",
              style: pw.TextStyle(font: fontBold),
            ),
            pw.Text(
              "Depósito registrado: ${_formatMoney(depositAmount)}",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.Text(
              "Saldo pendiente: ${_formatMoney(pendingAmount)}",
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 12),
            if (notes.toString().trim().isNotEmpty) ...[
              pw.Text(
                "Observaciones",
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                notes,
                style: pw.TextStyle(font: fontRegular),
              ),
              pw.SizedBox(height: 12),
            ],
            pw.Text(
              "Políticas de servicio",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              policies,
              style: pw.TextStyle(font: fontRegular),
            ),
            pw.SizedBox(height: 14),
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