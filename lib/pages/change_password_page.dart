import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final String userId;
  const ChangePasswordPage({super.key, required this.userId});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Visual visibility toggles
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ApiService.changePassword(
      widget.userId,
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Action complete'),
          backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );

      if (response['status'] == 'success') {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 Standardizing on your editorial skin-mate theme colors
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: colorPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Security Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
              ),
              const SizedBox(height: 20),

              // 🔑 Current Password Input Field
              const Text("Current Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter current password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_outline, color: colorPrimary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: colorPrimary),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter your current password' : null,
              ),
              const SizedBox(height: 20),

              // 🔑 New Password Input Field
              const Text("New Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter minimum 8 characters",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_reset_outlined, color: colorPrimary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: colorPrimary),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) => v!.length < 8 ? 'Password must be at least 8 characters long' : null,
              ),
              const SizedBox(height: 20),

              // 🔑 Confirm New Password Input Field
              const Text("Confirm New Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Retype new password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.gpp_good_outlined, color: colorPrimary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: colorPrimary),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) => v != _newPasswordController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 40),

              // 🌟 Pill-Shaped Animated Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "UPDATE PASSWORD",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}