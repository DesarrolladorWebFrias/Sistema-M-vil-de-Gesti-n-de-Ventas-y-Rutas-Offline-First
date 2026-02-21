import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/producto.dart';

class ProductCarousel extends StatefulWidget {
  final List<Producto> products;
  final Function(Producto) onProductSelected;

  const ProductCarousel({
    super.key, 
    required this.products, 
    required this.onProductSelected
  });

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.4); // Restaurado a 0.4
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getStockColor(int stockCajas, int stockPiezas) {
    int totalPiezas = (stockCajas * 12) + stockPiezas; // Asumiendo 12 piezas por caja
    if (totalPiezas > 50) return Colors.green;
    if (totalPiezas > 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox(
        height: 280, 
        child: Center(child: Text("Sin productos disponibles"))
      );
    }

    return SizedBox(
      height: 300, // Altura restaurada a 300 como pidió el usuario
      child: PageView.builder(
        controller: _pageController,
        pageSnapping: false, // Scroll libre sin "imanes"
        itemCount: widget.products.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final product = widget.products[index];
          
          // Calcular escala para efecto visual (el del centro más grande)
          bool isCenter = index == _currentPage;
          double scale = isCenter ? 1.0 : 0.85;
          
          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              onTap: () {
                widget.onProductSelected(product);
                _pageController.animateToPage(
                  index, 
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut
                );
              },
              behavior: HitTestBehavior.opaque, // Asegurar detección de toques incluso en imágenes
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isCenter 
                        ? Colors.blue.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.1),
                      blurRadius: isCenter ? 15 : 5,
                      spreadRadius: isCenter ? 2 : 0,
                      offset: const Offset(0, 3),
                    )
                  ],
                  border: Border.all(
                    color: isCenter 
                      ? Colors.blue.withValues(alpha: 0.8)
                      : Colors.blueGrey.withValues(alpha: 0.2), 
                    width: isCenter ? 3 : 1
                  )
                ),
                child: Stack(
                  children: [
                    // Contenido principal
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: product.imagenPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: product.imagenPath!.startsWith('assets/') 
                                    ? Image.asset(
                                        product.imagenPath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                      )
                                    : Image.file(
                                        File(product.imagenPath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                      ),
                                )
                              : const Icon(Icons.local_drink, size: 60, color: Colors.blue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              Text(
                                product.nombre,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: isCenter ? 14 : 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "\$${product.precio.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.green,
                                  fontSize: isCenter ? 16 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Badge de Stock
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStockColor(product.stockCajas, product.stockPiezas),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          "📦${product.stockCajas} | 🧊${product.stockPiezas}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14, // Aumentado de 10
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
