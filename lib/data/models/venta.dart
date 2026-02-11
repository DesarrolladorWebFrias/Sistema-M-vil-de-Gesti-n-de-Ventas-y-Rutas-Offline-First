class Venta {
  int? id;
  DateTime fechaHora;
  double total;
  String metodoPago;
  int? idSalida; // Vinculación con salida
  List<DetalleVenta>? detalles;

  Venta({
    this.id,
    required this.fechaHora,
    required this.total,
    this.metodoPago = 'EFECTIVO',
    this.idSalida,
    this.detalles,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_hora': fechaHora.toIso8601String(),
      'total': total,
      'metodo_pago': metodoPago,
      'id_salida': idSalida,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
      total: (map['total'] as num).toDouble(),
      metodoPago: map['metodo_pago'] as String? ?? 'EFECTIVO',
      idSalida: map['id_salida'] as int?,
    );
  }
}

class DetalleVenta {
  int? id;
  int? idVenta; // Nullable until saved
  int idProducto;
  int cantidad;
  String unidad; // 'CAJA' | 'PIEZA'
  double precioUnitario;
  double costoUnitario;
  double ganancia;

  DetalleVenta({
    this.id,
    this.idVenta,
    required this.idProducto,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
    required this.costoUnitario,
    required this.ganancia,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_venta': idVenta,
      'id_producto': idProducto,
      'cantidad': cantidad,
      'unidad': unidad,
      'precio_unitario': precioUnitario,
      'costo_unitario': costoUnitario,
      'ganancia': ganancia,
    };
  }

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'] as int?,
      idVenta: map['id_venta'] as int?,
      idProducto: map['id_producto'] as int,
      cantidad: map['cantidad'] as int,
      unidad: map['unidad'] as String,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      costoUnitario: (map['costo_unitario'] as num).toDouble(),
      ganancia: (map['ganancia'] as num).toDouble(),
    );
  }
}
