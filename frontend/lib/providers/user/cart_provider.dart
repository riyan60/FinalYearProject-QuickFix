import 'package:flutter/material.dart';
import '../../models/service_model.dart';

class CartProvider with ChangeNotifier {
  final List<Service> _cartItems = [];

  List<Service> get cartItems => _cartItems;

  String _normalizeCategory(String value) {
    return value.trim().toLowerCase();
  }

  String? get primaryCategory {
    if (_cartItems.isEmpty) return null;
    return _normalizeCategory(_cartItems.first.category);
  }

  bool hasCategoryConflict(Service service) {
    final existingCategory = primaryCategory;
    if (existingCategory == null) return false;
    return existingCategory != _normalizeCategory(service.category);
  }

  void addService(Service service) {
    _cartItems.add(service);
    notifyListeners();
  }

  void replaceCartWith(Service service) {
    _cartItems
      ..clear()
      ..add(service);
    notifyListeners();
  }

  void removeService(Service service) {
    _cartItems.remove(service);
    notifyListeners();
  }

  void decrementService(String serviceId) {
    final index = _cartItems.indexWhere((item) => item.id == serviceId);
    if (index == -1) return;
    _cartItems.removeAt(index);
    notifyListeners();
  }

  int quantityFor(String serviceId) {
    return _cartItems.where((item) => item.id == serviceId).length;
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.price);
}
