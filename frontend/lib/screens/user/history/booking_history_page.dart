import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: BookingHistoryPage()));

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text('Booking History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search booking history...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F2F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // List of Bookings
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                BookingCard(
                  id: "#QFJ-45879",
                  title: "Fix Leaky Faucet",
                  category: "Plumbing Job",
                  provider: "Ankit Sharma",
                  date: "24 April 2024",
                  time: "10:00 AM - 11:30 AM",
                  price: "2,500",
                  categoryColor: Colors.orange,
                ),
                BookingCard(
                  id: "#QFJ-45762",
                  title: "Electrical Panel Repair",
                  category: "Mr. Ashwani",
                  provider: "22 April 2024",
                  date: "22 April 2024",
                  time: "09:00 AM - 10:00 AM",
                  price: "1,500",
                  categoryColor: Colors.green,
                ),
                BookingCard(
                  id: "#QFJ-45649",
                  title: "Celling Fan Installation",
                  category: "Amita Verma",
                  provider: "21 April 2024",
                  date: "21 April 2024",
                  time: "03:00 PM - 04:00 PM",
                  price: "450",
                  categoryColor: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String id, title, category, provider, date, time, price;
  final Color categoryColor;

  const BookingCard({
    super.key, required this.id, required this.title, required this.category,
    required this.provider, required this.date, required this.time,
    required this.price, required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 25, backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.person, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: categoryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(category, style: TextStyle(color: categoryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 6, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(provider, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text("Completed", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("₹$price Paid", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              )
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text("$date • $time", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C8EEF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                ),
                child: const Text("View Details", style: TextStyle(fontSize: 12)),
              )
            ],
          )
        ],
      ),
    );
  }
}