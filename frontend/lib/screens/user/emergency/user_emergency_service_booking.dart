import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class UserEmergencyServiceBookingScreen extends StatelessWidget {
  const UserEmergencyServiceBookingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEFF), // Light blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.notifications_active, color: Colors.orange),
            ),
            const SizedBox(width: 10),
            const Text("Emergency Service", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Service Grid ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                _buildServiceCard("Electrician", Icons.bolt, Colors.red),
                _buildServiceCard("Plumber", Icons.water_drop, Colors.blue),
                _buildServiceCard("AC Repair", Icons.ac_unit, Colors.blueAccent),
                _buildServiceCard("Mechanic", Icons.build, Colors.orange),
              ],
            ),
            const SizedBox(height: 20),

            // --- Location Card ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 30),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Your Location", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("Curchorem Market, Goa", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(backgroundColor: Colors.blue.shade50, shape: StadiumBorder()),
                    child: const Row(children: [Text("Change"), Icon(Icons.chevron_right, size: 16)]),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Description Field ---
            const Text("Describe the issue", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: "Type your problem here...",
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(Icons.send_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // --- Priority Selection ---
            const Text("Priority", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityButton("Normal", false),
                const SizedBox(width: 10),
                _buildPriorityButton("Emergency", true),
              ],
            ),
            const SizedBox(height: 20),

            // --- Technicians List ---
            const Text("Nearest Available Technicians", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildTechnicianTile("Ryan Lobo", "4.8", "1.2 km away"),
            _buildTechnicianTile("Ankit Sharma", "4.0", "2.5 km away"),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // Helper: Service Cards
  Widget _buildServiceCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Helper: Priority Buttons
  Widget _buildPriorityButton(String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.red.shade200) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, 
                 color: isSelected ? Colors.red : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.red : Colors.black54)),
          ],
        ),
      ),
    );
  }

  // Helper: Technician List Tiles
  Widget _buildTechnicianTile(String name, String rating, String dist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(backgroundImage: NetworkImage('https://via.placeholder.com/150')),
        title: Row(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, color: Colors.blue, size: 16),
          ],
        ),
       
        ),
      );
  }

