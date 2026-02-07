import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

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
            icon: Icons.inventory_2,
            title: "Gestionar Productos",
            subtitle: "Crear, editar precios e imágenes",
            onTap: () {
              // Navigator.pushNamed(context, '/admin_products');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente: ABM Productos")));
            },
          ),
          _AdminMenuCard(
            icon: Icons.local_shipping,
            title: "Reabastecimiento en Ruta",
            subtitle: "Ingresar stock de Cajas/Piezas",
            onTap: () {
              // Navigator.pushNamed(context, '/admin_restock');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente: Reabastecimiento")));
            },
          ),
          _AdminMenuCard(
            icon: Icons.bar_chart,
            title: "Reportes y Cierre",
            subtitle: "Ver ventas, arqueos y exportar",
            onTap: () {
               // Navigator.pushNamed(context, '/admin_reports');
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente: Reportes")));
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
