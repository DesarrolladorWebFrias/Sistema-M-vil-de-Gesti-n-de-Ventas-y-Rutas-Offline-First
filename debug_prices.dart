import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final dbPath = join(Platform.environment['USERPROFILE']!, 'Documents', 'lactopos_pro.db');
  final db = await openDatabase(dbPath);

  print('═══════════════════════════════════════');
  print('💰 PRECIOS Y CONFIGURACIÓN DE LECHITAS');
  print('═══════════════════════════════════════');
  
  // Buscar productos que parezcan lechitas
  final productos = await db.query(
    'productos',
    where: "nombre LIKE '%LECHITA%' OR nombre LIKE '%FRESA%' OR nombre LIKE '%VAINILLA%' OR nombre LIKE '%CHOCOLATE%'",
  );

  if (productos.isEmpty) {
    print('❌ No encontré productos con esos nombres.');
  } else {
    for (var p in productos) {
      double precio = double.tryParse(p['precio'].toString()) ?? 0.0;
      int pxc = int.tryParse(p['piezas_por_caja'].toString()) ?? 0;
      
      double precioCaja = precio * pxc;
      
      print('PRODUCTO: ${p['nombre']} (ID: ${p['id']})');
      print('  - Precio Unitario: \$$precio');
      print('  - Piezas por Caja: $pxc');
      print('  - PRECIO POR CAJA CALCULADO: \$$precioCaja');
      print('---------------------------------------');
    }
  }
  
  print('');
  print('📊 VERIFICACIÓN DE VENTA (6 CAJAS DE CADA UNO)');
  print('Si el precio es correcto, 6 cajas deberían costar...');
  
  double totalCalculado = 0;
  for (var p in productos) {
    if (p['nombre'].toString().contains('FRESA') || 
        p['nombre'].toString().contains('VAINILLA') || 
        p['nombre'].toString().contains('CHOCOLATE')) {
          
      double precio = double.tryParse(p['precio'].toString()) ?? 0.0;
      int pxc = int.tryParse(p['piezas_por_caja'].toString()) ?? 0;
      double precioCaja = precio * pxc;
      
      print('  + 6 Cajas de ${p['nombre']} = \$${precioCaja * 6}');
      totalCalculado += (precioCaja * 6);
    }
  }
  print('💰 TOTAL ESPERADO SEGÚN BD: \$$totalCalculado');

  await db.close();
}
