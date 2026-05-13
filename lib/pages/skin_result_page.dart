import 'package:flutter/material.dart';

class SkinResultPage extends StatelessWidget {
  final String skinType;
  final int healthScore;
  final Map<String, dynamic> conditions;

  const SkinResultPage({
    super.key,
    required this.skinType,
    required this.healthScore,
    required this.conditions,
  });

  // Theme Colors matching your brand
  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text("Analysis Result", 
          style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. TOP SCORE SECTION
            _buildScoreHeader(),
            const SizedBox(height: 32),

            // 2. SKIN TYPE BADGE
            _buildTypeBadge(),
            const SizedBox(height: 32),

            // 3. DETAILED MARKS SECTION
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Condition Breakdown", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary)),
            ),
            const SizedBox(height: 16),
            
            // Generate bars for each condition
            ...conditions.entries.map((entry) => _buildConditionBar(entry.key, entry.value)).toList(),
            
            const SizedBox(height: 40),
            
            // 4. BACK BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("CLOSE REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: healthScore / 100,
                strokeWidth: 10,
                backgroundColor: Colors.grey[200],
                color: healthScore > 70 ? Colors.green : colorPrimary,
              ),
            ),
            Text("$healthScore", 
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 12),
        const Text("Overall Health Score", style: TextStyle(color: Colors.grey, letterSpacing: 1)),
      ],
    );
  }

  // Widget _buildScoreHeader() {
  //   // Ensure healthScore is treated as a double for the progress indicator
  //   double progress = healthScore / 100.0; 

  //   return Column(
  //     children: [
  //       Stack(
  //         alignment: Alignment.center,
  //         children: [
  //           SizedBox(
  //             width: 140,
  //             height: 140,
  //             child: CircularProgressIndicator(
  //               value: progress.clamp(0.0, 1.0),
  //               strokeWidth: 12,
  //               strokeCap: StrokeCap.round,
  //               backgroundColor: Colors.grey[200],
  //               // Color transitions based on health
  //               color: healthScore < 40 ? Colors.redAccent : 
  //                     (healthScore < 75 ? Colors.orange : Colors.green),
  //             ),
  //           ),
  //           Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text("$healthScore", 
  //                 style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorPrimary)),
  //               const Text("%", style: TextStyle(fontSize: 18, color: colorPrimary)),
  //             ],
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       const Text("Overall Health Score", 
  //         style: TextStyle(color: Colors.black54, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
  //     ],
  //   );
  // }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFED07F).withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFED07F)),
      ),
      child: Text(
        "${skinType.toUpperCase()} SKIN",
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B3400), letterSpacing: 1),
      ),
    );
  }

  // Widget _buildConditionBar(String label, dynamic value) {
  //   // Convert to double in case PHP sends it as a string or int
  //   double pct = double.tryParse(value.toString()) ?? 0.0;
    
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 10.0),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
  //             Text("${(pct * 100).toStringAsFixed(1)}%"),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         ClipRRect(
  //           borderRadius: BorderRadius.circular(5),
  //           child: LinearProgressIndicator(
  //             value: pct,
  //             minHeight: 10,
  //             backgroundColor: Colors.white,
  //             color: pct > 0.6 ? Colors.redAccent : colorPrimary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildConditionBar(String label, dynamic value) {
    // Now value is 0-100 (e.g., 86.5)
    double score = double.tryParse(value.toString()) ?? 0.0;
    double progressValue = score / 100; // Convert to 0.0 - 1.0 for the bar

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("${score.toStringAsFixed(1)}%"), // Displays "86.5%"
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
              backgroundColor: Colors.white,
              // Logic: Color is Red if score is LOW (Bad Health), Green if HIGH
              color: score < 40 ? Colors.redAccent : (score < 70 ? Colors.orange : Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}