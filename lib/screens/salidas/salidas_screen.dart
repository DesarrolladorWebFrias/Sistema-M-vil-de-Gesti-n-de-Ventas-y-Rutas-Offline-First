import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salida_provider.dart';
import '../../data/models/salida.dart';
import 'nueva_salida_screen.dart';
import 'package:intl/intl.dart';

class SalidasScreen extends StatefulWidget {
  const SalidasScreen({super.key});

  @override
  State<SalidasScreen> createState() => _SalidasScreenState();
}

class _SalidasScreenState extends State<SalidasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalidaProvider>(context, listen: false).loadSalidas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSalida(Salida salida) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Salida"),
        content: Text("¿Estás seguro de cerrar la salida '${salida.nombreRuta}'?\n\nEsta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cerrar Salida"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<SalidaProvider>(context, listen: false);
      bool success = await provider.cerrarSalida(salida.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Salida cerrada exitosamente" : "Error al cerrar salida"),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _verDetalles(Salida salida) async {
    final provider = Provider.of<SalidaProvider>(context, listen: false);
    final detalles = await provider.getDetallesSalida(salida.id!);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detalles - ${salida.nombreRuta}"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow("Tipo", salida.tipo == 'RUTA' ? '🗺️ Ruta' : '📦 Pedido Especial'),
              _buildInfoRow("Vendedor", salida.vendedor),
              if (salida.nombreCliente != null)
                _buildInfoRow("Cliente", salida.nombreCliente!),
              _buildInfoRow("Fecha", DateFormat('dd/MM/yyyy HH:mm').format(salida.fechaHora)),
              _buildInfoRow("Estado", salida.cerrada ? '🔒 Cerrada' : '🔓 Activa'),
              const Divider(height: 20),
              const Text("Productos:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...detalles.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text("• Producto #${d.idProducto}: ${d.cantidadCajas}C + ${d.cantidadPiezas}P - \$${d.precioVenta.toStringAsFixed(2)}"),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSalidaCard(Salida salida) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: salida.tipo == 'RUTA' ? Colors.blue : Colors.purple,
          child: Text(
            salida.tipo == 'RUTA' ? '🗺️' : '📦',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          salida.nombreRuta,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vendedor: ${salida.vendedor}"),
            if (salida.nombreCliente != null)
              Text("Cliente: ${salida.nombreCliente}", style: const TextStyle(fontStyle: FontStyle.italic)),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(salida.fechaHora),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'detalles') {
              _verDetalles(salida);
            } else if (value == 'cerrar') {
              _cerrarSalida(salida);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detalles',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text("Ver Detalles"),
                ],
              ),
            ),
            if (!salida.cerrada)
              const PopupMenuItem(
                value: 'cerrar',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Cerrar Salida"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salidaProvider = Provider.of<SalidaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Salidas / Rutas"),
        backgroundColor: Colors.blue[800],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Activas", icon: Icon(Icons.lock_open)),
            Tab(text: "Cerradas", icon: Icon(Icons.lock)),
          ],
        ),
      ),
      body: salidaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab Activas
                salidaProvider.salidasActivas.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No hay salidas activas",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: salidaProvider.salidasActivas.length,
                        itemBuilder: (context, index) {
                          return _buildSalidaCard(salidaProvider.salidasActivas[index]);
                        },
                      ),
                // Tab Cerradas
                salidaProvider.salidas.where((s) => s.cerrada).isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No hay salidas cerradas",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: salidaProvider.salidas.where((s) => s.cerrada).length,
                        itemBuilder: (context, index) {
                          final salidasCerradas = salidaProvider.salidas.where((s) => s.cerrada).toList();
                          return _buildSalidaCard(salidasCerradas[index]);
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NuevaSalidaScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Nueva Salida"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
