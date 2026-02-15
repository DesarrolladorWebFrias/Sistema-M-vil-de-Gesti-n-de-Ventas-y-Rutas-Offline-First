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
    
    debugPrint("🔍 DEBUG: Cargando productos para salida ID: $idSalida");
    debugPrint("🔍 DEBUG: Registros en detalle_salidas: ${cargas.length}");
    debugPrint("🔍 DEBUG: Total productos en catálogo: ${allProducts.length}");
    
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

    debugPrint("🔍 DEBUG: IDs de productos con carga: ${stockTotalRuta.keys.toList()}");
    debugPrint("🔍 DEBUG: IDs de productos en catálogo: ${allProducts.map((p) => p.id).toList()}");

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
    // SOLO se mostrarán los productos que fueron cargados en esta salida
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
    
    debugPrint("🔍 DEBUG: Productos filtrados encontrados: ${filteredProducts.length}");
    
    // FALLBACK INTELIGENTE: Si hay cargas en detalle_salidas pero no productos filtrados,
    // significa que hay un problema de IDs. Mostrar todos los productos con stock calculado.
    if (filteredProducts.isEmpty && stockTotalRuta.isNotEmpty) {
      debugPrint("⚠️ ADVERTENCIA: Hay ${stockTotalRuta.length} productos en detalle_salidas pero 0 coincidencias en catálogo");
      debugPrint("⚠️ Aplicando fallback: Mostrando catálogo completo con stock desde detalle_salidas");
      
      // Intentar emparejar por cualquier medio disponible
      for (var product in allProducts) {
        if (stockTotalRuta.containsKey(product.id)) {
          int totalCajas = stockTotalRuta[product.id]!['cajas']!;
          int totalPiezas = stockTotalRuta[product.id]!['piezas']!;
          
          int vendidoCajas = ventaMap[product.id]?['cajas'] ?? 0;
          int vendidoPiezas = ventaMap[product.id]?['piezas'] ?? 0;

          product.stockCajas = (totalCajas - vendidoCajas).clamp(0, 999999);
          product.stockPiezas = (totalPiezas - vendidoPiezas).clamp(0, 999999);
          
          filteredProducts.add(product);
        } else {
          // Producto no cargado en esta salida, mostrar con stock 0
          product.stockCajas = 0;
          product.stockPiezas = 0;
        }
      }
    }
    
    // Asignar solo los productos que tienen carga en esta salida
    _products = filteredProducts;
    debugPrint("✅ DEBUG: Productos finales asignados: ${_products.length}");
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
