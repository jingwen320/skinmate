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

  // 🏷️ Track the currently active filter tab
  String _selectedTab = 'All';

  // Define the master list of available category options
  final List<String> _tabs = [
    'All',
    'Processing',
    'In Transit',
    'Delivered',
    'Completed',
    'Refund',
    'Cancelled'
  ];

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

  // 🔍 Filter Logic: Matches your custom tabs against exact database status strings
  List<dynamic> _getFilteredOrders() {
    if (_selectedTab == 'All') {
      return _orders;
    }
    
    return _orders.where((order) {
      final String status = (order['status'] ?? '').toString().trim();
      
      switch (_selectedTab) {
        case 'Processing':
          return status == 'Processing';
        case 'In Transit':
          return status == 'In Transit';
        case 'Delivered':
          return status == 'Delivered';
        case 'Completed':
          return status == 'Completed' || status == 'Received';
        case 'Refund':
          // Groups all lifecycle steps of returns together neatly
          return status == 'Refund Processing' || 
                 status == 'Refunded' || 
                 status == 'Refund Rejected';
        case 'Cancelled':
          return status == 'Cancelled';
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);

    final filteredOrders = _getFilteredOrders();

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
      // body: _isLoading
      //     ? const Center(child: CircularProgressIndicator(color: colorPrimary))
      //     : _orders.isEmpty
      //         ? _buildEmptyState()
      //         : ListView.builder(
      //             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      //             itemCount: _orders.length,
      //             itemBuilder: (context, index) {
      //               final order = _orders[index];
      //               return GestureDetector(
      //                 onTap: () {
      //                   Navigator.push(
      //                     context,
      //                     MaterialPageRoute(
      //                       builder: (context) => OrderDetailsPage(
      //                         orderId: order['order_id'].toString(), // Safely pass it as a string
      //                       ),
      //                     ),
      //                   );
      //                 },
      //                 child: _buildOrderCard(order, colorPrimary),
      //               );
      //             },
      //           ),
      body: Column(
        children: [
          // 🗂️ Horizontal Filter Bar Section
          _buildFilterBar(colorPrimary),
          
          // 📦 Orders Display Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: colorPrimary))
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailsPage(
                                    orderId: order['order_id'].toString(),
                                  ),
                                ),
                              );
                            },
                            child: _buildOrderCard(order, colorPrimary),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // 🛠️ Widget Builder: Horizontal Scrollable Status Tabs
  Widget _buildFilterBar(Color colorPrimary) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final tabName = _tabs[index];
          final bool isSelected = _selectedTab == tabName;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                tabName.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
              selected: isSelected,
              selectedColor: colorPrimary,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              showCheckmark: false, // Clean setup without check icons
              shadowColor: Colors.transparent,
              selectedShadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? colorPrimary : Colors.black12,
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedTab = tabName;
                  });
                }
              },
            ),
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
          Text(
            _selectedTab == 'All' ? "No orders yet" : "No orders in $_selectedTab",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your filtered order lifecycle updates show up right here.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, Color colorPrimary) {
    final String currentStatus = (order['status'] ?? '').toString();

    bool isDelivered = currentStatus == 'Delivered';
    bool inTransit = currentStatus == 'In Transit';
    bool isProcessing = currentStatus == 'Processing';
    bool isCompleted = currentStatus == 'Completed' || currentStatus == 'Received';
    bool isCancelled = currentStatus == 'Cancelled';
    
    // Sub-status checks grouped under the parent 'Refund' banner
    bool isRefundProcessing = currentStatus == 'Refund Processing';
    bool isRefunded = currentStatus == 'Refunded';
    bool isRefundRejected = currentStatus == 'Refund Rejected';

    int totalItems = order['total_items'] ?? 0;
    String shipping = order['shipping_fee'] ?? '0.00';
    bool isFreeShipping = (shipping == "FREE" || shipping == "0.00" || shipping == "0");

    // 🎨 Dynamic layout context styling engine
    Color statusColor = Colors.grey;
    IconData cardIcon = Icons.shopping_basket_outlined;

    if (isProcessing) {
      statusColor = Colors.grey;
      cardIcon = Icons.cached_outlined;
    } else if (inTransit) {
      statusColor = Colors.orange;
      cardIcon = Icons.local_shipping_outlined;
    } else if (isDelivered) {
      statusColor = Colors.green;
      cardIcon = Icons.card_giftcard_outlined;
    } else if (isCompleted) {
      statusColor = colorPrimary;
      cardIcon = Icons.check_circle_outline;
    } else if (isRefundProcessing) {
      statusColor = Colors.orange;
      cardIcon = Icons.history_outlined;
    } else if (isRefunded) {
      statusColor = Colors.green;
      cardIcon = Icons.assignment_return_outlined;
    } else if (isRefundRejected) {
      statusColor = Colors.grey;
      cardIcon = Icons.block_outlined;
    } else if (isCancelled) {
      statusColor = Colors.grey;
      cardIcon = Icons.cancel_outlined;
    }

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
              Icon(cardIcon, color: statusColor),
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
                    Text(
                      "${order['status']} • ${order['date']} • $totalItems ${totalItems == 1 ? 'item' : 'items'}",
                      style: TextStyle(
                        color: statusColor, 
                        fontSize: 12,
                        fontWeight: !isProcessing && !isCancelled ? FontWeight.normal : FontWeight.normal
                      ),
                    ),
                    const SizedBox(height: 4),
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
                order['price'] ?? 'RM 0.00',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
          
          // Action triggers are only relevant when an item is safely checked out but not yet locked
          if (isDelivered) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row( 
              children: [
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
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        _showConfirmReceivedDialog(order['order_id'].toString(), colorPrimary);
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

  // 🛡️ Safety confirmation guard to ensure completion cannot be undone
  void _showConfirmReceivedDialog(String orderId, Color colorPrimary) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Confirm Order Delivery?",
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you have received all items for Order #$orderId? This will complete your order cycle and cannot be undone.",
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog overlay
                
                // Set global state to processing loading metrics if needed
                final response = await ApiService.completeOrder(widget.userId, orderId);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Order update completed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  if (response['status'] == 'success') {
                    _loadOrders(); // Refresh screen view to lock buttons
                  }
                }
              },
              child: Text(
                "YES, CONFIRM", 
                style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );
  }

  // A quick helper to prompt users about firing a refund request
  void _showRefundConfirmation(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Request Refund?",
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
            ),
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