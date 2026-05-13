// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../services/api_service.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// class ScanPage extends StatefulWidget {
//   final String userId;
//   const ScanPage({super.key, required this.userId});

//   @override
//   State<ScanPage> createState() => _ScanPageState();
// }

// class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
//   File? _imageFile;
//   bool _loading = false;
//   Map<String, dynamic>? _result;
//   late AnimationController _scanController;
//   final ImagePicker _picker = ImagePicker();
  
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isCameraInitialized = false;

//   final Color colorPrimary = const Color(0xFF91462E);
//   final Color colorPrimaryContainer = const Color(0xFFFE9D7F);
//   final Color colorTertiaryContainer = const Color(0xFFFED07F);
//   final Color colorBackground = const Color(0xFFF7F6F3);

//   @override
//   void initState() {
//     super.initState();
//     _scanController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     )..repeat(reverse: true);
//     _initCamera();
//   }

//   Future<void> _initCamera() async {
//     _cameras = await availableCameras();
//     if (_cameras != null && _cameras!.isNotEmpty) {
//       final front = _cameras!.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.front,
//         orElse: () => _cameras![0],
//       );
//       _cameraController = CameraController(front, ResolutionPreset.high, enableAudio: false);
//       try {
//         await _cameraController!.initialize();
//         if (!mounted) return;
//         setState(() => _isCameraInitialized = true);
//       } catch (e) {
//         debugPrint("Camera error: $e");
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _scanController.dispose();
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path);
//         _result = null;
//       });
//     }
//   }

//   Future<void> _captureFromLiveFeed() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) return;
//     setState(() => _loading = true);
//     try {
//       final XFile photo = await _cameraController!.takePicture();
//       setState(() {
//         _imageFile = File(photo.path);
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() => _loading = false);
//       debugPrint("Capture error: $e");
//     }
//   }

//   Future<void> _uploadImage() async {
//     if (_imageFile == null) return;
//     setState(() => _loading = true);
//     try {
//       var uri = Uri.parse('${ApiService.baseUrl}/upload_skin.php');
//       var request = http.MultipartRequest('POST', uri);
//       request.fields['user_id'] = widget.userId;
//       var multipartFile = await http.MultipartFile.fromPath(
//         'image', _imageFile!.path,
//         contentType: MediaType('image', 'png'),
//       );
//       request.files.add(multipartFile);
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);
//       var res = json.decode(response.body);
//       if (res['status'] == 'success') setState(() => _result = res);
//     } catch (e) {
//       debugPrint('Upload error: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: colorBackground,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text("Skin Scan", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
//         actions: [
//           _buildTopAction(Icons.flash_off),
//           _buildTopAction(Icons.flip_camera_ios),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   // 1. MAIN FEED (Camera or File)
//                   Container(
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.circular(40),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(40),
//                       child: _imageFile != null
//                           ? Image.file(_imageFile!, fit: BoxFit.cover)
//                           : (_isCameraInitialized 
//                               ? CameraPreview(_cameraController!) 
//                               : const Center(child: CircularProgressIndicator())),
//                     ),
//                   ),

//                   // 2. VIEW FINDER
//                   _buildViewfinderOverlay(),

//                   // 3. SCANNING LINE
//                   if (_loading || (_imageFile != null && _result == null))
//                     _buildScanningLine(),

//                   // 4. TIPS OVERLAY (Visible only when no image is captured)
//                   if (_imageFile == null) _buildTipsOverlay(),

//                   // 5. HUD STATUS / RESULTS
//                   Positioned(bottom: 24, left: 24, right: 24, child: _buildHUD()),
//                 ],
//               ),
//             ),
//           ),
//           _buildBottomActions(),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   Widget _buildTipsOverlay() {
//     return Positioned(
//       top: 30, // Sits above the HUD
//       left: 0, right: 0,
//       child: SizedBox(
//         height: 90,
//         child: ListView(
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           children: [
//             _tipCard(Icons.wb_sunny_outlined, "Light", "Natural light is best"),
//             _tipCard(Icons.face_retouching_off, "Clean", "No makeup or SPF"),
//             _tipCard(Icons.center_focus_strong, "Steady", "Hold 15cm away"),
//             _tipCard(Icons.flash_off, "No Flash", "Avoid glare/reflections"),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _tipCard(IconData icon, String title, String desc) {
//     return Container(
//       width: 150,
//       margin: const EdgeInsets.only(right: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white12),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: colorTertiaryContainer, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
//                 Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 9)),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildScanningLine() {
//     return AnimatedBuilder(
//       animation: _scanController,
//       builder: (context, child) {
//         return Positioned(
//           top: 100 + (250 * _scanController.value),
//           left: 60, right: 60,
//           child: Container(
//             height: 3,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(colors: [Colors.transparent, colorPrimaryContainer, Colors.transparent]),
//               boxShadow: [BoxShadow(color: colorPrimaryContainer.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildBottomActions() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Row(
//         children: [
//           IconButton(onPressed: _pickImage, icon: Icon(Icons.photo_library_outlined, color: colorPrimary)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: TextButton(
//               onPressed: () => setState(() { _imageFile = null; _result = null; }),
//               child: const Text("Retake", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: ElevatedButton(
//               onPressed: _loading ? null : (_imageFile == null ? _captureFromLiveFeed : _uploadImage),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorPrimary,
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
//               ),
//               child: _loading 
//                 ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                 : Text(_imageFile == null ? "Capture" : "Analyze Skin", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHUD() {
//     if (_result != null) {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24)),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("ANALYSIS COMPLETE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1)),
//             const SizedBox(height: 8),
//             Text("Skin Type: ${_result!['skin_type']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             Text("Conditions: ${_result!['skin_conditions']}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
//           ],
//         ),
//       );
//     }
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
//       child: const Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.auto_awesome, size: 16),
//           SizedBox(width: 8),
//           Text("Detecting texture...", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }

//   Widget _buildViewfinderOverlay() {
//     return Container(
//       width: 250, height: 320,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
//         borderRadius: BorderRadius.circular(60),
//       ),
//       child: Stack(
//         children: [
//           _corner(top: 0, left: 0, angle: 0),
//           _corner(top: 0, right: 0, angle: 1.57),
//           _corner(bottom: 0, left: 0, angle: -1.57),
//           _corner(bottom: 0, right: 0, angle: 3.14),
//         ],
//       ),
//     );
//   }

//   Widget _corner({double? top, double? left, double? right, double? bottom, required double angle}) {
//     return Positioned(
//       top: top, left: left, right: right, bottom: bottom,
//       child: Transform.rotate(angle: angle, child: Icon(Icons.north_west, color: colorPrimaryContainer, size: 40)),
//     );
//   }

//   Widget _buildTopAction(IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 8),
//       child: CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(icon, color: Colors.black, size: 20)),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'skin_result_page.dart';

class ScanPage extends StatefulWidget {
  final String userId;
  const ScanPage({super.key, required this.userId});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  File? _imageFile;
  bool _loading = false;
  Map<String, dynamic>? _result;
  late AnimationController _scanController;
  final ImagePicker _picker = ImagePicker();
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 0; // Index for front/rear rotation
  bool _isCameraInitialized = false;

  // AR/Positioning Logic
  bool _isFaceCentered = false;
  bool _isDetecting = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableTracking: true, performanceMode: FaceDetectorMode.fast),
  );

  final Color colorPrimary = const Color(0xFF91462E);
  final Color colorPrimaryContainer = const Color(0xFFFE9D7F);
  final Color colorTertiaryContainer = const Color(0xFFFED07F);
  final Color colorBackground = const Color(0xFFF7F6F3);

  @override
  void initState() {
    super.initState();
    // Requirement 1: Animation starts BEFORE scanning
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Use _cameraIndex instead of 'front' or '0'
      _cameraController = CameraController(
        _cameras![_cameraIndex], 
        ResolutionPreset.high, 
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      try {
        await _cameraController!.initialize();
        
        // Re-start the AR positioning stream for the new lens
        _cameraController!.startImageStream((image) {
          if (_isDetecting || _imageFile != null) return;
          _detectFace(image);
        });

        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
      } catch (e) {
        debugPrint("Camera error: $e");
      }
    }
  }

  // Requirement 4: Camera Rotation (Front/Rear)
  void _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    // 1. Update the index
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;

    // 2. IMPORTANT: Stop the current stream and dispose
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
    }

    // 3. Reset state so the UI shows a loading spinner during transition
    setState(() {
      _isCameraInitialized = false;
    });

    // 4. Restart with the new index
    _initCamera();
  }

  Future<void> _detectFace(CameraImage image) async {
    _isDetecting = true;
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(_cameras![_cameraIndex].sensorOrientation) 
                    ?? InputImageRotation.rotation0deg,
          format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);
      if (mounted) {
        setState(() => _isFaceCentered = faces.isNotEmpty);
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    }
    _isDetecting = false;
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _result = null;
        _scanController.stop(); // Requirement 2: Remove animation
      });
    }
  }

  Future<void> _captureFromLiveFeed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _loading = true);
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _imageFile = File(photo.path);
        _loading = false;
        // Requirement 2: Stop animation after capture
        _scanController.stop(); 
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("Capture error: $e");
    }
  }

  // Future<void> _uploadImage() async {
  //   if (_imageFile == null) return;
  //   setState(() => _loading = true);
  //   try {
  //     var uri = Uri.parse('${ApiService.baseUrl}/upload_skin.php');
  //     var request = http.MultipartRequest('POST', uri);
  //     request.fields['user_id'] = widget.userId;
  //     var multipartFile = await http.MultipartFile.fromPath(
  //       'image', _imageFile!.path,
  //       contentType: MediaType('image', 'png'),
  //     );
  //     request.files.add(multipartFile);
  //     var streamedResponse = await request.send();
  //     var response = await http.Response.fromStream(streamedResponse);
  //     var res = json.decode(response.body);
  //     if (res['status'] == 'success') setState(() => _result = res);
  //   } catch (e) {
  //     debugPrint('Upload error: $e');
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() => _loading = true);
    
    try {
      var uri = Uri.parse('${ApiService.baseUrl}/upload_skin.php');
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['user_id'] = widget.userId;
      var multipartFile = await http.MultipartFile.fromPath(
        'image', 
        _imageFile!.path,
        contentType: MediaType('image', 'jpeg'), // Match your PHP check
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var res = json.decode(response.body);

      if (res['status'] == 'success') {
        // 1. Update local state
        setState(() => _result = res);

        // 2. Navigate to the new Results Page
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SkinResultPage(
              skinType: res['skin_type'],
              healthScore: res['health_score'],
              conditions: res['conditions'], 
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${res['message']}")),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Skin Scan", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
        actions: [
          // Requirement 3 & 4: No Flash, Rotatable Camera Icon
          IconButton(
            onPressed: _toggleCamera,
            icon: CircleAvatar(
              radius: 20, 
              backgroundColor: Colors.white, 
              child: Icon(Icons.flip_camera_ios, color: colorPrimary, size: 20)
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : (_isCameraInitialized 
                              ? CameraPreview(_cameraController!) 
                              : const Center(child: CircularProgressIndicator())),
                    ),
                  ),

                  // Requirement 5: Viewfinder color changes based on AR detection
                  _buildViewfinderOverlay(_isFaceCentered ? Colors.greenAccent : Colors.white),

                  // Requirement 1 & 2: Animation line (Only if image is NOT yet captured)
                  if (_imageFile == null) _buildScanningLine(),

                  // TIPS OVERLAY
                  if (_imageFile == null) _buildTipsOverlay(),

                  // Requirement 6: HUD Positioning Text
                  Positioned(bottom: 24, left: 24, right: 24, child: _buildHUD()),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    // if (_result != null) {
    //   return Container(
    //     padding: const EdgeInsets.all(16),
    //     decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24)),
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         const Text("ANALYSIS COMPLETE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1)),
    //         const SizedBox(height: 8),
    //         Text("Skin Type: ${_result!['skin_type']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    //         Text("Conditions: ${_result!['skin_conditions']}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
    //       ],
    //     ),
    //   );
    // }

    if (_result != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ANALYSIS COMPLETE", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1)),
                  Text("Detected: ${_result!['skin_type']} Skin", 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // Re-open results if they close it
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SkinResultPage(
                      skinType: _result!['skin_type'],
                      healthScore: _result!['health_score'],
                      conditions: _result!['conditions'],
                    ),
                  ),
                );
              },
              child: const Text("VIEW DETAILS"),
            )
          ],
        ),
      );
    }

    // Requirement 6: Updated Text
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isFaceCentered ? Colors.green.withOpacity(0.8) : Colors.white.withOpacity(0.7), 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isFaceCentered ? Icons.check_circle : Icons.person_pin_circle_outlined, size: 16),
          const SizedBox(width: 8),
          Text(
            _isFaceCentered ? "Perfect! Capture now." : "Position face within the area", 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return Positioned(
          top: 210 + (220 * _scanController.value),
          left: 60, right: 60,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: colorPrimaryContainer, blurRadius: 10, spreadRadius: 2)],
              color: colorPrimaryContainer,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Gallery icon - usually good to keep available
          IconButton(
            onPressed: _pickImage, 
            icon: Icon(Icons.photo_library_outlined, color: colorPrimary)
          ),

          // Only show the Refresh/Retake button once an image is captured
          if (_imageFile != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                setState(() {
                  _imageFile = null;
                  _result = null;
                  _scanController.repeat(reverse: true); // Restart AR animation
                });
              }, 
              icon: Icon(Icons.refresh, color: colorPrimary)
            ),
          ],

          const SizedBox(width: 12),
          
          Expanded(
            child: ElevatedButton(
              onPressed: _loading ? null : (_imageFile == null ? _captureFromLiveFeed : _uploadImage),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              ),
              child: _loading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _imageFile == null ? "Capture" : "Analyze Skin", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderOverlay(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 250, height: 320,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(60),
      ),
      child: Stack(
        children: [
          _corner(top: 0, left: 0, angle: 0, color: color),
          _corner(top: 0, right: 0, angle: 1.57, color: color),
          _corner(bottom: 0, left: 0, angle: -1.57, color: color),
          _corner(bottom: 0, right: 0, angle: 3.14, color: color),
        ],
      ),
    );
  }

  Widget _corner({double? top, double? left, double? right, double? bottom, required double angle, required Color color}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Transform.rotate(angle: angle, child: Icon(Icons.north_west, color: color, size: 40)),
    );
  }

  // --- Utility Widgets ---
  Widget _buildTipsOverlay() {
    return Positioned(
      top: 30, // Sits above the HUD
      left: 0, right: 0,
      child: SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            _tipCard(Icons.wb_sunny_outlined, "Light", "Natural light is best"),
            _tipCard(Icons.face_retouching_off, "Clean", "No makeup or SPF"),
            _tipCard(Icons.center_focus_strong, "Steady", "Hold 15cm away"),
            _tipCard(Icons.flash_off, "No Flash", "Avoid glare/reflections"),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(IconData icon, String title, String desc) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorTertiaryContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}