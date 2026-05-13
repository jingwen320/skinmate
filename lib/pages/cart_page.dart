import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'mock_payment_page.dart';

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
  Future<bool> _showDeleteConfirmation(String productName) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remove Item?"),
          content: Text("Are you sure you want to remove '$productName' from your cart?"),
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
    final double itemPrice = double.parse(item['product_price'].toString());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Colors.grey, size: 40),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? "Product",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Plus Jakarta Sans'),
                ),
                // Text(
                //   // 🎨 Dynamically mapping category to a subtitle to keep your clean aesthetic
                //   "${item['product_category'] ?? 'General'} Skincare",
                //   style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                // ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    _iconButton(Icons.remove, () async {
                      final cartId = item['id'].toString();

                      if (item['quantity'] > 1) {
                        final newQty = item['quantity'] - 1;
                        
                        // Optimistically update UI
                        setState(() => item['quantity'] = newQty);
                        
                        // Silently update database in the background
                        await ApiService.updateCartQuantity(widget.userId, cartId, newQty);
                        
                      } else {
                        // 🔥 Triggers the pop-up prompt!
                        final shouldDelete = await _showDeleteConfirmation(item['product_name'] ?? 'this item');
                        
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    _iconButton(Icons.add, () async {
                      final cartId = item['id'].toString();
                      final newQty = item['quantity'] + 1;

                      // Optimistically update UI
                      setState(() => item['quantity'] = newQty);
                      
                      // Save to database
                      await ApiService.updateCartQuantity(widget.userId, cartId, newQty);
                    }),
                  ],
                )
              ],
            ),
          ),
          
          Text(
            "RM ${itemPrice.toStringAsFixed(2)}",
            style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Plus Jakarta Sans'),
          )
        ],
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