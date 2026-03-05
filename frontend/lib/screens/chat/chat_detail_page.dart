import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Provider Info Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage('https://placeholder.com/user_avatar'), // Replace with actual asset
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: CircleAvatar(radius: 6, backgroundColor: Colors.white, child: CircleAvatar(radius: 4, backgroundColor: Colors.green)),
                    )
                  ],
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ankit Sharma", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Green Park Apartment, Flat 12B,", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green),
                        SizedBox(width: 4),
                        Text("Online", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Chat Messages List
          Expanded(
            child: Container(
              color: const Color(0xFFF9F9FF),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ChatBubble(
                    message: "Hi, Ankit. I'll be arriving at your apartment in about 20-25 minutes. Is that ok with you?",
                    time: "9:32 AM",
                    isSender: false,
                  ),
                  ChatBubble(
                    message: "Hi, sounds good! I'll be ready.",
                    time: "9:33 AM",
                    isSender: true,
                  ),
                  ChatBubble(
                    message: "Great, I'll see you soon!",
                    time: "9:33 AM",
                    isSender: false,
                  ),
                  ChatBubble(
                    message: "See you!",
                    time: "9:33 AM",
                    isSender: true,
                  ),
                ],
              ),
            ),
          ),

          // Message Input Bar
          _buildMessageInput(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.send_outlined, color: Colors.grey, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFA5C9FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2C64C6)),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSender;

  const ChatBubble({super.key, required this.message, required this.time, required this.isSender});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isSender ? const Color(0xFFE0E7FF) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isSender ? 15 : 0),
                bottomRight: Radius.circular(isSender ? 0 : 15),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}                                                                         