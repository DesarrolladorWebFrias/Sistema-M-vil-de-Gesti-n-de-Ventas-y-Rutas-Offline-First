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
      // Cargar salidas y seleccionar la PRIMERA del día (la más antigua)
      salidaProvider.loadSalidas().then((_) {
        if (mounted && salidaProvider.salidasActivas.isNotEmpty) {
          // Ordenar cronológicamente ascendente para tomar la primera registrada
          var salidasOrdenadas = List.of(salidaProvider.salidasActivas);
          salidasOrdenadas.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
          
          setState(() {
            _selectedSalidaId = salidasOrdenadas.first.id;
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
    // Validar Stock Detallado en Ruta (considerando lo que ya está en el carrito)
    if (_selectedSalidaId != null) {
      int pxc = producto.piezasPorCaja > 0 ? producto.piezasPorCaja : 12;
      
      // Calcular cuánto de este producto ya está en el carrito
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      int cajasEnCarrito = 0;
      int piezasEnCarrito = 0;
      
      for (var item in salesProvider.cart) {
        if (item.idProducto == producto.id) {
          if (item.unidad == 'CAJA') {
            cajasEnCarrito += item.cantidad;
          } else {
            piezasEnCarrito += item.cantidad;
          }
        }
      }
      
      // Calcular stock disponible restando lo que ya está en el carrito
      int stockCajasDisponible = producto.stockCajas - cajasEnCarrito;
      int stockPiezasDisponible = producto.stockPiezas - piezasEnCarrito;
      
      // Ajustar si las piezas en carrito superan las sueltas (se abrieron cajas)
      while (stockPiezasDisponible < 0 && stockCajasDisponible > 0) {
        stockCajasDisponible--;
        stockPiezasDisponible += pxc;
      }
      
      if (_unidadSeleccionada == 'CAJA') {
        // Venta de CAJAS: Debe haber suficientes cajas cerradas
        if (_cantidad > stockCajasDisponible) {
          _mostrarErrorStock("Solo quedan ${stockCajasDisponible} cajas disponibles (ya tienes $cajasEnCarrito en el carrito).");
          return;
        }
      } else {
        // Venta de PIEZAS: Se pueden tomar de piezas sueltas + cajas cerradas disponibles
        int stockTotalPiezasDisponible = stockPiezasDisponible + (stockCajasDisponible * pxc);
        if (_cantidad > stockTotalPiezasDisponible) {
           _mostrarErrorStock("Solo quedan $stockTotalPiezasDisponible piezas disponibles (ya tienes $piezasEnCarrito piezas en el carrito).");
           return;
        }
      }
    }

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
          // 4. Contenido Desplazable (Selectores, Carrusel, Lista)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Selector de Salida con diseño mejorado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Consumer<SalidaProvider>(
                      builder: (context, salidaProvider, child) {
                        // VALIDACIÓN DE SEGURIDAD:
                        // Verificar si la salida seleccionada sigue existiendo en la lista activa.
                        // Si se cerró la ruta en otra pantalla, el ID quedará huérfano y causará error.
                        bool idEsValido = _selectedSalidaId == null || 
                            salidaProvider.salidasActivas.any((s) => s.id == _selectedSalidaId);

                        // Si el ID ya no es válido (ej. ruta cerrada), lo reseteamos visualmente a null
                        int? valorAmostrar = idEsValido ? _selectedSalidaId : null;
                        
                        // Si detectamos que el ID no es válido, aprovechamos para limpiar el estado
                        if (!idEsValido && mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                             setState(() {
                               _selectedSalidaId = null;
                             });
                          });
                        }

                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "📍 Ruta / Salida",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            prefixIcon: Icon(Icons.local_shipping, size: 20),
                          ),
                          value: valorAmostrar,
                          hint: const Text("Selecciona una ruta"),
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
                             });
                             Provider.of<ProductProvider>(context, listen: false)
                                 .loadProducts(idSalida: value);
                          },
                        );
                      },
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

                  // 3. Carrusel de Productos
                  SizedBox(
                    height: 300, // Altura restaurada
                    child: productProvider.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : productProvider.products.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.orange[700]),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedSalidaId != null 
                                    ? "No hay productos cargados en esta ruta"
                                    : "Selecciona una ruta para comenzar",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedSalidaId != null
                                    ? "Ve a 'Salidas / Rutas' para registrar productos en esta salida"
                                    : "Solo se mostrarán los productos que hayas cargado",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ProductCarousel(
                            products: productProvider.products,
                            onProductSelected: (producto) => _agregarProducto(producto),
                          ),
                  ),

                  const Divider(thickness: 2),

                  // 4. Lista de Carrito (Sin scroll interno, se expande)
                  salesProvider.cart.isEmpty
                      ? Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: const Text("Carrito Vacío - Seleccione Productos", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true, // Se ajusta al contenido
                          physics: const NeverScrollableScrollPhysics(), // Scroll manejado por el padre
                          reverse: false, // El último insertado (index 0) arriba
                          itemCount: salesProvider.cart.length,
                          itemBuilder: (context, index) {
                            final item = salesProvider.cart[index];
                            final producto = productProvider.products.firstWhere((p) => p.id == item.idProducto, orElse: () => Producto(nombre: "Desconocido", precio: 0, costo: 0));
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
                  const SizedBox(height: 20), // Espacio final
                ],
              ),
            ),
          ),
          
          // 5. Total y Botón de Cobrar (Fijo abajo)
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

  void _mostrarErrorStock(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // Auto-cerrar después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
        
        return AlertDialog(
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Stock Insuficiente",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mensaje,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "No puedes vender más de lo que tienes cargado en esta ruta.",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle),
              label: const Text("Entendido"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        );
      },
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
                      
                      // SnackBar verde con letras blancas
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "¡Venta Registrada Exitosamente!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green[700],
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Row(
                             children: [
                               Icon(Icons.error, color: Colors.white, size: 28),
                               SizedBox(width: 12),
                               Text(
                                 "Error al registrar venta",
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 16,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             ],
                           ),
                           backgroundColor: Colors.red[700],
                           duration: const Duration(seconds: 3),
                         ),
                       );
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
