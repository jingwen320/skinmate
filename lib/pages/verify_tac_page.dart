import 'package:flutter/material.dart';
import '../services/api_service.dart'; 

class VerifyTacPage extends StatefulWidget {
  final String email;
  const VerifyTacPage({super.key, required this.email});

  @override
  State<VerifyTacPage> createState() => _VerifyTacPageState();
}

class _VerifyTacPageState extends State<VerifyTacPage> {
  final _tacController = TextEditingController();
  bool _loading = false;

  // Theming constants (same as your RegisterPage)
  static const colorBackground = Color(0xFFF7F6F3);
  static const colorPrimary = Color(0xFF91462E);
  static const colorPrimaryContainer = Color(0xFFFE9D7F);
  static const colorSecondaryContainer = Color(0xFFFEC1D6);
  static const colorOnSurface = Color(0xFF2E2F2D);
  static const colorOnSurfaceVariant = Color(0xFF5B5C5A);
  static const colorOutlineVariant = Color(0xFFADADAB);
  static const colorSurfaceContainerLow = Color(0xFFF1F1EE);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Allows the screen to pop after we run our logic
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          // This is triggered when the system back gesture/button is used
          await ApiService.cancelRegistration(widget.email);
        }
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        // appBar: AppBar(
        //   backgroundColor: colorBackground,
        //   elevation: 0,
        //   leading: IconButton(
        //     icon: const Icon(Icons.arrow_back, color: colorPrimary),
        //     onPressed: () {
        //       ApiService.cancelRegistration(widget.email); 
        //       Navigator.pop(context);
        //     },
        //   ),
        // ),
        body: Stack(
          children: [
            // Background Blobs
            Positioned(top: -100, left: -100, child: CircleAvatar(radius: 150, backgroundColor: colorPrimaryContainer.withOpacity(0.15))),
            Positioned(bottom: -50, right: -50, child: CircleAvatar(radius: 130, backgroundColor: colorSecondaryContainer.withOpacity(0.2))),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const Text('Verification', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, fontSize: 32, color: colorPrimary)),
                      Text('Enter the 6-digit code sent to ${widget.email}', textAlign: TextAlign.center, style: const TextStyle(color: colorOnSurfaceVariant)),
                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: colorPrimary.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 20))],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _tacController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintText: '••••••',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : () => _verify(),
                                style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                child: _loading 
                                  ? const CircularProgressIndicator(color: Colors.white) 
                                  : const Text('Verify Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: colorPrimary, size: 28),
                  onPressed: () {
                    // ApiService.cancelRegistration(widget.email);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF91462E)),
    );
  }

  void _verify() async {
    setState(() => _loading = true);
    
    final res = await ApiService.verifyTac(widget.email, _tacController.text.trim());
    
    if (res['status'] == 'success') {
      // Show success message and navigate to Login
      _showSnackBar("Registration successful! You can now log in.");
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Verification failed')),
      );
    }
    
    setState(() => _loading = false);
  }
}