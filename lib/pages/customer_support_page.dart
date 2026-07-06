import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'refund_details_page.dart';
import 'refund_history_page.dart';
import 'chat_room_page.dart';

class CustomerSupportPage extends StatelessWidget {
  final String userId;
  const CustomerSupportPage({super.key, required this.userId});

  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text("Customer Support", style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
        backgroundColor: colorSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: colorPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Active Tickets", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary),
            ),
            const SizedBox(height: 12),
            
            // 🌟 Dynamic Tracker Grid
            FutureBuilder<List<dynamic>>(
              future: ApiService.getActiveRefunds(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: colorPrimary),
                  ));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "No active support or refund tickets found.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.map((ticket) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildRefundTicketCard(
                        context: context, 
                        ticketData: ticket,
                        ticketId: ticket['ticket_id'].toString(),
                        orderId: ticket['order_id'].toString(),
                        status: ticket['status'].toString(),
                        progress: (ticket['progress'] as num).toDouble(),
                        statusDetails: ticket['details'].toString(),
                        amount: (ticket['amount'] as num).toDouble(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () {
                  // Navigate cleanly to the permanent history archive page view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RefundHistoryPage(userId: userId),
                    ),
                  );
                },
                leading: const Icon(Icons.history_toggle_off_rounded, color: colorPrimary),
                title: const Text(
                  "Refund History", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                ),
                subtitle: const Text("View past approved, rejected, or cancelled claims"),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(thickness: 1),
            const SizedBox(height: 24),

            const Text(
              "Still Need Help?", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Chat directly with our support team to resolve your issues instantly.",
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Next action: Pusher dynamic conversation framework launcher
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        userId: int.parse(userId), // Passes your active customer ID downstream
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: const Text(
                  "CHAT WITH ADMIN",
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundTicketCard({
    required BuildContext context,
    required Map<String, dynamic> ticketData,
    required String ticketId, 
    required String orderId,
    required String status, 
    required double progress,
    required String statusDetails,
    required double amount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RefundDetailsPage(ticket: ticketData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ticketId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "RM ${amount.toStringAsFixed(2)}", 
                    style: const TextStyle(color: colorPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("Order Code: $orderId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status, style: const TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                Text("${(progress * 100).toInt()}%"),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorSurface,
                color: status == 'Refund Rejected' 
                ? Colors.redAccent 
                : (status == 'Refunded' ? Colors.green : colorPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              statusDetails,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}