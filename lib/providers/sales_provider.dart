import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../data/local/db_helper.dart';
import '../../data/models/producto.dart';
import '../../data/models/venta.dart';
import '../../data/models/movimiento_inventario.dart';

class SalesProvider with ChangeNotifier {
  final List<DetalleVenta> _cart = [];
  double _total = 0.0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<DetalleVenta> get cart => _cart;
  double get total => _total;

  // Configuración de Sonido
  Future<void> _playSound() async {
    try {
      // Asegúrate de tener el archivo 'dring.mp3' en assets/sounds/
      // Por ahora usaremos un sonido por defecto del sistema si falla
      await _audioPlayer.play(AssetSource('sounds/dring.mp3')); 
    } catch (e) {
      debugPrint("Error reproduciendo sonido: $e");
    }
  }

  void addToCart(Producto product, int quantity, String unidad, {int? piezasPorCaja}) { // unidad: 'CAJA' | 'PIEZA'
    // 1. Validar Stock ANTES de agregar al carrito (Lógica inteligente: Abrir Cajas)
    int piecesPerBox = piezasPorCaja ?? product.piezasPorCaja;
    if (piecesPerBox <= 0) piecesPerBox = 12; // Fallback seguro

    int totalPiezasDisponibles = (product.stockCajas * piecesPerBox) + product.stockPiezas;
    int totalPiezasRequeridas = quantity * (unidad == 'CAJA' ? piecesPerBox : 1);

    if (totalPiezasDisponibles < totalPiezasRequeridas) {
      // Auto-unboxing logic handled visually in UI or allowed here?
      // For now, we allow if total pieces exist.
      // throw Exception('Stock insuficiente...');
    }

    // 2. Calcular Precios
    // IMPORTANTE: Los precios en la BD están almacenados por PIEZA
    // Si se vende por CAJA, multiplicamos por piezas_por_caja para precio, pero validamos si hay precio caja especifico?
    // Asumimos precio x pieza * piezas_por_caja
    double precioUnitario = product.precio; // Precio por PIEZA
    if (unidad == 'CAJA') {
      precioUnitario = product.precio * piecesPerBox; // Precio por CAJA
    }

    double costoUnitario = product.costo; // Costo por PIEZA
    if (unidad == 'CAJA') {
        costoUnitario = product.costo * piecesPerBox; // Costo por CAJA
    }

    double ganancia = (precioUnitario - costoUnitario) * quantity;

    // 3. Agregar al carrito
    _cart.insert(0, DetalleVenta(
      idProducto: product.id!,
      cantidad: quantity,
      unidad: unidad,
      precioUnitario: precioUnitario,
      costoUnitario: costoUnitario,
      ganancia: ganancia,
    ));

    // 4. Feedback Auditivo
    _playSound();

    _calculateTotal();
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cart.removeAt(index);
    _calculateTotal();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _calculateTotal();
    notifyListeners();
  }

  void _calculateTotal() {
    _total = 0.0;
    for (var item in _cart) {
      _total += item.precioUnitario * item.cantidad;
    }
  }

  Future<bool> checkout(double pagoCliente, {int? idSalida}) async {
    if (_cart.isEmpty) return false;

    // Validar que el pago sea suficiente
    if (pagoCliente < _total) {
      throw Exception('Pago insuficiente. Total: \$${_total.toStringAsFixed(2)}, Recibido: \$${pagoCliente.toStringAsFixed(2)}');
    }

    final db = await DatabaseHelper().database;

    try {
      // Usar transacción explícita para garantizar atomicidad
      await db.transaction((txn) async {
        // 1. Crear Venta
        DateTime now = DateTime.now();
        Venta nuevaVenta = Venta(
          fechaHora: now,
          total: _total,
          metodoPago: 'EFECTIVO', // Por ahora fijo
          idSalida: idSalida, // Vincular con salida
        );
        
        int idVenta = await txn.insert('ventas', nuevaVenta.toMap());

        // 2. Guardar Detalles y Actualizar Inventario
        for (var item in _cart) {
          // Guardar Detalle
          item.idVenta = idVenta; // Asignar ID de la venta
          await txn.insert('detalle_ventas', item.toMap());

          // Registrar Movimiento Inventario
          MovimientoInventario mov = MovimientoInventario(
            fechaHora: now,
            tipo: 'VENTA',
            idProducto: item.idProducto,
            cantidadCajas: item.unidad == 'CAJA' ? -item.cantidad : 0, // Resta
            cantidadPiezas: item.unidad == 'PIEZA' ? -item.cantidad : 0, // Resta
            usuario: 'POS',
            notas: 'Venta #$idVenta'
          );
          await txn.insert('movimientos_inventario', mov.toMap());

          // Actualizar Stock Producto (Lógica de Abrir Cajas)
          // Primero obtenemos el stock actual de la BD para asegurar consistencia
          List<Map<String, dynamic>> stockResult = await txn.query(
            'productos',
            columns: ['stock_cajas', 'stock_piezas', 'piezas_por_caja'],
            where: 'id = ?',
            whereArgs: [item.idProducto],
          );
          
          if (stockResult.isNotEmpty) {
            int currentCajas = stockResult.first['stock_cajas'] as int;
            int currentPiezas = stockResult.first['stock_piezas'] as int;
            int piezasPorCaja = stockResult.first['piezas_por_caja'] as int;

            // Restar inventario
            if (item.unidad == 'CAJA') {
              currentCajas -= item.cantidad;
            } else {
              currentPiezas -= item.cantidad;
            }

            // Normalizar (Abrir cajas si faltan piezas)
            while (currentPiezas < 0) {
              // Permitimos que el stock de cajas sea negativo si es necesario para completar la venta.
              // La realidad física (producto en mano) manda sobre el sistema.
              currentCajas--; // Abrir una caja (aunque teóricamente no haya)
              currentPiezas += piezasPorCaja; // Sumar las piezas de la caja
            }

            // Guardar cambios
            await txn.update(
              'productos',
              {
                'stock_cajas': currentCajas,
                'stock_piezas': currentPiezas,
              },
              where: 'id = ?',
              whereArgs: [item.idProducto],
            );
          }
        }
      });
      
      clearCart();
      return true;

    } catch (e) {
      debugPrint("Error en Checkout: $e");
      return false;
    }
  }
}
