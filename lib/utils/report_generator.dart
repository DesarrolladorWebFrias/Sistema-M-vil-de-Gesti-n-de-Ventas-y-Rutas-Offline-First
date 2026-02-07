import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/cierre_caja.dart';
import '../data/models/venta.dart';

class ReportGenerator {
  
  static Future<void> generateAndSharePdf(CierreCaja cierre, List<Venta> ventasDia) async {
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
                  pw.Text('Reporte de Cierre de Caja - LactoPOS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateFormat.format(cierre.fechaHora)),
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
            pw.Table.fromTextArray(
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
            pw.Table.fromTextArray(
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

  static Future<void> generateAndShareExcel(CierreCaja cierre, List<Venta> ventasDia) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Cierre'];
    
    // Encabezados
    sheet.appendRow([TextCellValue('Reporte de Cierre de Caja'), TextCellValue(DateFormat('dd/MM/yyyy').format(cierre.fechaHora))]);
    sheet.appendRow([TextCellValue('')]);
    
    sheet.appendRow([TextCellValue('Concepto'), TextCellValue('Monto')]);
    sheet.appendRow([TextCellValue('Ventas Sistema'), DoubleCellValue(cierre.ventasSistema)]);
    sheet.appendRow([TextCellValue('Fondo Inicial'), DoubleCellValue(cierre.fondoCajaInicial)]);
    sheet.appendRow([TextCellValue('Efectivo Arqueo'), DoubleCellValue(cierre.dineroContado)]);
    sheet.appendRow([TextCellValue('Diferencia'), DoubleCellValue(cierre.diferencia)]);
    sheet.appendRow([TextCellValue('Ganancia Día'), DoubleCellValue(cierre.gananciaRealDia)]);
    
    // Guardar
    var fileBytes = excel.save();
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/reporte_excel_${DateFormat('yyyyMMdd').format(cierre.fechaHora)}.xlsx");
    
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Reporte Excel Cierre');
    }
  }
}
