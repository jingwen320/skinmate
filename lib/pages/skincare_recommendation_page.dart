import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'product_page.dart';

class ProductRecommendation {
  final int id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String image;
  final int matchScore;
  bool isWishlisted;

  ProductRecommendation({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.image,
    required this.matchScore,
    this.isWishlisted = false,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      brand: json['brand'] ?? 'Unknown',
      category: json['category'] ?? 'General',
      price: (json['price'] as num).toDouble(),
      image: json['image'] ?? '',
      matchScore: json['match_score'] ?? 0,
    );
  }
}

class SkincareRecommendationPage extends StatefulWidget {
  final int userId; 

  final String baseUrl = "https://library-valium-riverboat.ngrok-free.dev/skinmate_api/";

  const SkincareRecommendationPage({super.key, required this.userId});

  @override
  State<SkincareRecommendationPage> createState() => _SkincareRecommendationPageState();
}

class _SkincareRecommendationPageState extends State<SkincareRecommendationPage> {
  final List<String> categories = ['All', 'Cleanser', 'Toner', 'Serum', 'Moisturizer', 'Acne Treatment'];
  List<ProductRecommendation> allProducts = [];

  final Map<String, String> categoryDisplayNames = {
    'All': 'All',
    'Cleanser': 'Cleansers',
    'Toner': 'Toners',
    'Serum': 'Serums',
    'Moisturizer': 'Moisturizers',
    'Acne Treatment': 'Acne Treatment',
  };

  String _selectedSortOption = 'Latest to Oldest'; 

  // Available sorting criteria options
  final List<String> _sortOptions = [
    'Latest to Oldest',
    'Oldest to Latest',
    'Price: Lowest to Highest',
    'Price: Highest to Lowest'
  ];

  String _selectedBrand = 'All';

  final List<String> _brands = [
    'All', 
    'Skintific', 
    'Glad2Glow', 
    'Hada Labo', 
    'Cetaphil', 
    'Bio-essence'
  ];

  Set<String> wishlistedProductIds = {};
  
  String skinTypeStr = '';
  String concernsSummaryStr = '';

  List<dynamic> detectedConcernsList = [];

  // Fetch products
  List products = [];
  bool isLoading = true;
  
  bool _isLoading = false;
  bool _hasData = false;

  double currentBudget = 250.0;

  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _showBudgetBottomSheet();
    // });
  }

  void _showBudgetBottomSheet() {
    double currentBudget = 250.0;

    showModalBottomSheet(
      context: context,
      isDismissible: _hasData, 
      enableDrag: _hasData,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Set Your Budget Range", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "We will find the best products within your budget.", 
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEBEAE6)),
                      ),
                      child: Text(
                        "Max: RM ${currentBudget.toStringAsFixed(0)}", 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorPrimary),
                      ),
                    ),
                  ),
                  Slider(
                    value: currentBudget,
                    min: 20.0,
                    max: 250.0,
                    divisions: 23,
                    activeColor: colorPrimary,
                    inactiveColor: Colors.grey[300],
                    onChanged: (val) => setModalState(() => currentBudget = val),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(modalContext); 
                        
                        setState(() {
                          _isLoading = true;
                        });

                        final data = await ApiService.generateRecommendations(
                          userId: widget.userId, 
                          targetBudget: currentBudget,
                        );

                        if (data != null && data['status'] == 'success') {
                          final List<dynamic> rawList = data['recommendations'] ?? [];
                          // final List<dynamic> concernsList = data['detected_concerns'] ?? [];
                          
                          setState(() {
                            allProducts = rawList.map((item) => ProductRecommendation.fromJson(item)).toList();
                            skinTypeStr = data['detected_skin_type'] ?? 'Unknown';
                            
                            // concernsSummaryStr = concernsList.isEmpty 
                            //     ? "General Maintenance" 
                            //     : concernsList.map((c) => c.toString().toUpperCase()).join(" & ");

                            detectedConcernsList = (data['detected_concerns'] as List<dynamic>? ?? []).map((concern) {
                              String str = concern.toString();
                              return str.split(' ').map((word) {
                                if (word.isEmpty) return word;
                                return word[0].toUpperCase() + word.substring(1);
                              }).join(' ');
                            }).toList();
                            
                            _isLoading = false;
                            _hasData = true;
                          });
                        } else {
                          setState(() => _isLoading = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to retrieve recommendation rows.")),
                          );
                        }
                      },
                      child: const Text(
                        "GENERATE RECOMMENDATIONS", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

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
      res = await ApiService.deleteWishlist(widget.userId.toString(), productId);
    } else {
      res = await ApiService.addWishlist(widget.userId.toString(), productId);
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

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    
    final response = await ApiService.getProducts();

    final wishlistRes = await ApiService.getWishlist(widget.userId.toString());

    setState(() {
      products = response is List ? response : response['products'] ?? [];

      wishlistedProductIds.clear();
      
      final wishlistArray = wishlistRes['data'] ?? wishlistRes['wishlist'];
      
      if (wishlistRes['status'] == 'success' && wishlistArray != null) {
        for (var item in wishlistArray) {
          
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

  // Place this inside your State class, NOT inside build()
  void _applySorting() {
    setState(() {
      if (_selectedSortOption == 'Price: Lowest to Highest') {
        allProducts.sort((a, b) => a.price.compareTo(b.price));
      } else if (_selectedSortOption == 'Price: Highest to Lowest') {
        allProducts.sort((a, b) => b.price.compareTo(a.price));
      } else if (_selectedSortOption == 'Oldest to Latest') {
        allProducts.sort((a, b) => a.id.compareTo(b.id));
      } else if (_selectedSortOption == 'Latest to Oldest') {
        allProducts.sort((a, b) => b.id.compareTo(a.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorSurface,
        appBar: AppBar (
          title: const Text("Skincare Recommendation", 
            style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
          backgroundColor: colorSurface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: colorPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: colorPrimary),
              const SizedBox(height: 16),
              const Text("Matching best formulations...", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    // if (!_hasData) {
    //   return Scaffold(
    //     backgroundColor: const Color(0xFFF7F6F3),
    //     appBar: AppBar(
    //       backgroundColor: Colors.transparent, 
    //       elevation: 0, 
    //       iconTheme: const IconThemeData(color: colorPrimary),
    //     ),
    //     body: Center(
    //       child: ElevatedButton.icon(
    //         style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
    //         onPressed: _showBudgetBottomSheet,
    //         icon: const Icon(Icons.tune, color: Colors.white),
    //         label: const Text("Open Budget Filter", style: TextStyle(color: Colors.white)),
    //       ),
    //     ),
    //   );
    // }
    if (!_hasData) {

      return Scaffold(
        backgroundColor: colorSurface,
        appBar: AppBar(
          title: const Text("Skincare Budget", 
            style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
          backgroundColor: colorSurface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: colorPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StatefulBuilder(
          builder: (context, setPageState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Set Your Budget Range", 
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "We will find the best products within your budget.", 
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEBEAE6)),
                      ),
                      child: Text(
                        "Max: RM ${currentBudget.toStringAsFixed(0)}", 
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: currentBudget,
                    min: 20.0,
                    max: 250.0,
                    divisions: 23,
                    activeColor: colorPrimary,
                    inactiveColor: Colors.grey[300],
                    onChanged: (val) => setPageState(() => currentBudget = val),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary, 
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        final data = await ApiService.generateRecommendations(
                          userId: widget.userId, 
                          targetBudget: currentBudget,
                        );

                        print("API Response Debug: $data");

                        if (data != null && data['status'] == 'success') {
                          final List<dynamic> rawList = data['recommendations'] ?? [];
                          // final List<dynamic> concernsList = data['detected_concerns'] ?? [];
                          
                          setState(() {
                            allProducts = rawList.map((item) => ProductRecommendation.fromJson(item)).toList();
                            skinTypeStr = data['detected_skin_type'] ?? 'Unknown';
                            
                            // concernsSummaryStr = concernsList.isEmpty 
                            //     ? "General Maintenance" 
                            //     : concernsList.map((c) => c.toString().toUpperCase()).join(" & ");

                            detectedConcernsList = (data['detected_concerns'] as List<dynamic>? ?? []).map((concern) {
                              String str = concern.toString();
                              return str.split(' ').map((word) {
                                if (word.isEmpty) return word;
                                return word[0].toUpperCase() + word.substring(1);
                              }).join(' ');
                            }).toList();
                            
                            _isLoading = false;
                            _hasData = true;
                          });
                        } else {
                          setState(() => _isLoading = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to retrieve recommendation rows.")),
                          );
                        }
                      },
                      child: const Text(
                        "GENERATE RECOMMENDATIONS", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      );
    }

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: colorPrimary),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$skinTypeStr Skin Recommendations", 
                  style: const TextStyle(color: colorPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              
              // detectedConcernsList.isEmpty
              //     ? const Text("Targeting: General Maintenance", style: TextStyle(color: Colors.grey, fontSize: 11))
              //     : SingleChildScrollView(
              //         scrollDirection: Axis.horizontal,
              //         child: Row(
              //           children: [
              //             const Text("Targeting: ", style: TextStyle(color: Colors.grey, fontSize: 11)),
              //             ...detectedConcernsList.map((concern) => Container(
              //               margin: const EdgeInsets.only(right: 6),
              //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              //               decoration: BoxDecoration(
              //                 color: colorPrimary.withOpacity(0.1),
              //                 borderRadius: BorderRadius.circular(6),
              //                 border: Border.all(color: colorPrimary.withOpacity(0.3)),
              //               ),
              //               child: Text(
              //                 concern.toString(),
              //                 style: const TextStyle(color: colorPrimary, fontSize: 9, fontWeight: FontWeight.w600),
              //               ),
              //             )).toList(),
              //           ],
              //         ),
              //       ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune, color: colorPrimary),
              onPressed: _showBudgetBottomSheet, 
            )
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: colorPrimary,
            labelColor: colorPrimary,
            unselectedLabelColor: Colors.grey,
            tabs: categories.map((cat) => Tab(text: categoryDisplayNames[cat] ?? cat)).toList(),
          ),
        ),
        body: TabBarView(
          children: categories.map((categorySelection) {
            // final filteredList = categorySelection == 'All'
            //     ? allProducts
            //     : allProducts.where((p) => p.category.toLowerCase() == categorySelection.toLowerCase()).toList();

            final filteredList = allProducts.where((p) {
              final matchesCategory = (categorySelection == 'All' || 
                                      p.category.toLowerCase() == categorySelection.toLowerCase());
                                      
              final matchesBrand = (_selectedBrand == 'All' || 
                                    p.brand.toLowerCase() == _selectedBrand.toLowerCase());

              return matchesCategory && matchesBrand;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16.0), 
                  child: _buildBrandFilter(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Expanded(
                        child: detectedConcernsList.isEmpty
                            ? const Text("Targeting: General Maintenance", style: TextStyle(color: Colors.grey, fontSize: 11))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const Text("Targeting: ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ...detectedConcernsList.map((concern) => Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: colorPrimary.withOpacity(0.3)),
                                      ),
                                      child: Text(concern.toString(), style: const TextStyle(color: colorPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
                                    )),
                                  ],
                                ),
                              ),
                      ),

                      // _buildBrandFilter(),
                      // const SizedBox(width: 12),
                      _buildSortSection(),

                      // Row(
                      //   children: [
                      //     _buildBrandFilter(),
                      //     const SizedBox(width: 8),
                      //     _buildSortSection(),
                      //   ],
                      // ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildProductCount(filteredList, categorySelection),
                  ),
                ),

                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(child: Text("No matching products found in this category."))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,         
                            childAspectRatio: 0.7,     
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) => _buildProductCard(filteredList[index]),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Widget _buildProductCard(ProductRecommendation product) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.white, 
  //       borderRadius: BorderRadius.circular(16), 
  //       border: Border.all(color: const Color(0xFFEBEAE6)),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 70,
  //             height: 70,
  //             decoration: BoxDecoration(color: const Color(0xFFF7F6F3), borderRadius: BorderRadius.circular(12)),
  //             child: const Icon(Icons.spa_outlined, color: colorPrimary),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(product.brand.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimary)),
  //                 const SizedBox(height: 2),
  //                 Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
  //                 const SizedBox(height: 4),
  //                 Text("RM ${product.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
  //               ],
  //             ),
  //           ),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //             decoration: BoxDecoration(color: const Color(0xFFF7F6F3), borderRadius: BorderRadius.circular(8)),
  //             child: Text("${product.matchScore}% Match", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimary)),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildProductCount(List filteredList, String currentCategory) {
    final int count = filteredList.length;
    
    final bool isFiltered = currentCategory != 'All' || _selectedBrand != 'All';

    return Text(
      isFiltered ? "Showing $count products" : "Showing all $count products",
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
        color: const Color(0xFF2E2F2D).withOpacity(0.5),
      ),
    );
  }

  Widget _buildProductCard(ProductRecommendation product) {    
    // Check if this specific item is in our wishlist
    final bool isWishlisted = wishlistedProductIds.contains(product.id.toString());

    return GestureDetector(
      onTap: () async {
        final bool? updatedIsWishlisted = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPage(userId: widget.userId.toString(), productId: product.id.toString())
          ),
        );

        if (updatedIsWishlisted != null) {
          setState(() {
            if (updatedIsWishlisted) {
              wishlistedProductIds.add(product.id.toString().trim());
            } else {
              wishlistedProductIds.remove(product.id.toString().trim());
            }
          });
        }
        // _fetchProducts(); 
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- IMAGE CONTAINER ---
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      "${widget.baseUrl}/images/${product.image}",
                      fit: BoxFit.cover, 
                      width: double.infinity,
                      errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),

                // Match Score Badge: Floating at the top
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                    ),
                    child: Text(
                      "${product.matchScore}% Match", 
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimary),
                    ),
                  ),
                ),

                // Wishlist Heart: Floating at the bottom
                Positioned(
                  bottom: 20, right: 10,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(product.id.toString()),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isWishlisted ? const Color(0xFF91462E) : colorPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // --- TEXT DETAILS ---
          const SizedBox(height: 12),
          // Brand Name (Small, subtle)
          Text(
            product.brand.toUpperCase(), 
            style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.8, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          // Product Name
          Text(
            product.name, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Price
          Text(
            "RM ${product.price.toStringAsFixed(2)}", 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colorPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandFilter() {
    return SizedBox(
      height: 40, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16), // Padding here instead
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          final brand = _brands[index];
          final isSelected = _selectedBrand == brand;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedBrand = brand),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorPrimary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? colorPrimary : Colors.black.withOpacity(0.04),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: colorPrimary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Center(
                child: Text(
                  brand,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                    color: isSelected ? Colors.white : const Color(0xFF2E2F2D).withOpacity(0.7),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSortOption,
          hint: const Text("Sort", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.sort, size: 14, color: colorPrimary),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E2F2D)),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSortOption = newValue;
                _applySorting(); 
              });
            }
          },
          items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
        ),
      ),
    );
  }
}