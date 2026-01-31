import 'package:flutter/material.dart';
import 'home_page.dart';
import 'signup_page.dart';

void main() => runApp(const QuickFixApp());

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Georgia'), // Using Georgia for that Serif look
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showPassword = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Top Illustration with Curve
            Stack(
              children: [
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 380,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF4A89F3), // Bright blue
                          Color(0xFFE8B391), // Peachy tan
                        ],
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Image.asset(
                          'assets/images/header_image.png', // Ensure this image has no background
                          fit: BoxFit.contain,
                          height: 250,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Login Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Serif', 
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Username Field
                  const Text("Username", style: TextStyle(fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFF88B8B), width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFF88B8B), width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password Field
                  const Text("Password", style: TextStyle(fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off_outlined,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFF88B8B), width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFF88B8B), width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(color: Color(0xFF5B89E9), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Sign In Button
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_usernameController.text == '1234' && _passwordController.text == '1234') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        } else {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter valid username and password')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B94E1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Row(
                    children: [
                      Expanded(child: Divider(thickness: 1.5, color: Colors.black)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text("Or", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(thickness: 1.5, color: Colors.black)),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Social Logins
                  _socialButton('assets/images/apple_logo.png', "Login with Apple"),
                  const SizedBox(height: 20),
                  _socialButton('assets/images/google_logo.png', "Login with Google"),

                  const SizedBox(height: 40),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupPage()),
                          );
                        },
                        child: const Text("Register", style: TextStyle(color: Color(0xFF5B89E9), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(String assetPath, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(assetPath, height: 35, width: 35),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// Custom Clipper for the white wave effect
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 100);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 100);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}