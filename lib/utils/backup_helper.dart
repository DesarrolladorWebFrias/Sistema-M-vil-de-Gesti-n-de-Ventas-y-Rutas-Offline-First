import 'dart:io';
import 'package:flutter/material.dart';

// CLASE SIMPLIFICADA TEMPORALMENTE (STUB)
// Eliminada dependencia de file_picker para permitir generar APK.

class BackupHelper {
  
  static Future<bool> exportDatabase(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Función deshabilitada temporalmente en esta versión de prueba."),
          backgroundColor: Colors.orange,
        )
      );
    }
    return false;
  }

  static Future<bool> importDatabase(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Función deshabilitada temporalmente en esta versión de prueba."),
          backgroundColor: Colors.orange,
        )
      );
    }
    return false;
  }

  // Método agregado para evitar error de compilación en BackupScreen
  static Future<void> clearData(BuildContext context, {bool keepProducts = false}) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Limpieza de datos deshabilitada temporalmente."),
          backgroundColor: Colors.orange,
        )
      );
    }
  }
}
