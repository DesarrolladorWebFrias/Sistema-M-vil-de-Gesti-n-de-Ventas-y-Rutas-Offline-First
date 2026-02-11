import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/salida_provider.dart';
import '../../data/models/producto.dart';
import '../../widgets/product_carousel.dart';
import '../../data/models/salida.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _unidadSeleccionada = 'PIEZA'; // 'PIEZA' o 'CAJA'
  int _cantidad = 1;
  int? _selectedSalidaId; // Salida seleccionada para filtrar stock y registrar venta

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final salidaProvider = Provider.of<SalidaProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      // Cargar salidas y seleccionar la última activa por defecto
      salidaProvider.loadSalidas().then((_) {
        if (mounted && salidaProvider.salidasActivas.isNotEmpty) {
          setState(() {
            _selectedSalidaId = salidaProvider.salidasActivas.first.id;
          });
          // Cargar productos con el stock de la ruta seleccionada
          productProvider.loadProducts(idSalida: _selectedSalidaId);
        } else {
          // Si no hay salidas activas, cargar el almacén general
          productProvider.loadProducts();
        }
      });
    });
  }

  void _agregarProducto(Producto producto) {
    try {
      Provider.of<SalesProvider>(context, listen: false).addToCart(
        producto, 
        _cantidad, 
        _unidadSeleccionada,
        // Eliminamos el hardcode de 12, ahora usa lo que tenga el producto
        piezasPorCaja: producto.piezasPorCaja > 0 ? producto.piezasPorCaja : 12 
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Agregado: ${producto.nombre}"),
          duration: const Duration(milliseconds: 500),
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("LactoPOS - Punto de Venta"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.pushNamed(context, '/admin_login'), // Ir a login admin
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue[800]),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text("LactoPOS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Item de Salidas/Rutas
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.blue),
              title: const Text("Salidas / Rutas", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Gestionar salidas y pedidos"),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                Navigator.pushNamed(context, '/salidas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in, color: Colors.orange),
              title: const Text("Devolución de Producto", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Cerrar rutas y devoluciones"),
              onTap: () {
                Navigator.pop(context); 
                Navigator.pushNamed(context, '/cierre_ruta');
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.green),
              title: const Text("Reporte Financiero / Arqueo", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Cierre de caja y ventas"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cierre_caja');
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Inventario Rápido", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            // Lista rápida de stock
            ...productProvider.products.map((p) => ListTile(
              title: Text(p.nombre),
              subtitle: Text("Cajas: ${p.stockCajas} | Piezas: ${p.stockPiezas}"),
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
            )),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Selector de Salida (Ruta) y Totales
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              children: [
                Consumer<SalidaProvider>(
                  builder: (context, salidaProvider, child) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "📍 Seleccionar Ruta / Salida",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      value: _selectedSalidaId,
                      hint: const Text("Venta General (Stock Almacén)"),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text("🏭 Almacén General"),
                        ),
                        ...salidaProvider.salidasActivas.map((salida) {
                          return DropdownMenuItem(
                            value: salida.id,
                            child: Text(
                              "${salida.tipo == 'RUTA' ? '🗺️' : '📦'} ${salida.nombreRuta}",
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                         setState(() {
                           _selectedSalidaId = value;
                         });
                         // Recargar productos con stock de la ruta seleccionada
                         Provider.of<ProductProvider>(context, listen: false)
                             .loadProducts(idSalida: value);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 2. Selector de Unidad y Cantidad
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: [_unidadSeleccionada == 'PIEZA', _unidadSeleccionada == 'CAJA'],
                  onPressed: (int index) {
                    setState(() {
                      _unidadSeleccionada = index == 0 ? 'PIEZA' : 'CAJA';
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  selectedColor: Colors.white,
                  fillColor: Colors.blue[800],
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("PIEZA")),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("CAJA")),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (_cantidad > 1) setState(() => _cantidad--);
                      },
                    ),
                    Text("$_cantidad", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() => _cantidad++);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),

          // 2. Carrusel de Productos
          SizedBox(
            height: 300,
            child: productProvider.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ProductCarousel(
                  products: productProvider.products,
                  onProductSelected: (producto) => _agregarProducto(producto),
                ),
          ),

          const Divider(thickness: 2),

          // 3. Carrito de Compras
          Expanded(
            child: salesProvider.cart.isEmpty
                ? const Center(child: Text("Carrito Vacío - Seleccione Productos", style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
                    itemCount: salesProvider.cart.length,
                    itemBuilder: (context, index) {
                      final item = salesProvider.cart[index];
                      // Necesitamos el nombre del producto, pero en el carrito solo tenemos el ID.
                      // Buscamos en el productProvider (ineficiente para listas largas, pero ok para POS pequeño)
                      final producto = productProvider.products.firstWhere((p) => p.id == item.idProducto, orElse: () => Producto(nombre: "Desconocido", precio: 0, costo: 0));
                      
                      // Icono según unidad
                      String iconoUnidad = item.unidad == 'CAJA' ? '📦' : '🧊';
                      
                      return ListTile(
                        title: Text("${producto.nombre} (${item.cantidad} $iconoUnidad ${item.unidad}${item.cantidad > 1 ? 'S' : ''})"),
                        subtitle: Text("\$${item.precioUnitario.toStringAsFixed(2)} c/u"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("\$${(item.precioUnitario * item.cantidad).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => salesProvider.removeFromCart(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. Total y Botón de Cobrar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TOTAL A PAGAR", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("\$${salesProvider.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: salesProvider.cart.isEmpty ? null : () => _mostrarDialogoCobro(context, salesProvider),
                  icon: const Icon(Icons.payment),
                  label: const Text("COBRAR", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCobro(BuildContext context, SalesProvider salesProvider) {
    TextEditingController pagoController = TextEditingController();
    double total = salesProvider.total;
    double cambio = 0.0;


    // Obtener salidas activas
    final salidaProvider = Provider.of<SalidaProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Cerrar Venta"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Total: \$${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Mostrar Salida Seleccionada (Informativo)
                  if (_selectedSalidaId != null)
                     FutureBuilder<List<Salida>>( // Pequeño hack para obtener nombre, idealmente pasamos el objeto o buscamos en provider
                       future: Future.value(salidaProvider.salidasActivas), // Ya están cargadas
                       builder: (context, snapshot) {
                         final salida = snapshot.data?.firstWhere((s) => s.id == _selectedSalidaId, orElse: () => Salida(tipo: '', nombreRuta: 'Desconocida', vendedor: '', cerrada: false, fechaHora: DateTime.now()));
                         return Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Registrando salida en: ${salida?.nombreRuta}", style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                         );
                       }
                     )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.store, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Venta de Almacén (Sin Ruta asignada)",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (salidaProvider.salidasActivas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "No hay salidas activas. La venta se registrará sin salida.",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  TextField(
                    controller: pagoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Pago del Cliente", border: OutlineInputBorder()),
                    onChanged: (val) {
                      double pago = double.tryParse(val) ?? 0.0;
                      setState(() {
                         cambio = pago - total;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text("Cambio: \$${cambio > 0 ? cambio.toStringAsFixed(2) : '0.00'}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cambio >= 0 ? Colors.green : Colors.red)),
                ],
              ),
              actions: [
                TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.pop(context)),
                ElevatedButton(
                  child: const Text("CONFIRMAR VENTA"),
                  onPressed: () async {
                    bool success = await salesProvider.checkout(
                      double.tryParse(pagoController.text) ?? total,
                      idSalida: _selectedSalidaId,
                    );
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      // Actualizar stock en tiempo real
                      Provider.of<ProductProvider>(context, listen: false).loadProducts(idSalida: _selectedSalidaId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Venta Registrada Exitosamente!")));
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al registrar venta")));
                    }
                  },
                )
              ],
            );
          }
        );
      },
    );
  }
}
