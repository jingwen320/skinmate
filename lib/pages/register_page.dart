import 'package:flutter/material.dart';
import '../services/api_service.dart'; 
//import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // 1. New controller
  
  bool _loading = false;
  bool _isObscure = true; 
  bool _isObscureConfirm = true; // 2. New visibility state

  void _register() async {
    // Check if any fields are empty
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    // Check password length
    if (_passwordController.text.length < 8) {
      _showSnackBar("Password must be at least 8 characters long");
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match!");
      return;
    }

    setState(() => _loading = true);
    try {
      var res = await ApiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (res['status'] == 'success') {
        // String userId = res['user']['id'].toString();
        // await ApiService.saveUserSession(userId);

        if (!mounted) return;
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => HomePage(userId: userId),
        //   ),
        // );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Please log in."),
            backgroundColor: Color(0xFF91462E),
          ),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showSnackBar(res['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _showSnackBar('Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF91462E)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorBackground = Color(0xFFF7F6F3);
    const colorPrimary = Color(0xFF91462E);
    const colorPrimaryContainer = Color(0xFFFE9D7F);
    const colorSecondaryContainer = Color(0xFFFEC1D6);
    const colorOnSurface = Color(0xFF2E2F2D);
    const colorOnSurfaceVariant = Color(0xFF5B5C5A);
    const colorOutlineVariant = Color(0xFFADADAB);
    const colorSurfaceContainerLow = Color(0xFFF1F1EE);

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          // Decorative Background Blobs
          Positioned(
            top: -100, left: -100,
            child: CircleAvatar(radius: 150, backgroundColor: colorPrimaryContainer.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50, right: -50,
            child: CircleAvatar(radius: 130, backgroundColor: colorSecondaryContainer.withOpacity(0.2)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Brand Header
                    const Text(
                      'SkinMate',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1.0, color: colorPrimary),
                    ),
                    const Text(
                      'Create your SkinMate account',
                      style: TextStyle(fontFamily: 'Manrope', color: colorOnSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 40),

                    // Main Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: colorPrimary.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 20))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Join Us', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorOnSurface)),
                          const SizedBox(height: 24),

                          // Name Field
                          _buildLabel('FULL NAME'),
                          TextField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputStyle('Your Name', Icons.person_outline, colorSurfaceContainerLow, colorOutlineVariant),
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          _buildLabel('EMAIL ADDRESS'),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputStyle('hello@skinmate.com', Icons.alternate_email, colorSurfaceContainerLow, colorOutlineVariant),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          _buildLabel('PASSWORD'),
                          TextField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            decoration: _inputStyle(
                              '••••••••', 
                              Icons.lock_outline, 
                              colorSurfaceContainerLow, 
                              colorOutlineVariant,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: colorOutlineVariant,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _isObscure = !_isObscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password Field
                          _buildLabel('CONFIRM PASSWORD'),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _isObscureConfirm,
                            decoration: _inputStyle(
                              '••••••••', 
                              Icons.lock_outline, 
                              colorSurfaceContainerLow, 
                              colorOutlineVariant,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: colorOutlineVariant,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: _loading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(color: colorOnSurfaceVariant)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Login', style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF5B5C5A))),
  );

  InputDecoration _inputStyle(String hint, IconData icon, Color fill, Color outline, {Widget? suffixIcon}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: fill,
    prefixIcon: Icon(icon, size: 20, color: outline),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
  );
}