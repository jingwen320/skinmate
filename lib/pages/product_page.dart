import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';

class ProductPage extends StatefulWidget {
  final String userId;
  final String productId;

  const ProductPage({Key? key, required this.userId, required this.productId}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Map product = {};
  List reviews = [];
  List recommendedProducts = []; 
  bool isLoading = true;
  bool isWishlist = false;
  bool _showAllReviews = false;
  String _currentSortSetting = 'Latest';
  int quantity = 1; // 🌟 NEW: Track selected item volume counts locally

  final TextEditingController reviewController = TextEditingController();
  int rating = 5;
  String activeTab = 'Overview'; 

  // 🎨 Radiant Palette Semantic Custom Tokens
  final Color colorPrimary = const Color(0xFF91462E);
  final Color colorPrimaryContainer = const Color(0xFFFE9D7F);
  final Color colorSecondaryContainer = const Color(0xFFFEC1D6);
  final Color colorBackground = const Color(0xFFF7F6F3);
  final Color colorSurfaceContainerLow = const Color(0xFFF1F1EE);
  final Color colorSurfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color colorOnSurface = const Color(0xFF2E2F2D);
  final Color colorOnSurfaceVariant = const Color(0xFF5B5C5A);

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _fetchReviews();
    _checkWishlistStatus();
  }

  Future<void> _fetchProductDetails() async {
    final response = await ApiService.getProducts();
    final allProducts = response is List ? response : response['products'] ?? [];
    setState(() {
      product = allProducts.firstWhere(
        (p) => p['id'].toString() == widget.productId,
        orElse: () => {},
      );
      recommendedProducts = allProducts
          .where((p) => p['id'].toString() != widget.productId)
          .toList()
          .toSet() 
          .toList()
          .take(10)
          .toList();
    });
  }

  Future<void> _fetchReviews() async {
    final response = await ApiService.getReviews(widget.productId);
    setState(() {
      reviews = response['reviews'] ?? [];
      isLoading = false;
    });
  }

  Future<void> _checkWishlistStatus() async {
    final wishlistRes = await ApiService.getWishlist(widget.userId);
    final wishlistArray = wishlistRes['data'] ?? wishlistRes['wishlist'];
    
    if (wishlistRes['status'] == 'success' && wishlistArray != null) {
      for (var item in wishlistArray) {
        if (item['id'].toString().trim() == widget.productId.trim()) {
          setState(() {
            isWishlist = true;
          });
          break;
        }
      }
    }
  }

  Future<void> _toggleWishlist() async {
    final bool wasWishlisted = isWishlist;
    
    // 1. Instantly update the UI state locally
    setState(() {
      isWishlist = !isWishlist;
    });

    // 2. Instantly notify the user without waiting for the network
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasWishlisted 
              ? '${product['name'] ?? 'Item'} removed from wishlist' 
              : '${product['name'] ?? 'Item'} added to wishlist',
          style: const TextStyle(fontFamily: 'Manrope', fontSize: 13),
        ),
        backgroundColor: wasWishlisted ? colorOnSurfaceVariant : colorPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // 3. Fire off the actual backend syncing task in the background
    Map<String, dynamic> res;
    if (wasWishlisted) {
      res = await ApiService.deleteWishlist(widget.userId, widget.productId);
    } else {
      res = await ApiService.addWishlist(widget.userId, widget.productId);
    }

    // 4. If the server call fails, silently roll back the UI and show an alert
    if (res['status'] != 'success' && res['success'] != true && mounted) {
      setState(() {
        isWishlist = wasWishlisted;
      });
      
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update wishlist. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitReview() async {
    if (reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review comment before submitting!')),
      );
      return;
    }

    // 1. 🛑 SHOW CONFIRMATION DIALOG BEFORE POSTING
    final bool? shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            "Post Review?",
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
          ),
          content: const Text("Are you ready to share your review with the community?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Aborts the save
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Proceeds to the save
              child: const Text("SUBMIT", style: TextStyle(color: Color(0xFF91462E), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    // Exit completely if the user tapped Cancel or closed the dialog
    if (shouldSubmit != true) return;

    // 2. 🚀 PROCEED WITH YOUR API SUBMISSION PIPELINE
    final response = await ApiService.addReview(
      widget.userId,
      widget.productId,
      reviewController.text,
      rating,
    );

    if (response['success'] == true || response['status'] == 'success') {
      // 3. 🎉 SHOW SUCCESS SNACKBAR TO THE USER
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Review posted successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      // 4. 🧹 RESET INPUT CANVAS AND REFRESH UI FEED LIST
      reviewController.clear();
      setState(() {
        rating = 5;
      });
      _fetchReviews();
    } else {
      // Optional fallback alert message if backend DB verification drops or fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Submission failed. Please try again.')),
        );
      }
    }
  }

  String _calculateAverageRating() {
    if (reviews.isEmpty) return "0.0";
    double total = 0;
    for (var r in reviews) {
      total += double.tryParse(r['rating'].toString()) ?? 5.0;
    }
    return (total / reviews.length).toStringAsFixed(1);
  }

  Widget _buildProfessionalOverviewSection() {
    final rawSuitability = product['skin_suitability'];
    List<String> tags = [];
    
    if (rawSuitability is List) {
      tags = rawSuitability.map((e) => e.toString()).toList();
    } else if (rawSuitability is String && rawSuitability.isNotEmpty) {
      tags = rawSuitability.split(',').map((e) => e.trim()).toList();
    } else {
      tags = ["All Skin Types"];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorSurfaceContainerLow.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.02)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: colorPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Dermatologically Evaluated",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorPrimary,
                      letterSpacing: 0.5,
                      fontFamily: 'Manrope'
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product['description'] ?? "Formulated to integrate seamlessly into active recovery tracking arrays. Restores natural skin barrier function metrics via stable, non-comedogenic bio-hydration layers.",
                style: TextStyle(
                  fontSize: 13,
                  color: colorOnSurfaceVariant,
                  height: 1.6,
                  fontFamily: 'Manrope'
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Skin Type Compatibility Matrix",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorOnSurface, fontFamily: 'Plus Jakarta Sans'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorPrimary.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: colorPrimary.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: colorPrimary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorOnSurface,
                    fontFamily: 'Manrope'
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  String _formatPrice(dynamic rawPrice) {
    final double parsed = double.tryParse(rawPrice.toString()) ?? 0.00;
    return parsed.toStringAsFixed(2);
  }

  Future<void> _handleAddToCart() async {
    ScaffoldMessenger.of(context).clearSnackBars();

    // 🌟 1. Extract the brand and name segments cleanly from state
    final String rawBrand = product['brand'] ?? '';
    final String rawName = product['name'] ?? '';
    final String displayBrand = rawBrand.isNotEmpty ? "${rawBrand.toUpperCase()} " : "";

    // 🌟 2. Strip brand from product name for the database entry
    String cleanProductName = rawName;
    if (rawBrand.isNotEmpty) {
      if (rawName.toLowerCase().startsWith('${rawBrand.toLowerCase()} ')) {
        cleanProductName = rawName.substring(rawBrand.length).trim();
      } else if (rawName.toLowerCase().startsWith(rawBrand.toLowerCase())) {
        cleanProductName = rawName.substring(rawBrand.length).trim();
      }
    }

    // 🌟 3. Show immediate responsive SnackBar with RichText style matching your dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text.rich(
          TextSpan(
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 13, color: Colors.white),
            children: [
              // 1. Shows quantity count prefix with the trailing space
              TextSpan(text: '$quantity x '),
              
              // 2. The styled BRAND segment
              if (rawBrand.isNotEmpty)
                TextSpan(
                  text: displayBrand,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                
              // 3. The styled Product Name segment
              TextSpan(
                text: cleanProductName,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              
              // 4. Clean trailing action text closing statement
              const TextSpan(text: ' added'),
            ],
          ),
        ),
      ),
    );

    try {
      // 🌟 4. Extract short path fragment instead of absolute HTTP URL
      final String shortImagePath = product['image'] ?? product['image_path'] ?? '';

      final response = await ApiService.addToCart(
        userId: widget.userId,
        productId: widget.productId,
        productName: cleanProductName, // Saves only the item name component
        productPrice: product['price'].toString(),
        productImage: shortImagePath, // Saves the relative path
        quantity: quantity,
      );

      // Handle custom messages returned from your API response structure
      if (response['status'] != 'success' && response['success'] != true) {
        throw Exception("Backend rejected cart addition");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync cart data with server. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double unitPrice = double.tryParse(product['price'].toString()) ?? 0.00;
    final double totalPrice = unitPrice * quantity;

    final int stockQuantity = int.tryParse(product!['stock_quantity'].toString()) ?? 0;
    final int soldQuantity = int.tryParse(product!['sold_quantity'].toString()) ?? 0;

    final bool isOutOfStock = stockQuantity <= 0;

    return Scaffold(
      backgroundColor: colorBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: colorBackground.withOpacity(0.0),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.7),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: colorOnSurface, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  child: IconButton(
                    icon: Icon(
                      isWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isWishlist ? colorPrimary : colorOnSurface,
                      size: 20,
                    ),
                    onPressed: _toggleWishlist,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // 🌟 REDESIGNED: Sticky Bottom Bar featuring unified Quantity Counter step adjustments
      bottomNavigationBar: isLoading ? null : Container(
        padding: EdgeInsets.only(
          left: 24, 
          right: 24, 
          top: 16, 
          bottom: MediaQuery.of(context).padding.bottom + 16
        ),
        decoration: BoxDecoration(
          color: colorSurfaceContainerLowest,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.04), width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, -10))
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TOTAL PRICE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorOnSurfaceVariant, letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(
                      "RM ${_formatPrice(totalPrice)}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
                    ),
                  ],
                ),
                const Spacer(),
                // 🌟 NEW: Balanced Structural Quantity Selection Widget Block Frame
                Container(
                  decoration: BoxDecoration(
                    color: colorSurfaceContainerLow.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.remove_rounded, size: 18, color: colorOnSurface),
                        onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                      ),
                      //  FIXED: 'style' attached inside the Text widget child
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "$quantity",
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: colorOnSurface, 
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.add_rounded, size: 18, color: colorOnSurface),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isOutOfStock ? null : _handleAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  // 🌟 ADDED: Colors for when the button state turns to disabled
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // 🌟 FIX: Removed 'const' from here because the children list contains dynamic ternary logic
                  children: [
                    // 🌟 OPTIMIZATION: Only show the shopping bag icon if the item is in stock
                    if (!isOutOfStock) ...[
                      const Icon(Icons.shopping_bag_outlined, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isOutOfStock ? "SOLD OUT" : "Add to Cart",
                      style: const TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colorPrimary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌅 Immersive Full-Bleed Photo Section Frame
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width * 1.25,
                    color: colorSurfaceContainerLow,
                    child: product['image_url'] != null || product['image'] != null
                        ? Image.network(
                            product['image_url'] ?? product['image'],
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.image, size: 60, color: colorPrimary.withOpacity(0.2)),
                  ),

                  Transform.translate(
                    offset: const Offset(0, -48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: colorSurfaceContainerLowest,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: colorPrimary.withOpacity(0.08),
                                  blurRadius: 48,
                                  offset: const Offset(0, 24),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "SKINMATE'S PICK",
                                      style: TextStyle(
                                        color: colorPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 2.0,
                                        fontFamily: 'Manrope'
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // if (product['quantity_sold'] != null) ...[
                                        //   Container(
                                        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        //     decoration: BoxDecoration(
                                        //       color: colorOnSurfaceVariant.withOpacity(0.08),
                                        //       borderRadius: BorderRadius.circular(99),
                                        //     ),
                                        //     child: Text(
                                        //       "${product['quantity_sold']} Sold",
                                        //       style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorOnSurfaceVariant, fontFamily: 'Manrope'),
                                        //     ),
                                        //   ),
                                        //   const SizedBox(width: 6),
                                        // ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: colorSecondaryContainer.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.star_rounded, size: 14, color: colorPrimary),
                                              const SizedBox(width: 2),
                                              Text(
                                                _calculateAverageRating(),
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimary),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  product['name'] ?? 'Product Asset Name',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: colorOnSurface,
                                    fontFamily: 'Plus Jakarta Sans',
                                    height: 1.2
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${product['category']}",
                                  style: TextStyle(fontSize: 13, color: colorOnSurfaceVariant, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center, // Keeps both price and badge aligned on a perfect horizon line
                                  children: [
                                    Text(
                                      "RM ${_formatPrice(product['price'])}",
                                      style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.bold, 
                                        color: colorPrimary,
                                        fontFamily: 'Manrope',
                                      ),
                                    ),
                                    
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "$soldQuantity sold",
                                        style: const TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold, 
                                          fontFamily: 'Manrope', 
                                          color: Color(0xFF5B5C5A),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          Row(
                            children: ['Overview', 'Reviews'].map((tabTitle) {
                              final bool isSelected = activeTab == tabTitle;
                              return GestureDetector(
                                onTap: () => setState(() => activeTab = tabTitle),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 24),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: isSelected ? Border(bottom: BorderSide(color: colorPrimary, width: 2)) : null,
                                  ),
                                  child: Text(
                                    tabTitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? colorPrimary : colorOnSurfaceVariant,
                                      fontFamily: 'Manrope'
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(height: 1, color: Colors.black12),
                          const SizedBox(height: 16), 

                          // 🪄 Dynamic Tab Views Selector Layout
                          if (activeTab == 'Overview') ...[
                            _buildProfessionalOverviewSection(),
                          ] else ...[
                            ReviewSectionView(
                            reviews: reviews, 
                            colorOnSurface: colorOnSurface, 
                            colorPrimary: colorPrimary, 
                            colorOnSurfaceVariant: colorOnSurfaceVariant, 
                            reviewController: reviewController, 
                            colorBackground: colorBackground, 
                            rating: rating, 
                            // 🌟 FIX: Clean block body execution syntax for setState updates
                            onRatingChanged: (val) {
                              setState(() {
                                rating = val;
                              });
                            }, 
                            showAllReviews: _showAllReviews,
                            onToggleReviews: () {
                              setState(() {
                                _showAllReviews = !_showAllReviews;
                              });
                            },
                            onSubmit: _submitReview,
                            selectedSort: _currentSortSetting,
                            onSortChanged: (newSort) {
                              setState(() {
                                _currentSortSetting = newSort;
                              });
                            },
                            ),
                          ],

                          if (recommendedProducts.isNotEmpty) ...[
                            const SizedBox(height: 24), 
                            Text(
                              "Recommended Regimen",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorOnSurface, fontFamily: 'Plus Jakarta Sans'),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 190,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: recommendedProducts.length,
                                itemBuilder: (context, index) {
                                  final item = recommendedProducts[index];
                                  return GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => ProductPage(userId: widget.userId, productId: item['id'].toString())),
                                    ),
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 140,
                                            decoration: BoxDecoration(
                                              color: colorSurfaceContainerLow,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Image.network(item['image_url'] ?? item['image'] ?? '', fit: BoxFit.cover),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item['name'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorOnSurface),
                                          ),
                                          Text(
                                            "RM ${_formatPrice(item['price'])}",
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimary),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ReviewSectionView extends StatelessWidget {
  final List reviews;
  final Color colorOnSurface;
  final Color colorPrimary;
  final Color colorOnSurfaceVariant;
  final TextEditingController reviewController;
  final Color colorBackground;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;
  final bool showAllReviews;
  final VoidCallback onToggleReviews;
  
  // 🌟 ADDED: Pass the active sort string state value and change callback from the parent page
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const ReviewSectionView({
    Key? key,
    required this.reviews,
    required this.colorOnSurface,
    required this.colorPrimary,
    required this.colorOnSurfaceVariant,
    required this.reviewController,
    required this.colorBackground,
    required this.rating,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.showAllReviews,
    required this.onToggleReviews,
    // 🌟 ADDED HERE:
    required this.selectedSort,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🌟 FIXED: Created a local duplicate list array from 'reviews' instead of the non-existent 'widget.reviews'
    List sortedReviews = List.from(reviews);

    // 🌟 FIXED: Evaluates 'selectedSort' property parameters passed from parent state
    if (selectedSort == 'Latest') {
      sortedReviews.sort((a, b) => (int.tryParse(b['id'].toString()) ?? 0).compareTo(int.tryParse(a['id'].toString()) ?? 0));
    } else if (selectedSort == 'Oldest') {
      sortedReviews.sort((a, b) => (int.tryParse(a['id'].toString()) ?? 0).compareTo(int.tryParse(b['id'].toString()) ?? 0));
    } else if (selectedSort == 'Highest Rating') {
      sortedReviews.sort((a, b) => (int.tryParse(b['rating'].toString()) ?? 0).compareTo(int.tryParse(a['rating'].toString()) ?? 0));
    } else if (selectedSort == 'Lowest Rating') {
      sortedReviews.sort((a, b) => (int.tryParse(a['rating'].toString()) ?? 0).compareTo(int.tryParse(b['rating'].toString()) ?? 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Reviews (${reviews.length})",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorOnSurface, fontFamily: 'Plus Jakarta Sans'),
            ),
            if (reviews.isNotEmpty)
              DropdownButton<String>(
                value: selectedSort, // 🌟 FIXED
                underline: const SizedBox(),
                icon: Icon(Icons.sort_rounded, size: 16, color: colorPrimary),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorOnSurface, fontFamily: 'Plus Jakarta Sans'),
                items: const [
                  DropdownMenuItem(value: 'Latest', child: Text('Latest First  ')),
                  DropdownMenuItem(value: 'Oldest', child: Text('Oldest First  ')),
                  DropdownMenuItem(value: 'Highest Rating', child: Text('Highest Rating  ')),
                  DropdownMenuItem(value: 'Lowest Rating', child: Text('Lowest Rating  ')),
                ],
                onChanged: (String? newVal) {
                  if (newVal != null) {
                    onSortChanged(newVal); // 🌟 FIXED: Pass new values up to trigger state parent updates
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text("No community reviews filed for this item yet.", style: TextStyle(fontStyle: FontStyle.italic, color: colorOnSurfaceVariant)),
          )
        else ...[ 
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: showAllReviews ? sortedReviews.length : (sortedReviews.length > 3 ? 3 : sortedReviews.length),            
            itemBuilder: (context, index) {
              final r = sortedReviews[index]; // 🌟 Uses the freshly sorted local list array!
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r['name'] ?? "Verified Buyer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorOnSurface)),
                        Row(
                          children: List.generate(5, (starIdx) {
                            return Icon(
                              starIdx < (int.tryParse(r['rating'].toString()) ?? 5) ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 14,
                              color: const Color(0xFFFED07F),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2), 
                    Text(
                      r['created_at'] ?? 'Recently', 
                      style: TextStyle(color: colorOnSurfaceVariant, fontSize: 11, fontFamily: 'Manrope'),
                    ),
                    const SizedBox(height: 8),
                    Text(r['review'] ?? '', style: TextStyle(fontSize: 13, color: colorOnSurfaceVariant, height: 1.5, fontFamily: 'Manrope')),
                  ],
                ),
              );
            },
          ),
          if (reviews.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: onToggleReviews, 
                icon: Icon(
                  showAllReviews ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: colorPrimary,
                  size: 18,
                ),
                label: Text(
                  showAllReviews ? "SHOW LESS" : "VIEW ALL ${reviews.length} REVIEWS",
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: colorPrimary,
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Submit Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorOnSurface)),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Share your performance journey metrics...',
                  filled: true,
                  fillColor: colorBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DropdownButton<int>(
                    value: rating,
                    underline: const SizedBox(),
                    items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} Stars', style: const TextStyle(fontSize: 12)))),
                    onChanged: (val) => onRatingChanged(val!),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Submit', style: TextStyle(fontSize: 12, color: Colors.white)),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}