import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart'; 
import '../services/notification_service.dart';

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
  StreamSubscription? _notificationSubscription;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    // fetchNotifications();
    _startRealTimeNotificationStream();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel(); 
    super.dispose();
  }

  void _startRealTimeNotificationStream() {
    final client = HttpClient();
    final url = Uri.parse("${ApiService.baseUrl}/stream_notifications.php?user_id=${widget.userId}");

    bool isFirstLoad = true;

    client.getUrl(url).then((request) => request.close()).then((response) {
      _notificationSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
            if (line.startsWith("data: ")) {
              final String rawJson = line.substring(6).trim();
              if (rawJson.isEmpty) return;

              final Map<String, dynamic> data = json.decode(rawJson);
              if (data['status'] == 'success') {
                List incomingList = data['notifications'] ?? [];

                setState(() {
                  unreadCount = data['unread_count'];
                  notificationsList = incomingList;
                });

                if (!isFirstLoad && incomingList.isNotEmpty && incomingList.length > _lastCount) {
                  final newestNotification = incomingList.first;
                  
                  NotificationService.showInstantNotification(
                    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    title: newestNotification['title'] ?? "Order Update",
                    body: newestNotification['message'] ?? "",
                  );
                }
                
                isFirstLoad = false;
                _lastCount = incomingList.length;
              }
            }
          }, onError: (error) {
            debugPrint("Stream error encountered: $error. Reconnecting in 5s...");
            Future.delayed(const Duration(seconds: 5), _startRealTimeNotificationStream);
          }, onDone: () {
            debugPrint("Streaming server link terminated. Reconnecting...");
            Future.delayed(const Duration(seconds: 5), _startRealTimeNotificationStream);
          });
    }).catchError((e) {
      debugPrint("Streaming framework error connection drop: $e");
      Future.delayed(const Duration(seconds: 5), _startRealTimeNotificationStream);
    });
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
            markAsRead(); 
            _showNotificationsDialog(context);
          },
        ),
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

  Future<void> deleteNotification(String notificationId, int index, VoidCallback onStateSync) async {
    final fallbackItem = notificationsList[index];

    setState(() {
      notificationsList.removeAt(index);
      _lastCount = notificationsList.length;
    });
    onStateSync();

    final url = Uri.parse("${ApiService.baseUrl}/get_notifications.php?id=$notificationId&action=delete");
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (data['status'] != 'success') {
        setState(() {
          notificationsList.insert(index, fallbackItem);
          _lastCount = notificationsList.length;
        });
        onStateSync();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete notification.")));
      }
    } catch (e) {
      setState(() {
        notificationsList.insert(index, fallbackItem);
        _lastCount = notificationsList.length;
      });
      onStateSync();
      debugPrint("Error deleting notification record entry: $e");
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                              
                              final DateTime dateTime = DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now();
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              final String monthStr = months[dateTime.month - 1];
                              final int hour12 = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
                              final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
                              final String minuteStr = dateTime.minute.toString().padLeft(2, '0');
                              final String formattedDateTime = "${dateTime.day} $monthStr, ${dateTime.year} $hour12:$minuteStr $period";
                              
                              final String notificationId = item['id'].toString();

                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onLongPress: () {
                                  _showConfirmDeleteDialog(context, notificationId, index, () {
                                    setModalState(() {});
                                  });
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                  color: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF2D2D2D),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item['message'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            formattedDateTime,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
      },
    );
  }

  void _showConfirmDeleteDialog(BuildContext context, String notificationId, int index, VoidCallback onDeleted) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Notification?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to permanently clear this message from your history?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Color(0xFFD9534F), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog first
                deleteNotification(notificationId, index, onDeleted); // Execute API removal
                onDeleted(); // Sync sheet UI state
              },
            ),
          ],
        );
      },
    );
  }
}