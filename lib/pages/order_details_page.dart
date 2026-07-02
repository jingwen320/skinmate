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

  // Helper calculation function to format complex editorial address hierarchies cleanly
  List<String> _getFormattedAddressLines() {
    if (_orderDetails == null || _orderDetails!['address'] == null) return [];
    
    final addr = _orderDetails!['address'];
    final List<String> rawLines = [
      addr['line1']?.toString().trim() ?? '',
      addr['line2']?.toString().trim() ?? '',
      "${addr['postcode'] ?? ''} ${addr['city'] ?? ''}".trim(),
      "${addr['state'] ?? ''}, ${addr['region'] ?? ''}".trim(),
    ];

    // Filter out any potential empty or null fields over the payload wire
    final List<String> cleanLines = rawLines.where((line) => line.isNotEmpty).toList();

    // Map punctuations: commas for intermediate paths, full stop for the final segment
    return List.generate(cleanLines.length, (index) {
      if (index == cleanLines.length - 1) {
        return "${cleanLines[index]}."; // Final line ends with a full stop
      }
      return "${cleanLines[index]},"; // Intermediate lines end with a comma
    });
  }

  // 🌟 NEW HELPER: Formats raw DB numbers like 60123456789 -> (+60) 12-345 6789
  String _formatMalaysianPhone(dynamic rawPhone) {
    if (rawPhone == null || rawPhone.toString().isEmpty) return 'No contact provided';
    
    String phoneStr = rawPhone.toString().replaceAll(RegExp(r'[^0-9]'), '');
    
    // Strip leading 60 country prefix for inner body slicing
    String body = phoneStr.startsWith('60') ? phoneStr.substring(2) : phoneStr;
    
    if (body.length == 9) {
      // Formats to: (+60) 12-345 6789
      return "(+60) ${body.substring(0, 2)}-${body.substring(2, 5)} ${body.substring(5)}";
    } else if (body.length == 10) {
      // Formats to: (+60) 12-3456 7890
      return "(+60) ${body.substring(0, 2)}-${body.substring(2, 6)} ${body.substring(6)}";
    }
    
    return "(+60) $body";
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);

    final addressLines = _getFormattedAddressLines();

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: Text(
          "Invoice #${widget.orderId}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
        ),
        backgroundColor: colorSurface,
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
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E2F2D).withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow("Order Date", _orderDetails!['date'] ?? ''),
                            _infoRow("Status", _orderDetails!['status'] ?? '', valueColor: colorPrimary),
                            const Divider(height: 30),
                            
                            const Text(
                              "Items Purchased", 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Plus Jakarta Sans')
                            ),
                            const SizedBox(height: 16),

                            // 🛍️ UPGRADED: Rich Image and Brand Layout Core Items Loop
                            ...(_orderDetails!['items'] as List).map((item) {
                              double price = double.tryParse(item['price'].toString()) ?? 0.0;
                              int quantity = int.tryParse(item['qty'].toString()) ?? 0;

                              // Process custom premium images
                              final String rawImage = item['image'] ?? item['product_image'] ?? '';
                              String imageTarget = '';
                              if (rawImage.isNotEmpty) {
                                imageTarget = rawImage.startsWith('http') ? rawImage : '${ApiService.mediaUrl}$rawImage';
                              }

                              // Separate Brand text stamps out of fields
                              final String rawBrand = item['brand'] ?? item['product_brand'] ?? '';
                              final String displayBrand = rawBrand.isNotEmpty ? "${rawBrand.toUpperCase()} " : "";
                              final String rawName = item['name'] ?? item['product_name'] ?? 'Essential Product';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Image Thumbnail Box Frame Container
                                    Container(
                                      width: 55,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F1EE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: imageTarget.isNotEmpty
                                            ? Image.network(
                                                imageTarget,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => 
                                                    Icon(Icons.broken_image_outlined, color: colorPrimary.withOpacity(0.3), size: 20),
                                              )
                                            : Icon(Icons.image, color: colorPrimary.withOpacity(0.3), size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    
                                    // Brand & Product Text Core Matrix
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: displayBrand,
                                                  style: const TextStyle(
                                                    fontFamily: 'Plus Jakarta Sans',
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2E2F2D),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: rawName,
                                                  style: const TextStyle(
                                                    fontFamily: 'Plus Jakarta Sans',
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2E2F2D),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Qty: $quantity",
                                            style: const TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    
                                    // Total Aggregate Price Vector Tag
                                    Text(
                                      "RM ${(price * quantity).toStringAsFixed(2)}", 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Manrope', fontSize: 14)
                                    ),
                                  ],
                                ),
                              );
                            }),
                            
                            const Divider(height: 20),
                            
                            const Text(
                              "Shipping Address", 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Plus Jakarta Sans')
                            ),
                            const SizedBox(height: 10),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _orderDetails!['name'],
                                  style: const TextStyle(
                                    color: Color(0xFF2E2F2D), 
                                    fontSize: 13, 
                                    fontFamily: 'Manrope', 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                Text(
                                  " ", // Spacer for name and phone
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  _formatMalaysianPhone(_orderDetails!['phone']),
                                  style: const TextStyle(
                                    color: Color(0xFF2E2F2D), 
                                    fontSize: 13, 
                                    fontFamily: 'Manrope', 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),

                            // const SizedBox(height: 12),

                            // const SizedBox(height: 12),
                            
                            // 🏠 Render dynamically joined address blocks with intelligent punctuation placement
                            ...addressLines.map((line) => _addressText(line)),

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
          Text(title, style: const TextStyle(color: Colors.grey, fontFamily: 'Manrope')),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? Colors.black, fontFamily: 'Plus Jakarta Sans')),
        ],
      ),
    );
  }

  Widget _addressText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        text, 
        style: const TextStyle(color: Color(0xFF2E2F2D), fontSize: 13, fontFamily: 'Manrope', height: 1.3)
      ),
    );
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
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 15 : 13, fontFamily: 'Plus Jakarta Sans')),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14, color: color ?? Colors.black, fontFamily: 'Manrope')),
        ],
      ),
    );
  }
}