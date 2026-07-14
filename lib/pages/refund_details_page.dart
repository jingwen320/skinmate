import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pdf_viewer_page.dart';

class RefundDetailsPage extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const RefundDetailsPage({super.key, required this.ticket});

  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);
  // static const String serverBaseUrl = "https://carwash-manhandle-sprinkler.ngrok-free.dev/skinmate_api/"; 
  // static const String mediaBaseUrl = "https://carwash-manhandle-sprinkler.ngrok-free.dev/skinmate_api/images/"; 
  static const String serverBaseUrl = "https://library-valium-riverboat.ngrok-free.dev/skinmate_api/"; 
  static const String mediaBaseUrl = "https://library-valium-riverboat.ngrok-free.dev/skinmate_api/images/"; 
  

  @override
  Widget build(BuildContext context) {
    final String status = ticket['status'].toString();
    final double progress = (ticket['progress'] as num).toDouble();
    final double amount = (ticket['amount'] as num).toDouble();
    final String? adminReply = ticket['admin_reply'];

    final String productBrand = ticket['product_brand'] ?? "SkinMate";
    final String productName = ticket['product_name'] ?? "SkinMate Product";
    final int quantity = ticket['quantity'] ?? 1;

    final List<dynamic> itemsList = ticket['items'] ?? [
      {
        'brand': ticket['product_brand'] ?? "SkinMate",
        'name': ticket['product_name'] ?? "SkinMate Product",
        'quantity': ticket['quantity'] ?? 1,
        'image': ticket['product_image'],
        'amount': amount
      }
    ];

    final String rawProofPath = ticket['proof_path'] ?? "";
    final List<String> proofPaths = rawProofPath.isNotEmpty 
        ? rawProofPath.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList()
        : [];
    
    // Extracted items
    // final String productBrand = ticket['product_brand'] ?? "SkinMate";
    // final String productName = ticket['product_name'] ?? "SkinMate Product";
    // final int quantity = ticket['quantity'] ?? 1;
    // final String? proofPath = ticket['proof_path'];

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
            ListView.builder(
              shrinkWrap: true, // Prevents layout bounds errors inside a SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Let the main page handle the scrolling
              itemCount: itemsList.length,
              itemBuilder: (context, idx) {
                // Safely extract the item attributes for this specific iteration index loop
                final item = itemsList[idx];
                final String brand = item['brand'] ?? productBrand;
                final String name = item['name'] ?? productName;
                final int qty = item['quantity'] ?? quantity;
                final double itemAmount = (item['amount'] as num?)?.toDouble() ?? amount;
                final String? imgPath = item['image'] ?? ticket['product_image'];

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12), // Adds beautiful breathing room between cards
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      // Product Thumbnail Container
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
                          child: imgPath != null && imgPath.toString().isNotEmpty
                              ? Image.network(
                                  "$mediaBaseUrl$imgPath",
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: colorPrimary),
                                )
                              : const Icon(Icons.shopping_bag_outlined, color: colorPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Brand & Product Text Elements
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${brand.toUpperCase()} $name",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87, fontFamily: 'Plus Jakarta Sans'),
                            ),
                            const SizedBox(height: 4),
                            // Compact Metadata Row
                            Row(
                              children: [
                                Text(
                                  "Quantity: $qty",
                                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Plus Jakarta Sans'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Price Tag Metric
                      Text(
                        "RM ${itemAmount.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

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
            if (proofPaths.isNotEmpty) ...[
              const Text("Attached Proof Gallery", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans')),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: proofPaths.length,
                  itemBuilder: (context, index) {
                    final individualPath = proofPaths[index];
                    final bool isPdf = individualPath.toLowerCase().endsWith('.pdf');

                    return GestureDetector(
                      onTap: () => _openFullMediaViewer(context, individualPath, isPdf),
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: isPdf
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                                    SizedBox(height: 4),
                                    Text("PDF Document", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Plus Jakarta Sans')),
                                  ],
                                )
                              : Image.network(
                                  "$serverBaseUrl$individualPath",
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator(color: colorPrimary, strokeWidth: 2));
                                  },
                                  errorBuilder: (context, e, s) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            if (status.trim() == 'Pending') ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  // onPressed: () => _showCancelConfirmationDialog(context, ticket['ticket_id'].toString(), ticket['order_id'].toString()),
                  onPressed: () async {
                    final bool? didCancel = await _showCancelConfirmationDialog(
                      context, 
                      ticket['ticket_id'].toString(), 
                      ticket['order_id'].toString()
                    );

                    if (didCancel == true && context.mounted) {
                      Navigator.pop(context, true); // Return to the previous page and trigger a refresh
                    }
                  },
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

  // void _openFullMediaViewer(BuildContext context, String path, bool isPdf) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => Dialog(
  //       backgroundColor: Colors.transparent,
  //       insetPadding: const EdgeInsets.all(10),
  //       child: Stack(
  //         alignment: Alignment.center,
  //         children: [
  //           InteractiveViewer(
  //             panEnabled: true,
  //             boundaryMargin: const EdgeInsets.all(20),
  //             minScale: 0.5,
  //             maxScale: 4.0,
  //             child: isPdf
  //                 ? Container(
  //                     padding: const EdgeInsets.all(24),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white, 
  //                       borderRadius: BorderRadius.circular(16),
  //                     ),
  //                     child: const Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
  //                         SizedBox(height: 16),
  //                         Text(
  //                           "PDF Document attached via mobile device.", 
  //                           style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
  //                         ),
  //                       ],
  //                     ),
  //                   )
  //                 : Image.network("$serverBaseUrl$path", fit: BoxFit.contain),
  //           ),
  //           Positioned(
  //             top: 20,
  //             right: 20,
  //             child: CircleAvatar(
  //               backgroundColor: Colors.black.withOpacity(0.6),
  //               child: IconButton(
  //                 icon: const Icon(Icons.close, color: Colors.white),
  //                 onPressed: () => Navigator.pop(context),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _openFullMediaViewer(BuildContext context, String path, bool isPdf) {
    final Uri url = Uri.parse("$serverBaseUrl$path");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Content Area
            InteractiveViewer(
              panEnabled: !isPdf, // Disable pan for PDF container
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: isPdf
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                      constraints: const BoxConstraints(
                        minWidth: 280, 
                        minHeight: 150,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            "PDF Document",
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // if (await canLaunchUrl(url)) {
                              //   await launchUrl(url, mode: LaunchMode.externalApplication);
                              // }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerPage(url: "$serverBaseUrl$path"),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text("OPEN PDF"),
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Image.network("$serverBaseUrl$path", fit: BoxFit.contain),
            ),
            
            // Close Button
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

  Future<bool?> _showCancelConfirmationDialog(BuildContext parentContext, String ticketId, String orderId) {
    return showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Request?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to cancel your refund request for $ticketId? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Closes only the choice dialog safely
            child: const Text("No, Keep It", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              // 1. Close the confirmation dialog box immediately
              Navigator.pop(dialogContext); 
              
              // 2. Show a loading indicator overlay using the root parentContext
              showDialog(
                context: parentContext,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: colorPrimary)),
              );

              // 3. Fire your network API call
              bool success = await ApiService.cancelRefundRequest(orderId, ticketId);

              // 4. Verify the underlying page hasn't been closed while waiting
              if (!parentContext.mounted) return;

              // 5. Explicitly pop the top layer off parentContext (this closes the loading spinner!)
              Navigator.of(parentContext).pop(); 

              if (success) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text("Refund request $ticketId has been successfully cancelled."),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // 6. Return 'true' back to your Customer Support Page so it instantly refreshes the list!
                Navigator.pop(parentContext, true); 
              } else {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to cancel refund. Please try again or chat with support."),
                    backgroundColor: Colors.redAccent,
                  ),
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