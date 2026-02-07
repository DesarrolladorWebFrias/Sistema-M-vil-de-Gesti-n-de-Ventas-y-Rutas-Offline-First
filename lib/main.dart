import 'package:flutter/material.dart';
import 'package:calculadora_ventas_leche_v2/screens/admin/admin_login.dart';
import 'package:calculadora_ventas_leche_v2/screens/admin/admin_home.dart';

const kBlue = Color(0xFF1565C0); // Azul principal

import 'package:provider/provider.dart';
import 'package:calculadora_ventas_leche_v2/providers/product_provider.dart';
import 'package:calculadora_ventas_leche_v2/screens/admin/product_management.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEFF3F6),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/sales': (context) => const SalesCalculator(),
        '/admin_login': (context) => const AdminLoginScreen(),
        '/admin_home': (context) => const AdminHomeScreen(),
        '/admin_products': (context) => const ProductManagementScreen(),
      },
    );
  }
}

/// PANTALLA INICIAL
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SalesCalculator()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_drink, size: 110, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "CALCULADORA DE VENTAS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CALCULADORA
class SalesCalculator extends StatefulWidget {
  const SalesCalculator({super.key});
  @override
  State<SalesCalculator> createState() => _SalesCalculatorState();
}

class _SalesCalculatorState extends State<SalesCalculator> {
  String? productoSeleccionado;
  String tipoVenta = "Pieza";
  int cantidadSeleccionada = 1;
  int piezasPorCaja = 12;
  
  // Variables para el concentrado de ventas
  double totalVentasAcumulado = 0.0;
  double totalGananciasAcumulado = 0.0;

  final TextEditingController pagoController = TextEditingController();
  final List<VentaProducto> productosVenta = [];

  // PRECIOS DE VENTA (se mantienen como estaban)
  final Map<String, double> preciosVenta = {
    "ENTERA": 21.00,
    "SEMIDES": 20.00,
    "DESLACT": 20.00,
    "LIGHT": 19.00,
    "FRESA 250ml": 6.00,
    "VAINILLA 250ml": 6.00,
    "CHOCOLATE 250ml": 8.00,
    "LIGHT 250ml": 6.00,
    "SEMIDES POLVO": 32.00,
    "ENTERA POLVO": 36.00,
  };

  // COSTOS REALES (actualizados según lo especificado)
  final Map<String, double> costosReales = {
    "ENTERA": 20.50,          // Costo real: $20.50
    "SEMIDES": 19.50,         // Costo real: $19.50
    "LIGHT": 18.50,           // Costo real: $18.50
    "CHOCOLATE 250ml": 7.50,  // Costo real: $7.50
    "ENTERA POLVO": 35.50,    // Costo real: $35.50
  };

  final List<Map<String, dynamic>> productosLitros = [
    {"nombre": "ENTERA", "color": Color(0xFF00C853), "caja": 12},
    {"nombre": "SEMIDES", "color": Color(0xFFD50000), "caja": 12},
    {"nombre": "DESLACT", "color": Color(0xFF6A1B9A), "caja": 12},
    {"nombre": "LIGHT", "color": Color(0xFF00B8D4), "caja": 12},
  ];

  final List<Map<String, dynamic>> productosLechitas = [
    {"nombre": "FRESA 250ml", "color": Color(0xFFD50000), "caja": 27},
    {"nombre": "VAINILLA 250ml", "color": Color(0xFFFBC02D), "caja": 27},
    {"nombre": "CHOCOLATE 250ml", "color": Color(0xFF4E342E), "caja": 27},
    {"nombre": "LIGHT 250ml", "color": Color(0xFF00897B), "caja": 27},
  ];

  final List<Map<String, dynamic>> productosPolvo = [
    {"nombre": "SEMIDES POLVO", "color": Color(0xFF8E24AA), "caja": 36},
    {"nombre": "ENTERA POLVO", "color": Color(0xFFC62828), "caja": 36},
  ];

  void _seleccionarProducto(Map<String, dynamic> producto) {
    setState(() {
      productoSeleccionado = producto["nombre"];
      piezasPorCaja = producto["caja"];
      cantidadSeleccionada = 1;
      tipoVenta = "Pieza";
    });
  }

  // Calcular ganancia por producto
  double _calcularGanancia(String producto, int cantidad) {
    if (costosReales.containsKey(producto)) {
      // Para productos con costo real especificado
      double precioVenta = preciosVenta[producto] ?? 0;
      double costoReal = costosReales[producto] ?? 0;
      return (precioVenta - costoReal) * cantidad;
    }
    return 0.0; // Los demás productos no generan ganancia
  }

  void _agregarProducto() {
    if (productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione un producto")),
      );
      return;
    }

    int totalPiezas = tipoVenta == "Pieza"
        ? cantidadSeleccionada
        : cantidadSeleccionada * piezasPorCaja;
    double precioUnitario = preciosVenta[productoSeleccionado!] ?? 0;
    double totalProducto = precioUnitario * totalPiezas;
    double gananciaProducto = _calcularGanancia(productoSeleccionado!, totalPiezas);

    setState(() {
      productosVenta.add(VentaProducto(
        nombre: productoSeleccionado!,
        tipo: tipoVenta,
        piezasPorCaja: piezasPorCaja,
        cantidad: cantidadSeleccionada,
        precioUnitario: precioUnitario,
        precioTotal: totalProducto,
        ganancia: gananciaProducto,
      ));
      
      // Actualizar acumulados
      totalVentasAcumulado += totalProducto;
      totalGananciasAcumulado += gananciaProducto;
    });

    // 🔥 MOSTRAR MENSAJE DE ÉXITO AL AGREGAR
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Producto agregado correctamente",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _eliminarProducto(int index) {
    VentaProducto productoEliminado = productosVenta[index];
    setState(() {
      // Restar del acumulado al eliminar
      totalVentasAcumulado -= productoEliminado.precioTotal;
      totalGananciasAcumulado -= productoEliminado.ganancia;
      productosVenta.removeAt(index);
    });
  }

  void _cerrarVenta() {
    setState(() {
      productosVenta.clear();
      productoSeleccionado = null;
      cantidadSeleccionada = 1;
      pagoController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Venta cerrada, lista para nueva venta"),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // NUEVO: Función para vaciar todos los registros
  void _vaciarRegistros() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("¿Vaciar todos los registros?"),
          content: const Text("Esta acción eliminará todo el historial de ventas y no se puede deshacer."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  productosVenta.clear();
                  totalVentasAcumulado = 0.0;
                  totalGananciasAcumulado = 0.0;
                  productoSeleccionado = null;
                  cantidadSeleccionada = 1;
                  pagoController.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Todos los registros han sido eliminados"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text("Vaciar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  double get totalVenta =>
      productosVenta.fold(0, (suma, p) => suma + p.precioTotal);

  double get pagoCliente {
    try {
      return double.parse(pagoController.text);
    } catch (_) {
      return 0;
    }
  }

  double get cambio {
    final c = pagoCliente - totalVenta;
    return c < 0 ? 0 : c;
  }

  Map<int, int> getDesgloseCambio() {
    int cambioEntero = cambio.floor();
    List<int> billetes = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    Map<int, int> desglose = {};
    for (var b in billetes) {
      if (cambioEntero >= b) {
        desglose[b] = cambioEntero ~/ b;
        cambioEntero %= b;
      }
    }
    return desglose;
  }

  Widget _franjaProductos(String titulo, List<Map<String, dynamic>> productos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            titulo,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: productos.map((p) {
            bool seleccionado = productoSeleccionado == p["nombre"];
            return GestureDetector(
              onTap: () => _seleccionarProducto(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: seleccionado ? kBlue : Colors.grey.shade300,
                      width: seleccionado ? 3 : 1),
                  boxShadow: seleccionado
                      ? [
                          BoxShadow(
                              color: kBlue.withOpacity(0.4),
                              offset: const Offset(3, 3),
                              blurRadius: 10)
                        ]
                      : [
                          const BoxShadow(
                              color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                          BoxShadow(
                              color: Colors.grey.shade300,
                              offset: const Offset(3, 3),
                              blurRadius: 6),
                        ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.local_drink, size: 36, color: p["color"]),
                    const SizedBox(height: 6),
                    Text(
                      p["nombre"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _selectorCantidad() {
    List<Widget> numeros = List.generate(36, (index) {
      int numero = index + 1;
      bool seleccionado = numero == cantidadSeleccionada;
      return GestureDetector(
        onTap: () => setState(() => cantidadSeleccionada = numero),
        child: Container(
          width: 55,
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: seleccionado ? kBlue : Colors.grey.shade300,
                width: seleccionado ? 3 : 1),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                        color: kBlue.withOpacity(0.3),
                        offset: const Offset(3, 3),
                        blurRadius: 6)
                  ]
                : [
                    const BoxShadow(
                        color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                    BoxShadow(
                        color: Colors.grey.shade300,
                        offset: const Offset(3, 3),
                        blurRadius: 6),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            "$numero",
            style: TextStyle(
              fontSize: 18,
              color: seleccionado ? kBlue : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: numeros),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBlue,
        title: const Text("CALCULADORA DE VENTAS",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          // BOTÓN PARA VACIAR REGISTROS
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _vaciarRegistros,
            tooltip: "Vaciar todos los registros",
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/admin_login');
            },
            tooltip: "Administración",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CONCENTRADO DE VENTAS
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CONCENTRADO DE VENTAS",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: kBlue)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total vendido:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("\$${totalVentasAcumulado.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Ganancia total:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("\$${totalGananciasAcumulado.toStringAsFixed(2)}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green[700])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _vaciarRegistros,
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text(
                        "Vaciar todos los registros",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            _franjaProductos("LECHE DE 1 LITRO", productosLitros),
            _franjaProductos("LECHITAS 250 ml", productosLechitas),
            _franjaProductos("LECHE EN POLVO", productosPolvo),
            const SizedBox(height: 16),
            Row(
              children: [
                ChoiceChip(
                  label: const Text("Pieza"),
                  selected: tipoVenta == "Pieza",
                  selectedColor: kBlue.withOpacity(0.2),
                  onSelected: (_) => setState(() => tipoVenta = "Pieza"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Caja"),
                  selected: tipoVenta == "Caja",
                  selectedColor: kBlue.withOpacity(0.2),
                  onSelected: (_) => setState(() => tipoVenta = "Caja"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _selectorCantidad(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              label: const Text(
                "Agregar producto",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (productosVenta.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Productos seleccionados:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      ...productosVenta.asMap().entries.map((entry) {
                        int index = entry.key;
                        VentaProducto p = entry.value;
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text("${p.nombre} (${p.tipo} x${p.cantidad})"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Total: \$${p.precioTotal.toStringAsFixed(2)}"),
                                if (p.ganancia > 0)
                                  Text("Ganancia: \$${p.ganancia.toStringAsFixed(2)}",
                                      style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarProducto(index),
                            ),
                          ),
                        );
                      }),
                      const Divider(),
                      Text("Total: \$${totalVenta.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: pagoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Pago del cliente",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Cambio: \$${cambio.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      if (cambio > 0) ...[
                        const Text("Desglose de cambio:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: getDesgloseCambio()
                              .entries
                              .map((e) =>
                                  Chip(label: Text("\$${e.key} x${e.value}")))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _cerrarVenta,
                        icon: const Icon(Icons.check),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        label: const Text("Cerrar venta",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VentaProducto {
  final String nombre;
  final String tipo;
  final int piezasPorCaja;
  final int cantidad;
  final double precioUnitario;
  final double precioTotal;
  final double ganancia;

  VentaProducto({
    required this.nombre,
    required this.tipo,
    required this.piezasPorCaja,
    required this.cantidad,
    required this.precioUnitario,
    required this.precioTotal,
    required this.ganancia,
  });
}