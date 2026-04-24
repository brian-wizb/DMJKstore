import 'package:cloud_firestore/cloud_firestore.dart';

class Product { 
  final String id;
  final String title;
  final double price;
  final List<String> mediaUrls;
  final String category;
  final Map<String, String> specs;
  final Timestamp? timestamp; // Added timestamp for "NEW" badge
  final bool available;       // ✅ New field

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.mediaUrls,
    required this.category,
    this.specs = const {}, // Default value
    this.timestamp,        // Optional
    this.available = true, // Default to true
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      title: data['title'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      category: data['category'] ?? '',
      specs: Map<String, String>.from(data['specs'] ?? {}),
      timestamp: data['timestamp'],
      available: data['available'] ?? true, // ✅ Load availability
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'mediaUrls': mediaUrls,
      'category': category,
      'specs': specs,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'available': available, // ✅ Save availability
    };
  }
}
