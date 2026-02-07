class MovimientoInventario {
  int? id;
  DateTime fechaHora;
  String tipo; // 'VENTA', 'ALTA_REABASTECIMIENTO', 'AJUSTE', 'MERMA'
  int idProducto;
  int cantidadCajas;
  int cantidadPiezas;
  String? usuario;
  String? notas;

  MovimientoInventario({
    this.id,
    required this.fechaHora,
    required this.tipo,
    required this.idProducto,
    this.cantidadCajas = 0,
    this.cantidadPiezas = 0,
    this.usuario,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_hora': fechaHora.toIso8601String(),
      'tipo': tipo,
      'id_producto': idProducto,
      'cantidad_cajas': cantidadCajas,
      'cantidad_piezas': cantidadPiezas,
      'usuario': usuario,
      'notas': notas,
    };
  }

  factory MovimientoInventario.fromMap(Map<String, dynamic> map) {
    return MovimientoInventario(
      id: map['id'],
      fechaHora: DateTime.parse(map['fecha_hora']),
      tipo: map['tipo'],
      idProducto: map['id_producto'],
      cantidadCajas: map['cantidad_cajas'],
      cantidadPiezas: map['cantidad_piezas'],
      usuario: map['usuario'],
      notas: map['notas'],
    );
  }
}
