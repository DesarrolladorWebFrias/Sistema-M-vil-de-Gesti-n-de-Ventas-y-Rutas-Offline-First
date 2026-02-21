import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salida_provider.dart';
import '../../providers/product_provider.dart';
import '../../data/models/salida.dart';
import '../../data/models/producto.dart';

class NuevaSalidaScreen extends StatefulWidget {
  const NuevaSalidaScreen({super.key});

  @override
  State<NuevaSalidaScreen> createState() => _NuevaSalidaScreenState();
}

class _NuevaSalidaScreenState extends State<NuevaSalidaScreen> {
  final _formKey = GlobalKey<FormState>();
  String _tipoSeleccionado = 'RUTA';
  final TextEditingController _nombreRutaController = TextEditingController();
  final TextEditingController _nombreClienteController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  List<_ProductoSalida> _productos = [];

  @override
  void initState() {
    super.initState();
    // Cargar todos los productos del catálogo para poder seleccionarlos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _nombreRutaController.dispose();
    _nombreClienteController.dispose();
    _vendedorController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _agregarProducto() {
    setState(() {
      _productos.add(_ProductoSalida());
    });
  }

  void _eliminarProducto(int index) {
    setState(() {
      _productos.removeAt(index);
    });
  }

  Future<void> _registrarSalida() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes agregar al menos un producto")),
      );
      return;
    }

    // Validar que todos los productos estén completos
    for (var prod in _productos) {
      if (prod.producto == null || 
          (prod.cantidadCajas == 0 && prod.cantidadPiezas == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Completa producto y cantidades")),
        );
        return;
      }
    }

    // Crear detalles
    List<DetalleSalida> detalles = _productos.map((p) {
      return DetalleSalida(
        idProducto: p.producto!.id!,
        cantidadCajas: p.cantidadCajas,
        cantidadPiezas: p.cantidadPiezas,
        precioVenta: p.precioVenta,
      );
    }).toList();

    // Registrar salida
    final salidaProvider = Provider.of<SalidaProvider>(context, listen: false);
    int idSalida = await salidaProvider.crearSalida(
      tipo: _tipoSeleccionado,
      nombreRuta: _nombreRutaController.text,
      nombreCliente: _tipoSeleccionado == 'PEDIDO_ESPECIAL' 
        ? _nombreClienteController.text 
        : null,
      vendedor: _vendedorController.text,
      detalles: detalles,
      notas: _notasController.text.isEmpty ? null : _notasController.text,
    );

    if (!mounted) return;

    if (idSalida > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Salida registrada exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al registrar salida"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Salida"),
        backgroundColor: Colors.blue[800],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de Tipo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tipo de Salida",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("🗺️ Ruta"),
                            value: 'RUTA',
                            groupValue: _tipoSeleccionado,
                            onChanged: (value) {
                              setState(() => _tipoSeleccionado = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("📦 Pedido Especial"),
                            value: 'PEDIDO_ESPECIAL',
                            groupValue: _tipoSeleccionado,
                            onChanged: (value) {
                              setState(() => _tipoSeleccionado = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Información General
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreRutaController,
                      decoration: InputDecoration(
                        labelText: _tipoSeleccionado == 'RUTA' 
                          ? "Nombre de Ruta" 
                          : "Descripción del Pedido",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.route),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),
                    if (_tipoSeleccionado == 'PEDIDO_ESPECIAL') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombreClienteController,
                        decoration: const InputDecoration(
                          labelText: "Nombre del Cliente",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (_tipoSeleccionado == 'PEDIDO_ESPECIAL' && 
                              (value == null || value.isEmpty)) {
                            return 'Campo requerido para pedidos especiales';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vendedorController,
                      decoration: const InputDecoration(
                        labelText: "Vendedor",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notasController,
                      decoration: const InputDecoration(
                        labelText: "Notas (opcional)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lista de Productos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Productos a Llevar",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _agregarProducto,
                          icon: const Icon(Icons.add),
                          label: const Text("Agregar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._productos.asMap().entries.map((entry) {
                      int index = entry.key;
                      _ProductoSalida prod = entry.value;
                      
                      return Card(
                        color: Colors.grey[100],
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<Producto>(
                                      value: prod.producto,
                                      decoration: const InputDecoration(
                                        labelText: "Producto",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: productProvider.products.map((p) {
                                        return DropdownMenuItem(
                                          value: p,
                                          child: Text(p.nombre),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          prod.producto = value;
                                          // Pre-llenar precio de venta
                                          if (value != null) {
                                            prod.precioVenta = value.precio;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarProducto(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: "📦 Cajas",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      keyboardType: TextInputType.number,
                                      initialValue: prod.cantidadCajas.toString(),
                                      onChanged: (value) {
                                        setState(() {
                                          prod.cantidadCajas = int.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: "🧊 Piezas",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      keyboardType: TextInputType.number,
                                      initialValue: prod.cantidadPiezas.toString(),
                                      onChanged: (value) {
                                        setState(() {
                                          prod.cantidadPiezas = int.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Precio oculto, se toma del producto
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Total Card Removed

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _registrarSalida,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Registrar Salida"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoSalida {
  Producto? producto;
  int cantidadCajas = 0;
  int cantidadPiezas = 0;
  double precioVenta = 0.0;
}
