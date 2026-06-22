// import 'package:flutter/material.dart';

// class SkinHistoryDetailPage extends StatelessWidget {
//   final Map<String, dynamic> scan;

//   const SkinHistoryDetailPage({super.key, required this.scan});

//   @override
//   Widget build(BuildContext context) {
//     final Color colorPrimary = const Color(0xFF91462E);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F6F3),
//       appBar: AppBar(
//         title: const Text("Scan Details", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF91462E))),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: colorPrimary,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 1. Large Image Preview
//             ClipRRect(
//               borderRadius: BorderRadius.circular(32),
//               child: Image.network(
//                 // "http://192.168.0.22/skinmate_api/${scan['image']}"
//                 "http://10.0.2.2/skinmate_api/${scan['image']}",
//                 // "http://192.168.101.170/skinmate_api/${scan['image']}",
//                 width: double.infinity,
//                 height: 500,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             const SizedBox(height: 24),

//             // 2. Date and Status
//             Text(
//               scan['created_at'].toString(),
//               style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Result: ${scan['skin_type']}",
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorPrimary),
//             ),
            
//             const Divider(height: 40),

//             // 3. Detail Metrics
//             _buildDetailSection("Conditions Detected", scan['skin_conditions']),
//             _buildDetailSection("Recommended Routine", "Use a gentle cleanser and non-comedogenic moisturizer."),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailSection(String title, String content) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SkinHistoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> scan;

  const SkinHistoryDetailPage({super.key, required this.scan});

  // Reusing your brand palette
  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  @override
  Widget build(BuildContext context) {
    // Safely parse health score
    final int healthScore = (scan['health_score'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text("Scan Report", 
          style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: colorPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image Section
            Center(
              child: Hero(
                tag: 'scan_image_${scan['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    "${ApiService.baseUrl}/${scan['image']}",
                    width: double.infinity,
                    height: 500,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(height: 300, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Summary Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan['created_at'].toString().split(' ')[0],
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "${scan['skin_type']} Skin",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorPrimary),
                    ),
                  ],
                ),
                // Circular Health Badge
                _buildCircularScore(healthScore),
              ],
            ),
            
            const Divider(height: 40, thickness: 1),

            // 3. Condition Breakdown (The Health Bars)
            const Text("Condition Analysis", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary)),
            const SizedBox(height: 16),
            
            // Map the database columns back to the UI
            _buildConditionBar("Acne", scan['acne_pct']),
            _buildConditionBar("Dark Spots", scan['dark_spots_pct']),
            _buildConditionBar("Pigmentation", scan['pigmentation_pct']),
            _buildConditionBar("Pores", scan['pores_pct']),
            _buildConditionBar("Redness", scan['redness_pct']),
            _buildConditionBar("Wrinkles", scan['wrinkles_pct']),

            const SizedBox(height: 32),

            // 4. Recommendation Section
            _buildRecommendationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularScore(int score) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 6,
            backgroundColor: Colors.grey[200],
            color: score < 40 ? Colors.redAccent : (score < 75 ? Colors.orange : Colors.green),
          ),
        ),
        Text("$score%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildConditionBar(String label, dynamic value) {
    double score = (value as num?)?.toDouble() ?? 0.0;
    double progress = (score / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("${score.toStringAsFixed(1)}%"),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: score < 40 ? Colors.redAccent : (score < 75 ? Colors.orange : Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorPrimary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: colorPrimary),
              SizedBox(width: 8),
              Text("Expert Advice", style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Based on your ${scan['skin_type'].toString().toLowerCase()} skin profile, focus on maintaining hydration and using sun protection to improve your score.",
            style: const TextStyle(color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}