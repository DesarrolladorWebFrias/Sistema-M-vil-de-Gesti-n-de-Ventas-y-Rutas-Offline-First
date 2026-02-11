
import 'package:flutter/material.dart';
import '../../data/local/db_helper.dart';
import '../../data/models/cierre_caja.dart';
import '../../data/models/venta.dart';
import '../../utils/report_generator.dart';

import 'package:provider/provider.dart'; // Added import
import '../../providers/salida_provider.dart'; // Added import

class CloseDayScreen extends StatefulWidget {
  const CloseDayScreen({super.key});

  @override
  State<CloseDayScreen> createState() => _CloseDayScreenState();
}

class _CloseDayScreenState extends State<CloseDayScreen> {
  final _fondoInicialController = TextEditingController(text: '0.00');
  int? _selectedSalidaId; // State for filter
  
  // Controladores para Billetes
  final Map<int, TextEditingController> _billetesControl = {
    1000: TextEditingController(text: '0'),
    500: TextEditingController(text: '0'),
    200: TextEditingController(text: '0'),
    100: TextEditingController(text: '0'),
    50: TextEditingController(text: '0'),
    20: TextEditingController(text: '0'),
  };
  // Controladores para Monedas
  final Map<int, TextEditingController> _monedasControl = {
    10: TextEditingController(text: '0'),
    5: TextEditingController(text: '0'),
    2: TextEditingController(text: '0'),
    1: TextEditingController(text: '0'),
  };
  // Monedas centavos si fuera necesario, pero por ahora lo simplifico a enteros o input manual extra

  double _ventasSistema = 0.0;
  List<Venta> _ventasDelDia = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<SalidaProvider>(context, listen: false).loadSalidas();
    });
    _cargarDatosSistema();
  }

  Future<void> _cargarDatosSistema() async {
    final db = await DatabaseHelper().database;
    // Obtener ventas del día (desde las 00:00)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    
    // Construir query dinámica
    String whereClause = 'fecha_hora >= ?';
    List<dynamic> whereArgs = [startOfDay];

    if (_selectedSalidaId != null) {
      whereClause += ' AND id_salida = ?';
      whereArgs.add(_selectedSalidaId);
    }

    final res = await db.query(
      'ventas',
      where: whereClause,
      whereArgs: whereArgs
    );

    double total = 0.0;
    List<Venta> ventas = [];
    for (var v in res) {
      var venta = Venta.fromMap(v);
      total += venta.total;
      ventas.add(venta);
    }

    if (mounted) {
      setState(() {
        _ventasSistema = total;
        _ventasDelDia = ventas;
        _isLoading = false;
      });
    }
  }

  double _calcularDiferencia() {
    double efectivoTotal = _calcularTotalEfectivo();
    double fondo = double.tryParse(_fondoInicialController.text) ?? 0.0;
    double ventasSegunArqueo = efectivoTotal - fondo;
    return ventasSegunArqueo - _ventasSistema;
  }

  double _calcularTotalEfectivo() {
    double total = 0.0;
    _billetesControl.forEach((denom, ctrl) {
      total += denom * (int.tryParse(ctrl.text) ?? 0);
    });
    _monedasControl.forEach((denom, ctrl) {
      total += denom * (int.tryParse(ctrl.text) ?? 0);
    });
    return total;
  }

  Future<void> _generarCierre() async {
    double fondo = double.tryParse(_fondoInicialController.text) ?? 0.0;
    double efectivoContado = _calcularTotalEfectivo();
    double diferencia = _calcularDiferencia();
    
    // Calcular Ganancia Real desde la base de datos
    final db = await DatabaseHelper().database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final gananciaRes = await db.rawQuery('''
      SELECT COALESCE(SUM(dv.ganancia), 0.0) as total_ganancia 
      FROM detalle_ventas dv
      INNER JOIN ventas v ON dv.id_venta = v.id
      WHERE v.fecha_hora >= ?
    ''', [startOfDay]);
    
    double gananciaReal = ((gananciaRes.first['total_ganancia'] ?? 0) as num).toDouble();
    
    final cierre = CierreCaja(
      fechaHora: DateTime.now(),
      fondoCajaInicial: fondo,
      ventasSistema: _ventasSistema,
      dineroContado: efectivoContado,
      diferencia: diferencia,
      gananciaRealDia: gananciaReal, // Ganancia real calculada desde BD
      detallesBilletes: {
        ..._billetesControl.map((k, v) => MapEntry(k.toString(), int.tryParse(v.text) ?? 0)),
        ..._monedasControl.map((k, v) => MapEntry(k.toString(), int.tryParse(v.text) ?? 0)),
      }
    );

    // Guardar en BD
    await db.insert('cierres_caja', cierre.toMap());

    // Obtener información de Ruta para el reporte
    String? nombreRuta;
    if (_selectedSalidaId != null) {
      final salidaProvider = Provider.of<SalidaProvider>(context, listen: false);
      try {
        final salida = salidaProvider.salidas.firstWhere((s) => s.id == _selectedSalidaId);
        nombreRuta = "${salida.nombreRuta} (${salida.vendedor})";
      } catch (_) {}
    }

    // Generar PDF
    await ReportGenerator.generateAndSharePdf(cierre, _ventasDelDia, nombreRuta: nombreRuta);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final salidaProvider = Provider.of<SalidaProvider>(context); // Consume provider

    double efectivoTotal = _calcularTotalEfectivo();
    double diferencia = _calcularDiferencia();

    return Scaffold(
      appBar: AppBar(title: const Text("Reporte Financiero / Arqueo"), backgroundColor: Colors.blueGrey),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filtro de Ruta
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Filtrar por Ruta / Salida",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              value: _selectedSalidaId,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text("TODAS (General)")),
                ...salidaProvider.salidas.map((s) => DropdownMenuItem(
                  value: s.id, 
                  child: Text("${s.nombreRuta} - ${s.fechaHora.day}/${s.fechaHora.month}")
                )),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSalidaId = val;
                  _isLoading = true;
                });
                _cargarDatosSistema();
              },
            ),
            const SizedBox(height: 16),

            // Resumen Sistema
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Ventas Registradas (Sistema)", style: TextStyle(fontSize: 16)),
                    Text("\$${_ventasSistema.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Fondo Inicial
            TextField(
              controller: _fondoInicialController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Fondo de Caja Inicial", border: OutlineInputBorder()),
              onChanged: (_) => setState((){}),
            ),
            const SizedBox(height: 20),
            
            const Text("Arqueo de Efectivo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Billetes
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _billetesControl.entries.map((e) => _buildDenomInput(e.key, e.value, Colors.green[100]!)).toList(),
            ),
            const SizedBox(height: 10),
            // Monedas
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _monedasControl.entries.map((e) => _buildDenomInput(e.key, e.value, Colors.yellow[100]!)).toList(),
            ),

            const SizedBox(height: 20),
            const Divider(),
            
            // Resultados Tiempo Real
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Contado:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("\$${efectivoTotal.toStringAsFixed(2)}"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Diferencia:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "\$${diferencia.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diferencia == 0 ? Colors.green : (diferencia < 0 ? Colors.red : Colors.orange)
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _generarCierre(),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("CERRAR DÍA Y GENERAR REPORTE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20)
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDenomInput(int denom, TextEditingController ctrl, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Column(
        children: [
          Text("\$$denom", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(isDense: true, border: InputBorder.none),
            onChanged: (_) => setState((){}),
          )
        ],
      ),
    );
  }
}
