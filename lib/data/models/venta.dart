class Venta {
  int? id;
  DateTime fechaHora;
  double total;
  String metodoPago;
  List<DetalleVenta>? detalles;

  Venta({
    this.id,
    required this.fechaHora,
    required this.total,
    this.metodoPago = 'EFECTIVO',
    this.detalles,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_hora': fechaHora.toIso8601String(),
      'total': total,
      'metodo_pago': metodoPago,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'],
      fechaHora: DateTime.parse(map['fecha_hora']),
      total: map['total'],
      metodoPago: map['metodo_pago'],
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
      id: map['id'],
      idVenta: map['id_venta'],
      idProducto: map['id_producto'],
      cantidad: map['cantidad'],
      unidad: map['unidad'],
      precioUnitario: map['precio_unitario'],
      costoUnitario: map['costo_unitario'],
      ganancia: map['ganancia'],
    );
  }
}
