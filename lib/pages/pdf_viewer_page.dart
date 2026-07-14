import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfViewerPage extends StatefulWidget {
  final String url;
  const PdfViewerPage({super.key, required this.url});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      
      if (mounted) {
        setState(() {
          localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error downloading PDF: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);
    const colorSurface = Color(0xFFF7F6F3);
    const colorOnSurface = Color(0xFF2E2F2D);

    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "Document Preview",
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: Color(0xFF91462E)),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : localPath != null
              ? PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onError: (error) {
                    debugPrint("PDFView Error: $error");
                  },
                  onRender: (pages) {
                    debugPrint("PDF rendered with $pages pages.");
                  },
                )
              : const Center(child: Text("Failed to load PDF")),
    );
  }
}