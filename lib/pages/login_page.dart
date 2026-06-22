import 'package:flutter/material.dart';
import '../services/api_service.dart';
//import 'home_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../main_wrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false; 
  bool _isObscure = true; //  MOVED HERE: Now it belongs to the State!

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final res = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (res['status'] == 'success') {
        // 1. Extract the userId from your nested JSON response
        String userId = res['user']['id'].toString();

        // 2. SAVE the session so main.dart can find it next time
        await ApiService.saveUserSession(userId);

        if (!mounted) return;

        // 3. Use pushAndRemoveUntil to clear the "Welcome" and "Login" pages
        // from the back-button history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(userId: userId),
          ),
          (route) => false, // This wipes the stack clean
        );
      } else {
        _showSnackBar(res['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showSnackBar('Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF91462E)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Brand Colors
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
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        letterSpacing: -1.0,
                        color: colorPrimary,
                      ),
                    ),
                    const Text(
                      'AI-Powered Skincare Concierge',
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
                          const Text('Welcome Back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorOnSurface)),
                          const SizedBox(height: 24),

                          // Email Field
                          _buildLabel('EMAIL ADDRESS'),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputStyle('hello@skinmate.com', Icons.alternate_email, colorSurfaceContainerLow, colorOutlineVariant),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel('PASSWORD'),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot?', 
                                  style: TextStyle(
                                    color: colorPrimary, 
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _passwordController,
                            obscureText: _isObscure, 
                            decoration: _inputStyle(
                              '••••••••', 
                              Icons.lock_outline, 
                              colorSurfaceContainerLow, 
                              colorOutlineVariant,
                              //  Passing the suffixIcon here works now!
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: colorOutlineVariant,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure; 
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Login Button / Loading Indicator
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    // Footer: Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?", style: TextStyle(color: colorOnSurfaceVariant)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                          child: const Text('Sign Up', style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
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

  //  UPDATED: Added Widget? suffixIcon parameter here!
  InputDecoration _inputStyle(String hint, IconData icon, Color fill, Color outline, {Widget? suffixIcon}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: fill,
    prefixIcon: Icon(icon, size: 20, color: outline),
    suffixIcon: suffixIcon, // Now mapped correctly!
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
  );
}