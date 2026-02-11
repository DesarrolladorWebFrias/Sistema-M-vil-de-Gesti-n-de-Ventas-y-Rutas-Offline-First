class Producto {
  int? id;
  String nombre;
  
  // IMPORTANTE: precio y costo están en la unidad base: PIEZA
  // Si se vende por CAJA, multiplicar por piezasPorCaja
  double precio;  // Precio de venta por PIEZA
  double costo;   // Costo por PIEZA
  
  String? imagenPath;
  int stockCajas;
  int stockPiezas;
  int piezasPorCaja;
  int? colorHex;
  int ordenCarrusel;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.costo,
    this.imagenPath,
    this.stockCajas = 0,
    this.stockPiezas = 0,
    this.piezasPorCaja = 12,
    this.colorHex,
    this.ordenCarrusel = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'costo': costo,
      'imagen_path': imagenPath,
      'stock_cajas': stockCajas,
      'stock_piezas': stockPiezas,
      'piezas_por_caja': piezasPorCaja,
      'color_hex': colorHex,
      'orden_carrusel': ordenCarrusel,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      costo: (map['costo'] as num).toDouble(),
      imagenPath: map['imagen_path'] as String?,
      stockCajas: map['stock_cajas'] as int? ?? 0,
      stockPiezas: map['stock_piezas'] as int? ?? 0,
      piezasPorCaja: map['piezas_por_caja'] as int? ?? 12,
      colorHex: map['color_hex'] as int?,
      ordenCarrusel: map['orden_carrusel'] as int? ?? 0,
    );
  }
}
