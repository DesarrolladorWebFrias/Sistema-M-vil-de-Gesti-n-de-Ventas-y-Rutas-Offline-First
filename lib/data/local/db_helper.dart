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
      version: 4, // Incrementada a 4 para LIMPIEZA TOTAL y recarga de 11 productos
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

    if (oldVersion < 4) {
      // Migración a versión 4: LIMPIEZA TOTAL y recarga
      await _insertarDatosIniciales(db);
    }
  }

  Future<void> _insertarDatosIniciales(Database db) async {
    // ---------------------------------------------------------------------------
    // TEMPLATE PARA PRODUCTOS POR DEFECTO
    // Edite esta lista con sus propios productos e imágenes.
    // Asegúrese de colocar las imágenes en la carpeta 'assets/images/' y registrarlas en pubspec.yaml
    // ---------------------------------------------------------------------------
    
    // LIMPIEZA TOTAL: Eliminar todos los productos existentes para dejar solo los 11 oficiales
    await db.delete('productos');

    final productosIniciales = [
      {
        'nombre': 'LECHE ENTERA',
        'precio': 23.00,
        'costo': 22.50,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 12,
        'orden_carrusel': 1,
        'imagen_path': 'assets/images/leche-entera.png', // CAMBIE ESTO por su imagen real
      },
      {
        'nombre': 'LECHE DESLACTOSADA',
        'precio': 22.00,
        'costo': 22.00,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 12, 
        'orden_carrusel': 2,
        'imagen_path': 'assets/images/leche-deslactosada.png',
      },
      {
        'nombre': 'LECHE SEMIDESCREMADA',
        'precio': 22.00,
        'costo': 21.50,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 12, 
        'orden_carrusel': 3,
        'imagen_path': 'assets/images/semidescremada-liquida.png',
      },
       {
        'nombre': 'LECHE LIGH',
        'precio': 21.00,
        'costo': 20.50,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 12,
        'orden_carrusel': 4,
        'imagen_path': 'assets/images/leche-ligh.png',
      },
      {
        'nombre': 'LECHITA DE FRESA',
        'precio': 7.00,
        'costo': 6.50,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 27,
        'orden_carrusel': 5,
        'imagen_path': 'assets/images/lechitas-fresas.png',
      },
      {
        'nombre': 'LECHITA DE VAINILLA',
        'precio': 7.00,
        'costo': 6.50,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 27,
        'orden_carrusel': 6,
        'imagen_path': 'assets/images/lechitas-vainillas.png',
      },
      {
        'nombre': 'LECHITA DE CHOCOLATE',
        'precio': 10.00,
        'costo': 10.00,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 27,
        'orden_carrusel': 7,
        'imagen_path': 'assets/images/lechitas-chocolates.png',
      },
      {
        'nombre': 'LECHITA NATURAL',
        'precio': 6.00,
        'costo': 5.50,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 27,
        'orden_carrusel': 8,
        'imagen_path': 'assets/images/lechita-natural.png',
      },
      {
        'nombre': 'LECHE ENTERA EN POLVO',
        'precio': 36.00,
        'costo': 35.50,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 36,
        'orden_carrusel': 9,
        'imagen_path': 'assets/images/entera-polvo.png',
      },
       {
        'nombre': 'LECHE SEMIDESCREMADA EN POLVO',
        'precio': 32.00,
        'costo': 32.00,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 36,
        'orden_carrusel': 10,
        'imagen_path': 'assets/images/semi-polvo.png',
      },
       {
        'nombre': 'LECHE SUBSIDIADA EN POLVO',
        'precio': 15.00,
        'costo': 15.00,
        'stock_cajas': 0,
        'stock_piezas': 0,
        'piezas_por_caja': 36,
        'orden_carrusel': 11,
        'imagen_path': 'assets/images/leche_polvo_subsidiada.jpg',
      },
      // ... otros
    ];

    // Insertar productos oficiales
    for (var producto in productosIniciales) {
        await db.insert('productos', producto);
    }
  }
}
