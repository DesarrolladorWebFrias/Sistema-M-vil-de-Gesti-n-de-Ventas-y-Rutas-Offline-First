import 'package:flutter/material.dart';
import '../../utils/backup_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  Future<void> _exportar() async {
    setState(() => _isLoading = true);
    await BackupHelper.exportDatabase(context);
    setState(() => _isLoading = false);
  }

  Future<void> _importar() async {
    setState(() => _isLoading = true);
    await BackupHelper.importDatabase(context);
    setState(() => _isLoading = false);
  }

  Future<void> _vaciarDatos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ADVERTENCIA - BORRADO DE DATOS"),
        content: const Text(
          "¿Estás seguro de que quieres VACIAR TODOS LOS DATOS?\n\n"
          "Esto borrará:\n"
          "- Historial de Ventas\n"
          "- Rutas y Salidas\n"
          "- Cortes de Caja\n"
          "- Stock de Productos (se pondrá en 0)\n\n"
          "Los productos y sus precios NO se borrarán.",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("BORRAR TODO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      // keepProducts = true para no borrar catálogo
      await BackupHelper.clearData(context, keepProducts: true); 
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Respaldo y Restauración"), backgroundColor: Colors.blueGrey),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Card(
                color: Colors.blueGrey,
                 child: Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Text(
                     "Gestión de Base de Datos\n\nRespalda tu información frecuentemente para evitar pérdidas.",
                     style: TextStyle(color: Colors.white, fontSize: 16),
                     textAlign: TextAlign.center,
                   ),
                 ),
              ),
              const SizedBox(height: 30),

              // Exportar
              ListTile(
                leading: const Icon(Icons.download, size: 40, color: Colors.green),
                title: const Text("Exportar Base de Datos (Respaldo)", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Guarda una copia de seguridad en tu dispositivo o envíala por correo."),
                onTap: _exportar,
              ),
              const Divider(),

              // Importar
              ListTile(
                leading: const Icon(Icons.upload, size: 40, color: Colors.orange),
                title: const Text("Importar Base de Datos (Restaurar)", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Carga un archivo de respaldo (.db) previamente guardado. REEMPLAZARÁ los datos actuales."),
                onTap: _importar,
              ),
              const Divider(),

              const SizedBox(height: 40),
              // ZONA DE PELIGRO
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.red[50]
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, size: 40, color: Colors.red),
                  title: const Text("Vaciar Datos (Reinicio de Fábrica)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: const Text("Borra ventas, cortes y stock. Mantiene los productos registrados."),
                  onTap: _vaciarDatos,
                ),
              ),
            ],
          ),
    );
  }
}
