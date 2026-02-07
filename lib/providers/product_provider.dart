import 'package:flutter/material.dart';
import '../../data/local/db_helper.dart';
import '../../data/models/producto.dart';

class ProductProvider with ChangeNotifier {
  List<Producto> _products = [];
  bool _isLoading = false;

  List<Producto> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('productos', orderBy: 'nombre ASC');

    _products = List.generate(maps.length, (i) {
      return Producto.fromMap(maps[i]);
    });

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
