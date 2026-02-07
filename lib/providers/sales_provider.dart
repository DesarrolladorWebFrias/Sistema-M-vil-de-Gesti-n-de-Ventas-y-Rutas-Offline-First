import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/db_helper.dart';
import '../../data/models/producto.dart';
import '../../data/models/venta.dart';
import '../../data/models/movimiento_inventario.dart';

class SalesProvider with ChangeNotifier {
  List<DetalleVenta> _cart = [];
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

  void addToCart(Producto product, int quantity, String unidad) { // unidad: 'CAJA' | 'PIEZA'
    // 1. Validar Stock (Opcional: permitir venta negativa si se desea, pero recomendado validar)
    int stockDisponible = unidad == 'CAJA' ? product.stockCajas : product.stockPiezas;
    if (stockDisponible < quantity) {
      // Podríamos lanzar una excepción o manejarlo en la UI
      // Por requerimiento de "Venta negativa" o "Deuda técnica", seguimos.
    }

    // 2. Calcular Precios
    double precioUnitario = product.precio; // El precio base es por pieza? O por caja? 
    // Asumimos precio en BD es por PIEZA. Si es CAJA, multiplicar.
    if (unidad == 'CAJA') {
      precioUnitario = product.precio * product.piezasPorCaja; 
    }

    double costoUnitario = product.costo;
    if (unidad == 'CAJA') {
        costoUnitario = product.costo * product.piezasPorCaja;
    }

    double ganancia = (precioUnitario - costoUnitario) * quantity;

    // 3. Agregar al carrito
    _cart.add(DetalleVenta(
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

  Future<bool> checkout(double pagoCliente) async {
    if (_cart.isEmpty) return false;

    final db = await DatabaseHelper().database;
    final batch = db.batch();

    try {
      // 1. Crear Venta
      DateTime now = DateTime.now();
      Venta nuevaVenta = Venta(
        fechaHora: now,
        total: _total,
        metodoPago: 'EFECTIVO' // Por ahora fijo
      );
      
      int idVenta = await db.insert('ventas', nuevaVenta.toMap());

      // 2. Guardar Detalles y Actualizar Inventario
      for (var item in _cart) {
        // Guardar Detalle
        item.idVenta = idVenta; // Asignar ID de la venta
        batch.insert('detalle_ventas', item.toMap());

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
        batch.insert('movimientos_inventario', mov.toMap());

        // Actualizar Stock Producto (Query directo para eficiencia)
        if (item.unidad == 'CAJA') {
          batch.rawUpdate(
            'UPDATE productos SET stock_cajas = stock_cajas - ? WHERE id = ?',
            [item.cantidad, item.idProducto]
          );
        } else {
           batch.rawUpdate(
            'UPDATE productos SET stock_piezas = stock_piezas - ? WHERE id = ?',
            [item.cantidad, item.idProducto]
          );
        }
      }

      await batch.commit();
      
      clearCart();
      return true;

    } catch (e) {
      debugPrint("Error en Checkout: $e");
      return false;
    }
  }
}
