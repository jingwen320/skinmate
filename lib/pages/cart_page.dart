import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'mock_payment_page.dart';
import '../widgets/notification_bell.dart';
import 'product_page.dart'; 
import '../widgets/shipping_info_row.dart';

class CartPage extends StatefulWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _promoController = TextEditingController();

  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  double _discount = 0.0;
  final String _shippingText = "COMPLIMENTARY";

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // 🛑 Pop-up confirmation asking the user if they actually want to delete the item
  Future<bool> _showDeleteConfirmation(String productBrand, String productName) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Remove Item?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Plus Jakarta Sans', // Keeping it aligned with your project's aesthetic
            ),
          ),
          content: Text("Are you sure you want to remove $productBrand $productName from your cart?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Returns false
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Returns true
              child: const Text("REMOVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  // 🛍️ 1. Fetch live data from your get_cart.php script
  Future<void> _fetchCart() async {
    // 💡 Note: You will need to add the getCart method in ApiService!
    final response = await ApiService.getCart(widget.userId);
    
    if (mounted) {
      if (response['status'] == 'success') {
        setState(() {
          _cartItems = response['cart'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🧮 2. Compute dynamic subtotal based on loaded quantities and prices
  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      final price = double.parse(item['product_price'].toString());
      final qty = int.parse(item['quantity'].toString());
      return sum + (price * qty);
    });
  }

  // 💰 3. Compute final balance
  double get _finalTotal => _subtotal - _discount;

  // 🎟️ 4. Apply promo code locally
  void _applyPromoCode(String code) {
    setState(() {
      if (code.toUpperCase() == "HELLOSKINMATE") {
        _discount = _subtotal * 0.10; // 10% discount
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo code HELLOSKINMATE applied!')),
        );
      } else {
        _discount = 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid promo code')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);
    const colorOnSurface = Color(0xFF2E2F2D);

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "Shopping Cart", 
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', color: Color(0xFF91462E))
        ),
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorOnSurface,
        actions: [
          NotificationBell(
            userId: widget.userId, // 🌟 Replace this variable with your session's user ID logic (e.g., user.id or shared preferences tracker)
            iconColor: colorPrimary,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return _buildCartItem(item, index, colorPrimary);
                        },
                      ),
                    ),
                    _buildSummarySection(colorPrimary),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, Color colorPrimary) {    
    final double itemPrice = double.tryParse(item['product_price'].toString()) ?? 0.0;
    
    // Assemble image URL matching ApiService structure definitions
    final String rawImage = item['product_image'] ?? item['image'] ?? '';
    String imageTarget = '';
    if (rawImage.isNotEmpty) {
      imageTarget = rawImage.startsWith('http') ? rawImage : '${ApiService.mediaUrl}$rawImage';
    }

    // Process BRAND Product Name formatting
    final String rawBrand = item['brand'] ?? item['product_brand'] ?? '';
    final String rawName = item['product_name'] ?? 'Essential Product';
    final String displayBrand = rawBrand.isNotEmpty ? "${rawBrand.toUpperCase()} " : "";

    final String rawSkinType = item['skin_suitability'] ?? 'All';

    // Translate database strings dynamically to your stylized editorial format strings
    String skinTypeDisplay = "ALL SKIN TYPES";
    if (rawSkinType.toLowerCase() == 'combination') {
      skinTypeDisplay = "COMBINATION SKIN";
    } else if (rawSkinType.toLowerCase() == 'oily') {
      skinTypeDisplay = "OILY SKIN";
    } else if (rawSkinType.toLowerCase() == 'dry') {
      skinTypeDisplay = "DRY SKIN";
    } else if (rawSkinType.toLowerCase() == 'sensitive') {
      skinTypeDisplay = "SENSITIVE SKIN";
    } else if (rawSkinType.isNotEmpty && rawSkinType.toLowerCase() != 'all') {
      skinTypeDisplay = "${rawSkinType.toUpperCase()} SKIN";
    }

    // 🌟 EXTRACT PRODUCT ID SAFELY (Handles nested or flat payload maps)
  final String prodId = item['product_id']?.toString() ?? item['id']?.toString() ?? '';

    // 🌟 WRAP THE CARD IN A GESTURDECTOR FOR PAGE NAVIGATION LINKING
    return GestureDetector(
      onTap: () async {
        if (prodId.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductPage(
                userId: widget.userId, 
                productId: prodId,
              ),
            ),
          );
          
          // 🌟 Refresh your cart array when returning back to this page 
          // to make sure pricing and items match backend database realities
          _fetchCart(); 
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Elegant rounded corners
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E2F2D).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Product Preview Image Frame
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageTarget.isNotEmpty
                    ? Image.network(
                        imageTarget,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.broken_image_outlined, color: colorPrimary.withOpacity(0.4)),
                      )
                    : Icon(Icons.image, color: colorPrimary.withOpacity(0.4)),
              ),
            ),
            const SizedBox(width: 16),
            
            // Metadata Column Matrix
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ BRAND Product Name with Text.rich styling
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: displayBrand,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2F2D),
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: rawName,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2F2D),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 🗂️ Product Category Display
                  Text(
                    item['product_category'] ?? item['category'] ?? 'The Essentials',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: Color(0xFF5B5C5A),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 🌟 THE NEW SKIN TYPE TAG CHIP
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1EE), // Subtle grey-beige tag background
                      borderRadius: BorderRadius.circular(6), // Structured mini-capsule rounding
                    ),
                    child: Text(
                      skinTypeDisplay,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9, // Small, clean editorial micro-typography
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF5B5C5A), // Soft readable contrast text formatting
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  
                  // 🔢 Quantity Picker Row Setup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _iconButton(Icons.remove, () async {
                            final cartId = item['id'].toString();
                            final currentQty = int.tryParse(item['quantity'].toString()) ?? 1;

                            if (currentQty > 1) {
                              final newQty = currentQty - 1;
                              setState(() => item['quantity'] = newQty);
                              await ApiService.updateCartQuantity(widget.userId, cartId, newQty);
                            } else {
                              final shouldDelete = await _showDeleteConfirmation(displayBrand, rawName);
                              if (shouldDelete && mounted) {
                                final response = await ApiService.deleteCartItem(widget.userId, cartId);
                                if (response['status'] == 'success') {
                                  setState(() {
                                    _cartItems.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Item removed from cart')),
                                  );
                                }
                              }
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "${item['quantity']}", 
                              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                          ),
                          _iconButton(Icons.add, () async {
                            final cartId = item['id'].toString();
                            final currentQty = int.tryParse(item['quantity'].toString()) ?? 1;
                            final newQty = currentQty + 1;

                            setState(() => item['quantity'] = newQty);
                            await ApiService.updateCartQuantity(widget.userId, cartId, newQty);
                          }),
                        ],
                      ),
                      
                      // 💰 2-Decimal Formatted Price Tag
                      Text(
                        "RM ${(itemPrice).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: colorPrimary, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Color(0xFFF1F1EE), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: const Color(0xFF91462E)),
      ),
    );
  }

  Widget _buildSummarySection(Color colorPrimary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1EE), 
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
            // const SizedBox(height: 16),

            // TextButton.icon(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       builder: (BuildContext context) {
            //         return AlertDialog(
            //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            //           title: const Text(
            //             'Shipping Information',
            //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF91462E)),
            //           ),
            //           content: Column(
            //             mainAxisSize: MainAxisSize.min,
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: const [
            //               Text(
            //                 'Review our delivery rates and estimated timeframes below:',
            //                 style: TextStyle(fontSize: 13, color: Color(0xFF5B5C5A), height: 1.4),
            //               ),
            //               SizedBox(height: 16),
            //               ShippingInfoRow(
            //                 region: 'West Malaysia',
            //                 rate: 'RM 7.50',
            //                 timeframe: '1–3 working days',
            //               ),
            //               Divider(height: 24),
            //               ShippingInfoRow(
            //                 region: 'East Malaysia',
            //                 rate: 'RM 15.00',
            //                 timeframe: '3–7 working days',
            //               ),
            //               Divider(height: 24),
            //               ShippingInfoRow(
            //                 region: 'Free Shipping',
            //                 rate: 'RM 0.00',
            //                 timeframe: 'Orders above RM 100',
            //               ),
            //             ],
            //           ),
            //           actions: [
            //             TextButton(
            //               onPressed: () => Navigator.pop(context),
            //               child: const Text('Got it', style: TextStyle(color: Color(0xFF91462E), fontWeight: FontWeight.bold)),
            //             ),
            //           ],
            //         );
            //       },
            //     );
            //   },
            //   icon: const Icon(Icons.help_outline, size: 16, color: Color(0xFF91462E)),
            //   label: const Text('Shipping Rates & Info', style: TextStyle(fontSize: 12, color: Color(0xFF91462E), fontWeight: FontWeight.bold)),
            //   style: TextButton.styleFrom(
            //     visualDensity: VisualDensity.compact,
            //   ),
            // ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: "Promo code",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _applyPromoCode(_promoController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEC1D6), 
                    foregroundColor: const Color(0xFF663A4B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  ),
                  child: const Text("APPLY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _summaryRow("Subtotal", "RM ${_subtotal.toStringAsFixed(2)}"),
            
            if (_discount > 0)
              _summaryRow("Promo Discount (10%)", "-RM ${_discount.toStringAsFixed(2)}", isDiscount: true),
              
            _summaryRow("Shipping", _shippingText, isComplimentary: true),
            
            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                Text(
                  "RM ${_finalTotal.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
                ),
              ],
            ),
            // const SizedBox(height: 20),

            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text(
                        'Shipping Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF91462E)),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Review our delivery rates and estimated timeframes below:',
                            style: TextStyle(fontSize: 13, color: Color(0xFF5B5C5A), height: 1.4),
                          ),
                          SizedBox(height: 16),
                          ShippingInfoRow(
                            region: 'West Malaysia',
                            rate: 'RM 7.50',
                            timeframe: '1–3 working days',
                          ),
                          Divider(height: 24),
                          ShippingInfoRow(
                            region: 'East Malaysia',
                            rate: 'RM 15.00',
                            timeframe: '3–7 working days',
                          ),
                          Divider(height: 24),
                          ShippingInfoRow(
                            region: 'Free Shipping',
                            rate: 'RM 0.00',
                            timeframe: 'Orders above RM 100',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it', style: TextStyle(color: Color(0xFF91462E), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.help_outline, size: 16, color: Color(0xFF91462E)),
              label: const Text('Shipping Rates & Info', style: TextStyle(fontSize: 12, color: Color(0xFF91462E), fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (_cartItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Your cart is empty!')),
                    );
                    return;
                  }

                  // 1. Send the user to the physical checkout screen
                  final checkoutComplete = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MockPaymentPage(
                        userId: widget.userId,
                        cartSubtotal: _subtotal,
                        discount: _discount, // 👈 PASS THE DISCOUNT VARIABLE HERE!
                      ),
                    ),
                  );

                  // 2. If the payment page returns "true", it means bank approved!
                  if (checkoutComplete == true && mounted) {
                    setState(() {
                      _cartItems.clear(); // Wipe local list since DB cart was wiped!
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Proceed to Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String amount, {bool isComplimentary = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isComplimentary || isDiscount ? Colors.green : Colors.black,
              fontSize: isComplimentary ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}