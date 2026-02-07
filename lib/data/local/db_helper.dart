import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'lactopos_pro.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla de Productos
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        costo REAL NOT NULL,
        imagen_path TEXT,
        stock_cajas INTEGER DEFAULT 0,
        stock_piezas INTEGER DEFAULT 0,
        piezas_por_caja INTEGER DEFAULT 12,
        color_hex INTEGER,
        orden_carrusel INTEGER
      )
    ''');

    // 2. Tabla de Ventas
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_hora TEXT NOT NULL,
        total REAL NOT NULL,
        metodo_pago TEXT DEFAULT 'EFECTIVO'
      )
    ''');

    // 3. Tabla Detalle de Venta
    await db.execute('''
      CREATE TABLE detalle_ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_venta INTEGER NOT NULL,
        id_producto INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        unidad TEXT NOT NULL, -- 'CAJA' o 'PIEZA'
        precio_unitario REAL NOT NULL,
        costo_unitario REAL NOT NULL,
        ganancia REAL NOT NULL,
        FOREIGN KEY (id_venta) REFERENCES ventas (id) ON DELETE CASCADE,
        FOREIGN KEY (id_producto) REFERENCES productos (id)
      )
    ''');

    // 4. Tabla de Movimientos de Inventario (Kardex)
    await db.execute('''
      CREATE TABLE movimientos_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_hora TEXT NOT NULL,
        tipo TEXT NOT NULL, -- 'VENTA', 'ALTA_REABASTECIMIENTO', 'AJUSTE', 'MERMA'
        id_producto INTEGER NOT NULL,
        cantidad_cajas INTEGER DEFAULT 0,
        cantidad_piezas INTEGER DEFAULT 0,
        usuario TEXT,
        notas TEXT,
        FOREIGN KEY (id_producto) REFERENCES productos (id)
      )
    ''');

     // 5. Tabla de Cierres de Caja (Arqueos)
    await db.execute('''
      CREATE TABLE cierres_caja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_hora TEXT NOT NULL,
        fondo_caja_inicial REAL NOT NULL,
        ventas_sistema REAL NOT NULL,
        dinero_contado REAL NOT NULL,
        diferencia REAL NOT NULL,
        ganancia_real_dia REAL NOT NULL,
        detalles_billetes TEXT -- JSON string con el conteo
      )
    ''');
    
    // Insertar datos iniciales (Seed Data)
    await _insertarDatosIniciales(db);
  }

  Future<void> _insertarDatosIniciales(Database db) async {
    // Aquí podemos insertar los productos por defecto si se desea
    // Por ahora lo dejamos vacío o para una futura migración
  }
}
