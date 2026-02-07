import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  void _login() {
    // Contraseña Maestra definida en requerimientos
    const String masterPassword = "Lu15Fr1@52026"; 

    if (_passwordController.text == masterPassword) {
      // Navegar al Panel de Administración y eliminar historial de navegación para evitar volver al login con "Atrás"
      Navigator.pushReplacementNamed(context, '/admin_home');
    } else {
      setState(() {
        _errorMessage = "Contraseña incorrecta";
      });
      // Vibrar o feedback visual adicional podría ir aquí
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Acceso Administrativo"),
        backgroundColor: Colors.blueGrey, // Color diferente para distinguir modo admin
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            const Text(
              "Ingrese la Clave Maestra",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
                child: const Text("INGRESAR"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
