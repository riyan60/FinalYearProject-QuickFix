import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'login_page.dart';
import '../location/location_picker_screen.dart';
import '../../core/utils/validators.dart';
import '../../services/api_service.dart';
import '../../services/city_service.dart';

class SignupRepairman extends StatefulWidget {
  const SignupRepairman({super.key});

  @override
  State<SignupRepairman> createState() => _SignupRepairmanState();
}

class _SignupRepairmanState extends State<SignupRepairman> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _isLoadingCities = true;
  LatLng? _selectedLocation;
  final CityService _cityService = CityService();
  List<String> _cities = [];
  String? _selectedCity;

  // Skills dropdown
  final List<String> _skillsList = [
    'Mechanic',
    'Carpenter',
    'AC repair',
    'Electrician',
    'Plumber',
    'Cleaning',
  ];
  final List<int> _experienceYears = List<int>.generate(31, (index) => index);
  String? _selectedSkill;
  int? _selectedExperience;

  // Text Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _cityService.getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _selectedCity = cities.isNotEmpty ? cities.first : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cities = [];
        _selectedCity = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // Validate all fields
    if (_usernameController.text.trim().isEmpty) {
      _showError("Please enter a username");
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError("Please enter your full name");
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter your email");
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError("Please enter your phone number");
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showError("Please enter your address");
      return;
    }
    if ((_selectedCity ?? '').trim().isEmpty) {
      _showError("Please select your city");
      return;
    }
    if (_selectedLocation == null) {
      _showError("Please select your location on map");
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
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    final phoneError = Validators.validatePhone(_phoneController.text);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService().post('/api/auth/register', {
        'username': _usernameController.text.trim(),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _selectedCity!.trim(),
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'role': 'repairman',
        'skills': _selectedSkill ?? '',
        'experience': _selectedExperience ?? 0,
        'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0,
        'bio': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Account created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
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
              "Signup as Repairman",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            _buildSignupField(
              Icons.person_outline,
              "Username",
              controller: _usernameController,
            ),
            _buildSignupField(
              Icons.person_outline,
              "Full name",
              controller: _nameController,
            ),
            _buildSignupField(
              Icons.email_outlined,
              "Email",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildSignupField(
              Icons.phone_outlined,
              "Phone No",
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            _buildSignupField(
              Icons.location_on_outlined,
              "Address",
              controller: _addressController,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.location_city_outlined,
                    color: Colors.grey,
                  ),
                  hintText: _isLoadingCities
                      ? "Loading cities..."
                      : "Select City",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                items: _cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: _isLoadingCities || _cities.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final location = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        initialLocation: _selectedLocation,
                      ),
                    ),
                  );

                  if (location != null && mounted) {
                    setState(() {
                      _selectedLocation = location;
                    });
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  _selectedLocation == null
                      ? 'Select Location'
                      : 'Location Selected (${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)})',
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            // Skills Dropdown
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSkill,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.build, color: Colors.grey),
                  hintText: "Select Skill",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                items: _skillsList.map((skill) {
                  return DropdownMenuItem(
                    value: skill,
                    child: Text(skill),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSkill = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: DropdownButtonFormField<int>(
                initialValue: _selectedExperience,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.work, color: Colors.grey),
                  hintText: "Select experience in years",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                items: _experienceYears.map((years) {
                  final label = years == 1 ? '1 year' : '$years years';
                  return DropdownMenuItem(
                    value: years,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExperience = value;
                  });
                },
              ),
            ),
            _buildSignupField(
              Icons.attach_money,
              "Hourly Rate",
              controller: _hourlyRateController,
              keyboardType: TextInputType.number,
            ),
            _buildSignupField(
              Icons.description,
              "Description",
              controller: _descriptionController,
              maxLines: 3,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Repairman registration is handled with this form. Social sign-up is not connected in this project.',
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),
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
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
}
