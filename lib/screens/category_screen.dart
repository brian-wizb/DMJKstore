import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category_products_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalInset = width >= 1200 ? (width - 1100) / 2 : 0.0;

    return Column(
      children: [
        // Gradient header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse all product categories',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search categories...',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.green.shade700),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.toLowerCase()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Categories grid
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                        color: Colors.green.shade700));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState('No categories found.');
              }

              final products = snapshot.data!.docs;

              // Map category -> {image, count}
              final Map<String, String> categoryImages = {};
              final Map<String, int> categoryCounts = {};
              for (var doc in products) {
                final data = doc.data() as Map<String, dynamic>;
                final category = data['category'] as String?;
                final mediaUrls = data['mediaUrls'] as List<dynamic>?;
                if (category != null && category.isNotEmpty) {
                  categoryCounts[category] =
                      (categoryCounts[category] ?? 0) + 1;
                  if (!categoryImages.containsKey(category) &&
                      mediaUrls != null &&
                      mediaUrls.isNotEmpty) {
                    categoryImages[category] = mediaUrls.first.toString();
                  }
                }
              }

              final filteredCategories = categoryImages.keys
                  .where((c) => c.toLowerCase().contains(_searchQuery))
                  .toList()
                ..sort();

              if (filteredCategories.isEmpty) {
                return _emptyState('No matching categories.');
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                    12 + horizontalInset, 12, 12 + horizontalInset, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1200
                        ? 4
                        : constraints.maxWidth >= 900
                            ? 3
                            : 2;

                    return GridView.builder(
                      itemCount: filteredCategories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: columns >= 3 ? 0.95 : 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (ctx, index) {
                        final category = filteredCategories[index];
                        final imageUrl = categoryImages[category];
                        final count = categoryCounts[category] ?? 0;

                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CategoryProductsScreen(
                                  selectedCategory: category),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Image
                                  if (imageUrl != null)
                                    Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.green.shade50,
                                        child: Icon(Icons.category,
                                            size: 60,
                                            color: Colors.green.shade300),
                                      ),
                                    )
                                  else
                                    Container(
                                      color: Colors.green.shade50,
                                      child: Icon(Icons.category,
                                          size: 60,
                                          color: Colors.green.shade300),
                                    ),

                                  // Gradient overlay
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color(0xDD000000)
                                        ],
                                        stops: [0.45, 1.0],
                                      ),
                                    ),
                                  ),

                                  // Text & badge
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 0, 10, 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            category,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade600,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$count item${count == 1 ? '' : 's'}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}
