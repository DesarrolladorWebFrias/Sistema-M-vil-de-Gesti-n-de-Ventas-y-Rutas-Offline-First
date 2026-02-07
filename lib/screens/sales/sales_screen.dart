import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Aunque no lo tengo en pubspec, usaré TextStyle normal por ahora
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../data/models/producto.dart';
import '../../widgets/product_carousel.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _unidadSeleccionada = 'PIEZA'; // 'PIEZA' o 'CAJA'
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  void _agregarProducto(Producto producto) {
    Provider.of<SalesProvider>(context, listen: false).addToCart(
      producto, 
      _cantidad, 
      _unidadSeleccionada
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Agregado: ${producto.nombre}"),
        duration: const Duration(milliseconds: 700),
        backgroundColor: Colors.green,
      )
    );
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
                  Icon(Icons.inventory, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Inventario Rápido", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
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
          // 1. Selector de Unidad y Cantidad
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
            height: 250,
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
                      
                      return ListTile(
                        title: Text("${producto.nombre} (${item.cantidad} ${item.unidad})"),
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
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
                    bool success = await salesProvider.checkout(double.tryParse(pagoController.text) ?? total);
                    if (success) {
                      Navigator.pop(context);
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
