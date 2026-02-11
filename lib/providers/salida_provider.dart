import 'package:flutter/material.dart';
import '../data/local/db_helper.dart';
import '../data/models/salida.dart';
import '../data/models/producto.dart';

class SalidaProvider with ChangeNotifier {
  List<Salida> _salidas = [];
  List<Salida> _salidasActivas = [];
  bool _isLoading = false;

  List<Salida> get salidas => _salidas;
  List<Salida> get salidasActivas => _salidasActivas;
  bool get isLoading => _isLoading;

  // Cargar todas las salidas
  Future<void> loadSalidas() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'salidas',
      orderBy: 'fecha_hora DESC',
    );

    _salidas = List.generate(maps.length, (i) {
      return Salida.fromMap(maps[i]);
    });

    // Filtrar salidas activas (no cerradas)
    _salidasActivas = _salidas.where((s) => !s.cerrada).toList();

    _isLoading = false;
    notifyListeners();
  }

  // Obtener detalles de una salida
  Future<List<DetalleSalida>> getDetallesSalida(int idSalida) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detalle_salidas',
      where: 'id_salida = ?',
      whereArgs: [idSalida],
    );

    return List.generate(maps.length, (i) {
      return DetalleSalida.fromMap(maps[i]);
    });
  }

  // Crear nueva salida
  Future<int> crearSalida({
    required String tipo,
    required String nombreRuta,
    String? nombreCliente,
    required String vendedor,
    required List<DetalleSalida> detalles,
    String? notas,
  }) async {
    final db = await DatabaseHelper().database;

    try {
      int idSalida = 0;
      
      await db.transaction((txn) async {
        // 1. Insertar salida
        Salida nuevaSalida = Salida(
          fechaHora: DateTime.now(),
          tipo: tipo,
          nombreRuta: nombreRuta,
          nombreCliente: nombreCliente,
          vendedor: vendedor,
          cerrada: false,
          notas: notas,
        );

        idSalida = await txn.insert('salidas', nuevaSalida.toMap());

        // 2. Insertar detalles
        for (var detalle in detalles) {
          detalle.idSalida = idSalida;
          await txn.insert('detalle_salidas', detalle.toMap());
        }

        // 3. Descontar del inventario (opcional, según lógica de negocio)
        // Por ahora no descontamos, solo registramos la salida
      });

      await loadSalidas();
      return idSalida;
    } catch (e) {
      debugPrint("Error al crear salida: $e");
      return -1;
    }
  }

  // Cerrar salida
  Future<bool> cerrarSalida(int idSalida) async {
    final db = await DatabaseHelper().database;

    try {
      await db.update(
        'salidas',
        {'cerrada': 1},
        where: 'id = ?',
        whereArgs: [idSalida],
      );

      await loadSalidas();
      return true;
    } catch (e) {
      debugPrint("Error al cerrar salida: $e");
      return false;
    }
  }

  // Calcular devolución de una salida
  Future<Map<String, dynamic>> calcularDevolucion(int idSalida) async {
    final db = await DatabaseHelper().database;

    // Obtener detalles de la salida
    final detalles = await getDetallesSalida(idSalida);

    // Obtener ventas asociadas a esta salida
    final List<Map<String, dynamic>> ventasMaps = await db.rawQuery('''
      SELECT dv.id_producto, dv.cantidad, dv.unidad
      FROM detalle_ventas dv
      INNER JOIN ventas v ON dv.id_venta = v.id
      WHERE v.id_salida = ?
    ''', [idSalida]);

    // Calcular productos vendidos por producto
    Map<int, Map<String, int>> vendidos = {};
    for (var venta in ventasMaps) {
      int idProducto = venta['id_producto'] as int;
      int cantidad = venta['cantidad'] as int;
      String unidad = venta['unidad'] as String;

      if (!vendidos.containsKey(idProducto)) {
        vendidos[idProducto] = {'cajas': 0, 'piezas': 0};
      }

      if (unidad == 'CAJA') {
        vendidos[idProducto]!['cajas'] = 
          (vendidos[idProducto]!['cajas'] ?? 0) + cantidad;
      } else {
        vendidos[idProducto]!['piezas'] = 
          (vendidos[idProducto]!['piezas'] ?? 0) + cantidad;
      }
    }

    // Calcular devolución
    List<Map<String, dynamic>> devolucion = [];
    for (var detalle in detalles) {
      int cajasVendidas = vendidos[detalle.idProducto]?['cajas'] ?? 0;
      int piezasVendidas = vendidos[detalle.idProducto]?['piezas'] ?? 0;

      int cajasDevueltas = detalle.cantidadCajas - cajasVendidas;
      int piezasDevueltas = detalle.cantidadPiezas - piezasVendidas;

      if (cajasDevueltas > 0 || piezasDevueltas > 0) {
        // Obtener nombre del producto
        final List<Map<String, dynamic>> productRes = await db.query(
          'productos',
          columns: ['nombre'],
          where: 'id = ?',
          whereArgs: [detalle.idProducto],
        );
        String nombreProducto = productRes.isNotEmpty ? productRes.first['nombre'] as String : 'Producto #${detalle.idProducto}';

        devolucion.add({
          'id_producto': detalle.idProducto,
          'nombre_producto': nombreProducto, // Added Name
          'cajas_devueltas': cajasDevueltas,
          'piezas_devueltas': piezasDevueltas,
        });
      }
    }

    return {
      'id_salida': idSalida,
      'devolucion': devolucion,
    };
  }
}
