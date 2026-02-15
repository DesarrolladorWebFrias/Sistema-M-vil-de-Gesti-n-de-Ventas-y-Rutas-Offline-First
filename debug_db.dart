import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Obtener ruta de la base de datos
  final dbPath = join(
    Platform.environment['USERPROFILE']!,
    'Documents',
    'lactopos_pro.db',
  );

  print('📂 Ruta de BD: $dbPath');
  print('');

  final db = await openDatabase(dbPath);

  // 1. Ver todas las salidas
  print('═══════════════════════════════════════');
  print('📦 SALIDAS REGISTRADAS:');
  print('═══════════════════════════════════════');
  final salidas = await db.query('salidas');
  for (var salida in salidas) {
    print('ID: ${salida['id']} | ${salida['nombre_ruta']} | Cerrada: ${salida['cerrada']}');
  }
  print('');

  // 2. Ver productos en catálogo
  print('═══════════════════════════════════════');
  print('📚 PRODUCTOS EN CATÁLOGO:');
  print('═══════════════════════════════════════');
  final productos = await db.query('productos');
  for (var prod in productos) {
    print('ID: ${prod['id']} | ${prod['nombre']}');
  }
  print('');

  // 3. Ver detalle_salidas para GAVIOTAS NORTE
  print('═══════════════════════════════════════');
  print('🔍 DETALLE_SALIDAS PARA GAVIOTAS NORTE:');
  print('═══════════════════════════════════════');
  
  // Primero obtener el ID de GAVIOTAS NORTE
  final gaviotasNorte = await db.query(
    'salidas',
    where: 'nombre_ruta LIKE ?',
    whereArgs: ['%GAVIOTAS NORTE%'],
  );

  if (gaviotasNorte.isEmpty) {
    print('❌ No se encontró GAVIOTAS NORTE');
  } else {
    final idSalida = gaviotasNorte.first['id'];
    print('ID de GAVIOTAS NORTE: $idSalida');
    print('');

    final detalles = await db.query(
      'detalle_salidas',
      where: 'id_salida = ?',
      whereArgs: [idSalida],
    );

    if (detalles.isEmpty) {
      print('❌ No hay productos cargados en detalle_salidas para esta salida');
    } else {
      print('✅ Productos encontrados: ${detalles.length}');
      for (var detalle in detalles) {
        print('  - ID Producto: ${detalle['id_producto']} | Cajas: ${detalle['cantidad_cajas']} | Piezas: ${detalle['cantidad_piezas']}');
      }
    }
  }

  await db.close();
}
