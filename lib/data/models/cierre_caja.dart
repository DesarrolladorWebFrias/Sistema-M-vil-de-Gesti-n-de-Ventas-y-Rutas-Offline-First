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
      id: map['id'] as int?,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
      fondoCajaInicial: (map['fondo_caja_inicial'] as num).toDouble(),
      ventasSistema: (map['ventas_sistema'] as num).toDouble(),
      dineroContado: (map['dinero_contado'] as num).toDouble(),
      diferencia: (map['diferencia'] as num).toDouble(),
      gananciaRealDia: (map['ganancia_real_dia'] as num).toDouble(),
      detallesBilletes: Map<String, int>.from(jsonDecode(map['detalles_billetes'] as String)),
    );
  }
}
