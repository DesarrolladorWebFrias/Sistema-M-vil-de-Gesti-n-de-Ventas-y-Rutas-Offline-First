import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Cerrar sesión y volver al inicio (Ventas o Splash)
              Navigator.pushNamedAndRemoveUntil(context, '/sales', (route) => false);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminMenuCard(
            icon: Icons.inventory,
            title: "Gestión de Productos",
            subtitle: "Altas, bajas y modificación de precios",
            onTap: () {
              Navigator.pushNamed(context, '/product_management');
            },
          ),
          const SizedBox(height: 16),
          // Nuevo Modulo Respaldo
           _AdminMenuCard(
            icon: Icons.settings_backup_restore,
            title: "Respaldo y Datos",
            subtitle: "Exportar DB, Importar y Vaciar Datos",
            onTap: () {
              Navigator.pushNamed(context, '/backup');
            },
          ),
          _AdminMenuCard(
            icon: Icons.local_shipping,
            title: "Reabastecimiento en Ruta",
            subtitle: "Ingresar stock de Cajas/Piezas",
            onTap: () {
               Navigator.pushNamed(context, '/admin_restock');
            },
          ),

        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
      ),
    );
  }
}
