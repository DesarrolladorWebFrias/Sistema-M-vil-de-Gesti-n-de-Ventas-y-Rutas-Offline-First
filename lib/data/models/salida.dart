class Salida {
  int? id;
  DateTime fechaHora;
  String tipo; // 'RUTA' o 'PEDIDO_ESPECIAL'
  String nombreRuta; // Nombre de la ruta o del cliente
  String? nombreCliente; // Solo para pedidos especiales
  String vendedor;
  bool cerrada; // false = activa, true = cerrada
  String? notas;

  Salida({
    this.id,
    required this.fechaHora,
    required this.tipo,
    required this.nombreRuta,
    this.nombreCliente,
    required this.vendedor,
    this.cerrada = false,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_hora': fechaHora.toIso8601String(),
      'tipo': tipo,
      'nombre_ruta': nombreRuta,
      'nombre_cliente': nombreCliente,
      'vendedor': vendedor,
      'cerrada': cerrada ? 1 : 0,
      'notas': notas,
    };
  }

  factory Salida.fromMap(Map<String, dynamic> map) {
    return Salida(
      id: map['id'] as int?,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
      tipo: map['tipo'] as String,
      nombreRuta: map['nombre_ruta'] as String,
      nombreCliente: map['nombre_cliente'] as String?,
      vendedor: map['vendedor'] as String,
      cerrada: (map['cerrada'] as int) == 1,
      notas: map['notas'] as String?,
    );
  }

  // Método helper para obtener el total de productos en la salida
  double calcularTotal(List<DetalleSalida> detalles) {
    double total = 0.0;
    for (var detalle in detalles) {
      total += detalle.precioVenta * 
               (detalle.cantidadCajas + detalle.cantidadPiezas);
    }
    return total;
  }
}

class DetalleSalida {
  int? id;
  int? idSalida;
  int idProducto;
  int cantidadCajas;
  int cantidadPiezas;
  double precioVenta; // Precio de venta para el ticket

  DetalleSalida({
    this.id,
    this.idSalida,
    required this.idProducto,
    this.cantidadCajas = 0,
    this.cantidadPiezas = 0,
    required this.precioVenta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_salida': idSalida,
      'id_producto': idProducto,
      'cantidad_cajas': cantidadCajas,
      'cantidad_piezas': cantidadPiezas,
      'precio_venta': precioVenta,
    };
  }

  factory DetalleSalida.fromMap(Map<String, dynamic> map) {
    return DetalleSalida(
      id: map['id'] as int?,
      idSalida: map['id_salida'] as int?,
      idProducto: map['id_producto'] as int,
      cantidadCajas: map['cantidad_cajas'] as int? ?? 0,
      cantidadPiezas: map['cantidad_piezas'] as int? ?? 0,
      precioVenta: (map['precio_venta'] as num).toDouble(),
    );
  }
}
