import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal() {
    // Inicializar FFI para plataformas de escritorio (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'lactopos_pro.db');
    final db = await openDatabase(
      path,
      version: 2, // Incrementada la versión para migración
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // Asegurar que los productos predefinidos existan y tengan stock
    await _insertarDatosIniciales(db);
    
    return db;
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración de versión 1 a 2: Agregar tablas de salidas
      
      // 1. Tabla de Salidas
      await db.execute('''
        CREATE TABLE salidas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha_hora TEXT NOT NULL,
          tipo TEXT NOT NULL,
          nombre_ruta TEXT NOT NULL,
          nombre_cliente TEXT,
          vendedor TEXT NOT NULL,
          cerrada INTEGER DEFAULT 0,
          notas TEXT
        )
      ''');

      // 2. Tabla Detalle de Salidas
      await db.execute('''
        CREATE TABLE detalle_salidas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_salida INTEGER NOT NULL,
          id_producto INTEGER NOT NULL,
          cantidad_cajas INTEGER DEFAULT 0,
          cantidad_piezas INTEGER DEFAULT 0,
          precio_venta REAL NOT NULL,
          FOREIGN KEY (id_salida) REFERENCES salidas(id) ON DELETE CASCADE,
          FOREIGN KEY (id_producto) REFERENCES productos(id)
        )
      ''');

      // 3. Agregar columna id_salida a tabla ventas
      await db.execute('''
        ALTER TABLE ventas ADD COLUMN id_salida INTEGER
      ''');
    }
  }

  Future<void> _insertarDatosIniciales(Database db) async {
    // Insertar o actualizar 10 productos lácteos predefinidos
    // Insertar o actualizar 10 productos lácteos predefinidos
    final productosIniciales = [
      {
        'nombre': 'Leche Entera 1L',
        'precio': 12.50,
        'costo': 8.00,
        'stock_cajas': 10,
        'stock_piezas': 8,
        'piezas_por_caja': 12,
        'orden_carrusel': 1,
      },
      {
        'nombre': 'Lechitas Saborizadas (Fresa/Choc)',
        'precio': 5.00,
        'costo': 3.50,
        'stock_cajas': 20,
        'stock_piezas': 0,
        'piezas_por_caja': 27, // CORREGIDO: 27 piezas por caja
        'orden_carrusel': 2,
      },
      {
        'nombre': 'Leche en Polvo 400g',
        'precio': 45.00,
        'costo': 35.00,
        'stock_cajas': 5,
        'stock_piezas': 2,
        'piezas_por_caja': 12, 
        'orden_carrusel': 3,
      },
       {
        'nombre': 'Leche en Polvo (Caja Grande)',
        'precio': 120.00,
        'costo': 90.00,
        'stock_cajas': 5,
        'stock_piezas': 0,
        'piezas_por_caja': 36, // CORREGIDO: 36 piezas
        'orden_carrusel': 4,
      },
      {
        'nombre': 'Crema Ácida 500ml',
        'precio': 22.00,
        'costo': 15.00,
        'stock_cajas': 5,
        'stock_piezas': 4,
        'piezas_por_caja': 12,
        'orden_carrusel': 5,
      },
      {
        'nombre': 'Queso Fresco 500g',
        'precio': 35.00,
        'costo': 25.00,
        'stock_cajas': 4,
        'stock_piezas': 8,
        'piezas_por_caja': 12,
        'orden_carrusel': 6,
      },
      {
        'nombre': 'Mantequilla 250g',
        'precio': 28.00,
        'costo': 20.00,
        'stock_cajas': 7,
        'stock_piezas': 5,
        'piezas_por_caja': 24, // Asumimos 24 para mantequilla
        'orden_carrusel': 7,
      },
      // ... otros
    ];

    // Insertar o actualizar cada producto
    for (var producto in productosIniciales) {
      // Verificar si el producto ya existe por nombre
      final List<Map<String, dynamic>> existing = await db.query(
        'productos',
        where: 'nombre = ?',
        whereArgs: [producto['nombre']],
      );

      if (existing.isEmpty) {
        // Insertar nuevo producto
        await db.insert('productos', producto);
      } else {
        // Actualizar producto existente (solo si tiene stock en 0)
        final existingProduct = existing.first;
        if (existingProduct['stock_cajas'] == 0 && existingProduct['stock_piezas'] == 0) {
          await db.update(
            'productos',
            producto,
            where: 'id = ?',
            whereArgs: [existingProduct['id']],
          );
        }
      }
    }
  }
}
