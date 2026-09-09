import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:path_provider/path_provider.dart';

class SkinComparisonPage extends StatefulWidget {
  final String userId;
  const SkinComparisonPage({super.key, required this.userId});

  @override
  State<SkinComparisonPage> createState() => _SkinComparisonPageState();
}

class _SkinComparisonPageState extends State<SkinComparisonPage> {
  List<dynamic> _historyScans = [];
  Map<String, dynamic>? _scan1; 
  Map<String, dynamic>? _scan2; 
  Map<String, dynamic>? _comparisonResult;
  bool _isLoading = true;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final data = await ApiService.getSkinProgress(widget.userId);
    setState(() {
      _historyScans = data is List ? data : (data['progress'] ?? []);
      _isLoading = false;
    });
  }

  void _openScanPicker(bool isScan1) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F6F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isScan1 ? "Select Before Scan" : "Select After Scan",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF91462E),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _historyScans.isEmpty
                    ? const Center(child: Text("No past scans found"))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                          // childAspectRatio: 0.8,
                        ),
                        itemCount: _historyScans.length,
                        itemBuilder: (context, index) {
                          final scan = _historyScans[index];
                          final imagePath = scan['image'] ?? '';
                          final date = (scan['created_at'] ?? '').split(' ')[0];

                          final dynamic currentSelected = isScan1 ? _scan1 : _scan2;
                          final bool isSelected = currentSelected != null && 
                              currentSelected['id'].toString() == scan['id'].toString();

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isScan1) {
                                  _scan1 = scan;
                                } else {
                                  _scan2 = scan;
                                }
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF91462E) : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: _buildScanImage(imagePath),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      date,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    // Ensure we don't duplicate slashes if path already contains leading slash or full url
    final String imageUrl = path.startsWith('http') 
        ? path 
        : "${ApiService.baseUrl}/${path.startsWith('/') ? path.substring(1) : path}";

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (c, e, s) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Future<void> _runComparison() async {
    if (_scan1 == null || _scan2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a Before and After scan.')),
      );
      return;
    }
    if (_scan1!['id'].toString() == _scan2!['id'].toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two different scans to compare.')),
      );
      return;
    }

    setState(() => _isComparing = true);
    final result = await ApiService.compareScans(_scan1!['id'].toString(), _scan2!['id'].toString());
    setState(() {
      _comparisonResult = result;
      _isComparing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "Skin Progress Comparison",
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: colorPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Images to Compare",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap the cards below to pick photos from your history gallery.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildImageSelectorCard("Before Scan", _scan1, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildImageSelectorCard("After Scan", _scan2, false)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isComparing ? null : _runComparison,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: _isComparing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "COMPARE SCANS",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 14),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_comparisonResult != null && _comparisonResult!['status'] == 'success')
                    _buildResultsCard(_comparisonResult!),
                ],
              ),
            ),
    );
  }

  Widget _buildImageSelectorCard(String label, Map<String, dynamic>? scanData, bool isScan1) {
    return GestureDetector(
      onTap: () => _openScanPicker(isScan1),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scanData != null ? const Color(0xFF91462E) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: scanData != null
                  ? _buildScanImage(scanData['image'], height: 110, width: double.infinity)
                  : Container(
                      height: 110,
                      width: double.infinity,
                      color: const Color(0xFFF7F6F3),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF91462E), size: 30),
                          SizedBox(height: 4),
                          Text("Tap to pick", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              scanData != null ? (scanData['created_at'] ?? '').split(' ')[0] : "Not selected",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: scanData != null ? Colors.black87 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(Map<String, dynamic> result) {
    final older = result['older_scan'];
    final newer = result['newer_scan'];
    final double healthDiff = (result['health_score_change'] ?? 0).toDouble();
    final double olderScore = (older['health_score'] ?? 0).toDouble();
    final double newerScore = (newer['health_score'] ?? 0).toDouble();
    final Map<String, dynamic> conditionDiffs = result['condition_changes'] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Comparison Analysis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF91462E))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _imagePreview("Before", older['image'], older['created_at']),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF91462E)),
              _imagePreview("After", newer['image'], newer['created_at']),
            ],
          ),
          const Divider(height: 30),
          // Overall Health Score display
          Text(
            "Overall Health Score: $olderScore% → $newerScore% (${healthDiff >= 0 ? '+' : ''}$healthDiff%)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: healthDiff >= 0 ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Condition Metrics Breakdown (Higher = Better):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          ...conditionDiffs.entries.map((entry) {
            final name = entry.key;
            final diffData = entry.value;
            final double difference = (diffData['difference'] ?? 0).toDouble();
            // Since higher marks = better, positive or zero difference means improvement
            final bool isImproved = difference >= 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    "${difference >= 0 ? '+' : ''}$difference% (${diffData['older']}% → ${diffData['newer']}%)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isImproved ? Colors.green[700] : Colors.orange[800],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _imagePreview(String label, String imagePath, String date) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildScanImage(imagePath, width: 90, height: 90),
        ),
        const SizedBox(height: 4),
        Text(date.split(' ')[0], style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}