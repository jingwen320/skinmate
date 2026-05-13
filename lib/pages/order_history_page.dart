import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_details_page.dart'; // Import the order details page for navigation
import 'refund_request_page.dart';

class OrderHistoryPage extends StatefulWidget {
  final String userId;

  const OrderHistoryPage({super.key, required this.userId});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final response = await ApiService.getOrders(widget.userId);
    
    if (mounted) {
      if (response['status'] == 'success') {
        setState(() {
          _orders = response['orders'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: colorPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : _orders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsPage(
                              orderId: order['order_id'].toString(), // Safely pass it as a string
                            ),
                          ),
                        );
                      },
                      child: _buildOrderCard(order, colorPrimary),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No orders yet",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your order history will appear here.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, Color colorPrimary) {
    bool isDelivered = order['status'] == 'Delivered';
    bool inTransit = order['status'] == 'In Transit';
    bool isRefunded = order['status'] == 'Refunded';
    bool isProcessing = order['status'] == 'Refund Processing';
    
    // Convert extracted item count to integer safely
    int totalItems = order['total_items'] ?? 0;
    String shipping = order['shipping_fee'] ?? '0.00';

    bool isFreeShipping = (shipping == "FREE" || shipping == "0.00" || shipping == "0");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column( 
        children: [
          Row(
            children: [
              Icon(
                isProcessing ? Icons.history_outlined : (inTransit ? Icons.local_shipping_outlined : Icons.shopping_basket_outlined), 
                color: isProcessing ? Colors.orange : colorPrimary
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${order['order_id']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    // 💡 UPGRADED SUBTITLE: Now shows status, date, AND physical item count!
                    Text(
                      "${order['status']} • ${order['date']} • $totalItems ${totalItems == 1 ? 'item' : 'items'}",
                      style: TextStyle(
                        color: isProcessing || inTransit 
                            ? Colors.orange 
                            : (isDelivered ? Colors.green : (isRefunded ? Colors.red : Colors.grey)), 
                        fontSize: 12,
                        fontWeight: inTransit || isDelivered || isRefunded ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 💡 SHIPPING TAG: Neatly renders Free shipping vs paid amounts
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFreeShipping ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isFreeShipping ? "FREE SHIPPING" : "+RM $shipping SHIPPING",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFreeShipping ? Colors.green : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                order['price'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
          
          // 🛑 Shows choice buttons ONLY when physical drop-off is complete!
          if (isDelivered) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row( 
              children: [
                // 1. RETURN & REFUND BUTTON
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {
                        _showRefundConfirmation(order['order_id'].toString());
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        "REQUEST REFUND", 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // 2. CONFIRM RECEIVED BUTTON
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () async {
                        final response = await ApiService.completeOrder(widget.userId, order['order_id'].toString());
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response['message'] ?? 'Action performed')),
                          );
                          if (response['status'] == 'success') {
                            _loadOrders(); 
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "CONFIRM RECEIVED", 
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  // A quick helper to prompt users about firing a refund request
  void _showRefundConfirmation(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Request Refund?"),
          content: Text("Are you sure you want to request a refund for Order #$orderId? You will need to select items and provide proof."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog first
                
                // 🚀 Navigate to the Refund Request Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RefundRequestPage(
                      orderId: orderId,
                      userId: widget.userId, // Using the userId from your OrderHistoryPage
                    ),
                  ),
                ).then((value) {
                  // If the user successfully submitted the refund, 'value' will be true
                  if (value == true) {
                    _loadOrders(); // Refresh the order list to show "Refund Processing" status
                  }
                });
              },
              child: const Text("PROCEED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}