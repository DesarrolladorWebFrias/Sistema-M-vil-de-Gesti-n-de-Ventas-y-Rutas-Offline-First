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
      // Obtener datos del producto (Nombre y PiezasPorCaja)
      final List<Map<String, dynamic>> productRes = await db.query(
        'productos',
        columns: ['nombre', 'piezas_por_caja'],
        where: 'id = ?',
        whereArgs: [detalle.idProducto], // Corrección aquí: usar el ID del detalle
      );

      String nombreProducto;
      int pxc;

      if (productRes.isNotEmpty) {
        nombreProducto = productRes.first['nombre'] as String;
        pxc = int.tryParse(productRes.first['piezas_por_caja'].toString()) ?? 12; // Default 12 si falla
      } else {
        nombreProducto = 'Producto #${detalle.idProducto} (No encontrado)';
        pxc = 12; // Fallback estandár si el producto fue borrado
      }

      // Calcular Devolución (Manejo de Cajas Abiertas)
      int cajasVendidas = vendidos[detalle.idProducto]?['cajas'] ?? 0; // Corrección aquí
      int piezasVendidas = vendidos[detalle.idProducto]?['piezas'] ?? 0; // Corrección aquí
      
      // Stock Inicial
      int stockCajas = detalle.cantidadCajas;
      int stockPiezas = detalle.cantidadPiezas;

      // Restar ventas
      int remanenteCajas = stockCajas - cajasVendidas;
      int remanentePiezas = stockPiezas - piezasVendidas;

      // Ajustar si se vendieron más piezas de las sueltas (se rompieron cajas)
      while (remanentePiezas < 0 && remanenteCajas > 0) {
        remanenteCajas--;
        remanentePiezas += pxc;
      }
      
      // Si aún así es negativo (se vendió más de lo que había), se deja en 0
      if (remanenteCajas < 0) remanenteCajas = 0;
      if (remanentePiezas < 0) remanentePiezas = 0;

      if (remanenteCajas > 0 || remanentePiezas > 0) {
        devolucion.add({
          'id_producto': detalle.idProducto, // Corrección aquí
          'nombre_producto': nombreProducto,
          'cajas_devueltas': remanenteCajas,
          'piezas_devueltas': remanentePiezas,
        });
      }
    }

    // Calcular total vendido en dinero (Suma de los totales de los tickets)
    final resultTotal = await db.rawQuery('''
      SELECT SUM(total) as total
      FROM ventas
      WHERE id_salida = ?
    ''', [idSalida]);
    
    double totalVendido = 0.0;
    if (resultTotal.isNotEmpty && resultTotal.first['total'] != null) {
      totalVendido = double.tryParse(resultTotal.first['total'].toString()) ?? 0.0;
    }

    return {
      'id_salida': idSalida,
      'devolucion': devolucion,
      'total_vendido': totalVendido,
    };
  }
}
