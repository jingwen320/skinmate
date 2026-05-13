import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'product_page.dart';

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
  String _userName = "User"; // Default fallback

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
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    
    // 1. Fetch Products
    final response = await ApiService.getProducts();
    
    // 2. Fetch User Profile for the Name
    final profileRes = await ApiService.getProfile(widget.userId);

    setState(() {
      // Handle products
      products = response is List ? response : response['products'] ?? [];
      
      // 🌟 Handle User Name
      if (profileRes['status'] == 'success') {
        // We convert to uppercase to match your design style
        _userName = (profileRes['user']['name'] ?? "User").toUpperCase();
      }
      
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                const SliverToBoxAdapter(child: SizedBox(height: 125)),

                // 2. SEARCH BAR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products or concerns...',
                        prefixIcon: Icon(Icons.search, color: colorPrimary),
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

                // 3. HERO: AI SCAN BANNER
                SliverToBoxAdapter(child: _buildHeroSection()),

                // 4. CATEGORIES
                SliverToBoxAdapter(child: _buildCategoriesSection()),

                // 5. PRODUCT GRID HEADER
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Bestsellers",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("View All",
                            style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                // 6. DYNAMIC PRODUCT GRID
                isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()))
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
                            (context, index) => _buildProductCard(products[index]),
                            childCount: products.length,
                          ),
                        ),
                      ),
                
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
                  _buildIconButton(Icons.notifications_none_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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
                        category == 'All' ? Icons.auto_awesome : Icons.spa_outlined,
                        color: colorPrimary,
                      ),
                      const SizedBox(height: 4),
                      Text(category,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildProductCard(dynamic product) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ProductPage(userId: widget.userId, productId: product['id'].toString()))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: colorSurfaceLow, borderRadius: BorderRadius.circular(24)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: product['image'] != null
                    ? Image.network(product['image'], fit: BoxFit.cover)
                    : const Icon(Icons.image),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(product['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text("RM ${product['price']}",
              style: TextStyle(color: colorPrimary, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.black12)),
      child: Icon(icon, color: colorPrimary, size: 20),
    );
  }
}