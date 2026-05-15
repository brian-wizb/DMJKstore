import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/product.dart';
import '../widgets/product_item.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import '../providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  List<Product> _matchedProducts = [];
  bool _isLoading = false;
  String _statusMessage = '';

  List<Product>? _filteredProductsCache;
  String? _lastSearchQuery;

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _matchedProducts = [];
      _statusMessage = '';
    });
  }

  void _setStatusMessage(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    setState(() => _statusMessage = message);
    Future.delayed(duration, () {
      if (mounted) setState(() => _statusMessage = '');
    });
  }

  String _normalizeLabel(String label) {
    final cleaned = label
        .toLowerCase()
        .replaceAll(
            RegExp(r'the product in the image is (a|an)?\s*',
                caseSensitive: false),
            '')
        .trim();
    debugPrint("🔍 Cleaned label: $cleaned");
    return cleaned;
  }

  Future<Uint8List> _compressImage(File file) async {
    return await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 800,
          minHeight: 800,
          quality: 40,
        ) ??
        await file.readAsBytes();
  }

  Future<void> _captureAndIdentify() async {
    final picker = ImagePicker();
    final pickedImage =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedImage == null) return;

    setState(() {
      _isLoading = true;
      _matchedProducts = [];
    });
    _setStatusMessage('Analyzing image...');

    try {
      final compressedBytes = await _compressImage(File(pickedImage.path));
      final base64Image = base64Encode(compressedBytes);

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('identifyProductFromImage');
      final result = await callable.call({'imageBase64': base64Image});
      final data = Map<String, dynamic>.from(result.data as Map);
      final label = (data['label'] ?? '').toString().trim();

      if (label.isEmpty) {
        _setStatusMessage("Failed to analyze image. Try again.");
        return;
      }

      final cleanedLabel = _normalizeLabel(label);
      debugPrint("🧠 Identified: $label -> $cleanedLabel");

      _setStatusMessage('Matching with store products...');
      await _matchProducts(cleanedLabel);
    } on FirebaseFunctionsException catch (e) {
      debugPrint("❌ Function error: ${e.code} ${e.message}");
      _setStatusMessage("Image analysis unavailable right now.");
    } catch (e) {
      debugPrint("❌ Error: $e");
      _setStatusMessage("An error occurred during analysis.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _matchProducts(String label) async {
    final labelWords = label.toLowerCase().split(' ');

    final querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    final allProducts = querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          Map<String, String> specsMap = {};
          if (data['specs'] != null) {
            final specsDynamic = data['specs'] as Map<dynamic, dynamic>;
            specsMap = specsDynamic.map(
                (key, value) => MapEntry(key.toString(), value.toString()));
          }

          return Product(
            id: doc.id,
            title: data['title'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            category: data['category'] ?? '',
            mediaUrls: (data['mediaUrls'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
            specs: specsMap,
            timestamp: data['timestamp'],
            available: data['available'] ?? true, // Hide unavailable
          );
        })
        .where((product) => product.available) // <-- hide
        .toList();

    final matches = allProducts.where((product) {
      final lowerTitle = product.title.toLowerCase();
      final lowerCategory = product.category.toLowerCase();
      return labelWords.any(
          (word) => lowerTitle.contains(word) || lowerCategory.contains(word));
    }).toList();

    setState(() => _matchedProducts = _sortNewOnTop(matches));

    _setStatusMessage(
      matches.isEmpty
          ? '❌ No matching product found for: "$label"'
          : '✅ Matched: ${label[0].toUpperCase()}${label.substring(1)}',
    );
  }

  List<Product> _filterProducts(List<Product> products, String query) {
    if (_lastSearchQuery == query && _filteredProductsCache != null) {
      return _filteredProductsCache!;
    }
    final filtered = products
        .where((product) =>
            product.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    _lastSearchQuery = query;
    _filteredProductsCache = filtered;
    return filtered;
  }

  List<Product> _sortNewOnTop(List<Product> products) {
    final now = DateTime.now();
    products.sort((a, b) {
      final aIsNew = a.specs['isNew'] == 'true' ||
          (a.timestamp != null &&
              now.difference(a.timestamp!.toDate()).inDays <= 7);
      final bIsNew = b.specs['isNew'] == 'true' ||
          (b.timestamp != null &&
              now.difference(b.timestamp!.toDate()).inDays <= 7);

      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;
      return 0;
    });
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: _selectedIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(112),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x332E7D32),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1220),
                      child: Column(
                        children: [
                          // Brand row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/dmjklogo.png',
                                    width: 34,
                                    height: 34,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'DMJK Store',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, '/admin-login'),
                                  icon: const Icon(Icons.admin_panel_settings,
                                      color: Colors.white70, size: 22),
                                  tooltip: 'Admin',
                                ),
                              ],
                            ),
                          ),
                          // Search row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                          _matchedProducts = [];
                                          _statusMessage = '';
                                        });
                                      },
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Search products...',
                                        hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14),
                                        prefixIcon: Icon(Icons.search,
                                            color: Colors.grey[500], size: 20),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 11),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _captureAndIdentify,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(21),
                                      border: Border.all(
                                          color: Colors.white38, width: 1),
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text('Analyzing image...',
                      style: TextStyle(color: Color(0xFF2E7D32))),
                ],
              ),
            )
          : _selectedIndex == 0
              ? Column(
                  children: [
                    if (_statusMessage.isNotEmpty)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1220),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _statusMessage.startsWith('✅')
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _statusMessage.startsWith('✅')
                                    ? const Color(0xFFA5D6A7)
                                    : const Color(0xFFEF9A9A),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _statusMessage.startsWith('✅')
                                      ? Icons.check_circle_outline
                                      : Icons.info_outline,
                                  color: _statusMessage.startsWith('✅')
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _statusMessage,
                                    style: TextStyle(
                                      color: _statusMessage.startsWith('✅')
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: _matchedProducts.isNotEmpty
                          ? _ProductGrid(
                              products: _matchedProducts,
                              headerLabel: 'Search Results',
                            )
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('products')
                                  .snapshots(),
                              builder: (ctx, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF2E7D32)));
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.storefront_outlined,
                                            size: 64, color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        Text('No products yet',
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 16)),
                                      ],
                                    ),
                                  );
                                }

                                final products = snapshot.data!.docs
                                    .map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      Map<String, String> specsMap = {};
                                      if (data['specs'] != null) {
                                        final specsDynamic = data['specs']
                                            as Map<dynamic, dynamic>;
                                        specsMap = specsDynamic.map(
                                            (key, value) => MapEntry(
                                                key.toString(),
                                                value.toString()));
                                      }
                                      return Product(
                                        id: doc.id,
                                        title: data['title'] ?? '',
                                        price: (data['price'] ?? 0).toDouble(),
                                        category: data['category'] ?? '',
                                        mediaUrls: (data['mediaUrls']
                                                    as List<dynamic>? ??
                                                [])
                                            .map((e) => e.toString())
                                            .toList(),
                                        specs: specsMap,
                                        timestamp: data['timestamp'],
                                        available: data['available'] ?? true,
                                      );
                                    })
                                    .where((product) => product.available)
                                    .toList();

                                final filteredProducts =
                                    _filterProducts(products, _searchQuery);
                                final sortedProducts =
                                    _sortNewOnTop(filteredProducts);

                                return _ProductGrid(
                                  products: sortedProducts,
                                  showBanner: _searchQuery.isEmpty,
                                  headerLabel: _searchQuery.isNotEmpty
                                      ? 'Results for "$_searchQuery"'
                                      : 'Featured Products',
                                );
                              },
                            ),
                    ),
                  ],
                )
              : _selectedIndex == 1
                  ? const CategoryScreen()
                  : CartScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavTapped,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Shop',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: const _CartTabIcon(active: false),
              activeIcon: const _CartTabIcon(active: true),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final String headerLabel;
  final bool showBanner;

  const _ProductGrid({
    required this.products,
    required this.headerLabel,
    this.showBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth >= 1440
        ? 1260.0
        : screenWidth >= 1200
            ? 1140.0
            : 900.0;
    final horizontalInset =
        ((screenWidth - maxContentWidth) / 2).clamp(0.0, double.infinity);
    final isDesktop = screenWidth >= 1024;
    final gridColumns = screenWidth >= 1380
        ? 5
        : screenWidth >= 1200
            ? 4
            : screenWidth >= 900
                ? 3
                : 2;

    return CustomScrollView(
      key: const PageStorageKey('productListScrollPosition'),
      slivers: [
        if (showBanner)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  12 + horizontalInset, 14, 12 + horizontalInset, 0),
              child: Container(
                height: isDesktop ? 124 : 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(Icons.storefront,
                          size: 110, color: Colors.white.withOpacity(0.08)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Welcome to DMJK Store',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Discover our latest products & deals',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16 + horizontalInset, 18, 16 + horizontalInset, 6),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  headerLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const Spacer(),
                Text(
                  '${products.length} items',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              12 + horizontalInset, 0, 12 + horizontalInset, 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => ProductItem(product: products[i]),
              childCount: products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              childAspectRatio: isDesktop ? 0.68 : 3 / 4.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// Keep backward-compat alias (used nowhere directly now but safe to retain)
class ProductList extends StatelessWidget {
  final List<Product> products;
  const ProductList({super.key, required this.products});

  @override
  Widget build(BuildContext context) =>
      _ProductGrid(products: products, headerLabel: 'Products');
}

class _CartTabIcon extends StatelessWidget {
  final bool active;

  const _CartTabIcon({required this.active});

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, int>(
      selector: (_, cart) => cart.itemCount,
      builder: (_, itemCount, __) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(active ? Icons.shopping_bag : Icons.shopping_bag_outlined),
            if (itemCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
