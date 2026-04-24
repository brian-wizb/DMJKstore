import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/product_item.dart';
import '../models/product.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String selectedCategory;

  const CategoryProductsScreen({super.key, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalInset =
        screenWidth >= 1200 ? (screenWidth - 1100) / 2 : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(selectedCategory)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: selectedCategory)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No products found in this category.'));
          }

          final products = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Product(
              id: doc.id,
              title: data['title'] ?? '',
              price: (data['price'] ?? 0).toDouble(),
              category: data['category'] ?? '',
              mediaUrls: (data['mediaUrls'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [],
            );
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1200
                  ? 4
                  : constraints.maxWidth >= 900
                      ? 3
                      : 2;

              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                    10 + horizontalInset, 10, 10 + horizontalInset, 10),
                itemCount: products.length,
                itemBuilder: (ctx, i) => ProductItem(product: products[i]),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: columns >= 3 ? 0.68 : 3 / 4.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
