import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/producto.dart';

class ProductCarousel extends StatefulWidget {
  final List<Producto> products;
  final Function(Producto) onProductSelected;

  const ProductCarousel({
    Key? key, 
    required this.products, 
    required this.onProductSelected
  }) : super(key: key);

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.33); // Mostrar 3 items
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox(
        height: 200, 
        child: Center(child: Text("Sin productos disponibles"))
      );
    }

    return SizedBox(
      height: 220, // Altura del carrusel
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.products.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final product = widget.products[index];
          // Calcular escala para efecto visual (el del centro más grande)
          // Nota: Con viewportFraction 0.33, el efecto es sutil.
          
          return GestureDetector(
            onTap: () => widget.onProductSelected(product),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ],
                border: Border.all(
                  color: Colors.blueGrey.withOpacity(0.2), 
                  width: 1
                )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: product.imagenPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(product.imagenPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.local_drink, size: 50, color: Colors.blue),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          product.nombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "\$${product.precio.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
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
