class Producto {
  int? id;
  String nombre;
  double precio;
  double costo;
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
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'],
      costo: map['costo'],
      imagenPath: map['imagen_path'],
      stockCajas: map['stock_cajas'],
      stockPiezas: map['stock_piezas'],
      piezasPorCaja: map['piezas_por_caja'],
      colorHex: map['color_hex'],
      ordenCarrusel: map['orden_carrusel'],
    );
  }
}
