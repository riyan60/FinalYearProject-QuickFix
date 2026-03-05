import 'package:flutter/material.dart';
import '../../models/service_model.dart';

class CartProvider with ChangeNotifier {
  final List<Service> _cartItems = [];

  List<Service> get cartItems => _cartItems;

  void addService(Service service) {
    _cartItems.add(service);
    notifyListeners();
  }

  void removeService(Service service) {
    _cartItems.remove(service);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.price);
}
