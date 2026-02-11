import 'package:flutter/material.dart';
import '../../data/local/db_helper.dart';
import '../../data/models/producto.dart';

class ProductProvider with ChangeNotifier {
  List<Producto> _products = [];
  bool _isLoading = false;

  List<Producto> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts({int? idSalida}) async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper().database;
    
    // 1. Cargar productos base (catálogo)
    final List<Map<String, dynamic>> maps = await db.query('productos', orderBy: 'nombre ASC');
    List<Producto> allProducts = List.generate(maps.length, (i) {
      return Producto.fromMap(maps[i]);
    });

    // 2. Si hay Salida seleccionada, calcular stock específico
    if (idSalida != null) {
      // 2a. Obtener Carga Inicial de la Salida
      final List<Map<String, dynamic>> cargas = await db.query(
        'detalle_salidas',
        where: 'id_salida = ?',
        whereArgs: [idSalida],
      );
      
      // Mapa de cargas: idProducto -> {cajas, piezas}
      Map<int, Map<String, int>> cargaMap = {};
      for (var carga in cargas) {
        int idProd = carga['id_producto'];
        cargaMap[idProd] = {
          'cajas': (carga['cantidad_cajas'] as int? ?? 0),
          'piezas': (carga['cantidad_piezas'] as int? ?? 0),
        };
      }

      // 2b. Obtener Ventas realizadas en esa Salida
      final List<Map<String, dynamic>> ventas = await db.rawQuery('''
        SELECT dv.id_producto, dv.cantidad, dv.unidad
        FROM detalle_ventas dv
        JOIN ventas v ON dv.id_venta = v.id
        WHERE v.id_salida = ?
      ''', [idSalida]);

      // Mapa de ventas: idProducto -> {cajas, piezas}
      Map<int, Map<String, int>> ventaMap = {};
      for (var venta in ventas) {
        int idProd = venta['id_producto'];
        String unidad = venta['unidad'];
        int cantidad = venta['cantidad'];
        
        if (!ventaMap.containsKey(idProd)) {
          ventaMap[idProd] = {'cajas': 0, 'piezas': 0};
        }
        
        if (unidad == 'CAJA') {
          ventaMap[idProd]!['cajas'] = (ventaMap[idProd]!['cajas']!) + cantidad;
        } else {
          ventaMap[idProd]!['piezas'] = (ventaMap[idProd]!['piezas']!) + cantidad;
        }
      }

      // 3. Aplicar cálculo al stock visual
      // Solo mostramos productos que fueron cargados en la ruta o que tienen stock
      List<Producto> filteredProducts = [];
      
      for (var product in allProducts) {
        // Si el producto está en la carga de la ruta
        if (cargaMap.containsKey(product.id)) {
          int cargaCajas = cargaMap[product.id]!['cajas']!;
          int cargaPiezas = cargaMap[product.id]!['piezas']!;
          
          int ventaCajas = ventaMap[product.id]?['cajas'] ?? 0;
          int ventaPiezas = ventaMap[product.id]?['piezas'] ?? 0;

          // Calcular remanente
          // Nota: Esto es simplificado. Si vendes piezas de una caja abierta, la lógica real puede ser más compleja.
          // Aquí asumimos resta directa por unidad para visualización rápida.
          // Si vendieron más piezas de las sueltas, necesitamos "abrir" cajas en la lógica? 
          // Por simplicidad visual: Mostramos lo que queda netamente.
          
          int stockCajasVisual = cargaCajas - ventaCajas;
          int stockPiezasVisual = cargaPiezas - ventaPiezas;
          
          // Ajuste básico: si piezas es negativo, restamos de cajas (abrir caja)
          while (stockPiezasVisual < 0 && stockCajasVisual > 0) {
            stockCajasVisual--;
            stockPiezasVisual += product.piezasPorCaja;
          }

          product.stockCajas = stockCajasVisual;
          product.stockPiezas = stockPiezasVisual;
          
          filteredProducts.add(product);
        } else {
          // Producto no cargado en la ruta -> Stock 0 o no mostrar?
          // Opción A: No mostrar.
          // Opción B: Mostrar con 0.
          // Vamos con opción A para limpiar la vista del vendedor.
          // filteredProducts.add(product..stockCajas=0..stockPiezas=0); 
        }
      }
      _products = filteredProducts;
      
    } else {
      // Sin Salida seleccionada -> Mostrar stock global (comportamiento original)
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
