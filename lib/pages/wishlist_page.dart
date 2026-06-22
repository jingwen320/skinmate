// lib/pages/wishlist_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'product_page.dart';

class WishlistPage extends StatefulWidget {
  final String userId;

  const WishlistPage({super.key, required this.userId});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<dynamic> _wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final response = await ApiService.getWishlist(widget.userId);
    
    if (mounted) {
      if (response['status'] == 'success') {
        setState(() {
          // Unified structural backend selector fallback matching your API layer
          _wishlistItems = response['data'] ?? response['wishlist'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🌟 UPDATED: Prompts the user for confirmation before firing the deletion query
  Future<void> _removeItem(String productId, String productBrand, String productName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Remove from Wishlist?",
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
          ),
          content: Text("Are you sure you want to remove $productBrand $productName from your wishlist?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog first
                
                // Fire the network query script
                final response = await ApiService.deleteWishlist(widget.userId, productId);
                
                if (mounted && response['status'] == 'success') {
                  _loadWishlist(); // Hot-reload data list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Removed from Wishlist', style: TextStyle(fontWeight: FontWeight.w600)),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text("REMOVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showQuantityDialog(Map<String, dynamic> item) {
    int selectedQuantity = 1; // Default selector starting value

    // 🌟 Extract the brand and name segments cleanly at the top of your dialog build
    final String rawBrand = item['brand'] ?? '';
    final String rawName = item['name'] ?? '';
    final String displayBrand = rawBrand.isNotEmpty ? "${rawBrand.toUpperCase()} " : "";

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // StatefulBuilder ensures the counter re-renders dynamically inside the dialog window
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                "Select Quantity",
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌟 THE INTEGRATION: Replaced the old text widget with the newly styled rich text block
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontFamily: 'Manrope', fontSize: 13, color: Color(0xFF2E2F2D), height: 1.5),
                      children: [
                        const TextSpan(text: "How many units of "),
                        
                        // The styled BRAND segment
                        TextSpan(
                          text: displayBrand,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF91462E), // Primary brand color accent
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        // The styled Product Name segment
                        TextSpan(
                          text: rawName,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF91462E), // Primary brand color accent
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        const TextSpan(text: " would you like to add to your shopping bag?"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Counter Controls Setup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus Incrementer
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF91462E)),
                        onPressed: selectedQuantity > 1 
                            ? () => setDialogState(() => selectedQuantity--) 
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "$selectedQuantity",
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Plus Incrementer
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF91462E)),
                        onPressed: () => setDialogState(() => selectedQuantity++),
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // Drop dialog instantly

                    final String prodId = (item['id'] ?? item['product_id'] ?? '').toString();
                    
                    // Fire network request using your raw database string fields
                    final response = await ApiService.addToCart(
                      userId: widget.userId,
                      productId: prodId,
                      productName: item['name'] ?? 'Essential Product',
                      productPrice: item['price'].toString(),
                      productImage: item['image'] ?? '', // Saves the raw string filename/path field context
                      quantity: selectedQuantity,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response['message'] ?? 'Cart updated successfully',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Manrope'),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: response['status'] == 'success' ? const Color(0xFF91462E) : Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: const Text("ADD TO CART", style: TextStyle(color: Color(0xFF91462E), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Theme configurations matching OrderHistoryPage exactly
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "My Wishlist",
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans', 
            fontWeight: FontWeight.bold, 
            color: colorPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : _wishlistItems.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  // 🌟 UPGRADED TO GRID: Renders items in responsive grid column layout matching the bento view
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns for a beautiful mobile grid
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.62, // Taller portrait ratio matching the aspect-[4/5] image style
                  ),
                  itemCount: _wishlistItems.length,
                  itemBuilder: (context, index) {
                    final item = _wishlistItems[index];
                    return _buildWishlistCard(item, colorPrimary);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Styled exactly like your Order History empty layout matrix
          Icon(Icons.favorite_border_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Your wishlist is empty",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Products you save will appear here.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item, Color colorPrimary) {
    final String imageTarget = item['image_url'] ?? '';
    final String prodId = item['id'].toString();
    final String rawName = item['name'] ?? '';

    final String rawBrand = item['brand'] ?? '';
    final String displayName = rawBrand.isNotEmpty 
        ? "${rawBrand.toUpperCase()} $rawName" 
        : rawName;

    final double priceValue = double.tryParse(item['price'].toString()) ?? 0.0;    

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32), // High-radius rounding matching rounded-[2rem]
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E2F2D).withOpacity(0.06), // Matches editorial-shadow
            blurRadius: 40,
            offset: const Offset(0, 24),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Portrait Image Frame with Absolute Heart Action Button
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductPage(userId: widget.userId, productId: prodId),
                        ),
                      );
                      _loadWishlist();
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFF1F1EE), // surface-container-low background
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
                  
                  // Floating Filled Red Heart Action Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _removeItem(prodId, rawBrand.toUpperCase(), rawName), // Passes both brand and name for a more informative dialog
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFF91462E), // Primary theme color fill for saved status
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Section: Editorial Typography and Cart Interactions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2E2F2D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['category'] ?? 'Deeply nourishing complex',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: Color(0xFF5B5C5A), // on-surface-variant
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Price and Add to Cart Row Layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RM ${priceValue.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorPrimary,
                        ),
                      ),
                      
                      // Circle Add to Cart Quick Trigger Interaction
                      GestureDetector(
                        onTap: () => _showQuantityDialog(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEC1D6), // secondary-container hex token code
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 16,
                            color: Color(0xFF663A4B), // on-secondary-container text token color
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}