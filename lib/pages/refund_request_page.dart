import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class RefundRequestPage extends StatefulWidget {
  final String orderId;
  final String userId;

  const RefundRequestPage({super.key, required this.orderId, required this.userId});

  @override
  State<RefundRequestPage> createState() => _RefundRequestPageState();
}

class _RefundRequestPageState extends State<RefundRequestPage> {
  final _formKey = GlobalKey<FormState>();
  
  List<dynamic> _orderItems = [];
  Map<String, dynamic>? _selectedItem;
  int _quantity = 1;
  double _calculatedRefund = 0.0;
  
  String? _selectedReason;
  final TextEditingController _descController = TextEditingController();
  File? _proofFile;
  bool _isLoadingItems = true;
  bool _isSubmitting = false;

  final List<String> _reasons = ["Did not receive", "Received broken", "Allergy"];

  // THEME COLORS (Synced with Edit Profile)
  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  @override
  void initState() {
    super.initState();
    _fetchOrderItems();
  }

  Future<void> _fetchOrderItems() async {
    try {
      final res = await ApiService.getOrderItems(widget.orderId);
      if (mounted) {
        setState(() {
          // Based on your get_order_details.php, items are nested: res['order']['items']
          // Adjust this line if your ApiService already flattens it
          _orderItems = res['items'] ?? []; 
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  void _updatePrice() {
    if (_selectedItem != null) {
      String rawPrice = _selectedItem!['price'].toString().replaceAll('RM ', '').replaceAll(',', '');
      double price = double.tryParse(rawPrice) ?? 0.0;
      setState(() => _calculatedRefund = price * _quantity);
    }
  }

  Future<void> _handleAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: colorPrimary),
              title: const Text('Take Photo', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: colorPrimary),
              title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: colorPrimary),
              title: const Text('Upload PDF Document', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
              onTap: () { Navigator.pop(context); _pickFile(); }, // Your existing file_picker logic
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80); // Compressed for faster PHP upload

    if (image != null) {
      setState(() => _proofFile = File(image.path));
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _proofFile = File(result.files.single.path!));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 1. Initial trigger with confirmation dialog
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null || _proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields & upload proof"))
      );
      return;
    }

    // 💡 CONFIRMATION DIALOG
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Submission", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to submit this refund request? Please ensure all details are correct."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _executeApiCall();      // Trigger the actual upload
            },
            child: const Text("SUBMIT", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. The actual API execution
  Future<void> _executeApiCall() async {
    setState(() => _isSubmitting = true);
    
    try {
      final res = await ApiService.submitRefundRequest(
        orderId: widget.orderId,
        userId: widget.userId,
        productId: _selectedItem!['product_id'].toString(),
        reason: _selectedReason!,
        description: _descController.text,
        quantity: _quantity,
        amount: _calculatedRefund,
        file: _proofFile!,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['status'] == 'success') {
          _showSuccessFeedback(); // 💡 SHOW SUCCESS MESSAGE
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? "Submission failed"))
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Matching Input Decoration from Edit Profile
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: colorPrimary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showSuccessFeedback() {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // Force user to click the button
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              "Request Submitted!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your refund request has been successfully submitted. Our team will review your request. Please wait for approval.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Sheet
                  Navigator.pop(context, true); // Go back to History with refresh signal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("BACK TO ORDERS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: Text("Refund Request #${widget.orderId}", 
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: colorPrimary)),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoadingItems 
        ? const Center(child: CircularProgressIndicator(color: colorPrimary)) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Request Details", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans')),
                  const SizedBox(height: 20),

                  // ITEM SELECTOR
                  const Text("Select Item", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<dynamic>(
                    // 💡 Add this Key based on the list length to force a rebuild when data arrives
                    key: ValueKey(_orderItems.length), 
                    
                    // Use initialValue to avoid the "deprecated" warning, or 'value' for strict control
                    value: _selectedItem,
                    
                    hint: Text(_orderItems.isEmpty ? "No items available" : "Select an item"),
                    decoration: _inputDecoration("Return Item", Icons.shopping_bag_outlined),
                    
                    // 💡 Use .toList() and ensure the value is mapped correctly
                    items: _orderItems.map<DropdownMenuItem<dynamic>>((item) {
                      return DropdownMenuItem<dynamic>(
                        value: item, // This must be the whole Map object
                        child: Text(
                          item['name'] ?? "Unknown Product",
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                        ),
                      );
                    }).toList(),
                    
                    onChanged: _orderItems.isEmpty ? null : (dynamic newValue) {
                      setState(() {
                        _selectedItem = newValue;
                        _quantity = 1; // Reset quantity on item change
                      });
                      _updatePrice();
                    },
                  ),
                  
                  if (_selectedItem != null) ...[
                    const SizedBox(height: 20),
                    const Text("Quantity to Return", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Quantity", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500)),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: colorPrimary), onPressed: _quantity > 1 ? () { setState(() => _quantity--); _updatePrice(); } : null),
                              Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(icon: const Icon(Icons.add_circle_outline, color: colorPrimary), onPressed: _quantity < int.parse(_selectedItem!['qty'].toString()) ? () { setState(() => _quantity++); _updatePrice(); } : null),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text("Reason for Refund", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.black, fontWeight: FontWeight.w500),
                    decoration: _inputDecoration("Select Reason", Icons.help_outline),
                    items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _selectedReason = val),
                  ),

                  const SizedBox(height: 20),
                  const Text("Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500),
                    decoration: _inputDecoration("Describe the issue...", Icons.description_outlined),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),

                  const SizedBox(height: 20),
                  const Text("Proof Attachment", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _handleAttachment, // Calls the new choice menu
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12),
                        border: _proofFile != null ? Border.all(color: colorPrimary, width: 1) : null,
                      ),
                      child: _proofFile == null
                          ? Row(
                              children: [
                                const Icon(Icons.add_a_photo_outlined, color: colorPrimary),
                                const SizedBox(width: 12),
                                const Text("Upload Photo or Document", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500)),
                              ],
                            )
                          : Column(
                              children: [
                                // Show image preview if it's not a PDF
                                if (_proofFile!.path.toLowerCase().endsWith('.jpg') || _proofFile!.path.toLowerCase().endsWith('.png'))
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_proofFile!, height: 300, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    // Text("File Attached: ${_proofFile!.path.split('/').last}", 
                                    //   style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _handleAttachment,
                                  child: const Text("Change File", style: TextStyle(color: colorPrimary, fontSize: 12)),
                                )
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  if (_selectedItem != null) ...[
                    Center(
                      child: Text(
                        "Total Refund: RM ${_calculatedRefund.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SAVE/SUBMIT BUTTON (Matching Edit Profile)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("SUBMIT REQUEST", 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}