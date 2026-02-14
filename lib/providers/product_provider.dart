import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/local/db_helper.dart';
import '../../data/models/producto.dart';

class ProductProvider with ChangeNotifier {
  List<Producto> _products = [];
  bool _isLoading = false;

  List<Producto> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> _loadProductsForRoute(int idSalida, List<Producto> allProducts, DatabaseExecutor db) async {
    // 2a. Obtener TODA la carga (Inicial + Reabastecimientos)
    final List<Map<String, dynamic>> cargas = await db.query(
      'detalle_salidas',
      where: 'id_salida = ?',
      whereArgs: [idSalida],
    );
    
    // Mapa: idProducto -> {cajas, piezas} (Acumulativo)
    Map<int, Map<String, int>> stockTotalRuta = {};

    for (var carga in cargas) {
      int? idProd = int.tryParse(carga['id_producto'].toString());
      if (idProd == null) continue;

      int cajas = int.tryParse(carga['cantidad_cajas'].toString()) ?? 0;
      int piezas = int.tryParse(carga['cantidad_piezas'].toString()) ?? 0;

      if (!stockTotalRuta.containsKey(idProd)) {
        stockTotalRuta[idProd] = {'cajas': 0, 'piezas': 0};
      }
      
      stockTotalRuta[idProd]!['cajas'] = (stockTotalRuta[idProd]!['cajas']!) + cajas;
      stockTotalRuta[idProd]!['piezas'] = (stockTotalRuta[idProd]!['piezas']!) + piezas;
    }

    // 2b. Obtener Ventas realizadas en esa Salida
    final List<Map<String, dynamic>> ventas = await db.rawQuery('''
      SELECT dv.id_producto, dv.cantidad, dv.unidad
      FROM detalle_ventas dv
      JOIN ventas v ON dv.id_venta = v.id
      WHERE v.id_salida = ?
    ''', [idSalida]);

    // Mapa de ventas
    Map<int, Map<String, int>> ventaMap = {};
    for (var venta in ventas) {
      int? idProd = int.tryParse(venta['id_producto'].toString());
      if (idProd == null) continue;
      
      String unidad = venta['unidad'].toString();
      int cantidad = int.tryParse(venta['cantidad'].toString()) ?? 0;
      
      if (!ventaMap.containsKey(idProd)) {
        ventaMap[idProd] = {'cajas': 0, 'piezas': 0};
      }
      
      if (unidad == 'CAJA') {
        ventaMap[idProd]!['cajas'] = (ventaMap[idProd]!['cajas']!) + cantidad;
      } else {
        ventaMap[idProd]!['piezas'] = (ventaMap[idProd]!['piezas']!) + cantidad;
      }
    }

    List<Producto> filteredProducts = [];
    
    // 3. Filtrar y Calcular Stock Restante
    for (var product in allProducts) {
      if (stockTotalRuta.containsKey(product.id)) {
        int totalCajas = stockTotalRuta[product.id]!['cajas']!;
        int totalPiezas = stockTotalRuta[product.id]!['piezas']!;
        
        int vendidoCajas = ventaMap[product.id]?['cajas'] ?? 0;
        int vendidoPiezas = ventaMap[product.id]?['piezas'] ?? 0;

        int remanenteCajas = totalCajas - vendidoCajas;
        int remanentePiezas = totalPiezas - vendidoPiezas;

        // Lógica de "Romper Cajas" segura
        int pxc = product.piezasPorCaja > 0 ? product.piezasPorCaja : 1;
        while (remanentePiezas < 0 && remanenteCajas > 0) {
          remanenteCajas--;
          remanentePiezas += pxc;
        }

        product.stockCajas = remanenteCajas < 0 ? 0 : remanenteCajas;
        product.stockPiezas = remanentePiezas < 0 ? 0 : remanentePiezas;

        filteredProducts.add(product);
      }
    }
    
    // FALLBACK: Si la lista filtrada queda vacía (pero hay salida seleccionada),
    // puede ser porque es una salida antigua con IDs viejos. 
    // Para no mostrar pantalla blanca, devolvemos todo con stock 0 y aviso.
    if (filteredProducts.isEmpty) {
       _products = allProducts.map((p) {
         p.stockCajas = 0;
         p.stockPiezas = 0;
         // Opcional: p.nombre += " (Sin Carga)"; 
         return p;
       }).toList();
    } else {
       _products = filteredProducts;
    }
  }

  Future<void> loadProducts({int? idSalida}) async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper().database;
    
    // 1. Cargar catálogo base
    final List<Map<String, dynamic>> maps = await db.query('productos', orderBy: 'nombre ASC');
    List<Producto> allProducts = List.generate(maps.length, (i) => Producto.fromMap(maps[i]));

    if (idSalida != null) {
      await _loadProductsForRoute(idSalida, allProducts, db);
    } else {
      // Carga global (Almacén)
      _products = allProducts;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Producto producto) async {
    final db = await DatabaseHelper().database;
    await db.insert('productos', producto.toMap());
    await loadProducts();
  }

  Future<void> updateProduct(Producto producto) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadProducts();
  }
}
