import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  final Color _colorPrimary = const Color(0xFF91462E);
  final Color _colorSurface = const Color(0xFFF7F6F3);
  final Color _colorCardBg = Colors.white;

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
      backgroundColor: _colorSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isScan1 ? "Select Initial Scan (Before)" : "Select Target Scan (After)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _colorPrimary,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  Text(
                    "${_historyScans.length} available",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _historyScans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            const Text("No past skin scans found", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _historyScans.length,
                        itemBuilder: (context, index) {
                          final scan = _historyScans[index];
                          final imagePath = scan['image'] ?? '';
                          final date = (scan['created_at'] ?? '').split(' ')[0];
                          // final score = scan['health_score']?.toString() ?? '--';

                          final rawScore = scan['health_score'];
                          final score = rawScore != null ? (rawScore is double ? rawScore.toStringAsFixed(0) : rawScore.toString()) : '--';

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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _colorCardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? _colorPrimary : Colors.grey.withOpacity(0.2),
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isSelected ? 0.06 : 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildScanImage(imagePath, fit: BoxFit.cover),
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "$score%",
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: Text(
                                      date,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
                                        color: isSelected ? _colorPrimary : Colors.black87,
                                      ),
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
    return Scaffold(
      backgroundColor: _colorSurface,
      appBar: AppBar(
        title: Text(
          "Skin Progress Tracking",
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: _colorPrimary),
        ),
        centerTitle: true,
        backgroundColor: _colorSurface,
        elevation: 0,
        foregroundColor: _colorPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _colorPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _colorPrimary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _colorPrimary.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_graph_rounded, color: _colorPrimary, size: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Analyze Skin Transformation",
                                style: TextStyle(fontWeight: FontWeight.bold, color: _colorPrimary, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Select two past scans to track your skin health progress over time.",
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Side-by-side selection stage
                  Row(
                    children: [
                      Expanded(child: _buildSelectorTile("Before Scan", _scan1, true)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                          ),
                          child: Icon(Icons.compare_arrows_rounded, color: _colorPrimary, size: 20),
                        ),
                      ),
                      Expanded(child: _buildSelectorTile("After Scan", _scan2, false)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action trigger button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isComparing ? null : _runComparison,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: _isComparing
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "GENERATE COMPARISON REPORT",
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, fontSize: 13),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Results dashboard view
                  if (_comparisonResult != null && _comparisonResult!['status'] == 'success')
                    _buildExecutiveResultsCard(_comparisonResult!),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectorTile(String label, Map<String, dynamic>? scanData, bool isScan1) {
    final hasData = scanData != null;
    final date = hasData ? (scanData['created_at'] ?? '').split(' ')[0] : "Tap to choose";
    final score = hasData ? "${scanData['health_score'] ?? '--'}%" : "";

    return GestureDetector(
      onTap: () => _openScanPicker(isScan1),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _colorCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasData ? _colorPrimary.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
            width: hasData ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                if (hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _colorPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(score, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _colorPrimary)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasData
                    ? _buildScanImage(scanData['image'], fit: BoxFit.cover)
                    : Container(
                        color: _colorSurface,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: _colorPrimary.withOpacity(0.7), size: 26),
                            const SizedBox(height: 6),
                            Text("Select scan", style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasData ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveResultsCard(Map<String, dynamic> result) {
    final older = result['older_scan'];
    final newer = result['newer_scan'];
    final double healthDiff = (result['health_score_change'] ?? 0).toDouble();
    final double olderScore = (older['health_score'] ?? 0).toDouble();
    final double newerScore = (newer['health_score'] ?? 0).toDouble();
    final Map<String, dynamic> conditionDiffs = result['condition_changes'] ?? {};
    final bool isPositiveProgress = healthDiff >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress Report",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _colorPrimary, fontFamily: 'Plus Jakarta Sans'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositiveProgress ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositiveProgress ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: isPositiveProgress ? Colors.green[700] : Colors.orange[800],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${isPositiveProgress ? '+' : ''}$healthDiff% Overall",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPositiveProgress ? Colors.green[700] : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Visual comparison side-by-side display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultPreviewCard("Before", older['image'], older['created_at'], olderScore),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _colorSurface, shape: BoxShape.circle),
                child: Icon(Icons.arrow_forward_rounded, color: _colorPrimary, size: 18),
              ),
              _buildResultPreviewCard("After", newer['image'], newer['created_at'], newerScore),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),

          // Metric breakdown section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Condition Metric Shifts",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              Text(
                "Higher is better",
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic metrics breakdown rows
          ...conditionDiffs.entries.map((entry) {
            final name = entry.key;
            final diffData = entry.value;
            final double difference = (diffData['difference'] ?? 0).toDouble();
            final double olderVal = (diffData['older'] ?? 0).toDouble();
            final double newerVal = (diffData['newer'] ?? 0).toDouble();
            final bool isImproved = difference >= 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _colorSurface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "$olderVal% → $newerVal%",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isImproved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${difference >= 0 ? '+' : ''}$difference%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isImproved ? Colors.green[700] : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultPreviewCard(String label, String imagePath, String date, double score) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(height: 6),
        SizedBox(
          width: 95,
          height: 95,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildScanImage(imagePath, fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                      child: Text(
                        "$score%",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(date.split(' ')[0], style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }
}