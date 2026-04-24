import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'admin_orders_screen.dart';
import 'edit_product_screen.dart';

class AdminProductScreen extends StatefulWidget {
  static const routeName = '/admin-product';
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToEditProduct({Product? product}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: product ??
              Product(
                id: '',
                title: '',
                price: 0,
                mediaUrls: [],
                category: '',
                specs: {},
                available: true,
              ),
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete product: $e')));
      }
    }
  }

  Future<void> _toggleProductAvailability(Product product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update({'available': !product.available});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${product.title} is now ${product.available ? 'hidden' : 'visible'} to users'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const gradientColors = [Color(0xFF1B5E20), Color(0xFF388E3C)];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(124),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      const Text('Admin Panel',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('DMJK Store', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(icon: Icon(Icons.inventory_2_outlined, size: 20), text: 'Products'),
                    Tab(icon: Icon(Icons.receipt_long_outlined, size: 20), text: 'Orders'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.green.shade600),
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
              ),

              // Product list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Colors.green.shade700));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }

                    final products = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Product(
                        id: doc.id,
                        title: data['title'] ?? '',
                        price: (data['price'] ?? 0).toDouble(),
                        mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
                        category: data['category'] ?? '',
                        specs: Map<String, String>.from(data['specs'] ?? {}),
                        available: data['available'] ?? true,
                      );
                    }).where((p) => p.title.toLowerCase().contains(_searchQuery)).toList();

                    if (products.isEmpty) {
                      return const Center(child: Text('No matching products.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: products.length,
                      itemBuilder: (ctx, i) {
                        final product = products[i];
                        final firstMedia = product.mediaUrls.isNotEmpty ? product.mediaUrls.first : null;
                        final isAvailable = product.available;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 60, height: 60,
                                    child: firstMedia != null
                                        ? (firstMedia.endsWith('.mp4')
                                            ? Container(color: Colors.green.shade50, child: Icon(Icons.videocam, color: Colors.green.shade400, size: 30))
                                            : Image.network(firstMedia, fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported))))
                                        : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported)),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.title,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'TZS ${product.price.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: isAvailable ? Colors.green.shade300 : Colors.grey.shade300),
                                            ),
                                            child: Text(
                                              isAvailable ? 'Visible' : 'Hidden',
                                              style: TextStyle(
                                                color: isAvailable ? Colors.green.shade700 : Colors.grey.shade500,
                                                fontSize: 11, fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (product.category.isNotEmpty)
                                        Text(product.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                    ],
                                  ),
                                ),

                                // Actions
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _actionIcon(Icons.edit_outlined, Colors.blue.shade600,
                                        () => _navigateToEditProduct(product: product)),
                                    const SizedBox(height: 6),
                                    _actionIcon(Icons.delete_outline, Colors.red.shade400,
                                        () => _confirmDelete(product)),
                                    const SizedBox(height: 6),
                                    _actionIcon(
                                      isAvailable ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      isAvailable ? Colors.orange.shade600 : Colors.grey.shade500,
                                      () => _toggleProductAvailability(product),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const AdminOrdersScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              onPressed: () => _navigateToEditProduct(),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: _tabController.index == 0
          ? BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              color: Colors.white,
              elevation: 8,
              child: const SizedBox(height: 50),
            )
          : null,
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
