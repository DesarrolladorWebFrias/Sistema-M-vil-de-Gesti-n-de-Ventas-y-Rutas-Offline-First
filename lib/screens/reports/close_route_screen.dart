import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salida_provider.dart';
import '../../data/models/salida.dart';
import '../../data/models/cierre_caja.dart';
import '../../utils/report_generator.dart';

class CloseRouteScreen extends StatefulWidget {
  const CloseRouteScreen({super.key});

  @override
  State<CloseRouteScreen> createState() => _CloseRouteScreenState();
}

class _CloseRouteScreenState extends State<CloseRouteScreen> {
  int? _selectedSalidaId;
  Map<String, dynamic>? _devolucionData;
  bool _isLoadingCalculation = false;

  final _motivoController = TextEditingController();
  
  // Arqueo de Caja (Simplificado para este ejemplo, o reutilizar lógica de CloseDay)
  // Por ahora un campo de total efectivo para no complicar demasiado la UI inicial
  final _efectivoController = TextEditingController(text: '0.00');

  // Controladores detallados (Opcional, si el usuario quiere detalle de billetes por ruta)
  // Dejaremos solo el total por ahora para agilizar, ya que el arqueo detallado es mas común al cierre del día global.
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalidaProvider>(context, listen: false).loadSalidas();
    });
  }

  Future<void> _calcularDevolucion(int idSalida) async {
    setState(() {
      _isLoadingCalculation = true;
      _devolucionData = null;
    });

    try {
      final data = await Provider.of<SalidaProvider>(context, listen: false).calcularDevolucion(idSalida);
      // Enriquecer con nombres de productos si es necesario (el provider devuelve IDs)
      // Por simplicidad, asumimos que el reporteador o la vista resolverá los nombres, 
      // o podemos hacer una consulta extra aquí.
      setState(() {
        _devolucionData = data;
        
        // Asignar Total Vendido al campo de texto automáticamente
        if (data.containsKey('total_vendido')) {
           _efectivoController.text = (data['total_vendido'] as double).toStringAsFixed(2);
        } else {
           _efectivoController.text = '0.00';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error calculando devolución: $e")));
    } finally {
      setState(() {
        _isLoadingCalculation = false;
      });
    }
  }

  Future<void> _cerrarRuta() async {
    if (_selectedSalidaId == null) return;
    
    // 1. Confirmación
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Cierre de Ruta"),
        content: const Text("¿Estás seguro de cerrar esta ruta? Esto marcará la salida como completada y generará el reporte."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CERRAR RUTA")),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    // 2. Cerrar Salida en BD
    final salidaProvider = Provider.of<SalidaProvider>(context, listen: false);
    bool cerrado = await salidaProvider.cerrarSalida(_selectedSalidaId!);

    if (cerrado) {
      // 3. Generar Reporte
      await ReportGenerator.generateRouteReport(
        routeData: _devolucionData!, // Sabemos que no es null si estamos cerrando
        devoluciones: _devolucionData!['devolucion'],
        efectivoRecaudado: double.tryParse(_efectivoController.text) ?? 0.0,
        notas: _motivoController.text,
      ); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ruta Cerrada Exitosamente")));
        Navigator.pop(context); // Regresar
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al cerrar la ruta")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final salidaProvider = Provider.of<SalidaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Devolución de Producto"), // Cambiado de "Cierre de Ruta / Salida"
        backgroundColor: Colors.orange[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Seleccione la Ruta para Devolución:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              hint: const Text("Seleccionar Ruta Activa"),
              value: _selectedSalidaId,
              items: salidaProvider.salidasActivas.map((salida) {
                return DropdownMenuItem(
                  value: salida.id,
                  child: Text("${salida.nombreRuta} (${salida.vendedor})"),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSalidaId = val);
                  _calcularDevolucion(val);
                }
              },
            ),

            const SizedBox(height: 20),

            if (_isLoadingCalculation)
              const Center(child: CircularProgressIndicator())
            else if (_devolucionData != null)
              _buildResumenDevolucion(),

          ],
        ),
      ),
    );
  }

  Widget _buildResumenDevolucion() {
    // Aquí mostraríamos la tabla de lo que se llevó vs lo que vendió vs lo que debe devolver.
    // Usamos _devolucionData['devolucion'] que es una lista de mapas.
    List<dynamic> devoluciones = _devolucionData!['devolucion'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.info_outline, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                const Text("Productos a Devolver al Almacén", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("(Carga Inicial - Ventas Registradas)", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        if (devoluciones.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("¡Todo vendido! No hay devoluciones pendientes.", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devoluciones.length,
            itemBuilder: (context, index) {
              final item = devoluciones[index];
              return ListTile(
                leading: const Icon(Icons.assignment_return, color: Colors.orange),
                title: Text(item['nombre_producto'] ?? "Producto ${item['id_producto']}", style: const TextStyle(fontWeight: FontWeight.bold)), 
                subtitle: Text("Devolver: ${item['cajas_devueltas']} Cajas, ${item['piezas_devueltas']} Piezas"),
              );
            },
          ),

        const SizedBox(height: 20),
        const Divider(),
        const Text("Arqueo de Efectivo de la Ruta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _efectivoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Total Efectivo Recaudado",
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
            helperText: "Total calculado según ventas registradas: \$${_devolucionData?['total_vendido']?.toStringAsFixed(2) ?? '0.00'}",
            helperStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _motivoController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Motivo de Devolución / Notas",
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _cerrarRuta,
          icon: const Icon(Icons.check_circle),
          label: const Text("CERRAR RUTA Y GENERAR REPORTE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
