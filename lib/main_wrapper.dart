import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/scan_page.dart';
import '../pages/cart_page.dart';
import '../pages/profile_page.dart';
import '../pages/skin_history_page.dart'; // 👈 Needed for the sub-page

class MainWrapper extends StatefulWidget {
  final String userId;
  const MainWrapper({super.key, required this.userId});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  // bool _isViewingHistory = false; 

  // 🔄 DYNAMIC GETTER: This recreates the list when state changes
  // This ensures the userId is always fresh and the sub-page logic works.
  // Inside _MainWrapperState
  List<Widget> _getPages() {
    return [
      HomePage(
        userId: widget.userId,
        // 🌟 ADD THIS: This tells the Home page how to switch tabs
        onNavigateToScan: () => setState(() => _selectedIndex = 1), 
      ),
      ScanPage(userId: widget.userId),
      CartPage(userId: widget.userId),
      ProfilePage(
        userId: widget.userId,
        onNavigateToScan: () => setState(() => _selectedIndex = 1),
        // 🌟 CHANGE THIS: Use a standard Navigator push
        onNavigateToHistory: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SkinHistoryPage(
                userId: widget.userId,
                onBack: () => Navigator.pop(context), // Pop the full screen
              ),
            ),
          );
        },
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // _isViewingHistory = false; // Reset history view when switching tabs
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorOnSurfaceVariant = Color(0xFF5B5C5A);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      
      // 🌟 Use the getter here!
      body: _getPages()[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: colorPrimary,
        unselectedItemColor: colorOnSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined), label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined), label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile',
          ),
        ],
      ),
    );
  }
}