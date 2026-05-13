import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; 
import 'edit_profile_page.dart'; 
import 'order_history_page.dart';
import '../services/notification_service.dart'; 
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final VoidCallback onNavigateToScan; 
  final VoidCallback onNavigateToHistory;

  const ProfilePage({
    super.key, 
    required this.userId, 
    required this.onNavigateToScan,
    required this.onNavigateToHistory,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  List<dynamic> _recentOrders = [];
  bool loading = true;

  // Controllers to track Name and Email
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String skinType = "Loading...";
  String lastScan = "Loading...";

  int healthScore = 0;

  // Individual condition scores
  double acneScore = 0.0;
  double darkSpotsScore = 0.0;
  double pigmentationScore = 0.0;
  double poresScore = 0.0;
  double rednessScore = 0.0;
  double wrinklesScore = 0.0;

  // Toggles for Routine Reminders
  // bool _morningRoutine = true;
  // bool _eveningRoutine = true;

  // Default times, but these will change when the user picks a new one
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  bool _morningRoutine = false;
  bool _eveningRoutine = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestNotificationPermissions() async {
    // 1. Ask for standard notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // 2. IMPORTANT for S24 Ultra: Ask for Exact Alarm permission
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> _loadProfile() async {
    var res = await ApiService.getProfile(widget.userId);
    var orderRes = await ApiService.getOrders(widget.userId);

    if (res['status'] == 'success') {
      setState(() {
        user = res['user'];

        // This maps the 'skin_type' from PHP/Database to your Flutter variable
        skinType = user!['skin_type'] ?? 'Not Analyzed';

        // String rawDate = user!['created_at'] ?? 'No scans yet'; 
        // // Split the string at the space and take index 0 (the date)
        // lastScan = rawDate.contains(' ') ? rawDate.split(' ')[0] : rawDate;

        String? rawDate = user!['created_at']; 

        if (rawDate != null && rawDate.isNotEmpty) {
            // Only split if we actually have a date string from the database
            lastScan = rawDate.contains(' ') ? rawDate.split(' ')[0] : rawDate;
        } else {
            // Full fallback message
            lastScan = 'No scans yet';
        }

        healthScore = (user!['health_score'] as num?)?.toInt() ?? 0;

        // Map the database columns to your UI variables
        acneScore = (user!['acne_pct'] as num?)?.toDouble() ?? 0.0;
        darkSpotsScore = (user!['dark_spots_pct'] as num?)?.toDouble() ?? 0.0;
        pigmentationScore = (user!['pigmentation_pct'] as num?)?.toDouble() ?? 0.0;
        poresScore = (user!['pores_pct'] as num?)?.toDouble() ?? 0.0;
        rednessScore = (user!['redness_pct'] as num?)?.toDouble() ?? 0.0;
        wrinklesScore = (user!['wrinkles_pct'] as num?)?.toDouble() ?? 0.0;

        _nameController.text = user!['name'] ?? '';
        _emailController.text = user!['email'] ?? '';

        // 🕒 1. Load Morning Reminder from DB
        // Note: PHP might return 1/0 for boolean or strings like '08:30:00'
        _morningRoutine = (user!['morning_enabled'] == 1 || user!['morning_enabled'] == "1");
        
        if (user!['morning_time'] != null) {
          List<String> mParts = user!['morning_time'].split(':');
          _morningTime = TimeOfDay(hour: int.parse(mParts[0]), minute: int.parse(mParts[1]));
        }

        // 🕒 2. Load Evening Reminder from DB
        _eveningRoutine = (user!['evening_enabled'] == 1 || user!['evening_enabled'] == "1");

        if (user!['evening_time'] != null) {
          List<String> eParts = user!['evening_time'].split(':');
          _eveningTime = TimeOfDay(hour: int.parse(eParts[0]), minute: int.parse(eParts[1]));
        }

        if (orderRes['status'] == 'success') {
          _recentOrders = orderRes['orders'].take(2).toList();
        }
        loading = false;
      });

      // 🔔 3. CRITICAL: Sync the physical S24 Ultra notifications with DB settings
      _syncSystemNotifications();
    }
  }

  // Helper to ensure the phone's alarm manager matches the DB
  void _syncSystemNotifications() {
    if (_morningRoutine) {
      NotificationService.scheduleDailyNotification(
        id: 1,
        title: "Morning Glow! ✨",
        body: "Time for your morning skincare.",
        hour: _morningTime.hour,
        minute: _morningTime.minute,
      );
    }
    
    if (_eveningRoutine) {
      NotificationService.scheduleDailyNotification(
        id: 2,
        title: "Nightly Reset 🌙",
        body: "Don't forget your evening routine.",
        hour: _eveningTime.hour,
        minute: _eveningTime.minute,
      );
    }
  }

  // Helper to show the Logout Confirmation Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out of SkinMate?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); 
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()), 
                  (Route<dynamic> route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB31B25)),
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isMorning) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMorning ? _morningTime : _eveningTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF91462E),
              onSurface: Color(0xFF663A4B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMorning) {
          _morningTime = picked;
          _morningRoutine = true; 
        } else {
          _eveningTime = picked;
          _eveningRoutine = true;
        }
      });

      // 🚀 1. SAVE TO DATABASE IMMEDIATELY
      await ApiService.saveRemindersToDb(
        userId: widget.userId,           // 👈 Add "userId:"
        morningTime: _morningTime,       // 👈 Add "morningTime:"
        morningOn: _morningRoutine,      // 👈 Add "morningOn:"
        eveningTime: _eveningTime,       // 👈 Add "eveningTime:"
        eveningOn: _eveningRoutine,      // 👈 Add "eveningOn:"
      );

      // 🔔 2. SCHEDULE NOTIFICATION
      NotificationService.scheduleDailyNotification(
        id: isMorning ? 1 : 2,
        title: isMorning ? "Morning Glow! ✨" : "Nightly Reset 🌙",
        body: "Time for your skincare routine.",
        hour: picked.hour,
        minute: picked.minute,
      );

      // Add this right after you call NotificationService.scheduleDailyNotification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reminder set for ${picked.format(context)}")),
      );
    }
  }

  void _handleToggle(bool isMorning, bool val) async {
    // 🚀 1. Check for Exact Alarm Permission (Required for S24 Ultra)
    if (val) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        // This will open the "Alarms & Reminders" page specifically for SkinMate
        await openAppSettings(); 
        // If the user doesn't turn it on, we shouldn't proceed with scheduling
        return; 
      }
    }

    setState(() {
      if (isMorning) {
        _morningRoutine = val;
      } else {
        _eveningRoutine = val;
      }
    });

    // 🚀 2. SAVE TOGGLE STATE TO DATABASE
    await ApiService.saveRemindersToDb(
      userId: widget.userId,
      morningTime: _morningTime,
      morningOn: _morningRoutine,
      eveningTime: _eveningTime,
      eveningOn: _eveningRoutine,
    );

    if (val) {
      final time = isMorning ? _morningTime : _eveningTime;
      
      // 🚀 3. Schedule the Notification
      await NotificationService.scheduleDailyNotification(
        id: isMorning ? 1 : 2,
        title: isMorning ? "Morning Glow! ✨" : "Nightly Reset 🌙",
        body: "Time for your skincare routine.",
        hour: time.hour,
        minute: time.minute,
      );

      // Optional: Add a SnackBar to confirm it worked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${isMorning ? 'Morning' : 'Evening'} reminder set for ${time.format(context)}")),
      );
    } else {
      await NotificationService.cancelNotification(isMorning ? 1 : 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);
    const colorOnSurface = Color(0xFF2E2F2D);

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "SkinMate Profile",
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: Color(0xFF91462E)),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : user == null
              ? const Center(child: Text("Failed to load profile"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 40),
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 32),
                      _buildSkinProfileCard(colorPrimary),
                      const SizedBox(height: 16),
                      _buildRemindersCard(),
                      const SizedBox(height: 16),
                      _buildRecentOrders(),
                      const SizedBox(height: 16),
                      _buildActionButtons(colorOnSurface),
                    ],
                  ),
                ),
    );
  }

  // --- WIDGET BLOCKS ---

  Widget _buildHeaderSection() {
    // 🔗 Grab the photo URL generated by the database subquery
    final profilePicUrl = user?['profile_pic'];

    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              // 🖼️ Layers the photo from 'skin_progress' over the circle
              foregroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
              
              // 👤 Fallback icon if there are no images yet
              child: const Icon(Icons.person, size: 50, color: Color(0xFF91462E)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF91462E),
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                  onPressed: () async {
                    // 🚀 Moves to edit profile page
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          userId: widget.userId,
                          currentName: _nameController.text,
                          currentEmail: _emailController.text,
                        ),
                      ),
                    );

                    // 🔄 If edits were saved, refresh data so image/name updates!
                    if (updated == true) {
                      _loadProfile();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kept text fields here so data reflects instantly on return
              TextField(
                controller: _nameController,
                readOnly: true, // Set to read-only since editing moves to the next page!
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              ),
              TextField(
                controller: _emailController,
                readOnly: true, // Set to read-only since editing moves to the next page!
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  Chip(
                    label: Text(
                      '${skinType.toUpperCase()} SKIN', 
                      style: const TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1,
                        color: Color(0xFF4B3400),
                      )
                    ),
                    backgroundColor: Color(0xFFFED07F),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkinProfileCard(Color colorPrimary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text("Skin Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF91462E))),
          //     Icon(Icons.auto_awesome, color: Color(0xFFFE9D7F)),
          //   ],
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Skin Profile", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF91462E))
              ),
              // 🌟 Using TextButton.icon to combine the label and the icon
              TextButton.icon(
                onPressed: widget.onNavigateToHistory,
                icon: const Icon(Icons.history, color: Color(0xFFFE9D7F), size: 20),
                label: const Text(
                  "History", 
                  style: TextStyle(fontSize: 12, color: Color(0xFFFE9D7F), fontWeight: FontWeight.bold)
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact, // Makes it take up less space
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _skinMetricRow("Last Scan", lastScan),
          _skinMetricRow("Skin Type", skinType),

          // const Padding(
          //   padding: EdgeInsets.symmetric(vertical: 8.0),
          //   child: Divider(),
          // ),

          _skinConditionRow("Acne", acneScore),
          _skinConditionRow("Dark Spots", darkSpotsScore),
          _skinConditionRow("Pigmentation", pigmentationScore),
          _skinConditionRow("Pores", poresScore),
          _skinConditionRow("Redness", rednessScore),
          _skinConditionRow("Wrinkles", wrinklesScore), 
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onNavigateToScan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("RETAKE SKIN SCAN", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skinMetricRow(String label, String value, {bool? isGood}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isGood == null ? Colors.black : (isGood ? Colors.green : Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skinConditionRow(String label, dynamic value) {
    // 1. Parse score safely
    double score = (value is num) ? value.toDouble() : (double.tryParse(value.toString()) ?? 0.0);
    
    // 2. Determine color (Higher is Better)
    Color barColor = score >= 85 ? Colors.green : (score >= 60 ? Colors.orange : Colors.redAccent);
    
    // 3. Normalize progress (0.0 to 1.0)
    double progress = (score / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Slightly more padding for horizontal layout
      child: Row(
        children: [
          // Left: Label
          SizedBox(
            width: 250, // Fixed width so all bars start at the same alignment
            child: Text(
              label, 
              style: const TextStyle(color: Colors.grey, fontSize: 13)
            ),
          ),
          
          // Center: The Progress Bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Stack(
                children: [
                  // Background Track
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Progress Fill
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Percentage Mark
          SizedBox(
            width: 45, // Fixed width for consistent right alignment
            child: Text(
              "${score.toStringAsFixed(0)}%",
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEC1D6), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reminders", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF663A4B), fontFamily: 'Plus Jakarta Sans')
          ),
          const SizedBox(height: 16),
          
          // Morning Row
          _customSwitchRow(
            "Morning Routine", 
            _morningTime.format(context), // 👈 Dynamic time string
            _morningRoutine, 
            (val) => _handleToggle(true, val),
            () => _selectTime(context, true), // 👈 Open clock on tap
          ),
          
          const Divider(color: Color(0xFFE5ACB0), height: 24),
          
          // Evening Row
          _customSwitchRow(
            "Evening Routine", 
            _eveningTime.format(context), // 👈 Dynamic time string
            _eveningRoutine, 
            (val) => _handleToggle(false, val),
            () => _selectTime(context, false), // 👈 Open clock on tap
          ),
        ],
      ),
    );
  }

  // 🎨 Updated Helper Widget
  Widget _customSwitchRow(String title, String time, bool isEnabled, Function(bool) onToggle, VoidCallback onTimeTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF663A4B))),
            const SizedBox(height: 4),
            // 🕒 The Clickable Time
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF663A4B))
                ),
              ),
            ),
          ],
        ),
        Switch(
          value: isEnabled,
          onChanged: onToggle,
          activeColor: const Color(0xFF91462E),
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E5), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderHistoryPage(userId: widget.userId),
                    ),
                  );
                }, 
                child: const Text("View All", style: TextStyle(color: Color(0xFF91462E), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          if (_recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text("No orders placed yet.", style: TextStyle(color: Colors.grey)),
            )
          else
            ..._recentOrders.map((order) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _orderItem(
                    "Order #${order['order_id']}", 
                    "${order['status']} • ${order['date']}", 
                    order['price']
                  ),
                )),
        ],
      ),
    );
  }

  Widget _orderItem(String title, String subtitle, String price) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.shopping_basket, color: Color(0xFF91462E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color colorOnSurface) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {}, 
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8E8E5),
            foregroundColor: colorOnSurface,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(
            children: [
              Icon(Icons.help_outline),
              SizedBox(width: 12),
              Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(),
              Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, size: 16, color: Color(0xFFB31B25)),
            label: const Text("LOG OUT", style: TextStyle(color: Color(0xFFB31B25), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFFFEFEE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}