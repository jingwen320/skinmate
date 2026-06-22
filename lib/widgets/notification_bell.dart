import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart'; 

class NotificationBell extends StatefulWidget {
  final String userId;
  final Color iconColor;

  const NotificationBell({
    Key? key, 
    required this.userId, 
    required this.iconColor
  }) : super(key: key);

  @override
  _NotificationBellState createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int unreadCount = 0;
  List notificationsList = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // 📥 Fetch counts and notifications payload list
  Future<void> fetchNotifications() async {
    // 🌟 Refactored to reference your ApiService configuration
    final url = Uri.parse("${ApiService.baseUrl}/get_notifications.php?user_id=${widget.userId}&action=fetch");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            unreadCount = data['unread_count'];
            notificationsList = data['notifications'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading alert metrics: $e");
    }
  }

  // 📝 Clear unread indicator flag locally and on remote server tables
  Future<void> markAsRead() async {
    if (unreadCount == 0) return;

    // Optimistic state change updates layout instantly
    setState(() {
      unreadCount = 0;
    });

    // 🌟 Refactored to reference your ApiService configuration
    final url = Uri.parse("${ApiService.baseUrl}/get_notifications.php?user_id=${widget.userId}&action=mark_read");
    try {
      await http.get(url);
    } catch (e) {
      debugPrint("Error updating unread marker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: widget.iconColor),
          onPressed: () {
            markAsRead(); // Deducts / clears unread balance metrics instantly
            _showNotificationsDialog(context);
          },
        ),
        // 🔴 Dynamic badge layer displays only if unread count is above zero
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFD9534F), // High-contrast crimson alert badge color
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)), // Separator ring
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
    ],
    );
  }

  // 📑 Bottom UI Modal Sheet Feed View
  void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF91462E)),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Expanded(
                child: notificationsList.isEmpty
                    ? const Center(child: Text("No tracking status alerts found."))
                    : ListView.builder(
                        itemCount: notificationsList.length,
                        itemBuilder: (context, index) {
                          final item = notificationsList[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(item['message'], style: const TextStyle(fontSize: 13)),
                            trailing: Text(
                              item['created_at'].toString().substring(11, 16), // Clean timestamp text conversion
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}