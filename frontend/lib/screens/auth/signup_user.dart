import 'package:flutter/material.dart';
import 'login_page.dart';

class SignupUser extends StatefulWidget {
  const SignupUser({super.key});

  @override
  State<SignupUser> createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Logo Circle
            Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Signup as User", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500)),
            const SizedBox(height: 30),
            _buildSignupField(Icons.person_outline, "Full name"),
            _buildSignupField(Icons.phone_outlined, "Phone No"),
            _buildSignupField(Icons.email_outlined, "Email"),
            _buildSignupField(Icons.lock_outline, "Password", isPassword: true, showVisibilityIcon: true),
            _buildSignupField(Icons.lock_outline, "Confirm Password", isPassword: true, showVisibilityIcon: true, isConfirmPassword: true),
            const SizedBox(height: 20),
            
            // Create Account Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A94D6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: const Text("Create account", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text("Or", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            // Social Buttons
            _socialButton('assets/images/apple_logo.png', "Sign up with Apple", Colors.white, Colors.black),
            const SizedBox(height: 20),
            _socialButton('assets/images/google_logo.png', "Sign up with Google", Colors.white, Colors.black),
            
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text("sign in", style: TextStyle(color: Color(0xFF6A94D6), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupField(IconData icon, String hint, {bool isPassword = false, bool showVisibilityIcon = false, bool isConfirmPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        obscureText: isPassword && (isConfirmPassword ? !_showConfirmPassword : !_showPassword),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          suffixIcon: showVisibilityIcon 
            ? IconButton(
                icon: Icon(
                  (isConfirmPassword ? _showConfirmPassword : _showPassword) 
                    ? Icons.visibility_outlined 
                    : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirmPassword) {
                      _showConfirmPassword = !_showConfirmPassword;
                    } else {
                      _showPassword = !_showPassword;
                    }
                  });
                },
              )
            : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        ),
      ),
    );
  }

  Widget _buildSocialRow(IconData icon, String label, {Color iconColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _socialButton(String assetPath, String label, Color backgroundColor, Color textColor) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming Soon')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, height: 35, width: 35),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }
}

