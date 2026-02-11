import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/models/producto.dart';
import '../../providers/product_provider.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar productos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  void _showProductDialog(BuildContext context, {Producto? product}) {
    showDialog(
      context: context,
      builder: (context) => _ProductDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Productos"),
        backgroundColor: Colors.blueGrey,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add),
        onPressed: () => _showProductDialog(context),
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : productProvider.products.isEmpty
              ? const Center(child: Text("No hay productos registrados"))
              : ListView.builder(
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: product.imagenPath != null
                            ? Image.file(File(product.imagenPath!), width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        title: Text(product.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Precio: \$${product.precio.toStringAsFixed(2)} | Costo: \$${product.costo.toStringAsFixed(2)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showProductDialog(context, product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Confirmar"),
                                    content: Text("¿Eliminar ${product.nombre}?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  productProvider.deleteProduct(product.id!);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Producto? product;

  const _ProductDialog({this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _piezasPorCajaController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.nombre ?? '');
    _priceController = TextEditingController(text: widget.product?.precio.toString() ?? '');
    _costController = TextEditingController(text: widget.product?.costo.toString() ?? '');
    _piezasPorCajaController = TextEditingController(text: widget.product?.piezasPorCaja.toString() ?? '12'); // Default 12
    _imagePath = widget.product?.imagenPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final cost = double.tryParse(_costController.text) ?? 0.0;
      final piezasCaja = int.tryParse(_piezasPorCajaController.text) ?? 12;

      final newProduct = Producto(
        id: widget.product?.id,
        nombre: name,
        precio: price,
        costo: cost,
        imagenPath: _imagePath,
        stockCajas: widget.product?.stockCajas ?? 0,
        stockPiezas: widget.product?.stockPiezas ?? 0,
        piezasPorCaja: piezasCaja, // Guardar valor
      );

      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (widget.product == null) {
        provider.addProduct(newProduct);
      } else {
        provider.updateProduct(newProduct);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? "Nuevo Producto" : "Editar Producto"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               // ... Image Picker (omitted for brevity in replacement if possible, but easier to include entire MainAxisSize.min block if contiguous)
               GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Galería'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Cámara'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                  child: _imagePath == null ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nombre del Producto"),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: "Precio Venta"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(labelText: "Costo Real"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _piezasPorCajaController,
                decoration: const InputDecoration(
                  labelText: "Piezas por Caja",
                  helperText: "Ej: 12 para litros, 27 para lechitas",
                  border: OutlineInputBorder()
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Requerido" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: _saveProduct,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          child: const Text("Guardar"),
        ),
      ],
    );
  }
}
