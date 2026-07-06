import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'refund_details_page.dart';

class RefundHistoryPage extends StatelessWidget {
  final String userId;
  const RefundHistoryPage({super.key, required this.userId});

  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text("Refund History", style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
        backgroundColor: colorSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: colorPrimary),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getRefundHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: colorPrimary));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No historical refund receipts found.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final ticket = snapshot.data![index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildRefundTicketCard(
                  context: context,
                  ticketData: ticket,
                  ticketId: ticket['ticket_id'].toString(),
                  orderId: ticket['order_id'].toString(),
                  status: ticket['status'].toString(), // Approved, Rejected, Cancelled
                  progress: (ticket['progress'] as num).toDouble(),
                  statusDetails: ticket['details'].toString(),
                  amount: (ticket['amount'] as num).toDouble(),
                ),
              );
            },
          );
        },
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
    // Determine custom theme status color rules
    Color textStatusColor = colorPrimary;
    Color barColor = colorPrimary;

    if (status == 'Rejected') {
      textStatusColor = Colors.redAccent;
      barColor = Colors.redAccent;
    } else if (status == 'Approved') {
      textStatusColor = Colors.green;
      barColor = Colors.green;
    } else if (status == 'Cancelled') {
      textStatusColor = Colors.grey;
      barColor = Colors.grey;
    }

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
                Text(status, style: TextStyle(color: textStatusColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
                color: barColor,
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