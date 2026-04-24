import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitOrder({
    required List<CartItem> items,
    required String type, // "pickup" or "delivery"
    String? phone,
    String? address,
  }) async {
    final orderData = {
      'type': type,
      'timestamp': Timestamp.now(),
      'phone': phone,
      'address': address,
      'items':
          items
              .map(
                (item) => {
                  'title': item.title,
                  'price': item.price,
                  'quantity': item.quantity,
                },
              )
              .toList(),
    };

    await _db.collection('orders').add(orderData);
  }
}
