import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final response = await ApiService.getOrderDetails(widget.orderId);
    if (mounted) {
      if (response['status'] == 'success') {
        setState(() {
          _orderDetails = response['order'];
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
        title: Text(
          "Invoice #${widget.orderId}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : _orderDetails == null
              ? const Center(child: Text("Failed to load invoice details."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow("Order Date", _orderDetails!['date'] ?? ''),
                            _infoRow("Status", _orderDetails!['status'] ?? '', valueColor: colorPrimary),
                            const Divider(height: 30),
                            
                            const Text("Items Purchased", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),

                            // 🛍️ Corrected Items Loop
                            ...(_orderDetails!['items'] as List).map((item) {
                              // Using tryParse and matching your PHP keys: 'price' and 'qty'
                              double price = double.tryParse(item['price'].toString()) ?? 0.0;
                              int quantity = int.tryParse(item['qty'].toString()) ?? 0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "$quantity x ${item['name'] ?? 'Unknown Item'}", 
                                        style: const TextStyle(fontSize: 14)
                                      ),
                                    ),
                                    Text(
                                      "RM ${(price * quantity).toStringAsFixed(2)}", 
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              );
                            }),
                            
                            const Divider(height: 30),
                            
                            const Text("Shipping Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            _addressText(_orderDetails!['address']['line1']),
                            if (_orderDetails!['address']['line2'] != null)
                              _addressText(_orderDetails!['address']['line2']),
                            _addressText("${_orderDetails!['address']['postcode']} ${_orderDetails!['address']['city']}"),
                            _addressText("${_orderDetails!['address']['state']}, ${_orderDetails!['address']['region']}"),

                            const Divider(height: 30),

                            _mathRow("Subtotal", "RM ${double.tryParse(_orderDetails!['subtotal'].toString())?.toStringAsFixed(2) ?? '0.00'}"),

                            if (double.parse(_orderDetails!['discount'].toString()) > 0)
                              _mathRow(
                                "Discount Applied", 
                                "-RM ${double.parse(_orderDetails!['discount'].toString()).toStringAsFixed(2)}", 
                                color: Colors.red
                              ),

                            _renderShippingRow(_orderDetails!['shipping_fee'].toString()),

                            const Divider(height: 20),

                            _mathRow(
                              "Total Paid", 
                              "RM ${double.tryParse(_orderDetails!['final_total'].toString())?.toStringAsFixed(2) ?? '0.00'}", 
                              isBold: true, 
                              color: colorPrimary
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _addressText(String? text) {
    return Text(text ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14));
  }

  Widget _renderShippingRow(String shippingValue) {
    bool isFree = (shippingValue == "FREE" || shippingValue == "0" || shippingValue == "0.00");
    return _mathRow(
      "Shipping", 
      isFree ? "FREE" : "RM $shippingValue",
      color: isFree ? Colors.green : Colors.black
    );
  }

  Widget _mathRow(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14, color: color ?? Colors.black)),
        ],
      ),
    );
  }
}