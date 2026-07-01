import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'product_page.dart';
import '../widgets/notification_bell.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final VoidCallback onNavigateToScan;
  const HomePage({super.key, required this.userId, required this.onNavigateToScan,});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List products = [];
  Map<String, dynamic>? user;
  bool isLoading = true;
  String _selectedCategory = 'All';

  // 🌟 NEW STATE VARIABLES FOR BUDGET SLIDER
  double _maxBudget = 250.0; // Starting/Default maximum slider threshold limit
  final double _absoluteMaxPrice = 250.0; // The ceiling cap limit of the slider row

  String _selectedSortOption = 'Latest to Oldest'; 

  // Available sorting criteria options
  final List<String> _sortOptions = [
    'Latest to Oldest',
    'Oldest to Latest',
    'Price: Lowest to Highest',
    'Price: Highest to Lowest'
  ];

  String _userName = "User"; // Default fallback

  Set<String> wishlistedProductIds = {};

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _searchResults = [];
  bool _isSearchLoading = false;

  // 🎨 Radiant Palette
  final Color colorPrimary = const Color(0xFF91462E);
  final Color colorPrimaryContainer = const Color(0xFFFE9D7F);
  final Color colorSecondaryContainer = const Color(0xFFFEC1D6);
  final Color colorTertiaryContainer = const Color(0xFFFED07F);
  final Color colorBackground = const Color(0xFFF7F6F3);
  final Color colorSurfaceLow = const Color(0xFFF1F1EE);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ⏱️ Debounce handler: stops API spam while typing
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _performSearch(_searchController.text.trim());
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  // 🌐 Calls your ApiService helper method
  Future<void> _performSearch(String query) async {
    setState(() => _isSearchLoading = true);
    
    // Calls your updated ApiService helper that reaches search_products.php
    final results = await ApiService.searchProducts(query);
    
    setState(() {
      _searchResults = results;
      _isSearchLoading = false;
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    
    // 1. Fetch Products
    final response = await ApiService.getProducts();
    
    // 2. Fetch User Profile for the Name
    final profileRes = await ApiService.getProfile(widget.userId);

    // 3. 🌟 Fetch User Wishlist to sync heart states on load
    final wishlistRes = await ApiService.getWishlist(widget.userId);

    setState(() {
      // Handle products
      products = response is List ? response : response['products'] ?? [];
      
      // 🌟 Handle User Name
      if (profileRes['status'] == 'success') {
        // We convert to uppercase to match your design style
        _userName = (profileRes['user']['name'] ?? "User").toUpperCase();
      }

      // 🌟 UPDATED: Populate our wishlist tracker set accurately
      wishlistedProductIds.clear();
      
      // Target whichever key your PHP is wrapping the array inside ('data' or 'wishlist')
      final wishlistArray = wishlistRes['data'] ?? wishlistRes['wishlist'];
      
      if (wishlistRes['status'] == 'success' && wishlistArray != null) {
        for (var item in wishlistArray) {
          
          // 🛑 CRITICAL FIX HERE:
          // Because your SQL query joins `products p`, the product's ID is stored in 'id'
          if (item['id'] != null) {
            String productDbId = item['id'].toString().trim();
            wishlistedProductIds.add(productDbId);
          }
        }
      }
      
      debugPrint("Verified Wishlisted IDs in memory: $wishlistedProductIds");
      
      isLoading = false;
    });
  }

  // 🌟 Toggle Wishlist local state and hit the remote backend database
  Future<void> _toggleWishlist(String productId) async {
    final isCurrentlyFaved = wishlistedProductIds.contains(productId);

    // 1. Instantly trigger responsive layout color changes
    setState(() {
      if (isCurrentlyFaved) {
        wishlistedProductIds.remove(productId);
      } else {
        wishlistedProductIds.add(productId);
      }
    });

    Map<String, dynamic> res;
    
    if (isCurrentlyFaved) {
      res = await ApiService.deleteWishlist(widget.userId, productId);
    } else {
      res = await ApiService.addWishlist(widget.userId, productId);
    }

    // 2. Evaluate server transaction results
    if (res['status'] == 'success' && mounted) {
      // Clear any existing snackbars to prevent layout stacking delays
      ScaffoldMessenger.of(context).clearSnackBars();
      
      // 🌟 DISPLAY SUCCESS ALERTS TO THE USER
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFaved 
                ? 'Removed from Wishlist' 
                : 'Added to Wishlist!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: isCurrentlyFaved ? Colors.grey[800] : colorPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (res['status'] != 'success' && mounted) {
      // Revert local UI state back to original setup if network fails
      setState(() {
        if (isCurrentlyFaved) {
          wishlistedProductIds.add(productId);
        } else {
          wishlistedProductIds.remove(productId);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to update wishlist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((product) {
      // 1. Evaluate Category Match Logic
      final String prodCategory = (product['product_category'] ?? product['category'] ?? '').toString().toLowerCase();
      final String selectedFilter = _selectedCategory.toLowerCase();
      
      bool matchesCategory = _selectedCategory == 'All' ||
          prodCategory == selectedFilter ||
          prodCategory == selectedFilter.replaceAll(RegExp(r's$'), '') ||
          selectedFilter == prodCategory.replaceAll(RegExp(r's$'), '');

      // 2. Evaluate Dynamic Slider Budget Limit Range Match
      final double price = double.tryParse(product['price'].toString()) ?? 0.0;
      bool matchesBudget = price <= _maxBudget;

      return matchesCategory && matchesBudget;
    }).toList();

    if (_selectedSortOption == 'Price: Lowest to Highest') {
      filteredProducts.sort((a, b) {
        final double priceA = double.tryParse(a['price'].toString()) ?? 0.0;
        final double priceB = double.tryParse(b['price'].toString()) ?? 0.0;
        return priceA.compareTo(priceB);
      });
    } else if (_selectedSortOption == 'Price: Highest to Lowest') {
      filteredProducts.sort((a, b) {
        final double priceA = double.tryParse(a['price'].toString()) ?? 0.0;
        final double priceB = double.tryParse(b['price'].toString()) ?? 0.0;
        return priceB.compareTo(priceA); // Inverted comparison
      });
    } else if (_selectedSortOption == 'Oldest to Latest') {
      filteredProducts.sort((a, b) {
        // Falls back to indexing order sequence sorting via product structural IDs
        final int idA = int.tryParse(a['id'].toString()) ?? 0;
        final int idB = int.tryParse(b['id'].toString()) ?? 0;
        return idA.compareTo(idB);
      });
    } else if (_selectedSortOption == 'Latest to Oldest') {
      filteredProducts.sort((a, b) {
        final int idA = int.tryParse(a['id'].toString()) ?? 0;
        final int idB = int.tryParse(b['id'].toString()) ?? 0;
        return idB.compareTo(idA); // Inverted comparison
      });
    }

    // 🌟 3. SPLIT INTO AVAILABLE AND SOLD OUT ARRAYS
    final availableProducts = filteredProducts.where((p) {
      final int stock = int.tryParse(p['stock_quantity'].toString()) ?? 0;
      return stock > 0;
    }).toList();

    final soldOutProducts = filteredProducts.where((p) {
      final int stock = int.tryParse(p['stock_quantity'].toString()) ?? 0;
      return stock <= 0;
    }).toList();

    // Determine if user is actively searching
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          // 1. SCROLLABLE CONTENT
          RefreshIndicator(
            onRefresh: _fetchProducts,
            color: colorPrimary,
            edgeOffset: 120, // 👈 Pushes the spinner below the sticky bar
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🛑 SPACER: Prevents first item from being hidden under the header
                const SliverToBoxAdapter(child: SizedBox(height: 140)),

                // 2. SEARCH BAR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products or concerns...',
                        prefixIcon: Icon(Icons.search, color: colorPrimary),
                        suffixIcon: isSearching
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus(); // Close keyboard on clear
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // ====================================================================
                // 🔍 SEARCH RESULTS VIEW BRANCH
                // ====================================================================
                if (isSearching) ...[
                  if (_isSearchLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_searchResults.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              "No matching products found.",
                              style: TextStyle(fontFamily: 'Manrope', color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // 🌟 Leverage your existing product card builder grid for search matching output uniformity!
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _searchResults[index];
                            final int stock = int.tryParse(product['stock_quantity'].toString()) ?? 0;
                            // Dynamically marks product card visually as sold out if stock is 0
                            return _buildProductCard(product, isSoldOut: stock <= 0);
                          },
                          childCount: _searchResults.length,
                        ),
                      ),
                    ),
                ]

                else ...[
                  // 3. HERO: AI SCAN BANNER
                  SliverToBoxAdapter(child: _buildHeroSection()),

                  // 4. CATEGORIES
                  SliverToBoxAdapter(child: _buildCategoriesSection()),

                  // 5. BUDGET SLIDER
                  SliverToBoxAdapter(child: _buildBudgetSliderSection()),

                  // 6. SORTING OPTIONS
                  SliverToBoxAdapter(child: _buildSortSection()),

                  const SliverToBoxAdapter(child: SizedBox(height: 15)),

                  // 5. PRODUCT GRID HEADER
                  // SliverPadding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  //   sliver: SliverToBoxAdapter(
                  //     // child: Row(
                  //     //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     //   children: [
                  //     //     const Text("Bestsellers",
                  //     //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  //     //     Text("View All",
                  //     //         style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
                  //     //   ],
                  //     // ),
                  //   ),
                  // ),

                  // 6. DYNAMIC PRODUCT GRID
                  isLoading
                      ? const SliverFillRemaining(
                          hasScrollBody: false, 
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : availableProducts.isEmpty && soldOutProducts.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.filter_list_off_rounded, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No products found under RM ${_maxBudget.toStringAsFixed(0)}",
                                      style: TextStyle(fontFamily: 'Manrope', color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.65,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildProductCard(availableProducts[index], isSoldOut: false),
                                  childCount: availableProducts.length,
                                ),
                              ),
                            ),

                  // 7. SOLD OUT SECTION
                  if (!isLoading && soldOutProducts.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Out of Stock",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                fontFamily: 'Plus Jakarta Sans', 
                                color: Color(0xFF2E2F2D)
                              ),
                            ),
                            Text(
                              "Temporarily unavailable items",
                              style: TextStyle(fontSize: 12, fontFamily: 'Manrope', color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductCard(soldOutProducts[index], isSoldOut: true),
                          childCount: soldOutProducts.length,
                        ),
                      ),
                    ),
                  ],
                ],
                  
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // 7. STICKY TOP BAR (Layered over the ScrollView)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              decoration: BoxDecoration(
                color: colorBackground.withOpacity(0.95), // Subtle glass effect
                border: Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // CircleAvatar(
                      //   radius: 20,
                      //   backgroundColor: colorPrimaryContainer,
                      //   child: const Icon(Icons.person, color: Colors.white),
                      // ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorPrimaryContainer,
                        // 🖼️ Use the profile pic from the database if it exists
                        backgroundImage: (user?['profile_pic'] != null) 
                            ? NetworkImage(user!['profile_pic']) 
                            : null,
                        child: (user?['profile_pic'] == null) 
                            ? const Icon(Icons.person, color: Colors.white) 
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("HELLO, $_userName",
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5)),
                          Text("SkinMate",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorPrimary,
                                  fontFamily: 'Plus Jakarta Sans')),
                        ],
                      ),
                    ],
                  ),
                  NotificationBell(
                    userId: widget.userId,
                    iconColor: colorPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSortSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Sort By",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Plus Jakarta Sans',
              color: const Color(0xFF2E2F2D).withOpacity(0.6),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSortOption,
                icon: Icon(Icons.swap_vert_rounded, size: 18, color: colorPrimary),
                elevation: 3,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2F2D),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSortOption = newValue;
                    });
                  }
                },
                items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSliderSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Max Budget Range",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', color: Color(0xFF2E2F2D)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "RM ${_maxBudget.toStringAsFixed(0)}",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Manrope', color: colorPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: colorPrimary,
              inactiveTrackColor: const Color(0xFFE2E1DE),
              thumbColor: colorPrimary,
              overlayColor: colorPrimary.withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: _maxBudget,
              min: 10.0,
              max: _absoluteMaxPrice,
              divisions: (_absoluteMaxPrice - 10.0) ~/ 5, // Stepped slider breaks (Increments cleanly by RM 5 values)
              onChanged: (newValue) {
                setState(() {
                  _maxBudget = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 240,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorPrimary, colorPrimaryContainer]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          const Positioned(
              right: -10,
              bottom: -10,
              child: Icon(Icons.face_retouching_natural, size: 180, color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: colorTertiaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: const Text("AI TECHNOLOGY",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                const Text("Your Skin,\nDecoded.",
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                const Spacer(),
                ElevatedButton(
                  // 🌟 CHANGE THIS: From Navigator.push to widget.onNavigateToScan()
                  onPressed: widget.onNavigateToScan, 
                  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Scan Now", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = ['All', 'Cleansers', 'Toners', 'Serums', 'Moisturizers', 'Acne Treatments'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.only(left: 24, top: 10),
            child: Text("The Essentials",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'))),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colorSecondaryContainer : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: colorPrimary.withOpacity(0.1), blurRadius: 10)] 
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: isSelected ? colorPrimary : const Color(0xFF5B5C5A),
                      ),
                      const SizedBox(height: 4),
                      Text(category,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(dynamic product, {required bool isSoldOut}) {
    final String imageTarget = product['image_url'] ?? '';
    final String prodId = product['id'].toString().trim();
    
    // Check if this specific item is currently tracked inside our wishlist set
    final bool isWishlisted = wishlistedProductIds.contains(prodId);
    
    // Safely evaluate price extraction values to double cleanly
    final double displayPrice = double.tryParse(product['price'].toString()) ?? 0.0;

    return GestureDetector(
      onTap: () async {
        // 🌟 Wait for the user to finish viewing the product page
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ProductPage(userId: widget.userId, productId: prodId)));
        
        // 🌟 When they press back and return here, automatically refresh the heart states!
        _fetchProducts(); 
      },
      child: Opacity(
        opacity: isSoldOut ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 1. PRODUCT PICTURE IMAGE CONTAINER FRAME
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: colorSurfaceLow, 
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: imageTarget.isNotEmpty
                          ? Image.network(
                              imageTarget, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.broken_image_outlined, color: colorPrimary.withOpacity(0.4)),
                                );
                              },
                            )
                          : Icon(Icons.image, color: colorPrimary.withOpacity(0.4)),
                    ),
                  ),

                  // 2. OUT OF STOCK OVERLAY DARK BLUR LAYER
                  if (isSoldOut)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "SOLD OUT",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.black87, fontFamily: 'Plus Jakarta Sans'),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. CLEAN SINGLE ANIMATED WISHLIST HEART ICON POSITIONED BUTTON
                  // We wrap it in a single negation block so it doesn't show up on sold out items
                  if (!isSoldOut)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _toggleWishlist(prodId),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              key: ValueKey<bool>(isWishlisted),
                              color: isWishlisted ? const Color(0xFF91462E) : colorPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            // PRODUCT TITLE
            Text(
              product['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Plus Jakarta Sans'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // PRODUCT SUBTITLE / CATEGORY
            Text(
              product['category'] ?? 'Deeply nourishing complex',
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: Color(0xFF5B5C5A), 
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // PRODUCT RETAIL VALUATION PRICE DISPLAYER
            Text(
              "RM ${displayPrice.toStringAsFixed(2)}",
              style: TextStyle(
                color: isSoldOut ? Colors.grey[600] : colorPrimary, 
                fontWeight: FontWeight.w900,
                fontFamily: 'Manrope',
                decoration: isSoldOut ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildIconButton(IconData icon) {
  //   return Container(
  //     padding: const EdgeInsets.all(8),
  //     decoration: BoxDecoration(
  //         shape: BoxShape.circle,
  //         color: Colors.white,
  //         border: Border.all(color: Colors.black12)),
  //     child: Icon(icon, color: colorPrimary, size: 20),
  //   );
  // }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All': return Icons.auto_awesome;
      case 'Cleansers': return Icons.face_retouching_natural_rounded;
      case 'Toners': return Icons.opacity_rounded;
      case 'Serums': return Icons.science_outlined;
      case 'Moisturizers': return Icons.spa_outlined;
      case 'Acne Treatments': return Icons.healing_rounded;
      default: return Icons.bubble_chart_outlined;
    }
  }
}