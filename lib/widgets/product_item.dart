import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../screens/product_detail_screen.dart';

class ProductItem extends StatelessWidget {
  static OverlayEntry? _activeToastEntry;

  final Product product;

  const ProductItem({super.key, required this.product});

  bool get isNew {
    if (product.timestamp == null) return false;
    final now = DateTime.now();
    final addedDate = product.timestamp!.toDate();
    return now.difference(addedDate).inHours <= 24;
  }

  String _formatPrice(double price) {
    final parts = price.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i != 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return 'TZS ${buffer.toString()}';
  }

  void _showAddToCartPopup(BuildContext context, String title) {
    _activeToastEntry?.remove();
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _activeToastEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(ctx).padding.bottom + 18,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$title added to cart',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_activeToastEntry!);
    Future.delayed(const Duration(milliseconds: 1400), () {
      _activeToastEntry?.remove();
      _activeToastEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.mediaUrls.isNotEmpty
                      ? Image.network(
                          product.mediaUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF1F8E9),
                            child: const Icon(Icons.broken_image_outlined,
                                color: Colors.grey, size: 40),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF1F8E9),
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: Colors.grey, size: 40),
                        ),
                  // Gradient fade at bottom of image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // NEW badge
                  if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1B2A1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(product.price),
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          cart.addItem(
                              product.id, product.title, product.price);
                          _showAddToCartPopup(context, product.title);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_shopping_cart_outlined, size: 14),
                            SizedBox(width: 4),
                            Text('Add to Cart',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
