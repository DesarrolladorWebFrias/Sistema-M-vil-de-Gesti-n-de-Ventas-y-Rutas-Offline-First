import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/producto.dart';
import '../../data/models/movimiento_inventario.dart';
import '../../data/models/salida.dart';
import '../../data/local/db_helper.dart';
import '../../providers/product_provider.dart';
import '../../providers/salida_provider.dart';

class RestockScreen extends StatefulWidget {
  const RestockScreen({super.key});

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  int? _selectedSalidaId; // Ruta seleccionada
  Producto? _selectedProduct;
  final _cajasController = TextEditingController(text: '0');
  final _piezasController = TextEditingController(text: '0');
  final _notasController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      Provider.of<SalidaProvider>(context, listen: false).loadSalidas();
    });
  }

  Future<void> _submitRestock() async {
    if (_selectedSalidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seleccione una ruta primero"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un producto")));
      return;
    }

    final int cajas = int.tryParse(_cajasController.text) ?? 0;
    final int piezas = int.tryParse(_piezasController.text) ?? 0;

    if (cajas == 0 && piezas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingrese una cantidad válida")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper().database;

      // 1. Registrar en detalle_salidas (Reabastecimiento de la ruta)
      await db.insert('detalle_salidas', {
        'id_salida': _selectedSalidaId,
        'id_producto': _selectedProduct!.id,
        'cantidad_cajas': cajas,
        'cantidad_piezas': piezas,
        'precio_venta': _selectedProduct!.precio, // Precio actual del producto
      });

      // 2. Registrar Movimiento en Kardex
      final movimiento = MovimientoInventario(
        fechaHora: DateTime.now(),
        tipo: 'ALTA_REABASTECIMIENTO',
        idProducto: _selectedProduct!.id!,
        cantidadCajas: cajas,
        cantidadPiezas: piezas,
        usuario: 'ADMIN',
        notas: _notasController.text.isEmpty 
          ? 'Reabastecimiento en Ruta ID: $_selectedSalidaId' 
          : _notasController.text,
      );

      await db.insert('movimientos_inventario', movimiento.toMap());

      // 3. Recargar Productos en Provider con la salida seleccionada
      if (mounted) {
        await Provider.of<ProductProvider>(context, listen: false).loadProducts(idSalida: _selectedSalidaId);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Reabastecimiento registrado en la ruta",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Limpiar campos
      _cajasController.text = '0';
      _piezasController.text = '0';
      _notasController.clear();
      setState(() => _selectedProduct = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products;
    final salidaProvider = Provider.of<SalidaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reabastecimiento en Ruta"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. SELECTOR DE RUTA (PRIMERO)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Selecciona primero la ruta a reabastecer",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedSalidaId,
                    decoration: const InputDecoration(
                      labelText: "📍 Ruta / Salida",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text("Selecciona una ruta activa"),
                    items: salidaProvider.salidasActivas.map((salida) {
                      return DropdownMenuItem(
                        value: salida.id,
                        child: Text(
                          "${salida.tipo == 'RUTA' ? '🗺️' : '📦'} ${salida.nombreRuta}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSalidaId = value;
                        _selectedProduct = null; // Reset producto al cambiar ruta
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. Selector de Producto
            DropdownButtonFormField<Producto>(
              value: _selectedProduct,
              decoration: const InputDecoration(
                labelText: "Seleccionar Producto",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              items: products.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.nombre),
                );
              }).toList(),
              onChanged: _selectedSalidaId == null 
                ? null // Deshabilitar si no hay ruta seleccionada
                : (val) {
                    setState(() => _selectedProduct = val);
                  },
            ),
            const SizedBox(height: 20),
            
            // Info de Stock Actual
            if (_selectedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      const Text("Stock Actual (Cajas)", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${_selectedProduct!.stockCajas}", style: const TextStyle(fontSize: 18)),
                    ]),
                    Column(children: [
                      const Text("Stock Actual (Piezas)", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${_selectedProduct!.stockPiezas}", style: const TextStyle(fontSize: 18)),
                    ]),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Inputs de Cantidad
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cajasController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Cajas a Agregar",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _piezasController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Piezas a Agregar",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: "Notas (Opcional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitRestock,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_alt),
                label: const Text("REGISTRAR ENTRADA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
