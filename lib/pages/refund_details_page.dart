import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RefundDetailsPage extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const RefundDetailsPage({super.key, required this.ticket});

  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);
  static const String serverBaseUrl = "https://carwash-manhandle-sprinkler.ngrok-free.dev/skinmate_api/"; 
  static const String mediaBaseUrl = "https://carwash-manhandle-sprinkler.ngrok-free.dev/skinmate_api/images/"; 

  @override
  Widget build(BuildContext context) {
    final String status = ticket['status'].toString();
    final double progress = (ticket['progress'] as num).toDouble();
    final double amount = (ticket['amount'] as num).toDouble();
    final String? adminReply = ticket['admin_reply'];
    
    // Extracted items
    final String productBrand = ticket['product_brand'] ?? "SkinMate";
    final String productName = ticket['product_name'] ?? "SkinMate Product";
    final int quantity = ticket['quantity'] ?? 1;
    final String? proofPath = ticket['proof_path'];

    Color statusColor = colorPrimary;
    if (status == 'Rejected') statusColor = Colors.redAccent;
    if (status == 'Approved') statusColor = Colors.green;

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: Text(ticket['ticket_id'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
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
            // 1. Status Summary Block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text("Total Refund Amount", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    "RM ${amount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorPrimary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("${(progress * 100).toInt()}%"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colorSurface,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket['details'].toString(),
                    style: const TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (adminReply != null && adminReply.trim().isNotEmpty) ...[
              const Text("Admin Response", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: status == 'Rejected' ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: status == 'Rejected' ? Colors.redAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Text("Message from Support Team", style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      adminReply,
                      style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 🌟 2. NEW: Product & Quantity Summary List Card
            const Text("Item Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ticket['product_image'] != null && ticket['product_image'].toString().isNotEmpty
                          ? Image.network(
                              "$mediaBaseUrl${ticket['product_image']}",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: colorPrimary),
                            )
                          : const Icon(Icons.shopping_bag_outlined, color: colorPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${productBrand.toUpperCase()} $productName",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Quantity: $quantity",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "RM ${(amount).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Request Metadata Info Block
            const Text("Request Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _buildInfoRow("Order ID", ticket['order_id'].toString()),
                  const Divider(height: 24),
                  _buildInfoRow("Request Date", ticket['date'].toString()),
                  const Divider(height: 24),
                  _buildInfoRow("Last Update", ticket['updated_date'].toString()),
                  const Divider(height: 24),
                  _buildInfoRow("Reason", ticket['reason'] ?? "Not Specified"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Description
            const Text("Your Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(
                ticket['description'] ?? "No additional description provided.",
                style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),

            // 🌟 5. NEW: Attached Image Proof Section
            if (proofPath != null && proofPath.isNotEmpty) ...[
              const Text("Attached Proof", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary)),
              const SizedBox(height: 12),
              GestureDetector(
                // 🌟 Tapping triggers an elegant, interactive full-screen image viewer dialog modal
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // InteractiveViewer allows pinch-to-zoom scaling dynamically
                          InteractiveViewer(
                            panEnabled: true,
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              "$serverBaseUrl$proofPath",
                              fit: BoxFit.contain, // Fits the whole uncropped image cleanly on any device frame
                            ),
                          ),
                          // Close overlay option floating helper button
                          Positioned(
                            top: 20,
                            right: 20,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.6),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            "$serverBaseUrl$proofPath",
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: colorPrimary));
                            },
                          ),
                        ),
                      ),
                      // Subtle tap invitation overlay tag
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.fullscreen, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text("View Full Image", style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],

            if (status.trim() == 'Pending') ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelConfirmationDialog(context, ticket['ticket_id'].toString(), ticket['order_id'].toString()),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                  label: const Text(
                    "CANCEL REFUND REQUEST",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 0.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showCancelConfirmationDialog(BuildContext context, String ticketId, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Request?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to cancel your refund request for $ticketId? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No, Keep It", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog box immediately
              
              // Show a loading indicator overlay while processing network database changes
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: colorPrimary)),
              );

              bool success = await ApiService.cancelRefundRequest(orderId, ticketId);

              Navigator.pop(context); // Remove the loading spinner indicator array context layer

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Refund request $ticketId has been successfully cancelled.")),
                );
                Navigator.pop(context); // Pop back smoothly to Customer Support Dashboard list view
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to cancel refund. Please try again or chat with support.")),
                );
              }
            },
            child: const Text(
              "Yes, Cancel", 
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}