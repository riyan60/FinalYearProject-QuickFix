import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

String _getBaseUrl() {
  // Automatically detect the correct IP based on the platform
  if (Platform.isAndroid) {
    // Android Emulator: 10.0.2.2 is the special IP for emulator to access host machine
    // For physical Android devices, you may need to change this to your computer's IP
    return 'http://10.0.2.2:5000';
  } else if (Platform.isIOS) {
    // iOS Simulator: Use localhost
    return 'http://localhost:5000';
  } else {
    // Default for other platforms (web, desktop, etc.)
    return 'http://localhost:5000';
  }
}

class SignupUser extends StatefulWidget {
  const SignupUser({super.key});

  @override
  State<SignupUser> createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // Validate all fields
    if (_nameController.text.trim().isEmpty) {
      _showError("Please enter your full name");
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError("Please enter your phone number");
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter your email");
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError("Please enter a password");
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _showError("Please confirm your password");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the appropriate base URL based on the platform
      final String baseUrl = _getBaseUrl();

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _nameController.text.trim(),
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'address': _phoneController.text
              .trim(), // Using phone as address for now
          'role': 'client',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        _showError(errorData['message'] ?? 'Failed to create account');
      }
    } catch (e) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

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
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
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
            const Text(
              "Signup as User",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            _buildSignupField(
              Icons.person_outline,
              "Full name",
              controller: _nameController,
            ),
            _buildSignupField(
              Icons.phone_outlined,
              "Phone No",
              controller: _phoneController,
            ),
            _buildSignupField(
              Icons.email_outlined,
              "Email",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildSignupField(
              Icons.lock_outline,
              "Password",
              isPassword: true,
              showVisibilityIcon: true,
              controller: _passwordController,
            ),
            _buildSignupField(
              Icons.lock_outline,
              "Confirm Password",
              isPassword: true,
              showVisibilityIcon: true,
              isConfirmPassword: true,
              controller: _confirmPasswordController,
            ),
            const SizedBox(height: 20),

            // Create Account Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A94D6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Create account",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Or", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Social Buttons
            _socialButton(
              'assets/images/apple_logo.png',
              "Sign up with Apple",
              Colors.white,
              Colors.black,
            ),
            const SizedBox(height: 20),
            _socialButton(
              'assets/images/google_logo.png',
              "Sign up with Google",
              Colors.white,
              Colors.black,
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "sign in",
                    style: TextStyle(
                      color: Color(0xFF6A94D6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupField(
    IconData icon,
    String hint, {
    bool isPassword = false,
    bool showVisibilityIcon = false,
    bool isConfirmPassword = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText:
            isPassword &&
            (isConfirmPassword ? !_showConfirmPassword : !_showPassword),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRow(
    IconData icon,
    String label, {
    Color iconColor = Colors.black,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _socialButton(
    String assetPath,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Coming Soon')));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, height: 35, width: 35),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
