import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  // 🎨 Radiant Palette
  final Color colorPrimary = const Color(0xFF91462E);
  final Color colorPrimaryContainer = const Color(0xFFFE9D7F);
  final Color colorBackground = const Color(0xFFF7F6F3);

  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    // Trigger animations shortly after the page builds
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _startAnimation = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          // 1. Animated Background Glow
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            top: _startAnimation ? -80 : -150,
            right: _startAnimation ? -30 : -100,
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              width: _startAnimation ? 350 : 200,
              height: _startAnimation ? 350 : 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorPrimaryContainer.withOpacity(0.15),
              ),
            ),
          ),

          // 2. Main Content with Staggered Entry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Brand Icon ---
                _animatedEntry(
                  delay: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorPrimary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorPrimary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 40),

                // --- Headline ---
                _animatedEntry(
                  delay: 200,
                  child: Text(
                    "SkinMate",
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: colorPrimary,
                      height: 1.0,
                      letterSpacing: -2,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Subheadline ---
                _animatedEntry(
                  delay: 400,
                  child: Text(
                    "Advanced AI skin analysis tailored to your unique glow.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // --- Interactive Button ---
                _animatedEntry(
                  delay: 600,
                  child: _buildInteractiveButton(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for staggered slide + fade entry
  Widget _animatedEntry({required int delay, required Widget child}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      opacity: _startAnimation ? 1.0 : 0.0,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 800),
        padding: EdgeInsets.only(top: _startAnimation ? 0 : 40),
        child: child,
      ),
    );
  }

  Widget _buildInteractiveButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: _startAnimation ? 1.0 : 0.9),
      duration: const Duration(milliseconds: 1000),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: double.infinity,
            height: 65,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('seenWelcome', true); // 📝 Mark as seen

                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: colorPrimary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}