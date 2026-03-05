import 'package:flutter/material.dart';

class PaymentOptionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () {}),
        title: const Text("Payment Options", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Detail Card
            _buildServiceCard(),
            const SizedBox(height: 20),

            // Coupon Section
            _buildCouponSection(),
            const SizedBox(height: 20),

            // Booking Summary
            const Text("Booking Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSummaryCard(),
            const SizedBox(height: 20),

            // Payment Methods
            const Text("Payment Methods", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPaymentMethods(),
            const SizedBox(height: 30),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Confirm & Pay", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text("Free cancellation before 1 hour of booking time.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.plumbing, color: Colors.orange, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Plumbing - Fix Leak", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Sep 10, 2026 • 10:00 AM - 11:00 AM", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const Text("Amit Sharma", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const Text("123 Main St, Mumbai", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            TextButton(onPressed: () {}, child: const Text("Edit Booking >", style: TextStyle(color: Colors.orange)))
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Enter coupon code...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Apply"),
        )
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          _summaryRow("Service Fees (18%)", "₹ 550"),
          _summaryRow("Visiting Charges", "₹ 200"),
          _summaryRow("Discount", "- ₹ 100", isDiscount: true),
          const Divider(),
          _summaryRow("Total Amount", "₹ 650", isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.green : Colors.black,
            fontSize: isTotal ? 18 : 14,
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _paymentTile("UPI / Net Banking", true),
        _paymentTile("Credit / Debit Card", false),
        _paymentTile("Wallet (Paytm, PhonePe)", false),
        _paymentTile("Cash on Service", false),
      ],
    );
  }

  Widget _paymentTile(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.orange : Colors.grey),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Booking"),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Map"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
