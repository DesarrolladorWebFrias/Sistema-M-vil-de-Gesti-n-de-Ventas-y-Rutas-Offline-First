import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/cierre_caja.dart';
import '../data/models/venta.dart';

class ReportGenerator {
  
  static Future<void> generateAndSharePdf(CierreCaja cierre, List<Venta> ventasDia, {String? nombreRuta}) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column( // Changed to Column to handle route name
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Reporte Financiero - LactoPOS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(dateFormat.format(cierre.fechaHora)),
                    ]
                  ),
                  if (nombreRuta != null) ...[
                    pw.SizedBox(height: 5),
                    pw.Text('Ruta: $nombreRuta', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ]
                ]
              )
            ),
            pw.SizedBox(height: 20),
            
            // Resumen Financiero
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RESUMEN FINANCIERO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  _buildPdfRow('Ventas Totales (Sistema):', cierre.ventasSistema, currencyFormat),
                  _buildPdfRow('Fondo de Caja Inicial:', cierre.fondoCajaInicial, currencyFormat),
                  _buildPdfRow('Efectivo Contado (Arqueo):', cierre.dineroContado, currencyFormat),
                  pw.Divider(),
                  _buildPdfRow('Diferencia:', cierre.diferencia, currencyFormat, isBold: true),
                  pw.SizedBox(height: 5),
                  _buildPdfRow('Ganancia Estimada del Día:', cierre.gananciaRealDia, currencyFormat, color: PdfColors.green700),
                ]
              )
            ),
            
            pw.SizedBox(height: 20),
            pw.Text('Desglose de Billetes y Monedas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              headers: ['Denominación', 'Cantidad', 'Subtotal'],
              data: cierre.detallesBilletes.entries.map((e) {
                double val = double.tryParse(e.key) ?? 0;
                return [
                  '\$${e.key}',
                  '${e.value}',
                  currencyFormat.format(val * e.value)
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            
            pw.SizedBox(height: 20),
            pw.Text('Detalle de Ventas (${ventasDia.length} Transacciones)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              headers: ['Hora', 'Total'],
              data: ventasDia.map((v) => [
                DateFormat('HH:mm').format(v.fechaHora),
                currencyFormat.format(v.total)
              ]).toList(),
              border: null,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            ),
          ];
        },
      ),
    );

    // Guardar y Compartir
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/reporte_cierre_${DateFormat('yyyyMMdd').format(cierre.fechaHora)}.pdf");
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte de Cierre ${dateFormat.format(cierre.fechaHora)}');
  }

  static pw.Widget _buildPdfRow(String label, double value, NumberFormat format, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.Text(format.format(value), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null, color: color)),
      ]
    );
  }

  // Método para generar reporte de Cierre de Ruta
  static Future<void> generateRouteReport({
    required Map<String, dynamic> routeData,
    required List<dynamic> devoluciones,
    required double efectivoRecaudado, 
    String? notas
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cierre de Ruta - LactoPOS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateFormat.format(DateTime.now())),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            
            // Info Ruta
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INFORMACIÓN DE RUTA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  // Aquí idealmente pasaríamos el objeto Salida completo, pero usamos el ID por ahora
                  _buildPdfRow('ID Salida:', (routeData['id_salida'] ?? 0).toDouble(), NumberFormat("0", "en_US")), 
                  _buildPdfRow('Efectivo Recaudado:', efectivoRecaudado, currencyFormat, isBold: true),
                  if (notas != null && notas.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text('Notas: $notas', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ]
                ]
              )
            ),

            pw.SizedBox(height: 20),
            pw.Text('Productos a Devolver (Carga - Ventas)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            
            if (devoluciones.isEmpty)
              pw.Text('Sin devoluciones (Todo vendido)', style: const pw.TextStyle(color: PdfColors.green))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Producto', 'Cajas Dev.', 'Piezas Dev.'], // Changed Header
                data: devoluciones.map((item) => [
                  item['nombre_producto']?.toString() ?? "ID ${item['id_producto']}", // Changed Data
                  item['cajas_devueltas'].toString(),
                  item['piezas_devueltas'].toString(),
                ]).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                }
              ),

            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text('Firma Vendedor'),
                  ]
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text('Firma Almacén/Supervisor'),
                  ]
                ),
              ]
            )
          ];
        },
      ),
    );

    // Guardar y Compartir
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/reporte_ruta_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf");
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte Cierre Ruta');
  }
}
