import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user/cart_provider.dart';
import '../cart/cart_page.dart';

class BookingSummaryPage extends StatelessWidget {
  const BookingSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.cartItems;
        return Scaffold(
          appBar: AppBar(title: const Text('Booking Summary')),
          body: cartItems.isEmpty
              ? const Center(child: Text('No services selected yet.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...cartItems.map(
                      (service) => Card(
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(service.description),
                          trailing: Text(
                            'Rs ${service.price.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total amount',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Rs ${cartProvider.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CartPage(),
                                    ),
                                  );
                                },
                                child: const Text('Continue to scheduling'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
