import 'dart:convert';

class CierreCaja {
  int? id;
  DateTime fechaHora;
  double fondoCajaInicial;
  double ventasSistema;
  double dineroContado;
  double diferencia;
  double gananciaRealDia;
  Map<String, int> detallesBilletes; // { "1000": 3, "500": 1... }

  CierreCaja({
    this.id,
    required this.fechaHora,
    required this.fondoCajaInicial,
    required this.ventasSistema,
    required this.dineroContado,
    required this.diferencia,
    required this.gananciaRealDia,
    this.detallesBilletes = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_hora': fechaHora.toIso8601String(),
      'fondo_caja_inicial': fondoCajaInicial,
      'ventas_sistema': ventasSistema,
      'dinero_contado': dineroContado,
      'diferencia': diferencia,
      'ganancia_real_dia': gananciaRealDia,
      'detalles_billetes': jsonEncode(detallesBilletes),
    };
  }

  factory CierreCaja.fromMap(Map<String, dynamic> map) {
    return CierreCaja(
      id: map['id'],
      fechaHora: DateTime.parse(map['fecha_hora']),
      fondoCajaInicial: map['fondo_caja_inicial'],
      ventasSistema: map['ventas_sistema'],
      dineroContado: map['dinero_contado'],
      diferencia: map['diferencia'],
      gananciaRealDia: map['ganancia_real_dia'],
      detallesBilletes: Map<String, int>.from(jsonDecode(map['detalles_billetes'])),
    );
  }
}
