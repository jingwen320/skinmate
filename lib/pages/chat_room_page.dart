import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../services/api_service.dart';

class ChatRoomPage extends StatefulWidget {
  final int userId;
  const ChatRoomPage({super.key, required this.userId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  
  bool _isLoading = true;
  int? _roomId;

  bool _isChatClosedByAdminOrUser = false;
  
  // 🌟 Initialize Pusher Channels reference instance
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  @override
  void initState() {
    super.initState();
    _loadHistoryAndSetupSockets();
  }

  @override
  void dispose() {
    // 🌟 Clean memory up by unsubscribing when page closes
    if (_roomId != null) {
      _pusher.unsubscribe(channelName: "chat-room-$_roomId");
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryAndSetupSockets() async {
    // 1. Send the initialization ping first to establish/find the room ID
    final setupRoom = await ApiService.sendChatMessage(
      userId: widget.userId,
      senderType: 'user',
      message: '检查连接', 
    );

    if (setupRoom['status'] == 'success' && setupRoom['room_id'] != null) {
      if (mounted) {
        setState(() {
          _roomId = int.parse(setupRoom['room_id'].toString());
        });
      }

      // 2. NOW fetch the true historical chat messages using your main history API
      final history = await ApiService.getChatMessages(widget.userId);
      
      if (mounted) {
        setState(() {
          _messages.clear(); // Safe to clear now before adding the definitive history list
          _messages.addAll(List<Map<String, dynamic>>.from(history));

          _isChatClosedByAdminOrUser = setupRoom['room_status'] == 'closed';

          _isLoading = false;
        });
        _scrollToBottom(immediate: true);
      }
      
      // 3. Connect real-time sockets for any new messages
      await _initPusherRealtime(); 
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initPusherRealtime() async {
    try {
      await _pusher.init(
        apiKey: "1b9d74bdae41a56142c8", 
        cluster: "ap1", 
        onEvent: (PusherEvent event) {
          // Trigger when a new real-time message packet arrives over the channel hook
          if (event.eventName == "new-message" && event.data != null) {
            final dynamic decodedData = javaScriptJsonDecode(event.data.toString());

            if (decodedData['message'] == "CHAT_CLOSED") {
              if (mounted) {
                setState(() {
                  _isChatClosedByAdminOrUser = true; // 💥 Updates your UI!
                });
              }
              return;
            }
            
            if (mounted) {
              setState(() {
                _messages.add({
                  "sender_type": decodedData['sender_type'],
                  "message": decodedData['message'],
                  "time": decodedData['time'] ?? 'Just now',
                });
              });
              _scrollToBottom();
            }
          }
        },
      );

      // Subscribe to this specific room's channel matching your PHP file naming format
      await _pusher.subscribe(channelName: "chat-room-$_roomId");
      await _pusher.connect();
    } catch (e) {
      debugPrint("Pusher connection initialization anomaly error: $e");
    }
  }

  // Safe decoding utility handler variant to normalize variations in Pusher library transport string structures
  dynamic javaScriptJsonDecode(String source) {
    try {
      return jsonDecode(source);
    } catch(_) {
      // Sometimes double encoded payloads present string formats requiring alternative strip parses
      return jsonDecode(jsonDecode(source));
    }
  }

  void _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || text == '检查连接') return;

    _messageController.clear();

    // Fire network dispatch task pipeline out to PHP script
    await ApiService.sendChatMessage(
      userId: widget.userId,
      senderType: 'user',
      message: text,
    );
  }

  void _scrollToBottom({bool immediate = false}) {
    Future.delayed(Duration(milliseconds: immediate ? 50 : 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);

    return Scaffold(
      backgroundColor: colorSurface,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Admin Support", style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
        backgroundColor: colorSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: colorPrimary),
        actions: [
          if (!_isChatClosedByAdminOrUser && _roomId != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: colorPrimary,
                  backgroundColor: const Color(0xFFFEC1D6), 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.power_settings_new_rounded, size: 14),
                label: const Text(
                  "END CHAT",
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () async {
                  int countdown = 5;
                  Timer? timer;
                  bool isCountingDown = false;

                  await showDialog(
                    context: context,
                    barrierDismissible: false, 
                    builder: (c) {
                      return StatefulBuilder(
                        builder: (dialogContext, setDialogState) {
                          
                          void startCountdownTimer() {
                            setDialogState(() => isCountingDown = true);
                            
                            timer = Timer.periodic(const Duration(seconds: 1), (t) async {
                              if (countdown > 1) {
                                setDialogState(() => countdown--);
                              } else {
                                t.cancel();
                                Navigator.pop(dialogContext); 
                                
                                // Execute network requests out securely
                                await ApiService.closeChatRoom(_roomId!);
                                // if (mounted) Navigator.pop(context); 
                                if (mounted) {
                                  setState(() {
                                    _isChatClosedByAdminOrUser = true; 
                                  });
                                }
                              }
                            });
                          }

                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              isCountingDown ? "Ending Chat..." : "End Chat?",
                              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              isCountingDown 
                                  ? "This support conversation will be ended in $countdown (s)..."
                                  : "This will close your support ticket permanently. You won't see this timeline history next time.",
                              style: const TextStyle(fontFamily: 'Manrope', fontSize: 14),
                            ),
                            actions: [
                              if (!isCountingDown) ...[
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text("NO", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                                TextButton(
                                  onPressed: startCountdownTimer, 
                                  child: Text("YES, END IT", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                                ),
                              ] else ...[
                                TextButton(
                                  onPressed: () {
                                    timer?.cancel(); 
                                    Navigator.pop(dialogContext); 
                                  },
                                  child: const Text(
                                    "CANCEL", 
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorPrimary))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // Filter out our internal silent initialization string check rows so they don't print to UI layout
                      if (msg['message'] == '检查连接') return const SizedBox.shrink();

                      final bool isAdmin = msg['sender_type'] == 'admin';
                      final String timeString = msg['time'] ?? '';

                      return Align(
                        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isAdmin ? Colors.grey.shade200 : colorPrimary,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isAdmin ? 0 : 16),
                                  bottomRight: Radius.circular(isAdmin ? 16 : 0),
                                ),
                              ),
                              child: Text(
                                msg['message'],
                                style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: isAdmin ? Colors.black87 : Colors.white),
                              ),
                            ),

                            if (timeString.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isAdmin ? 4 : 0, 
                                  right: isAdmin ? 0 : 4, 
                                  bottom: 8, // Space between this message pair and the next one
                                ),
                                child: Text(
                                  timeString,
                                  style: TextStyle(
                                    fontFamily: 'Manrope', 
                                    fontSize: 10, 
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          spreadRadius: 1,
                          blurRadius: 12,
                          offset: const Offset(0, -4), // Soft top drop shadow to separate from history list
                        ),
                      ],
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: _isChatClosedByAdminOrUser
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "This support conversation has ended.",
                                style: TextStyle(fontFamily: 'Manrope', color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF91462E),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("EXIT CHAT", style: TextStyle(color: Colors.white, fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              )
                            ],
                          )
                        : Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    style: const TextStyle(fontFamily: 'Manrope', fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: "Type your message...",
                                      hintStyle: TextStyle(fontFamily: 'Manrope', color: Colors.grey.shade400, fontSize: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                      fillColor: Colors.grey.shade100,
                                      filled: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Color(0xFF91462E)),
                                  onPressed: _sendMessage,
                                ),
                              ],
                            ),
                          ),
                  ),
                )
              ],
            ),
    );
  }
}