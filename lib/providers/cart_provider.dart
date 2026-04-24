import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(String id, String title, double price) {
    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existing) => CartItem(
          id: existing.id,
          title: existing.title,
          quantity: existing.quantity + 1,
          price: existing.price,
        ),
      );
    } else {
      _items[id] = CartItem(
        id: id,
        title: title,
        quantity: 1,
        price: price,
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
}
