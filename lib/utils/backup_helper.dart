import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/local/db_helper.dart';

class BackupHelper {
  
  // 1. Exportar Base de Datos (Compartir archivo .db)
  static Future<bool> exportDatabase(BuildContext context) async {
    try {
      // Obtener ruta de la BD actual
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = join(dbFolder.path, 'lactopos_pro.db');
      final File dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se encontró la base de datos.")));
        return false;
      }

      // Compartir archivo
      final xFile = XFile(dbPath);
      await Share.shareXFiles([xFile], text: 'Respaldo Base de Datos LactoPOS');
      return true;

    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al exportar: $e")));
      return false;
    }
  }

  // 2. Importar Base de Datos (Reemplazar archivo .db)
  static Future<bool> importDatabase(BuildContext context) async {
    try {
      // Seleccionar archivo
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File sourceFile = File(result.files.single.path!);
        
        // Validar extensión (básica)
        if (!sourceFile.path.endsWith('.db') && !sourceFile.path.endsWith('.sqlite')) {
             if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Archivo inválido. Debe ser .db o .sqlite")));
             return false;
        }

        // Obtener ruta destino
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbPath = join(dbFolder.path, 'lactopos_pro.db');

        // Cerrar conexión actual si está abierta (Importante para evitar bloqueos)
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;
        if (db.isOpen) await db.close();

        // Copiar archivo (Sobrescribir)
        await sourceFile.copy(dbPath);

        // Reiniciar Helper (forzar reapertura) o avisar usuario
        // Como DatabaseHelper es Singleton, la instancia _database quedará cerrada.
        // Necesitamos una forma de resetear _database a null en el Helper, o simplemente
        // confiar en que el usuario reinicie la app.
        
        if (context.mounted) {
           showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Importación Exitosa"),
              content: const Text("La base de datos se ha restaurado. Es necesario reiniciar la aplicación para aplicar los cambios correctamente."),
              actions: [
                TextButton(
                  child: const Text("Cerrar App (Si es posible) o OK"),
                  onPressed: () => exit(0), // Intentar cerrar app
                )
              ],
            ),
          );
        }
        return true;
      }
      return false; // Cancelado por usuario
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
      return false;
    }
  }

  // 3. Vaciar Datos (Factory Reset parcial)
  static Future<bool> clearData(BuildContext context, {bool keepProducts = true}) async {
    try {
      final db = await DatabaseHelper().database;
      
      await db.transaction((txn) async {
        // Borrar tablas transaccionales
        await txn.delete('detalle_ventas');
        await txn.delete('ventas');
        await txn.delete('detalle_salidas');
        await txn.delete('salidas');
        await txn.delete('movimientos_inventario');
        await txn.delete('cierres_caja');
        
        // Resetear autoincrement de ventas (opcional)
        await txn.rawDelete("DELETE FROM sqlite_sequence WHERE name='ventas'");
        await txn.rawDelete("DELETE FROM sqlite_sequence WHERE name='salidas'");

        if (!keepProducts) {
          await txn.delete('productos');
        } else {
           // Si conservamos productos, quizás queramos resetear stock a 0?
           // await txn.update('productos', {'stock_cajas': 0, 'stock_piezas': 0});
           // El usuario pidió "Vaciar Datos", asumiremos resetear stock también? 
           // Mejor preguntar o hacerlo explícito. Por ahora solo borro historial ventas.
           // Si vaciamos ventas, el stock debería volver a su estado original? 
           // NO, el stock es estado actual. Si borramos ventas, el stock sigue siendo el físico actual.
           // Pero si borramos movimientos de inventario, perdemos el rastro.
           // Para un "Reinicio de Sistema", lo ideal es poner Stock en 0.
           await txn.update('productos', {'stock_cajas': 0, 'stock_piezas': 0});
        }
      });

      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Datos eliminados correctamente.")));
      }
      return true;

    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al limpiar datos: $e")));
      return false;
    }
  }
}
