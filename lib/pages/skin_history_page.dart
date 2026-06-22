import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'skin_history_detail_page.dart'; // 👈 Import the detail page

class SkinHistoryPage extends StatelessWidget {
  final String userId;
  final VoidCallback onBack; // 👈 1. Added this variable

  const SkinHistoryPage({
    super.key, 
    required this.userId, 
    required this.onBack, // 👈 2. Added to constructor
  });

  // 🎨 Palette
  final Color colorPrimary = const Color(0xFF91462E);
  final Color colorBackground = const Color(0xFFF7F6F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        // 👈 3. Added the leading button to trigger the back action
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack, 
        ),
        title: const Text("Scan History", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF91462E))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getSkinHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            // itemBuilder: (context, index) {
            //   final scan = snapshot.data![index];
            //   return _buildHistoryCard(scan);
            // },
            itemBuilder: (context, index) {
              // 👈 Cast to Map explicitly to prevent "type 'dynamic' is not a subtype of Map" errors
              final Map<String, dynamic> scan = Map<String, dynamic>.from(snapshot.data![index]); 
              return _buildHistoryCard(context, scan);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> scan) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SkinHistoryDetailPage(scan: scan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. Skin Image Preview with Hero Animation
              Hero(
                tag: 'scan_image_${scan['id']}', // 🌟 Unique tag for animation
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "${ApiService.baseUrl}/${scan['image']}",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 2. Scan Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan['created_at'].toString().split(' ')[0],
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Skin Type: ${scan['skin_type']}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary, fontSize: 16),
                    ),
                    // Text(
                    //   "Condition: ${scan['skin_conditions']}",
                    //   style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    // ),
                    Text(
                      "Overall Health Score: ${scan['health_score']}%",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: colorPrimary.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No scans yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Your skin progress will appear here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}